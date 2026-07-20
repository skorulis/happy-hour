export type ExtractSourceType = "image" | "webpage" | "pdf";

export type ExtractedDeal = {
  title: string;
  details: string[];
  conditions: string[];
  days: string[];
  times: string[];
  promotionDates: string[] | null;
};

export type ExtractDealsResponse = {
  deals: ExtractedDeal[];
};

export type ExtractDealsSource = {
  type: ExtractSourceType;
  index?: number;
  url: string;
  sourceURL?: string;
  imageBase64?: string;
  mimeType?: string;
  imageUrl?: string;
  markdown?: string;
  text?: string;
};

export type ExtractDealsRequest = {
  venueName: string;
  model?: string;
  source: ExtractDealsSource;
};

export type ProcessedDealSchedule = {
  dayOfWeek: number;
  startMinute: number;
  endMinute: number;
};

export type ProcessedDealStatus = "new" | "rejected";

export type ProcessedDeal = {
  title: string | null;
  details: string | null;
  conditions: string | null;
  creativeURL: string | null;
  sourceURL: string | null;
  status: ProcessedDealStatus;
  startDate: string | null;
  endDate: string | null;
  schedules: ProcessedDealSchedule[];
};

export type ExtractProcessDealsResponse = {
  deals: ProcessedDeal[];
};
