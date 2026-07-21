import { deal, dealSchedule, venue } from "@/db/schema";
import { db } from "@/lib/db";
import { eq } from "drizzle-orm";

export type UserDealScheduleInput = {
  dayOfWeek: number;
  startMinute: number;
  endMinute: number;
};

export type UserDealInput = {
  title: string | null;
  details: string | null;
  conditions: string | null;
  startDate: string | null;
  endDate: string | null;
  schedules: UserDealScheduleInput[];
};

export type CreateUserDealsInput = {
  venueId: number;
  imageUrl: string;
  userId: string;
  deals: UserDealInput[];
};

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

export class CreateUserDealsValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CreateUserDealsValidationError";
  }
}

function asOptionalTrimmedString(value: unknown): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (typeof value !== "string") {
    throw new CreateUserDealsValidationError("Expected string or null");
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function asOptionalIsoDate(value: unknown, field: string): string | null {
  const text = asOptionalTrimmedString(value);
  if (text === null) {
    return null;
  }
  if (!ISO_DATE_RE.test(text)) {
    throw new CreateUserDealsValidationError(`Invalid ${field}`);
  }
  return text;
}

function parseSchedule(raw: unknown): UserDealScheduleInput {
  if (!raw || typeof raw !== "object") {
    throw new CreateUserDealsValidationError("Invalid schedule");
  }

  const schedule = raw as Record<string, unknown>;
  const dayOfWeek = schedule.dayOfWeek;
  const startMinute = schedule.startMinute;
  const endMinute = schedule.endMinute;

  if (
    typeof dayOfWeek !== "number" ||
    !Number.isInteger(dayOfWeek) ||
    dayOfWeek < 1 ||
    dayOfWeek > 7
  ) {
    throw new CreateUserDealsValidationError("Invalid schedule dayOfWeek");
  }

  if (
    typeof startMinute !== "number" ||
    !Number.isInteger(startMinute) ||
    startMinute < 0 ||
    startMinute > 1439
  ) {
    throw new CreateUserDealsValidationError("Invalid schedule startMinute");
  }

  if (
    typeof endMinute !== "number" ||
    !Number.isInteger(endMinute) ||
    endMinute < 1 ||
    endMinute > 2880
  ) {
    throw new CreateUserDealsValidationError("Invalid schedule endMinute");
  }

  return { dayOfWeek, startMinute, endMinute };
}

export function parseUserDealInputs(rawDeals: unknown): UserDealInput[] {
  if (!Array.isArray(rawDeals) || rawDeals.length === 0) {
    throw new CreateUserDealsValidationError("At least one deal is required");
  }

  return rawDeals.map((raw) => {
    if (!raw || typeof raw !== "object") {
      throw new CreateUserDealsValidationError("Invalid deal");
    }

    const dealInput = raw as Record<string, unknown>;
    const schedulesRaw = dealInput.schedules;
    if (!Array.isArray(schedulesRaw)) {
      throw new CreateUserDealsValidationError("Invalid deal schedules");
    }

    return {
      title: asOptionalTrimmedString(dealInput.title),
      details: asOptionalTrimmedString(dealInput.details),
      conditions: asOptionalTrimmedString(dealInput.conditions),
      startDate: asOptionalIsoDate(dealInput.startDate, "startDate"),
      endDate: asOptionalIsoDate(dealInput.endDate, "endDate"),
      schedules: schedulesRaw.map(parseSchedule),
    };
  });
}

export async function createUserDeals(
  input: CreateUserDealsInput,
): Promise<number[]> {
  const venues = await db
    .select({ id: venue.id })
    .from(venue)
    .where(eq(venue.id, input.venueId))
    .limit(1);

  if (venues.length === 0) {
    throw new CreateUserDealsValidationError("Venue not found");
  }

  return db.transaction(async (tx) => {
    const dealIds: number[] = [];

    for (const item of input.deals) {
      const [inserted] = await tx
        .insert(deal)
        .values({
          venueId: input.venueId,
          creationSource: "user",
          status: "new",
          userId: input.userId,
          title: item.title,
          details: item.details,
          conditions: item.conditions,
          startDate: item.startDate,
          endDate: item.endDate,
          imageUrl: input.imageUrl,
          sourceUrl: null,
        })
        .returning({ id: deal.id });

      if (!inserted) {
        throw new Error("Failed to insert deal");
      }

      dealIds.push(inserted.id);

      if (item.schedules.length > 0) {
        await tx.insert(dealSchedule).values(
          item.schedules.map((schedule) => ({
            dealId: inserted.id,
            dayOfWeek: schedule.dayOfWeek,
            startMinute: schedule.startMinute,
            endMinute: schedule.endMinute,
          })),
        );
      }
    }

    return dealIds;
  });
}
