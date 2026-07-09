import {
  bowlChopsticks,
  bowling,
  burger,
  chairsTablePlatter,
  cheese,
  kebab,
  lunchBox,
} from "@lucide/lab";
import {
  Baby,
  Beef,
  Beer,
  BottleWine,
  CalendarDays,
  CircleQuestionMark,
  Clock,
  Coins,
  Cookie,
  CookingPot,
  Drumstick,
  Fish,
  Footprints,
  GlassWater,
  Glasses,
  GraduationCap,
  Grid3x3,
  Ham,
  Icon,
  Infinity,
  Martini,
  Mic,
  Moon,
  Music,
  Music4,
  Percent,
  Pizza,
  Salad,
  Sandwich,
  Soup,
  Sparkles,
  Sun,
  UserStar,
  Users,
  UtensilsCrossed,
  Wine,
  type IconNode,
  type LucideIcon,
} from "lucide-react";
import type { ComponentType } from "react";
import {
  bowls,
  chips,
  nachos,
  pool,
  saki,
  taco,
  wings,
} from "./customProductIcons";

type ProductIconProps = {
  size?: number;
  className?: string;
};

type ProductIcon = ComponentType<ProductIconProps>;

function labIcon(iconNode: IconNode): ProductIcon {
  return function LabProductIcon({ size = 16, className }) {
    return (
      <Icon
        iconNode={iconNode}
        size={size}
        className={className}
        strokeWidth={2.25}
      />
    );
  };
}

function wrapLucideIcon(IconComponent: LucideIcon): ProductIcon {
  return function LucideProductIcon({ size = 16, className }) {
    return (
      <IconComponent
        className={className}
        size={size}
        strokeWidth={2.25}
      />
    );
  };
}

const PRODUCT_ICON_REGISTRY: Record<string, ProductIcon> = {
  Baby: wrapLucideIcon(Baby),
  Beef: wrapLucideIcon(Beef),
  Beer: wrapLucideIcon(Beer),
  BottleWine: wrapLucideIcon(BottleWine),
  BowlChopsticks: labIcon(bowlChopsticks),
  Bowls: labIcon(bowls),
  Bowling: labIcon(bowling),
  Burger: labIcon(burger),
  CalendarDays: wrapLucideIcon(CalendarDays),
  ChairsTablePlatter: labIcon(chairsTablePlatter),
  Cheese: labIcon(cheese),
  Chips: labIcon(chips),
  CircleQuestionMark: wrapLucideIcon(CircleQuestionMark),
  Clock: wrapLucideIcon(Clock),
  Coins: wrapLucideIcon(Coins),
  Cookie: wrapLucideIcon(Cookie),
  CookingPot: wrapLucideIcon(CookingPot),
  Drumstick: wrapLucideIcon(Drumstick),
  Fish: wrapLucideIcon(Fish),
  Footprints: wrapLucideIcon(Footprints),
  GlassWater: wrapLucideIcon(GlassWater),
  Glasses: wrapLucideIcon(Glasses),
  GraduationCap: wrapLucideIcon(GraduationCap),
  Grid3x3: wrapLucideIcon(Grid3x3),
  Ham: wrapLucideIcon(Ham),
  Infinity: wrapLucideIcon(Infinity),
  Kebab: labIcon(kebab),
  LunchBox: labIcon(lunchBox),
  Martini: wrapLucideIcon(Martini),
  Mic: wrapLucideIcon(Mic),
  Moon: wrapLucideIcon(Moon),
  Music: wrapLucideIcon(Music),
  Music4: wrapLucideIcon(Music4),
  Nachos: labIcon(nachos),
  Percent: wrapLucideIcon(Percent),
  Pizza: wrapLucideIcon(Pizza),
  Pool: labIcon(pool),
  Saki: labIcon(saki),
  Salad: wrapLucideIcon(Salad),
  Sandwich: wrapLucideIcon(Sandwich),
  Soup: wrapLucideIcon(Soup),
  Sparkles: wrapLucideIcon(Sparkles),
  Sun: wrapLucideIcon(Sun),
  Taco: labIcon(taco),
  UserStar: wrapLucideIcon(UserStar),
  Users: wrapLucideIcon(Users),
  UtensilsCrossed: wrapLucideIcon(UtensilsCrossed),
  Wine: wrapLucideIcon(Wine),
  Wings: labIcon(wings),
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
  const IconComponent = PRODUCT_ICON_REGISTRY[name];
  if (!IconComponent) {
    return null;
  }

  return <IconComponent className={className} size={size} />;
}

export function isRegisteredProductIcon(name: string): boolean {
  return name in PRODUCT_ICON_REGISTRY;
}
