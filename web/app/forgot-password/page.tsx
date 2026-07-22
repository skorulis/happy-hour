import type { Metadata } from "next";
import { Suspense } from "react";
import { ForgotPasswordPageContent } from "@/components/ForgotPasswordPageContent";

export const metadata: Metadata = {
  title: "Forgot password",
  description: "Reset your DuskRoute account password.",
};

export default function ForgotPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-6 py-10">
          <p className="text-sm text-muted">Loading...</p>
        </div>
      }
    >
      <ForgotPasswordPageContent />
    </Suspense>
  );
}
