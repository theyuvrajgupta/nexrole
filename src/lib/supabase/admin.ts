import { createClient as createSupabaseClient } from "@supabase/supabase-js";

/**
 * Service-role Supabase client. Bypasses RLS entirely — server-only, and only
 * for operations that must run before a user has a session (e.g. managing the
 * allowed_emails table from a future admin surface). Never import this from
 * client code or from anything reachable without an explicit admin check.
 */
export function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SECRET_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );
}
