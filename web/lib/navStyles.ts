const activePill =
  "border-amber-600 bg-amber-600 text-white dark:border-amber-500 dark:bg-amber-500";
const inactivePill =
  "border-zinc-300 text-zinc-600 hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400";

/** Icon-only on mobile, labeled pill from md */
export function navIconPillClassName(isActive: boolean) {
  return `inline-flex items-center justify-center gap-1.5 rounded-full border p-2.5 text-sm font-medium transition-colors md:px-3 md:py-1.5 ${
    isActive ? activePill : inactivePill
  }`;
}

export function navTextLinkClassName(isActive: boolean) {
  return `inline-flex items-center px-1.5 py-1.5 text-sm font-medium transition-colors ${
    isActive
      ? "text-amber-700 dark:text-amber-400"
      : "text-zinc-600 hover:text-amber-700 dark:text-zinc-400 dark:hover:text-amber-400"
  }`;
}

export function navPrimaryCtaClassName(isActive: boolean) {
  return `inline-flex items-center rounded-full px-3 py-1.5 text-sm font-medium transition-colors ${
    isActive
      ? "bg-amber-700 text-white dark:bg-amber-400 dark:text-zinc-950"
      : "bg-amber-600 text-white hover:bg-amber-700 dark:bg-amber-500 dark:hover:bg-amber-400 dark:hover:text-zinc-950"
  }`;
}

export const navFallbackIconClassName =
  "inline-flex h-10 w-10 items-center justify-center rounded-full border border-zinc-300 dark:border-zinc-600 md:h-auto md:w-auto md:gap-1.5 md:px-3 md:py-1.5";

export const navFallbackTextClassName =
  "inline-flex items-center px-1.5 py-1.5 text-sm font-medium text-zinc-600 dark:text-zinc-400";

export const navFallbackCtaClassName =
  "inline-flex items-center rounded-full bg-zinc-200 px-3 py-1.5 text-sm font-medium text-zinc-500 dark:bg-zinc-700 dark:text-zinc-400";
