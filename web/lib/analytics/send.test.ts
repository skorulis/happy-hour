import { beforeEach, describe, expect, it, vi } from "vitest";

const { sendToAmplitude, recordSearchQueryFromEvent } = vi.hoisted(() => ({
  sendToAmplitude: vi.fn(),
  recordSearchQueryFromEvent: vi.fn(),
}));

vi.mock("@/lib/analytics/amplitude", () => ({
  sendToAmplitude,
}));

vi.mock("@/lib/analytics/search-queries", () => ({
  recordSearchQueryFromEvent,
}));

import { sendAnalyticsEvent } from "./send";

describe("sendAnalyticsEvent", () => {
  beforeEach(() => {
    sendToAmplitude.mockReset();
    recordSearchQueryFromEvent.mockReset();
    sendToAmplitude.mockResolvedValue({ sent: true });
    recordSearchQueryFromEvent.mockResolvedValue({ recorded: true });
    vi.spyOn(console, "error").mockImplementation(() => {});
  });

  it("fans out to Amplitude and the search query recorder", async () => {
    await sendAnalyticsEvent({
      event_type: "search_performed",
      device_id: "device-1",
      insert_id: "insert-1",
      time: 1_700_000_000_000,
      user_id: "user-1",
      event_properties: {
        where_kind: "suburb",
        suburb_id: 12,
        days: "3",
        what: "beer",
      },
    });

    expect(sendToAmplitude).toHaveBeenCalledWith({
      event_type: "search_performed",
      device_id: "device-1",
      insert_id: "insert-1",
      time: 1_700_000_000_000,
      user_id: "user-1",
      event_properties: {
        where_kind: "suburb",
        suburb_id: 12,
        days: "3",
        what: "beer",
      },
    });

    expect(recordSearchQueryFromEvent).toHaveBeenCalledWith({
      event_type: "search_performed",
      user_id: "user-1",
      event_properties: {
        where_kind: "suburb",
        suburb_id: 12,
        days: "3",
        what: "beer",
      },
    });
  });

  it("isolates sink failures", async () => {
    sendToAmplitude.mockRejectedValue(new Error("amplitude down"));
    recordSearchQueryFromEvent.mockResolvedValue({ recorded: true });

    await expect(
      sendAnalyticsEvent({
        event_type: "search_performed",
        device_id: "device-1",
        event_properties: { where_kind: "nearMe" },
      }),
    ).resolves.toBeUndefined();

    expect(recordSearchQueryFromEvent).toHaveBeenCalled();
    expect(console.error).toHaveBeenCalled();
  });

  it("still completes when both sinks fail", async () => {
    sendToAmplitude.mockRejectedValue(new Error("amplitude down"));
    recordSearchQueryFromEvent.mockRejectedValue(new Error("db down"));

    await expect(
      sendAnalyticsEvent({
        event_type: "page_viewed",
        device_id: "device-1",
        event_properties: { path: "/" },
      }),
    ).resolves.toBeUndefined();

    expect(console.error).toHaveBeenCalledTimes(2);
  });
});
