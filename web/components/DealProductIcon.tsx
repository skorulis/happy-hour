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
  variant?: "contained" | "plain";
};

export function DealProductIcon({
  deal,
  className = "",
  size = 16,
  variant = "contained",
}: DealProductIconProps) {
  const iconName = resolveMapIconForDeals([deal]);
  const hasRegisteredIcon = iconName && isRegisteredProductIcon(iconName);
  const icon = hasRegisteredIcon ? (
    <ProductMapIcon name={iconName} size={size} />
  ) : (
    <CircleQuestionMark
      aria-hidden
      className="h-4 w-4"
      strokeWidth={1.75}
    />
  );

  if (variant === "plain") {
    return (
      <span
        className={`inline-flex shrink-0 items-center justify-center text-accent-soft ${className}`}
      >
        {icon}
      </span>
    );
  }

  return (
    <span
      className={`inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-accent-muted text-accent-soft ${className}`}
    >
      {icon}
    </span>
  );
}
