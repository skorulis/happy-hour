"use client";

import Link from "next/link";
import { authClient } from "@/lib/auth-client";
import { useSearchParams } from "next/navigation";
import { type FormEvent, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

export function ForgotPasswordPageContent() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState(
    () => searchParams.get("email")?.trim() ?? "",
  );
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setMessage(null);
    setLoading(true);

    try {
      const result = await authClient.requestPasswordReset({
        email: email.trim(),
        redirectTo: "/reset-password",
      });

      if (result.error) {
        throw new Error(
          result.error.message ?? "Could not send reset email.",
        );
      }

      setMessage(
        "If that email exists, we sent a reset link. Check your inbox.",
      );
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Could not send reset email. Please try again.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-6 px-6 py-10">
      <header className="space-y-2 text-center">
        <h1 className="text-3xl font-bold text-foreground">Forgot password</h1>
        <p className="text-sm text-muted">
          Enter your email and we&apos;ll send you a link to reset your
          password.
        </p>
      </header>

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="space-y-1">
          <label
            htmlFor="email"
            className="block text-sm font-medium text-secondary"
          >
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            autoComplete="email"
            required
            className={inputClassName}
          />
        </div>

        {error ? <p className="text-sm text-danger">{error}</p> : null}
        {message ? <p className="text-sm text-muted">{message}</p> : null}

        <button type="submit" disabled={loading} className={buttonClassName}>
          {loading ? "Sending..." : "Send reset link"}
        </button>
      </form>

      <p className="text-center text-sm text-secondary">
        <Link
          href="/login"
          className="font-medium text-accent-soft hover:text-foreground"
        >
          Back to log in
        </Link>
      </p>
    </div>
  );
}
