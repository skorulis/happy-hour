"use client";

import { authClient } from "@/lib/auth-client";
import { useRouter, useSearchParams } from "next/navigation";
import { type FormEvent, useEffect, useRef, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

function verifyErrorMessage(error: unknown) {
  return error instanceof Error
    ? error.message
    : "Could not verify email. Please try again.";
}

async function verifyEmailOtp(nextEmail: string, nextOtp: string) {
  const result = await authClient.emailOtp.verifyEmail({
    email: nextEmail.trim(),
    otp: nextOtp.trim(),
  });

  if (result.error) {
    throw new Error(result.error.message ?? "Could not verify email.");
  }
}

export function VerifyEmailPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialEmail = searchParams.get("email") ?? "";
  const initialOtp = searchParams.get("otp") ?? "";
  const callbackUrl = searchParams.get("callbackUrl") ?? "/profile";
  const shouldAutoVerify = Boolean(initialEmail && initialOtp);

  const [email, setEmail] = useState(initialEmail);
  const [otp, setOtp] = useState(initialOtp);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(shouldAutoVerify);
  const [resending, setResending] = useState(false);
  const autoSubmitted = useRef(false);

  async function verify(nextEmail: string, nextOtp: string) {
    setError(null);
    setMessage(null);
    setLoading(true);

    try {
      await verifyEmailOtp(nextEmail, nextOtp);
      router.push(callbackUrl);
      router.refresh();
    } catch (verifyError) {
      setError(verifyErrorMessage(verifyError));
      setLoading(false);
    }
  }

  useEffect(() => {
    if (autoSubmitted.current || !shouldAutoVerify) return;
    autoSubmitted.current = true;

    let cancelled = false;

    void (async () => {
      try {
        await verifyEmailOtp(initialEmail, initialOtp);
        if (cancelled) return;
        router.push(callbackUrl);
        router.refresh();
      } catch (verifyError) {
        if (cancelled) return;
        setError(verifyErrorMessage(verifyError));
        setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [callbackUrl, initialEmail, initialOtp, router, shouldAutoVerify]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await verify(email, otp);
  }

  async function handleResend() {
    setError(null);
    setMessage(null);
    setResending(true);

    try {
      const trimmed = email.trim();
      if (!trimmed) {
        throw new Error("Enter your email address first.");
      }

      const result = await authClient.emailOtp.sendVerificationOtp({
        email: trimmed,
        type: "email-verification",
      });

      if (result.error) {
        throw new Error(result.error.message ?? "Could not resend code.");
      }

      setMessage("A new verification code has been sent.");
    } catch (resendError) {
      setError(
        resendError instanceof Error
          ? resendError.message
          : "Could not resend code. Please try again.",
      );
    } finally {
      setResending(false);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-6 px-6 py-10">
      <header className="space-y-2 text-center">
        <h1 className="text-3xl font-bold text-foreground">Verify your email</h1>
        <p className="text-sm text-muted">
          Enter the 6-digit code we sent you, or open the link from the email.
        </p>
      </header>

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="space-y-1">
          <label htmlFor="email" className="text-sm font-medium text-foreground">
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className={inputClassName}
          />
        </div>

        <div className="space-y-1">
          <label htmlFor="otp" className="text-sm font-medium text-foreground">
            Verification code
          </label>
          <input
            id="otp"
            name="otp"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            required
            minLength={6}
            maxLength={8}
            value={otp}
            onChange={(event) => setOtp(event.target.value)}
            className={inputClassName}
          />
        </div>

        {error ? <p className="text-sm text-red-600">{error}</p> : null}
        {message ? <p className="text-sm text-muted">{message}</p> : null}

        <button type="submit" disabled={loading} className={buttonClassName}>
          {loading ? "Verifying..." : "Verify email"}
        </button>
      </form>

      <button
        type="button"
        disabled={resending || loading}
        onClick={() => void handleResend()}
        className="text-sm font-medium text-secondary transition-colors hover:text-foreground disabled:opacity-60"
      >
        {resending ? "Sending..." : "Resend code"}
      </button>
    </div>
  );
}
