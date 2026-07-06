"use client";

import { useSession } from "@/lib/auth-client";
import Link from "next/link";
import { usePathname } from "next/navigation";

function NavLinkFallback({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-zinc-300 px-3 py-1.5 text-sm font-medium text-zinc-600 dark:border-zinc-600 dark:text-zinc-400">
      {label}
    </span>
  );
}

function navLinkClassName(isActive: boolean) {
  return `inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors ${
    isActive
      ? "border-amber-600 bg-amber-600 text-white dark:border-amber-500 dark:bg-amber-500"
      : "border-zinc-300 text-zinc-600 hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400"
  }`;
}

export function AuthNavLinks() {
  const pathname = usePathname();
  const { data: session, isPending } = useSession();

  if (isPending) {
    return (
      <>
        <NavLinkFallback label="Log in" />
        <NavLinkFallback label="Sign up" />
      </>
    );
  }

  if (session) {
    const isProfileActive = pathname === "/profile";

    return (
      <Link
        href="/profile"
        aria-current={isProfileActive ? "page" : undefined}
        className={navLinkClassName(isProfileActive)}
      >
        Profile
      </Link>
    );
  }

  const isLoginActive = pathname === "/login";
  const isSignupActive = pathname === "/signup";

  return (
    <>
      <Link
        href="/login"
        aria-current={isLoginActive ? "page" : undefined}
        className={navLinkClassName(isLoginActive)}
      >
        Log in
      </Link>
      <Link
        href="/signup"
        aria-current={isSignupActive ? "page" : undefined}
        className={navLinkClassName(isSignupActive)}
      >
        Sign up
      </Link>
    </>
  );
}
