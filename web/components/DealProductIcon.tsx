import { resolveMapIconForDeals } from "@data/products";
import { CircleQuestionMark } from "lucide-react";
import {
  isRegisteredProductIcon,
  ProductMapIcon,
} from "@/lib/search/ProductMapIcon";

type DealTextFields = {
  title: string | null;
  details: string | null;
  conditions: string | null;
};

type DealProductIconProps = {
  deal: DealTextFields;
  className?: string;
  size?: number;
};

export function DealProductIcon({
  deal,
  className = "",
  size = 16,
}: DealProductIconProps) {
  const iconName = resolveMapIconForDeals([deal]);
  const hasRegisteredIcon = iconName && isRegisteredProductIcon(iconName);

  return (
    <span
      className={`inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400 ${className}`}
    >
      {hasRegisteredIcon ? (
        <ProductMapIcon name={iconName} size={size} />
      ) : (
        <CircleQuestionMark
          aria-hidden
          className="h-4 w-4"
          strokeWidth={1.75}
        />
      )}
    </span>
  );
}
