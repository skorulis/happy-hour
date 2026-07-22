"use client";

import { useId, useState } from "react";
import { PopularSuburbs } from "@/components/PopularSuburbs";
import type { SuburbStatistics } from "@/lib/search/queries";
import {
  sortSuburbStatistics,
  type SuburbStatsView,
} from "@/lib/search/suburb-statistics";

const VIEW_TABS: Array<{
  id: SuburbStatsView;
  label: string;
  title: string;
  description: string;
  statsMode: "perSqkm" | "perThousand";
}> = [
  {
    id: "density",
    label: "Density",
    title: "Suburbs by density",
    description: "Venues and deals per square kilometre.",
    statsMode: "perSqkm",
  },
  {
    id: "population",
    label: "Population",
    title: "Suburbs by population",
    description: "Venues and deals per 1,000 people.",
    statsMode: "perThousand",
  },
];

type RegionStatisticsViewProps = {
  suburbs: SuburbStatistics[];
  regionName: string;
};

export function RegionStatisticsView({
  suburbs,
  regionName,
}: RegionStatisticsViewProps) {
  const baseId = useId();
  const [view, setView] = useState<SuburbStatsView>("density");
  const activeTab = VIEW_TABS.find((tab) => tab.id === view) ?? VIEW_TABS[0]!;
  const sorted = sortSuburbStatistics(suburbs, view);

  return (
    <div className="space-y-4">
      <div
        className="overflow-x-auto rounded-xl border border-border bg-surface-muted p-1"
        role="tablist"
        aria-label={`Statistics views for ${regionName}`}
      >
        <div className="flex min-w-max gap-0.5">
          {VIEW_TABS.map((tab) => {
            const isActive = tab.id === activeTab.id;
            const tabId = `${baseId}-tab-${tab.id}`;
            const panelId = `${baseId}-panel`;

            return (
              <button
                key={tab.id}
                type="button"
                role="tab"
                id={tabId}
                aria-selected={isActive}
                aria-controls={panelId}
                tabIndex={isActive ? 0 : -1}
                onClick={() => setView(tab.id)}
                className={`inline-flex min-w-0 flex-1 items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors ${
                  isActive
                    ? "bg-surface-elevated font-medium text-foreground shadow-card"
                    : "text-secondary hover:text-foreground"
                }`}
              >
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      <div
        role="tabpanel"
        id={`${baseId}-panel`}
        aria-labelledby={`${baseId}-tab-${activeTab.id}`}
      >
        <PopularSuburbs
          suburbs={sorted}
          statsMode={activeTab.statsMode}
          title={activeTab.title}
          description={activeTab.description}
          includeSpecialLinks={false}
        />
      </div>
    </div>
  );
}
