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
      className="inline-flex shrink-0 items-center justify-center rounded-full border border-zinc-300 p-2 text-zinc-500 transition-colors hover:border-amber-500 hover:bg-amber-50 hover:text-amber-700 dark:border-zinc-600 dark:text-zinc-400 dark:hover:border-amber-500 dark:hover:bg-amber-950/30 dark:hover:text-amber-400"
    >
      <Flag aria-hidden className="h-4 w-4" strokeWidth={1.75} />
    </Link>
  );
}
