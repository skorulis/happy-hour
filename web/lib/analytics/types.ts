export const ANALYTICS_EVENT_TYPES = [
  "page_viewed",
  "search_performed",
  "view_mode_toggled",
  "map_marker_selected",
  "venue_opened",
] as const;

export type AnalyticsEventType = (typeof ANALYTICS_EVENT_TYPES)[number];

export type AnalyticsPropertyValue = string | number | boolean | null;

export type AnalyticsEventProperties = Record<string, AnalyticsPropertyValue>;

export type AnalyticsTrackRequest = {
  event_type: AnalyticsEventType;
  device_id: string;
  insert_id?: string;
  time?: number;
  event_properties?: AnalyticsEventProperties;
};

export type AnalyticsEventPayload = {
  event_type: AnalyticsEventType;
  device_id: string;
  insert_id: string;
  time: number;
  event_properties: AnalyticsEventProperties;
  user_id?: string;
};
