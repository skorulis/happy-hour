"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-zinc-300 bg-white px-3 py-2 text-sm text-zinc-900 outline-none ring-amber-500 focus:ring-2 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50";

const buttonClassName =
  "w-full rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-amber-500 dark:hover:bg-amber-600";

type AuthFormProps = {
  mode: "login" | "signup";
  onSubmit: (values: { email: string; password: string }) => Promise<void>;
  onGoogleSignIn: () => Promise<void>;
};

export function AuthForm({ mode, onSubmit, onGoogleSignIn }: AuthFormProps) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  const isSignup = mode === "signup";
  const title = isSignup ? "Create an account" : "Log in";
  const alternateHref = isSignup ? "/login" : "/signup";
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
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          {title}
        </h1>
      </header>

      <form className="space-y-4" onSubmit={handleSubmit}>
        <div className="space-y-1">
          <label
            htmlFor="email"
            className="block text-sm font-medium text-zinc-700 dark:text-zinc-300"
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
            className="block text-sm font-medium text-zinc-700 dark:text-zinc-300"
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
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        ) : null}

        <button type="submit" disabled={loading || googleLoading} className={buttonClassName}>
          {loading ? "Please wait..." : isSignup ? "Sign up" : "Log in"}
        </button>
      </form>

      <div className="relative">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-zinc-200 dark:border-zinc-800" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-white px-2 text-zinc-500 dark:bg-zinc-950 dark:text-zinc-400">
            Or continue with
          </span>
        </div>
      </div>

      <button
        type="button"
        onClick={() => void handleGoogleSignIn()}
        disabled={loading || googleLoading}
        className="w-full rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm font-medium text-zinc-900 transition-colors hover:bg-zinc-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-zinc-600 dark:bg-zinc-950 dark:text-zinc-50 dark:hover:bg-zinc-900"
      >
        {googleLoading ? "Redirecting..." : "Continue with Google"}
      </button>

      <p className="text-center text-sm text-zinc-600 dark:text-zinc-400">
        <Link
          href={alternateHref}
          className="font-medium text-amber-700 hover:text-amber-800 dark:text-amber-400 dark:hover:text-amber-300"
        >
          {alternateLabel}
        </Link>
      </p>
    </div>
  );
}
