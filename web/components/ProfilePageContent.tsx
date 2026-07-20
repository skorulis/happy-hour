"use client";

import Link from "next/link";
import { signOut } from "@/lib/auth-client";
import { useRouter } from "next/navigation";

type ProfilePageContentProps = {
  name: string;
  email: string;
  isAdmin: boolean;
};

export function ProfilePageContent({ name, email, isAdmin }: ProfilePageContentProps) {
  const router = useRouter();

  async function handleSignOut() {
    await signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-foreground">
          User Profile
        </h1>
      </header>

      <div className="rounded-xl border border-border p-6">
        <dl className="space-y-4 text-sm">
          <div>
            <dt className="font-medium text-muted">Name</dt>
            <dd className="mt-1 text-foreground">{name}</dd>
          </div>
          <div>
            <dt className="font-medium text-muted">Email</dt>
            <dd className="mt-1 text-foreground">{email}</dd>
          </div>
        </dl>
      </div>

      <div className="flex flex-wrap gap-3">
        <Link
          href="/profile/reports"
          className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
        >
          Reports
        </Link>
        {isAdmin ? (
          <Link
            href="/admin"
            className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
          >
            Admin
          </Link>
        ) : null}
      </div>

      <button
        type="button"
        onClick={() => void handleSignOut()}
        className="w-fit rounded-lg border border-border px-4 py-2 text-sm font-medium text-secondary transition-colors hover:bg-surface-muted"
      >
        Sign out
      </button>
    </div>
  );
}
