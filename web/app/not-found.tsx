import Image from "next/image";
import Link from "next/link";
import { Beer, MapPinOff, Martini, Moon, Wine } from "lucide-react";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Page not found | DuskRoute",
};

const floatingIcons = [
  { Icon: Beer, className: "left-[8%] top-[18%] -rotate-12" },
  { Icon: Martini, className: "right-[10%] top-[22%] rotate-12" },
  { Icon: Wine, className: "left-[14%] bottom-[24%] rotate-6" },
  { Icon: Moon, className: "right-[12%] bottom-[28%] -rotate-6" },
  { Icon: MapPinOff, className: "left-1/2 top-[12%] -translate-x-1/2 rotate-3" },
] as const;

export default function NotFound() {
  return (
    <div className="relative flex flex-1 flex-col items-center justify-center overflow-hidden px-6 py-20 text-center">
      <div
        className="pointer-events-none absolute inset-0"
        aria-hidden
        style={{
          background: `
            radial-gradient(ellipse 70% 50% at 50% 40%, rgb(124 58 87 / 0.35) 0%, transparent 65%),
            radial-gradient(ellipse 50% 40% at 20% 80%, rgb(245 158 11 / 0.15) 0%, transparent 55%),
            radial-gradient(ellipse 45% 35% at 85% 70%, rgb(180 83 45 / 0.2) 0%, transparent 50%)
          `,
        }}
      />

      {floatingIcons.map(({ Icon, className }) => (
        <Icon
          key={className}
          aria-hidden
          className={`pointer-events-none absolute h-10 w-10 text-accent-soft/10 md:h-14 md:w-14 ${className}`}
          strokeWidth={1.25}
        />
      ))}

      <div className="relative flex flex-col items-center gap-6">
        <p
          className="text-7xl font-bold tracking-tighter text-accent-soft/40 md:text-8xl"
          aria-hidden
        >
          404
        </p>

        <Image
          src="/icon.png"
          alt=""
          width={112}
          height={112}
          className="h-24 w-24 rounded-full shadow-card md:h-28 md:w-28"
          priority
        />

        <div className="flex max-w-md flex-col gap-3">
          <h1 className="text-2xl font-semibold tracking-tight text-foreground md:text-3xl">
            This happy hour has ended
          </h1>
          <p className="text-sm text-muted md:text-base">
            We couldn&apos;t find that page — maybe the deals moved on. Let&apos;s
            get you back on the route.
          </p>
        </div>

        <Link
          href="/"
          className="mt-2 rounded-lg bg-accent px-5 py-2.5 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover"
        >
          Find happy hours
        </Link>
      </div>
    </div>
  );
}
