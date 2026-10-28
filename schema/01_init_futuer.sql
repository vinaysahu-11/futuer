-- Futuer Remote Device Management Platform Schema
-- InsForge PostgreSQL Database Migration

CREATE TABLE IF NOT EXISTS public.devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    device_model TEXT,
    device_platform TEXT NOT NULL DEFAULT 'android',
    pairing_code TEXT,
    pairing_code_expires_at TIMESTAMPTZ,
    is_paired BOOLEAN NOT NULL DEFAULT FALSE,
    battery_level INTEGER,
    is_charging BOOLEAN DEFAULT FALSE,
    permission_status JSONB DEFAULT '{}'::jsonb,
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_devices_owner ON public.devices(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_devices_pairing_code ON public.devices(pairing_code);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON public.devices(last_seen_at);

CREATE TABLE IF NOT EXISTS public.device_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_locations_device_time ON public.device_locations(device_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS public.device_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    app_package TEXT,
    notification_title TEXT,
    notification_text TEXT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_device_time ON public.device_notifications(device_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS public.call_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    call_type TEXT NOT NULL,
    phone_number TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_calls_device_time ON public.call_activity(device_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS public.device_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    session_type TEXT NOT NULL,
    status TEXT NOT NULL,
    session_data JSONB DEFAULT '{}'::jsonb,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_sessions_device_status ON public.device_sessions(device_id, status);

CREATE TABLE IF NOT EXISTS public.device_heartbeats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    connection_state TEXT NOT NULL,
    app_version TEXT,
    battery_level INTEGER,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_heartbeats_device_time ON public.device_heartbeats(device_id, received_at DESC);

CREATE TABLE IF NOT EXISTS public.device_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES public.devices(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    result TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_owner_time ON public.device_audit_logs(owner_user_id, created_at DESC);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_audit_logs ENABLE ROW LEVEL SECURITY;

-- Devices Policies
DROP POLICY IF EXISTS "Owner can manage devices" ON public.devices;
CREATE POLICY "Owner can manage devices" ON public.devices FOR ALL USING (auth.uid() = owner_user_id);

DROP POLICY IF EXISTS "Agent pairing lookup" ON public.devices;
CREATE POLICY "Agent pairing lookup" ON public.devices FOR SELECT USING (pairing_code IS NOT NULL);

DROP POLICY IF EXISTS "Agent update paired device" ON public.devices;
CREATE POLICY "Agent update paired device" ON public.devices FOR UPDATE USING (true);

-- Locations Policies
DROP POLICY IF EXISTS "Owner read locations" ON public.device_locations;
CREATE POLICY "Owner read locations" ON public.device_locations FOR SELECT USING (device_id IN (SELECT id FROM public.devices WHERE owner_user_id = auth.uid()));

DROP POLICY IF EXISTS "Agent insert locations" ON public.device_locations;
CREATE POLICY "Agent insert locations" ON public.device_locations FOR INSERT WITH CHECK (true);

-- Notifications Policies
DROP POLICY IF EXISTS "Owner read notifications" ON public.device_notifications;
CREATE POLICY "Owner read notifications" ON public.device_notifications FOR SELECT USING (device_id IN (SELECT id FROM public.devices WHERE owner_user_id = auth.uid()));

DROP POLICY IF EXISTS "Agent insert notifications" ON public.device_notifications;
CREATE POLICY "Agent insert notifications" ON public.device_notifications FOR INSERT WITH CHECK (true);

-- Call Activity Policies
DROP POLICY IF EXISTS "Owner read calls" ON public.call_activity;
CREATE POLICY "Owner read calls" ON public.call_activity FOR SELECT USING (device_id IN (SELECT id FROM public.devices WHERE owner_user_id = auth.uid()));

DROP POLICY IF EXISTS "Agent insert calls" ON public.call_activity;
CREATE POLICY "Agent insert calls" ON public.call_activity FOR INSERT WITH CHECK (true);

-- Sessions Policies
DROP POLICY IF EXISTS "Owner manage sessions" ON public.device_sessions;
CREATE POLICY "Owner manage sessions" ON public.device_sessions FOR ALL USING (device_id IN (SELECT id FROM public.devices WHERE owner_user_id = auth.uid()));

DROP POLICY IF EXISTS "Agent manage sessions" ON public.device_sessions;
CREATE POLICY "Agent manage sessions" ON public.device_sessions FOR ALL USING (true);

-- Heartbeats Policies
DROP POLICY IF EXISTS "Owner read heartbeats" ON public.device_heartbeats;
CREATE POLICY "Owner read heartbeats" ON public.device_heartbeats FOR SELECT USING (device_id IN (SELECT id FROM public.devices WHERE owner_user_id = auth.uid()));

DROP POLICY IF EXISTS "Agent insert heartbeats" ON public.device_heartbeats;
CREATE POLICY "Agent insert heartbeats" ON public.device_heartbeats FOR INSERT WITH CHECK (true);

-- Audit Logs Policies
DROP POLICY IF EXISTS "Owner read audit logs" ON public.device_audit_logs;
CREATE POLICY "Owner read audit logs" ON public.device_audit_logs FOR SELECT USING (owner_user_id = auth.uid());

DROP POLICY IF EXISTS "Owner insert audit logs" ON public.device_audit_logs;
CREATE POLICY "Owner insert audit logs" ON public.device_audit_logs FOR INSERT WITH CHECK (owner_user_id = auth.uid());
