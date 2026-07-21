"use client";

import Link from "next/link";
import { authClient, signOut } from "@/lib/auth-client";
import { useRouter } from "next/navigation";
import { useState } from "react";

type ProfilePageContentProps = {
  name: string;
  email: string;
  emailVerified: boolean;
  isAdmin: boolean;
};

export function ProfilePageContent({
  name,
  email,
  emailVerified,
  isAdmin,
}: ProfilePageContentProps) {
  const router = useRouter();
  const [verifyLoading, setVerifyLoading] = useState(false);
  const [verifyError, setVerifyError] = useState<string | null>(null);

  async function handleSignOut() {
    await signOut();
    router.push("/");
    router.refresh();
  }

  async function handleVerifyEmail() {
    setVerifyError(null);
    setVerifyLoading(true);

    try {
      const result = await authClient.emailOtp.sendVerificationOtp({
        email,
        type: "email-verification",
      });

      if (result.error) {
        throw new Error(result.error.message ?? "Could not send verification email.");
      }

      router.push(`/verify-email?email=${encodeURIComponent(email)}`);
    } catch (error) {
      setVerifyError(
        error instanceof Error
          ? error.message
          : "Could not send verification email.",
      );
      setVerifyLoading(false);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">User Profile</h1>
      </header>

      <div className="rounded-xl border border-border p-6">
        <dl className="space-y-4 text-sm">
          <div>
            <dt className="font-medium text-muted">Name</dt>
            <dd className="mt-1 text-foreground">{name}</dd>
          </div>
          <div>
            <dt className="font-medium text-muted">Email</dt>
            <dd className="mt-1 flex flex-wrap items-center gap-2 text-foreground">
              <span>{email}</span>
              {emailVerified ? (
                <span className="rounded-md border border-border bg-surface-muted px-2 py-0.5 text-xs font-medium text-muted">
                  Verified
                </span>
              ) : (
                <button
                  type="button"
                  disabled={verifyLoading}
                  onClick={() => void handleVerifyEmail()}
                  className="rounded-md border border-border px-2 py-0.5 text-xs font-medium text-secondary transition-colors hover:bg-surface-muted disabled:opacity-60"
                >
                  {verifyLoading ? "Sending..." : "Verify email"}
                </button>
              )}
            </dd>
            {verifyError ? (
              <p className="mt-2 text-sm text-red-600">{verifyError}</p>
            ) : null}
          </div>
        </dl>
      </div>

      <div className="flex flex-wrap gap-3">
        <Link
          href="/profile/contributions"
          className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
        >
          Contributions
        </Link>
        <Link
          href="/profile/reports"
          className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
        >
          Reports
        </Link>
        {isAdmin ? (
          <Link
            href="/admin"
            className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
          >
            Admin
          </Link>
        ) : null}
      </div>

      <button
        type="button"
        onClick={() => void handleSignOut()}
        className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
      >
        Sign out
      </button>
    </div>
  );
}
