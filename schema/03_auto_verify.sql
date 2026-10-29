-- Function to auto verify a user by email on demand
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

-- Trigger to auto verify every user on insert
CREATE OR REPLACE FUNCTION public.auto_verify_user_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    NEW.email_verified := true;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_auto_verify_user_email ON auth.users;
CREATE TRIGGER trigger_auto_verify_user_email
BEFORE INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.auto_verify_user_email();
