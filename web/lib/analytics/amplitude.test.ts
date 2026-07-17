import { describe, expect, it } from "vitest";
import { buildAmplitudeRequestBody } from "./amplitude";

describe("buildAmplitudeRequestBody", () => {
  it("builds an Amplitude HTTP V2 payload", () => {
    expect(
      buildAmplitudeRequestBody("test-api-key", {
        event_type: "search_performed",
        device_id: "device-abc",
        insert_id: "insert-abc",
        time: 1_700_000_000_000,
        user_id: "user-1",
        event_properties: {
          view: "list",
          result_count: 3,
          what: null,
        },
      }),
    ).toEqual({
      api_key: "test-api-key",
      events: [
        {
          event_type: "search_performed",
          device_id: "device-abc",
          insert_id: "insert-abc",
          time: 1_700_000_000_000,
          app_version: "debug",
          user_id: "user-1",
          event_properties: {
            view: "list",
            result_count: 3,
            what: null,
          },
        },
      ],
    });
  });

  it("omits user_id when not provided", () => {
    const body = buildAmplitudeRequestBody("test-api-key", {
      event_type: "page_viewed",
      device_id: "device-abc",
      insert_id: "insert-abc",
      time: 1_700_000_000_000,
      event_properties: { path: "/map", search: "" },
    });

    expect(body.events[0]).not.toHaveProperty("user_id");
  });
});
