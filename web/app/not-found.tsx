import Image from "next/image";
import Link from "next/link";
import { Beer, MapPinOff, Martini, Moon, Wine } from "lucide-react";
import type { Metadata } from "next";
import { DuskAtmosphere } from "@/components/DuskAtmosphere";

export const metadata: Metadata = {
  title: "Page not found | DuskRoute",
};

const floatingIcons = [
  { Icon: Beer, className: "left-[8%] top-[18%] -rotate-12", delay: "0s" },
  { Icon: Martini, className: "right-[10%] top-[22%] rotate-12", delay: "1.5s" },
  { Icon: Wine, className: "left-[14%] bottom-[24%] rotate-6", delay: "3s" },
  { Icon: Moon, className: "right-[12%] bottom-[28%] -rotate-6", delay: "4.5s" },
  {
    Icon: MapPinOff,
    className: "left-1/2 top-[12%] -translate-x-1/2 rotate-3",
    delay: "2s",
  },
];

export default function NotFound() {
  return (
    <div className="relative flex flex-1 flex-col items-center justify-center overflow-hidden px-4 py-20 md:px-6 text-center">
      <DuskAtmosphere icons={floatingIcons} />

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
