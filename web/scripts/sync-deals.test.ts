import { describe, expect, it } from "vitest";
import {
  collectActiveSourceDealIds,
  collectOrphanDealIds,
  shouldSkipDeal,
  syncVenueDealsWithStore,
  type DealScheduleInput,
  type DealSyncStore,
  type DealUpsertInput,
  type SqliteDeal,
  type SqliteDealSchedule,
} from "./sync-deals";

function makeDeal(overrides: Partial<SqliteDeal> = {}): SqliteDeal {
  return {
    id: 1,
    venue_id: 10,
    title: "Happy hour",
    creative_url: null,
    source_url: "https://example.com/deal",
    details: "Cheap pints",
    conditions: null,
    start_date: "2026-01-01",
    end_date: "2026-12-31",
    ...overrides,
  };
}

describe("shouldSkipDeal", () => {
  it("skips deals that have not started yet", () => {
    expect(
      shouldSkipDeal(makeDeal({ start_date: "2099-01-01" }), "2026-07-07"),
    ).toBe(true);
  });

  it("skips expired deals", () => {
    expect(
      shouldSkipDeal(makeDeal({ end_date: "2020-01-01" }), "2026-07-07"),
    ).toBe(true);
  });

  it("keeps active deals", () => {
    expect(shouldSkipDeal(makeDeal(), "2026-07-07")).toBe(false);
  });
});

describe("collectActiveSourceDealIds", () => {
  it("includes only approved deals within the active date window", () => {
    const active = collectActiveSourceDealIds(
      [
        makeDeal({ id: 1 }),
        makeDeal({ id: 2, end_date: "2020-01-01" }),
        makeDeal({ id: 3, start_date: "2099-01-01" }),
      ],
      "2026-07-07",
    );

    expect([...active]).toEqual([1]);
  });
});

describe("collectOrphanDealIds", () => {
  it("marks scraper deals without a source id or outside the active set as orphans", () => {
    const orphanIds = collectOrphanDealIds(
      [
        { id: 100, sourceDealId: 1, creationSource: "scraper" },
        { id: 101, sourceDealId: 2, creationSource: "scraper" },
        { id: 102, sourceDealId: null, creationSource: "scraper" },
        { id: 103, sourceDealId: null, creationSource: "user" },
        { id: 104, sourceDealId: 99, creationSource: "venue" },
      ],
      new Set([1]),
    );

    expect(orphanIds).toEqual([101, 102]);
  });
});

function createMemoryDealSyncStore(): DealSyncStore & {
  deals: Map<string, { id: number; input: DealUpsertInput }>;
  schedules: Map<number, DealScheduleInput[]>;
} {
  let nextDealId = 1;
  const deals = new Map<string, { id: number; input: DealUpsertInput }>();
  const schedules = new Map<number, DealScheduleInput[]>();

  return {
    deals,
    schedules,
    async upsertDeal(input) {
      const key = `${input.venueId}:${input.sourceDealId}`;
      const existing = deals.get(key);

      if (existing) {
        existing.input = input;
        return { id: existing.id };
      }

      const created = { id: nextDealId, input };
      nextDealId += 1;
      deals.set(key, created);
      return { id: created.id };
    },
    async replaceSchedules(dealId, nextSchedules) {
      schedules.set(dealId, nextSchedules);
    },
    async deleteOrphanDeals(venueId, activeSourceDealIds) {
      for (const [key, deal] of deals.entries()) {
        if (deal.input.venueId !== venueId) {
          continue;
        }
        if (deal.input.creationSource !== "scraper") {
          continue;
        }

        if (
          activeSourceDealIds.size === 0 ||
          !activeSourceDealIds.has(deal.input.sourceDealId)
        ) {
          deals.delete(key);
          schedules.delete(deal.id);
        }
      }
    },
  };
}

