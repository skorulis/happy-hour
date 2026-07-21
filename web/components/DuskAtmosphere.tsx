import type { LucideIcon } from "lucide-react";
import { Beer, Martini, Moon, Wine } from "lucide-react";

export type DuskAtmosphereIcon = {
  Icon: LucideIcon;
  className: string;
  delay?: string;
};

const defaultIcons: DuskAtmosphereIcon[] = [
  { Icon: Beer, className: "left-[8%] top-[18%] -rotate-12", delay: "0s" },
  { Icon: Martini, className: "right-[10%] top-[22%] rotate-12", delay: "1.5s" },
  { Icon: Wine, className: "left-[14%] bottom-[24%] rotate-6", delay: "3s" },
  { Icon: Moon, className: "right-[12%] bottom-[28%] -rotate-6", delay: "4.5s" },
];

const duskGradient = `
  radial-gradient(ellipse 70% 50% at 50% 40%, rgb(124 58 87 / 0.35) 0%, transparent 65%),
  radial-gradient(ellipse 50% 40% at 20% 80%, rgb(245 158 11 / 0.15) 0%, transparent 55%),
  radial-gradient(ellipse 45% 35% at 85% 70%, rgb(180 83 45 / 0.2) 0%, transparent 50%)
`;

type DuskAtmosphereProps = {
  icons?: DuskAtmosphereIcon[];
  animate?: boolean;
};

export function DuskAtmosphere({
  icons = defaultIcons,
  animate = true,
}: DuskAtmosphereProps) {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden>
      <div className="absolute inset-0" style={{ background: duskGradient }} />

      {icons.map(({ Icon, className, delay }, index) => (
        <div key={`${className}-${index}`} className={`absolute ${className}`}>
          <Icon
            className={`h-10 w-10 text-accent-soft/10 md:h-14 md:w-14 ${
              animate ? "animate-dusk-float" : ""
            }`}
            strokeWidth={1.25}
            style={animate && delay ? { animationDelay: delay } : undefined}
          />
        </div>
      ))}
    </div>
  );
}
