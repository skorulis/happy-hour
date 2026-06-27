import { Suspense } from "react";
import { SearchPage } from "@/components/SearchPage";

export default function Home() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
          <header className="space-y-2">
            <p className="text-sm font-medium uppercase tracking-wide text-amber-700 dark:text-amber-400">
              Happy Hour
            </p>
            <h1 className="text-3xl font-bold text-zinc-900 dark:text-zinc-50">
              Find pub and bar deals
            </h1>
          </header>
        </div>
      }
    >
      <SearchPage />
    </Suspense>
  );
}
