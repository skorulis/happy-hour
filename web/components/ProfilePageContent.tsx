"use client";

import { signOut } from "@/lib/auth-client";
import { useRouter } from "next/navigation";

type ProfilePageContentProps = {
  name: string;
  email: string;
};

export function ProfilePageContent({ name, email }: ProfilePageContentProps) {
  const router = useRouter();

  async function handleSignOut() {
    await signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
          User Profile
        </h1>
      </header>

      <div className="rounded-xl border border-zinc-200 p-6 dark:border-zinc-800">
        <dl className="space-y-4 text-sm">
          <div>
            <dt className="font-medium text-zinc-500 dark:text-zinc-400">Name</dt>
            <dd className="mt-1 text-zinc-900 dark:text-zinc-50">{name}</dd>
          </div>
          <div>
            <dt className="font-medium text-zinc-500 dark:text-zinc-400">Email</dt>
            <dd className="mt-1 text-zinc-900 dark:text-zinc-50">{email}</dd>
          </div>
        </dl>
      </div>

      <button
        type="button"
        onClick={() => void handleSignOut()}
        className="w-fit rounded-lg border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-50 dark:border-zinc-600 dark:text-zinc-300 dark:hover:bg-zinc-900"
      >
        Sign out
      </button>
    </div>
  );
}
