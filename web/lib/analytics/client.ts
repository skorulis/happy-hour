import type {
  AnalyticsEventProperties,
  AnalyticsEventType,
} from "@/lib/analytics/types";

const DEVICE_ID_STORAGE_KEY = "dr_device_id";

function createId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `anon-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
}

export function getDeviceId(): string {
  if (typeof window === "undefined") {
    return createId();
  }

  try {
    const existing = window.localStorage.getItem(DEVICE_ID_STORAGE_KEY);
    if (existing && existing.length > 0 && existing.length <= 128) {
      return existing;
    }

    const deviceId = createId();
    window.localStorage.setItem(DEVICE_ID_STORAGE_KEY, deviceId);
    return deviceId;
  } catch {
    return createId();
  }
}

export function track(
  eventType: AnalyticsEventType,
  eventProperties?: AnalyticsEventProperties,
): void {
  if (typeof window === "undefined") {
    return;
  }

  const body = JSON.stringify({
    event_type: eventType,
    device_id: getDeviceId(),
    insert_id: createId(),
    time: Date.now(),
    event_properties: eventProperties ?? {},
  });

  try {
    void fetch("/api/analytics", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
      credentials: "include",
      keepalive: true,
    }).catch(() => {
      // Fire-and-forget: never surface analytics failures to the UI.
    });
  } catch {
    // Ignore synchronous failures (e.g. private mode quirks).
  }
}
