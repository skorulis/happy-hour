import type { DealReportCategory } from "@/db/schema";

export const dealReportCategories: {
  value: DealReportCategory;
  label: string;
}[] = [
  {
    value: "unavailable",
    label: "This deal is no longer available",
  },
  {
    value: "incorrect_schedule",
    label: "The days or times on this deal are incorrect",
  },
  {
    value: "incorrect_description",
    label: "The description on this deal is incorrect",
  },
];

const categorySet = new Set<string>(
  dealReportCategories.map((category) => category.value),
);

export function isDealReportCategory(
  value: string,
): value is DealReportCategory {
  return categorySet.has(value);
}
