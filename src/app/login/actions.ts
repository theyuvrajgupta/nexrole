"use server";

import { createClient } from "@/lib/supabase/server";

export type SendMagicLinkState = {
  status: "idle" | "sent" | "error";
  message?: string;
};

export async function sendMagicLink(
  _prev: SendMagicLinkState,
  formData: FormData,
): Promise<SendMagicLinkState> {
  const email = String(formData.get("email") ?? "")
    .trim()
    .toLowerCase();

  if (!email || !email.includes("@")) {
    return { status: "error", message: "Enter a valid email address." };
  }

  const supabase = await createClient();
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${siteUrl}/auth/confirm`,
      shouldCreateUser: true,
    },
  });

  if (error) {
    // The allowlist trigger rejects unknown emails at the database layer; surface
    // a single honest, non-technical message either way rather than leaking which
    // failure mode fired (also avoids confirming/denying who's on the allowlist).
    return {
      status: "error",
      message:
        "Couldn't send a sign-in link. If your email isn't on the invite list yet, ask the app owner to add it.",
    };
  }

  return { status: "sent", message: `Check ${email} for a sign-in link.` };
}
