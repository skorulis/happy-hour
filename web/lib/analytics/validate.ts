import {
  ANALYTICS_EVENT_TYPES,
  type AnalyticsEventProperties,
  type AnalyticsEventType,
  type AnalyticsPropertyValue,
  type AnalyticsTrackRequest,
} from "@/lib/analytics/types";

const MAX_DEVICE_ID_LENGTH = 128;
const MAX_INSERT_ID_LENGTH = 64;
const MAX_PROPERTY_KEYS = 32;
const MAX_PROPERTY_STRING_LENGTH = 512;

const EVENT_TYPE_SET = new Set<string>(ANALYTICS_EVENT_TYPES);

export type ValidateAnalyticsResult =
  | { ok: true; value: AnalyticsTrackRequest }
  | { ok: false; error: string };

function isAnalyticsEventType(value: string): value is AnalyticsEventType {
  return EVENT_TYPE_SET.has(value);
}

function isPropertyValue(value: unknown): value is AnalyticsPropertyValue {
  return (
    value === null ||
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  );
}

function sanitizeProperties(
  raw: unknown,
): { ok: true; value: AnalyticsEventProperties } | { ok: false; error: string } {
  if (raw === undefined) {
    return { ok: true, value: {} };
  }

  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, error: "Invalid event_properties" };
  }

  const entries = Object.entries(raw);
  if (entries.length > MAX_PROPERTY_KEYS) {
    return { ok: false, error: "Too many event_properties" };
  }

  const properties: AnalyticsEventProperties = {};

  for (const [key, value] of entries) {
    if (typeof key !== "string" || key.length === 0 || key.length > 64) {
      return { ok: false, error: "Invalid event_properties key" };
    }

    if (!isPropertyValue(value)) {
      return { ok: false, error: "Invalid event_properties value" };
    }

    if (typeof value === "string" && value.length > MAX_PROPERTY_STRING_LENGTH) {
      return { ok: false, error: "event_properties value too long" };
    }

    if (typeof value === "number" && !Number.isFinite(value)) {
      return { ok: false, error: "Invalid event_properties number" };
    }

    properties[key] = value;
  }

  return { ok: true, value: properties };
}

export function validateAnalyticsTrackRequest(
  body: unknown,
): ValidateAnalyticsResult {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return { ok: false, error: "Invalid JSON body" };
  }

  const record = body as Record<string, unknown>;

  if (typeof record.event_type !== "string" || !isAnalyticsEventType(record.event_type)) {
    return { ok: false, error: "Invalid event_type" };
  }

  if (
    typeof record.device_id !== "string" ||
    record.device_id.length === 0 ||
    record.device_id.length > MAX_DEVICE_ID_LENGTH
  ) {
    return { ok: false, error: "Invalid device_id" };
  }

  let insert_id: string | undefined;
  if (record.insert_id !== undefined) {
    if (
      typeof record.insert_id !== "string" ||
      record.insert_id.length === 0 ||
      record.insert_id.length > MAX_INSERT_ID_LENGTH
    ) {
      return { ok: false, error: "Invalid insert_id" };
    }
    insert_id = record.insert_id;
  }

  let time: number | undefined;
  if (record.time !== undefined) {
    if (
      typeof record.time !== "number" ||
      !Number.isFinite(record.time) ||
      !Number.isInteger(record.time) ||
      record.time <= 0
    ) {
      return { ok: false, error: "Invalid time" };
    }
    time = record.time;
  }

  const propertiesResult = sanitizeProperties(record.event_properties);
  if (!propertiesResult.ok) {
    return propertiesResult;
  }

  return {
    ok: true,
    value: {
      event_type: record.event_type,
      device_id: record.device_id,
      insert_id,
      time,
      event_properties: propertiesResult.value,
    },
  };
}
