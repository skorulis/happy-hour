import { Suspense } from "react";
import { MapPage } from "@/components/MapPage";

export default function NearbyMapPage() {
  return (
    <Suspense
      fallback={
        <div className="relative flex min-h-0 flex-1 flex-col">
          <div className="absolute inset-0 flex items-center justify-center bg-background text-sm text-muted">
            Loading map...
          </div>
        </div>
      }
    >
      <MapPage initialWhere={{ kind: "nearMe" }} />
    </Suspense>
  );
}
