import { createBrowserClient } from "@supabase/ssr";

/**
 * Browser-side Supabase client. Uses the publishable key only — safe to ship
 * to the client. Never import the secret key here.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
  );
}
