"use client";

import { useActionState } from "react";
import { sendMagicLink, type SendMagicLinkState } from "./actions";

const initialState: SendMagicLinkState = { status: "idle" };

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(sendMagicLink, initialState);

  return (
    <main className="flex min-h-screen items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <h1 className="mb-1 text-2xl font-semibold">NexRole</h1>
        <p className="mb-6 text-sm text-neutral-500">
          Invite-only. Enter your email and we&apos;ll send you a sign-in link.
        </p>

        <form action={formAction} className="space-y-3">
          <input
            type="email"
            name="email"
            placeholder="you@example.com"
            required
            autoComplete="email"
            className="w-full rounded border border-neutral-300 px-3 py-2 text-sm outline-none focus:border-neutral-800"
          />
          <button
            type="submit"
            disabled={pending}
            className="w-full rounded bg-neutral-900 px-3 py-2 text-sm font-medium text-white disabled:opacity-50"
          >
            {pending ? "Sending…" : "Send sign-in link"}
          </button>
        </form>

        {state.status === "sent" && (
          <p className="mt-4 text-sm text-emerald-700">{state.message}</p>
        )}
        {state.status === "error" && (
          <p className="mt-4 text-sm text-red-700">{state.message}</p>
        )}
      </div>
    </main>
  );
}
