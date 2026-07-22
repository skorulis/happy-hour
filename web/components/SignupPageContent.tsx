"use client";

import { AuthForm } from "@/components/AuthForm";
import { signIn, signUp, useSession } from "@/lib/auth-client";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect } from "react";

function buildVerifyEmailUrl(email: string, callbackUrl: string) {
  const params = new URLSearchParams({ email });
  if (callbackUrl !== "/profile") {
    params.set("callbackUrl", callbackUrl);
  }
  return `/verify-email?${params.toString()}`;
}

export function SignupPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, isPending } = useSession();
  const callbackUrl = searchParams.get("callbackUrl") ?? "/profile";

  useEffect(() => {
    if (!isPending && session) {
      if (session.user.emailVerified) {
        router.replace(callbackUrl);
        return;
      }
      router.replace(buildVerifyEmailUrl(session.user.email, callbackUrl));
    }
  }, [callbackUrl, isPending, router, session]);

  async function handleSubmit({
    email,
    password,
    name,
  }: {
    email: string;
    password: string;
    name?: string;
  }) {
    const trimmedName = name?.trim();
    if (!trimmedName) {
      throw new Error("Please enter your name.");
    }

    const verifyUrl = buildVerifyEmailUrl(email, callbackUrl);
    const result = await signUp.email({
      name: trimmedName,
      email,
      password,
      callbackURL: verifyUrl,
    });

    if (result.error) {
      throw new Error(result.error.message ?? "Could not create account.");
    }

    router.push(verifyUrl);
    router.refresh();
  }

  async function handleGoogleSignIn() {
    const result = await signIn.social({
      provider: "google",
      callbackURL: callbackUrl,
    });

    if (result.error) {
      throw new Error(result.error.message ?? "Could not sign in with Google.");
    }
  }

  if (isPending || session) {
    return (
      <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-4 py-10 md:px-6">
        <p className="text-sm text-muted">Loading...</p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-4 py-10 md:px-6">
      <AuthForm
        mode="signup"
        callbackUrl={callbackUrl}
        onSubmit={handleSubmit}
        onGoogleSignIn={handleGoogleSignIn}
      />
    </div>
  );
}
