import { Construction } from "lucide-react";
import { isRegionLive } from "@data/regions";

type RegionFocusNoticeProps = {
  regionName: string;
};

export function RegionFocusNotice({ regionName }: RegionFocusNoticeProps) {
  if (isRegionLive(regionName)) {
    return null;
  }

  return (
    <p
      role="note"
      className="flex items-start gap-3 rounded-lg border border-accent bg-accent-muted px-4 py-3 text-sm text-accent-soft"
    >
      <Construction
        aria-hidden
        className="mt-0.5 h-4 w-4 shrink-0"
        strokeWidth={1.5}
      />
      <span>
        DuskRoute is currently focused on Sydney happy hours. We&apos;ll put
        some love into {regionName} as soon as we can
      </span>
    </p>
  );
}
