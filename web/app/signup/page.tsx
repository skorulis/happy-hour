import type { Metadata } from "next";
import { Suspense } from "react";
import { SignupPageContent } from "@/components/SignupPageContent";

export const metadata: Metadata = {
  title: "Sign up",
  description: "Create a DuskRoute account.",
};

export default function SignupPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
          <p className="text-sm text-muted">Loading...</p>
        </div>
      }
    >
      <SignupPageContent />
    </Suspense>
  );
}
