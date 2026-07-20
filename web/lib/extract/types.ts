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
