import { resolveMapIconForDeals, type DealTextFields } from "@data/products";
import { isDealActiveNow, type ScheduleSlice } from "./schedule";

type DealWithSchedules = DealTextFields & {
  schedules: ScheduleSlice[];
};

export function resolveVenueMapIcon(
  deals: DealWithSchedules[],
  now = new Date(),
): string | undefined {
  const activeDeals = deals.filter((deal) =>
    isDealActiveNow(deal.schedules, now),
  );
  const inactiveDeals = deals.filter(
    (deal) => !isDealActiveNow(deal.schedules, now),
  );

  const activeIcon = resolveMapIconForDeals(activeDeals);
  if (activeIcon) {
    return activeIcon;
  }

  return resolveMapIconForDeals(
    inactiveDeals.length > 0 ? inactiveDeals : deals,
  );
}
