import {
  Baby,
  Beef,
  Beer,
  CalendarDays,
  CircleQuestionMark,
  Clock,
  Cookie,
  Fish,
  Footprints,
  Glasses,
  GraduationCap,
  Grid3x3,
  Infinity,
  Martini,
  Mic,
  Moon,
  Music,
  Percent,
  Pizza,
  Salad,
  Sandwich,
  Sparkles,
  Sun,
  UtensilsCrossed,
  Wine,
  type LucideIcon,
} from "lucide-react";

const PRODUCT_ICON_REGISTRY: Record<string, LucideIcon> = {
  Baby,
  Beef,
  Beer,
  CalendarDays,
  CircleQuestionMark,
  Clock,
  Cookie,
  Fish,
  Footprints,
  Glasses,
  GraduationCap,
  Grid3x3,
  Infinity,
  Martini,
  Mic,
  Moon,
  Music,
  Percent,
  Pizza,
  Salad,
  Sandwich,
  Sparkles,
  Sun,
  UtensilsCrossed,
  Wine,
};

type ProductMapIconProps = {
  name: string;
  className?: string;
  size?: number;
};

export function ProductMapIcon({
  name,
  className,
  size = 16,
}: ProductMapIconProps) {
  const Icon = PRODUCT_ICON_REGISTRY[name];
  if (!Icon) {
    return null;
  }

  return <Icon className={className} size={size} strokeWidth={2.25} />;
}

export function isRegisteredProductIcon(name: string): boolean {
  return name in PRODUCT_ICON_REGISTRY;
}
