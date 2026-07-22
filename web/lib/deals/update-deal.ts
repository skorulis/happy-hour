import { deal, dealSchedule, type DealStatus } from "@/db/schema";
import {
  CreateUserDealsValidationError,
  type UserDealInput,
} from "@/lib/deals/create-user-deals";
import { db } from "@/lib/db";
import { eq } from "drizzle-orm";

export type EditableDealStatus = Extract<DealStatus, "approved" | "rejected">;

export type UpdateDealInput = UserDealInput & {
  status: EditableDealStatus;
};

export async function updateManagedDeal(
  dealId: number,
  input: UpdateDealInput,
): Promise<void> {
  if (input.status !== "approved" && input.status !== "rejected") {
    throw new CreateUserDealsValidationError("Invalid status");
  }

  await db.transaction(async (tx) => {
    await tx
      .update(deal)
      .set({
        title: input.title,
        details: input.details,
        conditions: input.conditions,
        startDate: input.startDate,
        endDate: input.endDate,
        status: input.status,
      })
      .where(eq(deal.id, dealId));

    await tx.delete(dealSchedule).where(eq(dealSchedule.dealId, dealId));

    if (input.schedules.length > 0) {
      await tx.insert(dealSchedule).values(
        input.schedules.map((schedule) => ({
          dealId,
          dayOfWeek: schedule.dayOfWeek,
          startMinute: schedule.startMinute,
          endMinute: schedule.endMinute,
        })),
      );
    }
  });
}
