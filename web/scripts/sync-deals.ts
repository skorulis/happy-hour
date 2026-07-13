import { and, eq, isNull, notInArray, or } from "drizzle-orm";
import * as schema from "../db/schema";
import {
  clampSchedulesToOpeningHours,
  parseVenueOpeningHours,
} from "./venue-opening-hours";

export type SqliteDeal = {
  id: number;
  venue_id: number;
  title: string | null;
  creative_url: string | null;
  source_url: string | null;
  details: string | null;
  conditions: string | null;
  start_date: string | null;
  end_date: string | null;
};

export type SqliteDealSchedule = {
  id: number;
  deal_id: number;
  day_of_week: number;
  start_minute: number;
  end_minute: number;
};

export type DealUpsertInput = {
  venueId: number;
  sourceDealId: number;
  title: string | null;
  imageUrl: string | null;
  sourceUrl: string | null;
  details: string | null;
  conditions: string | null;
  startDate: string | null;
  endDate: string | null;
  syncedAt: Date;
};

export type DealScheduleInput = {
  dayOfWeek: number;
  startMinute: number;
  endMinute: number;
};

export type DealSyncStore = {
  upsertDeal(input: DealUpsertInput): Promise<{ id: number }>;
  replaceSchedules(
    dealId: number,
    schedules: DealScheduleInput[],
  ): Promise<void>;
  deleteOrphanDeals(
    venueId: number,
    activeSourceDealIds: Set<number>,
  ): Promise<void>;
};

type SyncTransaction = Parameters<
  Parameters<
    ReturnType<typeof import("drizzle-orm/postgres-js").drizzle>["transaction"]
  >[0]
>[0];

export function shouldSkipDeal(dealRow: SqliteDeal, today: string): boolean {
  if (dealRow.start_date && dealRow.start_date > today) {
    return true;
  }
  if (dealRow.end_date && dealRow.end_date < today) {
    return true;
  }
  return false;
}

export function collectActiveSourceDealIds(
  approvedDeals: SqliteDeal[],
  today: string,
): Set<number> {
  const activeSourceDealIds = new Set<number>();

  for (const dealRow of approvedDeals) {
    if (!shouldSkipDeal(dealRow, today)) {
      activeSourceDealIds.add(dealRow.id);
    }
  }

  return activeSourceDealIds;
}

export function collectOrphanDealIds(
  existingDeals: Array<{ id: number; sourceDealId: number | null }>,
  activeSourceDealIds: Set<number>,
): number[] {
  return existingDeals
    .filter(
      (deal) =>
        deal.sourceDealId === null ||
        !activeSourceDealIds.has(deal.sourceDealId),
    )
    .map((deal) => deal.id);
}

export function toDealUpsertInput(
  venueId: number,
  dealRow: SqliteDeal,
  syncedAt: Date,
): DealUpsertInput {
  return {
    venueId,
    sourceDealId: dealRow.id,
    title: dealRow.title,
    imageUrl: dealRow.creative_url,
    sourceUrl: dealRow.source_url,
    details: dealRow.details,
    conditions: dealRow.conditions,
    startDate: dealRow.start_date,
    endDate: dealRow.end_date,
    syncedAt,
  };
}

export function toDealScheduleInputs(
  schedules: SqliteDealSchedule[],
): DealScheduleInput[] {
  return schedules.map((schedule) => ({
    dayOfWeek: schedule.day_of_week,
    startMinute: schedule.start_minute,
    endMinute: schedule.end_minute,
  }));
}

export async function deleteOrphanDealsForVenue(
  tx: SyncTransaction,
  venueId: number,
  activeSourceDealIds: Set<number>,
): Promise<void> {
  if (activeSourceDealIds.size === 0) {
    await tx.delete(schema.deal).where(eq(schema.deal.venueId, venueId));
    return;
  }

  await tx.delete(schema.deal).where(
    and(
      eq(schema.deal.venueId, venueId),
      or(
        isNull(schema.deal.sourceDealId),
        notInArray(schema.deal.sourceDealId, [...activeSourceDealIds]),
      ),
    ),
  );
}

export function createDrizzleDealSyncStore(tx: SyncTransaction): DealSyncStore {
  return {
    async upsertDeal(input) {
      const [upsertedDeal] = await tx
        .insert(schema.deal)
        .values({
          venueId: input.venueId,
          sourceDealId: input.sourceDealId,
          title: input.title,
          imageUrl: input.imageUrl,
          sourceUrl: input.sourceUrl,
          details: input.details,
          conditions: input.conditions,
          startDate: input.startDate,
          endDate: input.endDate,
          syncedAt: input.syncedAt,
        })
        .onConflictDoUpdate({
          target: [schema.deal.venueId, schema.deal.sourceDealId],
          set: {
            title: input.title,
            imageUrl: input.imageUrl,
            sourceUrl: input.sourceUrl,
            details: input.details,
            conditions: input.conditions,
            startDate: input.startDate,
            endDate: input.endDate,
            syncedAt: input.syncedAt,
          },
        })
        .returning({ id: schema.deal.id });

      return upsertedDeal;
    },
    async replaceSchedules(dealId, schedules) {
      await tx
        .delete(schema.dealSchedule)
        .where(eq(schema.dealSchedule.dealId, dealId));

      if (schedules.length === 0) {
        return;
      }

      await tx.insert(schema.dealSchedule).values(
        schedules.map((schedule) => ({
          dealId,
          dayOfWeek: schedule.dayOfWeek,
          startMinute: schedule.startMinute,
          endMinute: schedule.endMinute,
        })),
      );
    },
    deleteOrphanDeals(venueId, activeSourceDealIds) {
      return deleteOrphanDealsForVenue(tx, venueId, activeSourceDealIds);
    },
  };
}

export async function syncVenueDealsWithStore(
  store: DealSyncStore,
  venueId: number,
  approvedDeals: SqliteDeal[],
  schedulesByDealId: Map<number, SqliteDealSchedule[]>,
  today: string,
  venueJson?: unknown,
): Promise<number> {
  const activeSourceDealIds = collectActiveSourceDealIds(approvedDeals, today);
  const openingHours = parseVenueOpeningHours(venueJson);
  let dealsSynced = 0;
  const syncedAt = new Date();

  for (const dealRow of approvedDeals) {
    if (shouldSkipDeal(dealRow, today)) {
      continue;
    }

    const upsertedDeal = await store.upsertDeal(
      toDealUpsertInput(venueId, dealRow, syncedAt),
    );
    await store.replaceSchedules(
      upsertedDeal.id,
      clampSchedulesToOpeningHours(
        toDealScheduleInputs(schedulesByDealId.get(dealRow.id) ?? []),
        openingHours,
      ),
    );

    dealsSynced += 1;
  }

  await store.deleteOrphanDeals(venueId, activeSourceDealIds);

  return dealsSynced;
}

export async function syncVenueDeals(
  tx: SyncTransaction,
  venueId: number,
  approvedDeals: SqliteDeal[],
  schedulesByDealId: Map<number, SqliteDealSchedule[]>,
  today: string,
  venueJson?: unknown,
): Promise<number> {
  return syncVenueDealsWithStore(
    createDrizzleDealSyncStore(tx),
    venueId,
    approvedDeals,
    schedulesByDealId,
    today,
    venueJson,
  );
}
