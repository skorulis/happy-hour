import { Flag } from "lucide-react";
import Link from "next/link";

type FlagDealButtonProps = {
  dealId: number;
};

export function FlagDealButton({ dealId }: FlagDealButtonProps) {
  return (
    <Link
      href={`/report?dealId=${dealId}`}
      aria-label="Report this deal"
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-border p-2 text-muted transition-colors hover:border-accent hover:bg-accent-muted hover:text-accent-soft"
    >
      <Flag aria-hidden className="h-4 w-4" strokeWidth={1.75} />
    </Link>
  );
}