describe("syncVenueDealsWithStore", () => {
  it("preserves postgres deal ids when the same source deal syncs twice", async () => {
    const store = createMemoryDealSyncStore();
    const approvedDeals = [makeDeal({ id: 42, title: "First title" })];

    const firstCount = await syncVenueDealsWithStore(
      store,
      5,
      approvedDeals,
      new Map(),
      "2026-07-07",
    );
    const secondCount = await syncVenueDealsWithStore(
      store,
      5,
      [makeDeal({ id: 42, title: "Updated title" })],
      new Map(),
      "2026-07-07",
    );

    expect(firstCount).toBe(1);
    expect(secondCount).toBe(1);
    expect(store.deals.get("5:42")?.id).toBe(1);
    expect(store.deals.get("5:42")?.input.title).toBe("Updated title");
    expect(store.deals.get("5:42")?.input.creationSource).toBe("scraper");
  });

  it("does not orphan user or venue deals during scraper sync", async () => {
    const store = createMemoryDealSyncStore();
    store.deals.set("9:user-1", {
      id: 50,
      input: {
        venueId: 9,
        sourceDealId: -1,
        creationSource: "user",
        title: "User deal",
        imageUrl: null,
        sourceUrl: null,
        details: null,
        conditions: null,
        startDate: null,
        endDate: null,
        syncedAt: new Date(),
      },
    });

    await syncVenueDealsWithStore(
      store,
      9,
      [makeDeal({ id: 1 })],
      new Map(),
      "2026-07-07",
    );
    await syncVenueDealsWithStore(store, 9, [], new Map(), "2026-07-07");

    expect(store.deals.has("9:1")).toBe(false);
    expect(store.deals.get("9:user-1")?.input.creationSource).toBe("user");
  });

  it("replaces schedules without changing the parent deal id", async () => {
    const store = createMemoryDealSyncStore();
    const approvedDeals = [makeDeal({ id: 7 })];
    const initialSchedules: SqliteDealSchedule[] = [
      {
        id: 1,
        deal_id: 7,
        day_of_week: 1,
        start_minute: 960,
        end_minute: 1080,
      },
    ];
    const updatedSchedules: SqliteDealSchedule[] = [
      {
        id: 2,
        deal_id: 7,
        day_of_week: 5,
        start_minute: 1020,
        end_minute: 1140,
      },
    ];

    await syncVenueDealsWithStore(
      store,
      3,
      approvedDeals,
      new Map([[7, initialSchedules]]),
      "2026-07-07",
    );
    expect(store.deals.get("3:7")?.id).toBe(1);
    expect(store.schedules.get(1)).toEqual([
      { dayOfWeek: 1, startMinute: 960, endMinute: 1080 },
    ]);

    await syncVenueDealsWithStore(
      store,
      3,
      approvedDeals,
      new Map([[7, updatedSchedules]]),
      "2026-07-07",
    );

    expect(store.deals.get("3:7")?.id).toBe(1);
    expect(store.schedules.get(1)).toEqual([
      { dayOfWeek: 5, startMinute: 1020, endMinute: 1140 },
    ]);
  });

  it("removes orphan deals when sqlite deals expire or disappear", async () => {
    const store = createMemoryDealSyncStore();

    await syncVenueDealsWithStore(
      store,
      9,
      [makeDeal({ id: 1 }), makeDeal({ id: 2, title: "Other deal" })],
      new Map(),
      "2026-07-07",
    );
    expect([...store.deals.keys()].sort()).toEqual(["9:1", "9:2"]);

    await syncVenueDealsWithStore(
      store,
      9,
      [makeDeal({ id: 2, end_date: "2020-01-01" })],
      new Map(),
      "2026-07-07",
    );

    expect([...store.deals.keys()]).toEqual([]);
  });

  it("clamps synced schedules to venue opening hours", async () => {
    const store = createMemoryDealSyncStore();
    const approvedDeals = [makeDeal({ id: 7 })];
    const schedules: SqliteDealSchedule[] = [
      {
        id: 1,
        deal_id: 7,
        day_of_week: 2,
        start_minute: 0,
        end_minute: 1440,
      },
    ];
    const venueJson = {
      regularOpeningHours: {
        periods: [
          {
            open: { day: 1, hour: 8, minute: 0 },
            close: { day: 1, hour: 18, minute: 0 },
          },
        ],
      },
    };

    await syncVenueDealsWithStore(
      store,
      3,
      approvedDeals,
      new Map([[7, schedules]]),
      "2026-07-07",
      venueJson,
    );

    expect(store.schedules.get(1)).toEqual([
      { dayOfWeek: 2, startMinute: 480, endMinute: 1080 },
    ]);
  });
});
