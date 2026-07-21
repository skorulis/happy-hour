"use client";

import { AuthForm } from "@/components/AuthForm";
import { signIn, signUp, useSession } from "@/lib/auth-client";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

export function SignupPageContent() {
  const router = useRouter();
  const { data: session, isPending } = useSession();
  const profileUrl = "/profile";

  useEffect(() => {
    if (!isPending && session) {
      if (session.user.emailVerified) {
        router.replace(profileUrl);
        return;
      }
      router.replace(
        `/verify-email?email=${encodeURIComponent(session.user.email)}`,
      );
    }
  }, [isPending, router, session]);

  async function handleSubmit({
    email,
    password,
  }: {
    email: string;
    password: string;
  }) {
    const verifyUrl = `/verify-email?email=${encodeURIComponent(email)}`;
    const result = await signUp.email({
      name: email.split("@")[0] ?? email,
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
      callbackURL: profileUrl,
    });

    if (result.error) {
      throw new Error(result.error.message ?? "Could not sign in with Google.");
    }
  }

  if (isPending || session) {
    return (
      <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
        <p className="text-sm text-muted">Loading...</p>
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
      <AuthForm
        mode="signup"
        onSubmit={handleSubmit}
        onGoogleSignIn={handleGoogleSignIn}
      />
    </div>
  );
}
