import type { Metadata } from "next";
import { SignupPageContent } from "@/components/SignupPageContent";

export const metadata: Metadata = {
  title: "Sign up",
  description: "Create a Duskroute account.",
};

export default function SignupPage() {
  return <SignupPageContent />;
}
