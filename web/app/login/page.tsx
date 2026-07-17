import type { Metadata } from "next";
import { Suspense } from "react";
import { LoginPageContent } from "@/components/LoginPageContent";

export const metadata: Metadata = {
  title: "Log in",
  description: "Log in to your DuskRoute account.",
};

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
          <p className="text-sm text-muted">Loading...</p>
        </div>
      }
    >
      <LoginPageContent />
    </Suspense>
  );
}
