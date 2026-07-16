import { describe, expect, it } from "vitest";
import { validateAnalyticsTrackRequest } from "./validate";

describe("validateAnalyticsTrackRequest", () => {
  it("accepts a valid page_viewed event", () => {
    const result = validateAnalyticsTrackRequest({
      event_type: "page_viewed",
      device_id: "device-123",
      insert_id: "insert-123",
      time: 1_700_000_000_000,
      event_properties: {
        path: "/",
        search: "",
      },
    });

    expect(result).toEqual({
      ok: true,
      value: {
        event_type: "page_viewed",
        device_id: "device-123",
        insert_id: "insert-123",
        time: 1_700_000_000_000,
        event_properties: {
          path: "/",
          search: "",
        },
      },
    });
  });

  it("rejects unknown event types", () => {
    const result = validateAnalyticsTrackRequest({
      event_type: "not_a_real_event",
      device_id: "device-123",
    });

    expect(result).toEqual({ ok: false, error: "Invalid event_type" });
  });

  it("rejects missing device_id", () => {
    const result = validateAnalyticsTrackRequest({
      event_type: "search_performed",
    });

    expect(result).toEqual({ ok: false, error: "Invalid device_id" });
  });

  it("rejects nested event_properties", () => {
    const result = validateAnalyticsTrackRequest({
      event_type: "venue_opened",
      device_id: "device-123",
      event_properties: {
        nested: { a: 1 },
      },
    });

    expect(result).toEqual({
      ok: false,
      error: "Invalid event_properties value",
    });
  });

  it("defaults missing event_properties to empty object", () => {
    const result = validateAnalyticsTrackRequest({
      event_type: "map_marker_selected",
      device_id: "device-123",
    });

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value.event_properties).toEqual({});
    }
  });
});
