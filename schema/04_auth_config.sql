-- Disable email verification and allow production and local redirect URLs for Google OAuth
UPDATE auth.config 
SET require_email_verification = false,
    allowed_redirect_urls = ARRAY[
      'https://futuer.vercel.app',
      'https://futuer.vercel.app/',
      'http://localhost:3000',
      'http://localhost:3000/',
      'http://localhost',
      'futuer://callback'
    ]::text[];
