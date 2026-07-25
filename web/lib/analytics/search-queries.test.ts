import { beforeEach, describe, expect, it, vi } from "vitest";

const { insert, insertValues } = vi.hoisted(() => {
  const insertValues = vi.fn();
  const insert = vi.fn(() => ({ values: insertValues }));
  return { insert, insertValues };
});

vi.mock("@/lib/db", () => ({
  db: {
    insert,
  },
}));

vi.mock("@/db/schema", () => ({
  searchQueries: { __table: "search_queries" },
}));

import {
  recordSearchQueryFromEvent,
  searchQueryFromEvent,
} from "./search-queries";

describe("searchQueryFromEvent", () => {
  it("maps nearMe searches to nearby rows", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        user_id: "user-1",
        event_properties: {
          where_kind: "nearMe",
          days: "5",
          what: "beer,wine",
        },
      }),
    ).toEqual({
      userId: "user-1",
      type: "nearby",
      suburbId: null,
      day: 5,
      products: "beer,wine",
    });
  });

  it("maps suburb searches with suburb_id", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        user_id: null,
        event_properties: {
          where_kind: "suburb",
          suburb_id: 42,
          days: "1",
          what: "cocktails",
        },
      }),
    ).toEqual({
      userId: null,
      type: "suburb",
      suburbId: 42,
      day: 1,
      products: "cocktails",
    });
  });

  it("stores null day when multiple days are selected", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        event_properties: {
          where_kind: "suburb",
          suburb_id: 7,
          days: "1,3,5",
          what: null,
        },
      }),
    ).toEqual({
      userId: null,
      type: "suburb",
      suburbId: 7,
      day: null,
      products: null,
    });
  });

  it("stores null day when no days are selected", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        event_properties: {
          where_kind: "nearMe",
          days: "",
          what: "",
        },
      }),
    ).toEqual({
      userId: null,
      type: "nearby",
      suburbId: null,
      day: null,
      products: null,
    });
  });

  it("skips anywhere and non-search events", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        event_properties: { where_kind: "anywhere" },
      }),
    ).toBeNull();

    expect(
      searchQueryFromEvent({
        event_type: "page_viewed",
        event_properties: { where_kind: "suburb", suburb_id: 1 },
      }),
    ).toBeNull();
  });

  it("ignores invalid suburb ids and days", () => {
    expect(
      searchQueryFromEvent({
        event_type: "search_performed",
        event_properties: {
          where_kind: "suburb",
          suburb_id: -1,
          days: "9",
          what: "  beer  ",
        },
      }),
    ).toEqual({
      userId: null,
      type: "suburb",
      suburbId: null,
      day: null,
      products: "beer",
    });
  });
});

describe("recordSearchQueryFromEvent", () => {
  beforeEach(() => {
    insert.mockClear();
    insertValues.mockClear();
    insertValues.mockResolvedValue(undefined);
  });

  it("inserts mapped rows and skips unsupported events", async () => {
    await expect(
      recordSearchQueryFromEvent({
        event_type: "search_performed",
        user_id: "user-2",
        event_properties: {
          where_kind: "nearMe",
          days: "2",
          what: "beer",
        },
      }),
    ).resolves.toEqual({ recorded: true });

    expect(insert).toHaveBeenCalledWith({ __table: "search_queries" });
    expect(insertValues).toHaveBeenCalledWith({
      userId: "user-2",
      type: "nearby",
      suburbId: null,
      day: 2,
      products: "beer",
    });

    await expect(
      recordSearchQueryFromEvent({
        event_type: "venue_opened",
        event_properties: { venue_id: 1 },
      }),
    ).resolves.toEqual({ recorded: false });

    expect(insert).toHaveBeenCalledTimes(1);
  });
});
