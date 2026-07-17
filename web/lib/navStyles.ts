const activePill =
  "border-accent bg-accent text-accent-fg";
const inactivePill =
  "border-border text-secondary hover:border-accent hover:bg-accent-muted hover:text-accent-soft";

/** Icon-only on mobile, labeled pill from md */
export function navIconPillClassName(isActive: boolean) {
  return `inline-flex items-center justify-center gap-1.5 rounded-full border p-2.5 text-sm font-medium transition-colors md:px-3 md:py-1.5 ${
    isActive ? activePill : inactivePill
  }`;
}

export function navTextLinkClassName(isActive: boolean) {
  return `inline-flex items-center px-1.5 py-1.5 text-sm font-medium transition-colors ${
    isActive
      ? "text-accent-soft"
      : "text-secondary hover:text-accent-soft"
  }`;
}

export function navPrimaryCtaClassName(isActive: boolean) {
  return `inline-flex items-center rounded-full px-3 py-1.5 text-sm font-medium transition-colors ${
    isActive
      ? "bg-accent-hover text-accent-fg"
      : "bg-accent text-accent-fg hover:bg-accent-hover"
  }`;
}

export const navFallbackIconClassName =
  "inline-flex h-10 w-10 items-center justify-center rounded-full border border-border md:h-auto md:w-auto md:gap-1.5 md:px-3 md:py-1.5";

export const navFallbackTextClassName =
  "inline-flex items-center px-1.5 py-1.5 text-sm font-medium text-secondary";

export const navFallbackCtaClassName =
  "inline-flex items-center rounded-full bg-surface-muted px-3 py-1.5 text-sm font-medium text-muted";
