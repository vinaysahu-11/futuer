-- Futuer Phase 2: Separate Controller & Managed Device Onboarding + Secure Pairing
-- Schema enhancements and atomic pairing stored procedure

-- 1. Enhance public.devices table with enrollment_status
ALTER TABLE public.devices 
ADD COLUMN IF NOT EXISTS enrollment_status TEXT NOT NULL DEFAULT 'ENROLLED';

-- 2. Create pairing_requests table
CREATE TABLE IF NOT EXISTS public.pairing_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    controller_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL DEFAULT 'Secondary Device',
    pairing_code TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'CONSUMED', 'EXPIRED', 'CANCELLED'
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    consumed_by_device_id UUID REFERENCES public.devices(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pairing_code_status ON public.pairing_requests(pairing_code, status);
CREATE INDEX IF NOT EXISTS idx_pairing_controller ON public.pairing_requests(controller_user_id);

-- Enable RLS on pairing_requests
ALTER TABLE public.pairing_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Controller manage pairing requests" ON public.pairing_requests;
CREATE POLICY "Controller manage pairing requests" ON public.pairing_requests 
FOR ALL USING (controller_user_id = auth.uid());

DROP POLICY IF EXISTS "Agent lookup pending pairing requests" ON public.pairing_requests;
CREATE POLICY "Agent lookup pending pairing requests" ON public.pairing_requests 
FOR SELECT USING (status = 'PENDING');

-- 3. Atomic verify and consume function to prevent race conditions & replay attacks
CREATE OR REPLACE FUNCTION public.verify_and_consume_pairing_code(
    p_code TEXT,
    p_device_model TEXT DEFAULT 'Android Phone'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_req RECORD;
    v_device_id UUID;
BEGIN
    -- Look up and lock the pending request
    SELECT * INTO v_req
    FROM public.pairing_requests
    WHERE pairing_code = upper(trim(p_code))
      AND status = 'PENDING'
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Invalid pairing code or code has already been consumed.'
        );
    END IF;

    -- Check expiration
    IF now() > v_req.expires_at THEN
        UPDATE public.pairing_requests
        SET status = 'EXPIRED'
        WHERE id = v_req.id;

        RETURN jsonb_build_object(
            'success', false,
            'error', 'Pairing code has expired. Please request a new code on the Controller.'
        );
    END IF;

    -- Register the device under the Controller's account
    INSERT INTO public.devices (
        owner_user_id,
        device_name,
        device_model,
        device_platform,
        is_paired,
        enrollment_status,
        last_seen_at
    ) VALUES (
        v_req.controller_user_id,
        v_req.device_name,
        coalesce(nullif(trim(p_device_model), ''), 'Android Device'),
        'android',
        true,
        'ENROLLED',
        now()
    ) RETURNING id INTO v_device_id;

    -- Mark pairing request as CONSUMED (single-use)
    UPDATE public.pairing_requests
    SET status = 'CONSUMED',
        consumed_at = now(),
        consumed_by_device_id = v_device_id
    WHERE id = v_req.id;

    -- Audit log
    INSERT INTO public.device_audit_logs (
        owner_user_id,
        device_id,
        action,
        result
    ) VALUES (
        v_req.controller_user_id,
        v_device_id,
        'PAIRING_CODE_CONSUMED',
        'SUCCESS'
    );

    RETURN jsonb_build_object(
        'success', true,
        'device_id', v_device_id,
        'device_name', v_req.device_name,
        'controller_user_id', v_req.controller_user_id
    );
END;
$$;
