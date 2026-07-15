"use client";

import { useSession } from "@/lib/auth-client";
import {
  navFallbackCtaClassName,
  navFallbackTextClassName,
  navIconPillClassName,
  navPrimaryCtaClassName,
  navTextLinkClassName,
} from "@/lib/navStyles";
import { User } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

export function AuthNavLinks() {
  const pathname = usePathname();
  const { data: session, isPending } = useSession();

  if (isPending) {
    return (
      <>
        <span className={navFallbackTextClassName}>Log in</span>
        <span className={navFallbackCtaClassName}>Sign up</span>
      </>
    );
  }

  if (session) {
    const isProfileActive = pathname === "/profile";

    return (
      <Link
        href="/profile"
        aria-label="Profile"
        aria-current={isProfileActive ? "page" : undefined}
        className={navIconPillClassName(isProfileActive)}
      >
        <User aria-hidden className="h-4 w-4 md:hidden" strokeWidth={1.75} />
        <span className="hidden md:inline" aria-hidden>
          Profile
        </span>
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
        className={navTextLinkClassName(isLoginActive)}
      >
        Log in
      </Link>
      <Link
        href="/signup"
        aria-current={isSignupActive ? "page" : undefined}
        className={navPrimaryCtaClassName(isSignupActive)}
      >
        Sign up
      </Link>
    </>
  );
}
