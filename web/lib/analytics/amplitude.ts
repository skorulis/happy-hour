import type { AnalyticsEventPayload } from "@/lib/analytics/types";

const AMPLITUDE_HTTP_API_URL = "https://api2.amplitude.com/2/httpapi";

export type AmplitudeEventBody = {
  api_key: string;
  events: Array<{
    event_type: string;
    device_id: string;
    insert_id: string;
    time: number;
    user_id?: string;
    event_properties: Record<string, string | number | boolean | null>;
  }>;
};

export function buildAmplitudeRequestBody(
  apiKey: string,
  event: AnalyticsEventPayload,
): AmplitudeEventBody {
  const amplitudeEvent: AmplitudeEventBody["events"][number] = {
    event_type: event.event_type,
    device_id: event.device_id,
    insert_id: event.insert_id,
    time: event.time,
    event_properties: event.event_properties,
  };

  if (event.user_id) {
    amplitudeEvent.user_id = event.user_id;
  }

  return {
    api_key: apiKey,
    events: [amplitudeEvent],
  };
}

export async function sendToAmplitude(
  event: AnalyticsEventPayload,
): Promise<{ sent: boolean; skipped?: boolean }> {
  const apiKey = process.env.AMPLITUDE_API_KEY?.trim();
  if (!apiKey) {
    return { sent: false, skipped: true };
  }

  const body = buildAmplitudeRequestBody(apiKey, event);

  const response = await fetch(AMPLITUDE_HTTP_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "*/*",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const responseText = await response.text().catch(() => "");
    throw new Error(
      `Amplitude request failed (${response.status}): ${responseText.slice(0, 200)}`,
    );
  }

  return { sent: true };
}
