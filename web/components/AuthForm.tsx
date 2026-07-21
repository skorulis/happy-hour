"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2";

const buttonClassName =
  "w-full rounded-lg bg-accent px-4 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

type AuthFormProps = {
  mode: "login" | "signup";
  callbackUrl?: string;
  onSubmit: (values: { email: string; password: string }) => Promise<void>;
  onGoogleSignIn: () => Promise<void>;
};

export function AuthForm({
  mode,
  callbackUrl,
  onSubmit,
  onGoogleSignIn,
}: AuthFormProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  const isSignup = mode === "signup";
  const title = isSignup ? "Create an account" : "Log in";
  const alternatePath = isSignup ? "/login" : "/signup";
  const alternateHref = callbackUrl
    ? `${alternatePath}?callbackUrl=${encodeURIComponent(callbackUrl)}`
    : alternatePath;
  const alternateLabel = isSignup
    ? "Already have an account? Log in"
    : "Don't have an account? Sign up";

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    try {
      await onSubmit({
        email,
        password,
      });
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Something went wrong. Please try again.",
      );
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError(null);
    setGoogleLoading(true);

    try {
      await onGoogleSignIn();
    } catch (googleError) {
      setError(
        googleError instanceof Error
          ? googleError.message
          : "Could not sign in with Google. Please try again.",
      );
      setGoogleLoading(false);
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-md flex-col gap-6">
      <header className="space-y-2 text-center">
        <h1 className="text-3xl font-bold text-foreground">
          {title}
        </h1>
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

        <div className="space-y-1">
          <label
            htmlFor="password"
            className="block text-sm font-medium text-secondary"
          >
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete={isSignup ? "new-password" : "current-password"}
            required
            minLength={8}
            className={inputClassName}
          />
        </div>

        {error ? (
          <p className="text-sm text-danger">{error}</p>
        ) : null}

        <button type="submit" disabled={loading || googleLoading} className={buttonClassName}>
          {loading ? "Please wait..." : isSignup ? "Sign up" : "Log in"}
        </button>
      </form>

      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-border-subtle" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-surface px-2 text-muted">
            Or continue with
          </span>
        </div>
      </div>

      <button
        type="button"
        onClick={() => void handleGoogleSignIn()}
        disabled={loading || googleLoading}
        className="w-full rounded-lg border border-border bg-surface px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-surface-muted disabled:cursor-not-allowed disabled:opacity-60"
      >
        {googleLoading ? "Redirecting..." : "Continue with Google"}
      </button>

      <p className="text-center text-sm text-secondary">
        <Link
          href={alternateHref}
          className="font-medium text-accent-soft hover:text-foreground"
        >
          {alternateLabel}
        </Link>
      </p>
    </div>
  );
}
