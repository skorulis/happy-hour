import {
  bowlChopsticks,
  bowling,
  burger,
  chairsTablePlatter,
  cheese,
  dress,
  hotDog,
  kebab,
  lunchBox,
  sausage,
} from "@lucide/lab";
import {
  Baby,
  BadgeDollarSign,
  Beef,
  Beer,
  BottleWine,
  Brain,
  CalendarDays,
  ChartPie,
  CircleQuestionMark,
  Clock,
  Club,
  Coffee,
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
  Headphones,
  Icon,
  Infinity,
  Martini,
  Mic,
  MicVocal,
  Moon,
  Music,
  Music4,
  Percent,
  Pizza,
  Salad,
  Sandwich,
  Soup,
  Spade,
  Sparkles,
  Sun,
  Target,
  Ticket,
  UserStar,
  Users,
  UtensilsCrossed,
  Wine,
  type IconNode,
  type LucideIcon,
} from "lucide-react";
import type { ComponentType } from "react";
import { chips, nachos, pool, sake, soju, taco, whisky } from "./customProductIcons";

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
  BadgeDollarSign: wrapLucideIcon(BadgeDollarSign),
  Beef: wrapLucideIcon(Beef),
  Beer: wrapLucideIcon(Beer),
  BottleWine: wrapLucideIcon(BottleWine),
  BowlChopsticks: labIcon(bowlChopsticks),
  Bowls: wrapLucideIcon(Salad),
  Bowling: labIcon(bowling),
  Burger: labIcon(burger),
  CalendarDays: wrapLucideIcon(CalendarDays),
  ChairsTablePlatter: labIcon(chairsTablePlatter),
  ChartPie: wrapLucideIcon(ChartPie),
  Cheese: labIcon(cheese),
  Chips: labIcon(chips),
  CircleQuestionMark: wrapLucideIcon(CircleQuestionMark),
  Brain: wrapLucideIcon(Brain),
  Clock: wrapLucideIcon(Clock),
  Club: wrapLucideIcon(Club),
  Coffee: wrapLucideIcon(Coffee),
  Coins: wrapLucideIcon(Coins),
  Cookie: wrapLucideIcon(Cookie),
  CookingPot: wrapLucideIcon(CookingPot),
  Dress: labIcon(dress),
  Drumstick: wrapLucideIcon(Drumstick),
  Fish: wrapLucideIcon(Fish),
  Footprints: wrapLucideIcon(Footprints),
  GlassWater: wrapLucideIcon(GlassWater),
  Glasses: wrapLucideIcon(Glasses),
  GraduationCap: wrapLucideIcon(GraduationCap),
  Grid3x3: wrapLucideIcon(Grid3x3),
  Ham: wrapLucideIcon(Ham),
  Headphones: wrapLucideIcon(Headphones),
  HotDog: labIcon(hotDog),
  Infinity: wrapLucideIcon(Infinity),
  Kebab: labIcon(kebab),
  LunchBox: labIcon(lunchBox),
  Martini: wrapLucideIcon(Martini),
  Mic: wrapLucideIcon(Mic),
  MicVocal: wrapLucideIcon(MicVocal),
  Moon: wrapLucideIcon(Moon),
  Music: wrapLucideIcon(Music),
  Music4: wrapLucideIcon(Music4),
  Nachos: labIcon(nachos),
  Percent: wrapLucideIcon(Percent),
  Pizza: wrapLucideIcon(Pizza),
  Pool: labIcon(pool),
  Sake: labIcon(sake),
  Salad: wrapLucideIcon(Salad),
  Sandwich: wrapLucideIcon(Sandwich),
  Sausage: labIcon(sausage),
  Soju: labIcon(soju),
  Soup: wrapLucideIcon(Soup),
  Spade: wrapLucideIcon(Spade),
  Sparkles: wrapLucideIcon(Sparkles),
  Sun: wrapLucideIcon(Sun),
  Taco: labIcon(taco),
  Target: wrapLucideIcon(Target),
  Ticket: wrapLucideIcon(Ticket),
  UserStar: wrapLucideIcon(UserStar),
  Users: wrapLucideIcon(Users),
  UtensilsCrossed: wrapLucideIcon(UtensilsCrossed),
  Wine: wrapLucideIcon(Wine),
  Wings: wrapLucideIcon(Drumstick),
  Whisky: labIcon(whisky),
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
