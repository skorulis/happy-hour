"use client";

import { AuthForm } from "@/components/AuthForm";
import { signIn, useSession } from "@/lib/auth-client";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect } from "react";

export function LoginPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, isPending } = useSession();
  const callbackUrl = searchParams.get("callbackUrl") ?? "/profile";

  useEffect(() => {
    if (!isPending && session) {
      router.replace(callbackUrl);
    }
  }, [callbackUrl, isPending, router, session]);

  async function handleSubmit({
    email,
    password,
  }: {
    email: string;
    password: string;
  }) {
    const result = await signIn.email({
      email,
      password,
      callbackURL: callbackUrl,
    });

    if (result.error) {
      throw new Error(result.error.message ?? "Could not log in.");
    }

    router.push(callbackUrl);
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
        mode="login"
        callbackUrl={callbackUrl}
        onSubmit={handleSubmit}
        onGoogleSignIn={handleGoogleSignIn}
      />
    </div>
  );
}
