import { Suspense } from "react";
import { SearchPage } from "@/components/SearchPage";

export default function NearbyPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-8 px-6 py-10">
          <header>
            <h1 className="text-3xl font-bold text-foreground">
            Your evening starts here
            </h1>
          </header>
        </div>
      }
    >
      <SearchPage initialWhere={{ kind: "nearMe" }} />
    </Suspense>
  );
}
