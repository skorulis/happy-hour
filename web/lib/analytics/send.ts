import { sendToAmplitude } from "@/lib/analytics/amplitude";
import { recordSearchQueryFromEvent } from "@/lib/analytics/search-queries";
import type {
  AnalyticsEventPayload,
  AnalyticsTrackRequest,
} from "@/lib/analytics/types";

export type SendAnalyticsInput = AnalyticsTrackRequest & {
  user_id?: string | null;
};

/**
 * Fan-out point for analytics sinks. Forwards to Amplitude and, for
 * search_performed events, inserts a first-party `search_queries` row.
 * Sink failures are isolated so one failing destination does not block others.
 */
export async function sendAnalyticsEvent(
  input: SendAnalyticsInput,
): Promise<void> {
  const payload: AnalyticsEventPayload = {
    event_type: input.event_type,
    device_id: input.device_id,
    insert_id: input.insert_id ?? crypto.randomUUID(),
    time: input.time ?? Date.now(),
    event_properties: input.event_properties ?? {},
  };

  if (input.user_id) {
    payload.user_id = input.user_id;
  }

  const results = await Promise.allSettled([
    sendToAmplitude(payload),
    recordSearchQueryFromEvent({
      event_type: input.event_type,
      user_id: input.user_id ?? null,
      event_properties: input.event_properties,
    }),
  ]);

  for (const result of results) {
    if (result.status === "rejected") {
      console.error("Analytics sink failed", result.reason);
    }
  }
}
