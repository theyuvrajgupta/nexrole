import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { SignOutButton } from "@/components/sign-out-button";

export default async function Home() {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();
  const email = data?.claims?.email as string | undefined;

  if (!email) {
    // Belt-and-braces: middleware already redirects unauthenticated requests,
    // this just keeps the page correct if ever rendered without it.
    redirect("/login");
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 px-4">
      <h1 className="text-2xl font-semibold">NexRole</h1>
      <p className="text-sm text-neutral-500">Signed in as {email}</p>
      <p className="max-w-sm text-center text-sm text-neutral-400">
        Auth spine is wired up. Profiles, job finder, fit analysis, documents, and
        interview prep land in the milestones that follow.
      </p>
      <SignOutButton />
    </main>
  );
}
