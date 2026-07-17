"use client";

import Image from "next/image";
import Link from "next/link";

export function HomeNavLink() {
  return (
    <Link
      href="/"
      aria-label="Duskroute"
      className="inline-flex items-center gap-2 text-lg font-semibold text-accent-soft transition-opacity hover:opacity-80"
    >
      <Image
        src="/icon.png"
        alt=""
        width={32}
        height={32}
        className="h-8 w-8 rounded-full"
        priority
      />
      <span className="hidden md:inline" aria-hidden>
        Duskroute
      </span>
    </Link>
  );
}
