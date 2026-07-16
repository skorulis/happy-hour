"use client";

import { pathnameToListHref } from "@/lib/search/url";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";

export function HomeNavLink() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const href = pathnameToListHref(pathname, searchParams);

  return (
    <Link
      href={href}
      aria-label="Happy Hours"
      className="inline-flex items-center gap-2 text-lg font-semibold text-amber-700 transition-opacity hover:opacity-80 dark:text-amber-400"
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
        Happy Hours
      </span>
    </Link>
  );
}
