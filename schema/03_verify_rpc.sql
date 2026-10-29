CREATE OR REPLACE FUNCTION public.verify_user_by_email(p_email TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE auth.users 
    SET email_verified = true 
    WHERE lower(trim(email)) = lower(trim(p_email));
    
    RETURN jsonb_build_object('success', true);
END;
$$;
