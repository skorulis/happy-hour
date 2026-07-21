import type { Metadata } from "next";
import { Suspense } from "react";
import { VerifyEmailPageContent } from "@/components/VerifyEmailPageContent";

export const metadata: Metadata = {
  title: "Verify email",
  description: "Verify your DuskRoute email address.",
};

export default function VerifyEmailPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
          <p className="text-sm text-muted">Loading...</p>
        </div>
      }
    >
      <VerifyEmailPageContent />
    </Suspense>
  );
}
