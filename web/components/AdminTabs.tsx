"use client";

import { useId, useState, type ReactNode } from "react";

export type AdminTab = {
  id: string;
  label: string;
  badgeCount?: number;
  content: ReactNode;
};

type AdminTabsProps = {
  tabs: AdminTab[];
  defaultTabId?: string;
  ariaLabel?: string;
};

function formatBadgeCount(count: number): string {
  return count > 99 ? "99+" : String(count);
}

export function AdminTabs({
  tabs,
  defaultTabId,
  ariaLabel = "Sections",
}: AdminTabsProps) {
  const baseId = useId();
  const initialTabId =
    defaultTabId && tabs.some((tab) => tab.id === defaultTabId)
      ? defaultTabId
      : tabs[0]?.id;
  const [activeTabId, setActiveTabId] = useState(initialTabId);
  const activeTab = tabs.find((tab) => tab.id === activeTabId) ?? tabs[0];

  if (!activeTab) {
    return null;
  }

  return (
    <div className="space-y-4">
      <div
        className="overflow-x-auto rounded-xl border border-border bg-surface-muted p-1"
        role="tablist"
        aria-label={ariaLabel}
      >
        <div className="flex min-w-max gap-0.5">
          {tabs.map((tab) => {
            const isActive = tab.id === activeTab.id;
            const tabId = `${baseId}-tab-${tab.id}`;
            const panelId = `${baseId}-panel-${tab.id}`;
            const badgeCount = tab.badgeCount ?? 0;

            return (
              <button
                key={tab.id}
                type="button"
                role="tab"
                id={tabId}
                aria-selected={isActive}
                aria-controls={panelId}
                tabIndex={isActive ? 0 : -1}
                onClick={() => setActiveTabId(tab.id)}
                className={`inline-flex min-w-0 flex-1 items-center justify-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors ${
                  isActive
                    ? "bg-surface-elevated font-medium text-foreground shadow-card"
                    : "text-secondary hover:text-foreground"
                }`}
              >
                <span>{tab.label}</span>
                {badgeCount > 0 ? (
                  <span
                    className={`flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-[11px] font-semibold leading-none ${
                      isActive
                        ? "bg-accent text-accent-fg"
                        : "bg-accent-muted text-accent-soft"
                    }`}
                    aria-label={`${badgeCount} needing action`}
                  >
                    {formatBadgeCount(badgeCount)}
                  </span>
                ) : null}
              </button>
            );
          })}
        </div>
      </div>

      <div
        role="tabpanel"
        id={`${baseId}-panel-${activeTab.id}`}
        aria-labelledby={`${baseId}-tab-${activeTab.id}`}
      >
        {activeTab.content}
      </div>
    </div>
  );
}
