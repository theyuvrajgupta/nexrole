import { type EmailOtpType } from "@supabase/supabase-js";
import { redirect } from "next/navigation";
import { type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

// Supabase's default (unmodified) email templates use {{ .ConfirmationURL }},
// which points at Supabase's own hosted /auth/v1/verify endpoint and lands here
// with a `code` param after it verifies the token server-side. Custom templates
// pointed directly at this route (SiteURL + token_hash + type) are the other
// possible shape, kept here in case a custom SMTP provider is added later and
// templates get customized to skip the hosted-verify hop.
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get("code");
  const token_hash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;
  const next = searchParams.get("next") ?? "/";

  const supabase = await createClient();

  if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      redirect(next);
    }
  } else if (token_hash && type) {
    const { error } = await supabase.auth.verifyOtp({ type, token_hash });
    if (!error) {
      redirect(next);
    }
  }

  redirect("/login?error=link-invalid-or-expired");
}
