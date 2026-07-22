"use client";

import Link from "next/link";
import { authClient } from "@/lib/auth-client";
import { useRouter, useSearchParams } from "next/navigation";
import { type FormEvent, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

export function ResetPasswordPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const tokenError = searchParams.get("error");

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(
    tokenError ? "This reset link is invalid or has expired." : null,
  );
  const [loading, setLoading] = useState(false);

  const canReset = Boolean(token) && !tokenError;

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token) return;

    setError(null);

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);

    try {
      const result = await authClient.resetPassword({
        newPassword: password,
        token,
      });

      if (result.error) {
        throw new Error(
          result.error.message ?? "Could not reset password.",
        );
      }

      router.push("/login");
      router.refresh();
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Could not reset password. Please try again.",
      );
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-6 px-6 py-10">
      <header className="space-y-2 text-center">
        <h1 className="text-3xl font-bold text-foreground">Reset password</h1>
        <p className="text-sm text-muted">
          {canReset
            ? "Choose a new password for your account."
            : "This reset link is invalid or has expired."}
        </p>
      </header>

      {canReset ? (
        <form className="space-y-4" onSubmit={handleSubmit}>
          <div className="space-y-1">
            <label
              htmlFor="password"
              className="block text-sm font-medium text-secondary"
            >
              New password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="new-password"
              required
              minLength={8}
              className={inputClassName}
            />
          </div>

          <div className="space-y-1">
            <label
              htmlFor="confirmPassword"
              className="block text-sm font-medium text-secondary"
            >
              Confirm password
            </label>
            <input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              autoComplete="new-password"
              required
              minLength={8}
              className={inputClassName}
            />
          </div>

          {error ? <p className="text-sm text-danger">{error}</p> : null}

          <button type="submit" disabled={loading} className={buttonClassName}>
            {loading ? "Saving..." : "Reset password"}
          </button>
        </form>
      ) : (
        <div className="space-y-4">
          {error ? <p className="text-center text-sm text-danger">{error}</p> : null}
          <Link
            href="/forgot-password"
            className={`${buttonClassName} inline-block text-center`}
          >
            Request a new reset link
          </Link>
        </div>
      )}

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
