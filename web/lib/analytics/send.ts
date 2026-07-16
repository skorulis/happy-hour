import { sendToAmplitude } from "@/lib/analytics/amplitude";
import type {
  AnalyticsEventPayload,
  AnalyticsTrackRequest,
} from "@/lib/analytics/types";

export type SendAnalyticsInput = AnalyticsTrackRequest & {
  user_id?: string | null;
};

/**
 * Fan-out point for analytics sinks. Today this only forwards to Amplitude;
 * a database insert can be added here later without changing the API route.
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

  await sendToAmplitude(payload);
}
