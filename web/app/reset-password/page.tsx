import type { Metadata } from "next";
import { Suspense } from "react";
import { ResetPasswordPageContent } from "@/components/ResetPasswordPageContent";

export const metadata: Metadata = {
  title: "Reset password",
  description: "Choose a new password for your DuskRoute account.",
};

export default function ResetPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col px-4 py-10 md:px-6">
          <p className="text-sm text-muted">Loading...</p>
        </div>
      }
    >
      <ResetPasswordPageContent />
    </Suspense>
  );
}
