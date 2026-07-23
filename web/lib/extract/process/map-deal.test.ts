import { describe, expect, it } from "vitest";
import { mapDeals } from "@/lib/extract/process/map-deal";
import { parseDealExtractionPayload } from "@/lib/extract/openrouter";
import type { ExtractedDeal } from "@/lib/extract/types";
import type { DealHours, MappedDeal } from "@/lib/extract/process/types";

// Ported from DealScraper/DealScraperTests/DealMapperTests.swift

const from = (minutes: number): DealHours => ({ kind: "from", minutes });
const between = (start: number, end: number): DealHours => ({
  kind: "between",
  start,
  end,
});
const allDay: DealHours = { kind: "allDay" };

function raw(o: Partial<ExtractedDeal>): ExtractedDeal {
  return {
    title: o.title ?? "",
    details: o.details ?? [],
    conditions: o.conditions ?? [],
    days: o.days ?? [],
    times: o.times ?? [],
    promotionDates: o.promotionDates ?? null,
  };
}

function first(deals: MappedDeal[]): MappedDeal {
  const deal = deals[0];
  expect(deal).toBeDefined();
  return deal!;
}

function fromJSON(json: string): ExtractedDeal[] {
  return parseDealExtractionPayload(json).deals;
}

describe("mapDeals", () => {
  it("maps raw deal with days and times", () => {
    const deals = mapDeals([
      raw({
        title: "CHEESEBURGER TUESDAYS",
        details: ["TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS"],
        days: ["EVERY TUES"],
        times: ["all day"],
      }),
    ]);
    expect(deals).toHaveLength(1);
    const deal = first(deals);
    expect(deal.title).toBe("Cheeseburger Tuesdays");
    expect(deal.details).toEqual([
      "Ten dollar beef or vegan cheeseburgers with chips",
    ]);
    expect(deal.days).toEqual(["tuesday"]);
    expect(deal.times).toEqual([allDay]);
  });

  it("parses time range from raw deal", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["TUES - THURS"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.days).toEqual(["tuesday", "wednesday", "thursday"]);
    expect(deal.times).toContainEqual(between(16 * 60, 18 * 60));
  });

  it("expands monday to friday day range", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["MONDAY - FRIDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.days).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
  });

  it("expands monday through wednesday day range", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["Monday through Wednesday"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.days).toEqual(["monday", "tuesday", "wednesday"]);
  });

  it("supplements missing times from context", () => {
    const deal = first(
      mapDeals(
        [
          raw({
            title: "HAPPY HOUR",
            details: ["$8 SCHOONERS"],
            days: ["FRIDAY"],
            times: [],
          }),
        ],
        ["TUES - THURS 4PM - 6PM / FRI 3PM - 5PM"],
      ),
    );
    expect(deal.times.length).toBeGreaterThan(0);
  });

  it("merges deals with shared text", () => {
    const deals = mapDeals([
      raw({
        title: "HAPPY HOUR",
        details: ["$8 WINES"],
        days: ["TUESDAY"],
        times: ["4PM - 6PM"],
      }),
      raw({
        title: "",
        details: ["$8 WINES"],
        days: ["THURSDAY"],
        times: ["4PM - 6PM"],
      }),
    ]);
    expect(deals).toHaveLength(1);
    expect(deals[0]!.days).toContain("tuesday");
    expect(deals[0]!.days).toContain("thursday");
  });

  it("parses till time as until end of range", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "LATE NIGHT SPECIAL",
          details: ["$5 BEERS"],
          days: ["FRIDAY"],
          times: ["till 10pm"],
        }),
      ]),
    );
    expect(deal.times).toEqual([between(0, 22 * 60)]);
  });

  it("parses from-till time range", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 WINES"],
          days: ["FRIDAY"],
          times: ["from 4pm till 10pm"],
        }),
      ]),
    );
    expect(deal.times).toEqual([between(16 * 60, 22 * 60)]);
  });

  it("parses PM-till-PM time range from raw deal", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 WINES"],
          days: ["FRIDAY"],
          times: ["4pm \u2019til 6pm"],
        }),
      ]),
    );
    expect(deal.times).toEqual([between(16 * 60, 18 * 60)]);
  });

  it("parses bare-hour-till-PM time range from raw deal", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "LUNCH SPECIAL",
          details: ["$15 MAINS"],
          days: ["SATURDAY"],
          times: ["12 \u2019TIL 3PM"],
        }),
      ]),
    );
    expect(deal.times).toEqual([between(12 * 60, 15 * 60)]);
  });

  it("parses compact time range from raw deal", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["FRIDAY"],
          times: ["5pm-630pm"],
        }),
      ]),
    );
    expect(deal.times).toEqual([between(17 * 60, 18 * 60 + 30)]);
  });

  it("parses dot-separated time from raw deal", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["FRIDAY"],
          times: ["6.30pm"],
        }),
      ]),
    );
    expect(deal.times).toEqual([from(18 * 60 + 30)]);
  });

  it("strips leading asterisk from conditions", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "STEAK NIGHT",
          details: ["$22 STEAK"],
          conditions: ["*only available with bar service"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.conditions).toEqual(["only available with bar service"]);
  });

  it("filters empty raw deals", () => {
    const deals = mapDeals([
      raw({ title: "   ", details: [], days: [], times: [] }),
    ]);
    expect(deals).toHaveLength(0);
  });

  it("removes title repeated in details", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["HAPPY HOUR", "$8 WINES"],
          days: ["FRIDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Happy Hour");
    expect(deal.details).toEqual(["$8 Wines"]);
  });

  it("removes duplicate detail lines", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "TACO TUESDAY",
          details: ["$2 TACOS", "$2 TACOS", "$3 BEERS"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.details).toEqual(["$2 Tacos", "$3 Beers"]);
  });

  it("deduplicates details case-insensitively", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "WING WEDNESDAY",
          details: ["$1 WINGS", "$1 wings"],
          days: ["WEDNESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.details).toEqual(["$1 Wings"]);
  });

  it("removes conditions duplicating title or details", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "STEAK NIGHT",
          details: ["$22 STEAK"],
          conditions: ["STEAK NIGHT", "$22 STEAK", "dine-in only"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.conditions).toEqual(["dine-in only"]);
  });

  it("appends leading price detail to title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "STEAK NIGHT",
          details: ["$22", "Premium cut with sides"],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Steak Night $22");
    expect(deal.details).toEqual(["Premium cut with sides"]);
  });

  it("uses leading price as title when title is empty", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "",
          details: ["$39PP", "Sunday roast with all the trimmings"],
          days: ["SUNDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("$39PP");
    expect(deal.details).toEqual(["Sunday roast with all the trimmings"]);
  });

  it("does not append price-plus-description detail to title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "HAPPY HOUR",
          details: ["$8 SCHOONERS"],
          days: ["FRIDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Happy Hour");
    expect(deal.details).toEqual(["$8 Schooners"]);
  });

  it("does not duplicate leading price already in title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "$22 STEAK NIGHT",
          details: ["$22", "Raise the Steaks"],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("$22 Steak Night");
    expect(deal.details).toEqual(["Raise the steaks"]);
  });

  it("strips day from start of title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "MONDAY STEAK NIGHT",
          details: ["Raise the steaks"],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Steak Night");
    expect(deal.details).toEqual(["Raise the steaks"]);
  });

  it("strips day from end of title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "STEAK NIGHT TUESDAY",
          details: ["Raise the steaks"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Steak Night");
    expect(deal.details).toEqual(["Raise the steaks"]);
  });

  it("appends first detail line when title is price-only", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "$22",
          details: ["Premium cut with sides", "Selected cuts only"],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("$22 Premium Cut With Sides");
    expect(deal.details).toEqual(["Selected cuts only"]);
  });

  it("replaces day-only title with first detail line", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "Monday",
          details: ["$5 BEERS", "Selected tap beers only"],
          days: ["MONDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("$5 Beers");
    expect(deal.details).toEqual(["Selected tap beers only"]);
  });

  it("replaces day-only title with first line of multiline detail", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "TUESDAY",
          details: ["STEAK NIGHT\n$22 PREMIUM CUT"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Steak Night");
    expect(deal.details).toEqual(["$22 Premium cut"]);
  });

  it("rejects day-only title when details are empty", () => {
    const deals = mapDeals([
      raw({
        title: "Wednesday",
        details: [],
        conditions: ["Bar service only"],
        days: ["WEDNESDAY"],
        times: ["all day"],
      }),
    ]);
    expect(deals).toHaveLength(0);
  });

  it("keeps non-day-only titles unchanged", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "CHEESEBURGER TUESDAYS",
          details: ["TEN DOLLAR BEEF OR VEGAN CHEESEBURGERS WITH CHIPS"],
          days: ["TUESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Cheeseburger Tuesdays");
  });

  it("filters deals with excluded keywords in title", () => {
    const footy = raw({
      title: "LIVE & LOUD FOOTY",
      details: [
        "Hahn super dry pints for schooner prices whenever the games on.",
      ],
      days: ["FRIDAY"],
      times: ["all day"],
    });
    const origin = raw({
      title: "WELCOME TO ORIGIN 2026",
      details: ["Catch the action live, loud and with $9 pints of tooheys new."],
      days: ["WEDNESDAY"],
      times: ["all day"],
    });
    const happyHour = raw({
      title: "HAPPY HOUR",
      details: ["$7.50 schooners & $10 pints of select house beers"],
      days: ["MONDAY - FRIDAY"],
      times: ["4PM - 6PM"],
    });
    const deals = mapDeals([footy, origin, happyHour]);
    expect(deals).toHaveLength(1);
    expect(deals[0]!.title).toBe("Happy Hour");
  });

  it("filters excluded keywords in resolved day-only title", () => {
    const deals = mapDeals([
      raw({
        title: "FRIDAY",
        details: ["LIVE & LOUD FOOTY", "Pints for schooner prices"],
        days: ["FRIDAY"],
        times: ["all day"],
      }),
    ]);
    expect(deals).toHaveLength(0);
  });

  it("sentence-cases multiline details", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "STEAK NIGHT",
          details: ["RAISE THE STEAKS\nWITH ALL THE TRIMMINGS\n$22 EACH"],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.details).toEqual([
      "Raise the steaks\nWith all the trimmings\n$22 Each",
    ]);
  });

  it("parses parenthesized time range from raw deal", () => {
    const json =
      '{"deals":[{"days":["TUE - FRI"],"times":["(11 AM - 2 PM )"],"conditions":[],"title":"$25\\nPIZZA!\\n+BEER","details":[]}]}';
    const deal = first(mapDeals(fromJSON(json)));
    expect(deal.title).toBe("$25 Pizza! +Beer");
    expect(deal.days).toEqual(["tuesday", "wednesday", "thursday", "friday"]);
    expect(deal.times).toEqual([between(11 * 60, 14 * 60)]);
  });

  it("parses noon time range from raw deal", () => {
    const json =
      '{"deals":[{"title":"Sunday ROOFTOP PARMA","conditions":["AVAILABLE ON THE ROOFTOP TERRACE & FIRST FLOOR, WITH A DRINK PURCHASE*","Qualifying drinks: Bottle of beer or RTD. Pint of beer or soft drink. Glass of wine or cocktail","Specials & Promos are not available for functions/events or on Public Holidays/Special Event Days.","Promos subject to change without notice."],"days":["SUNDAYS"],"times":["NOON - 4PM"],"details":["$7.5","Chicken Parma","SERVED WITH CHIPS"]}]}';
    const deal = first(mapDeals(fromJSON(json)));
    expect(deal.title).toBe("Rooftop Parma $7.5");
    expect(deal.days).toEqual(["sunday"]);
    expect(deal.times).toEqual([between(12 * 60, 16 * 60)]);
  });

  it("strips trailing time from title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "NIGHT TRIVIA 6:30PM",
          details: [],
          days: ["TUESDAY"],
          times: ["6:30PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Night Trivia");
  });

  it("strips available-from time suffix from title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "BOTTLE SHOP WINES FROM $20 AVAILABLE FROM 5PM",
          details: [],
          days: ["FRIDAY"],
          times: ["5PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Bottle Shop Wines From $20");
  });

  it("strips trailing from after time removed from title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "LUNCH FROM 12PM",
          details: [],
          days: ["WEEKDAY"],
          times: ["12PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Lunch");
  });

  it("strips trailing time range from title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "$19 CHICKEN PARMI 4PM - 6PM",
          details: [],
          days: ["MONDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("$19 Chicken Parmi");
  });

  it("strips dangling time range separator from title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "$19 CHICKEN PARMI 4PM -",
          details: [],
          days: ["MONDAY"],
          times: ["4PM - 6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("$19 Chicken Parmi");
  });

  it("strips day after trailing time removed", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "NIGHT TRIVIA TUESDAY 6:30PM",
          details: [],
          days: ["TUESDAY"],
          times: ["6:30PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Night Trivia");
  });

  it("keeps Mountbatten happy hour and cocktails separate when mapped together", () => {
    const happyHourJSON =
      '{"deals":[{"title":"Happy Hour","details":["LET\'S DRINK TO THAT!"],"days":["EVERY DAY"],"times":["5PM - 8PM"],"conditions":["Conditions apply.","Available to LDA Rewards members only.","Selected beers and wines only.","This promotion is at management\'s discretion and may not be available on public holidays or some special events.","Mountbatten Hotel practices the Responsible Service of Alcohol.","Please drink responsibly."]}]}';
    const cocktailsJSON =
      '{"deals":[{"title":"$14 Cocktails","details":["A TASTE OF PERFECTION"],"days":["EVERY DAY"],"times":["5PM - 8PM"],"conditions":["Conditions apply.","Available to JDA Rewards members only.","This promotion is at management\'s discretion and may not be available on public holidays or some special events.","Please drink responsibly."]}]}';
    const happyHour = fromJSON(happyHourJSON)[0]!;
    const cocktails = fromJSON(cocktailsJSON)[0]!;
    const deals = mapDeals([happyHour, cocktails]);
    expect(deals).toHaveLength(2);
    expect(deals.some((d) => d.title === "Happy Hour")).toBe(true);
    expect(deals.some((d) => d.title === "$14 Cocktails")).toBe(true);
  });

  it("parses start-between time range from raw deal", () => {
    const json =
      '{"deals":[{"times":["with a start between 12pm-3:15pm."],"days":["Friday/Saturday/Sunday"],"title":"BOTTOMLESS DAIQUIRI LUNCH","conditions":["Please note - there is a 5% surcharge on Sundays, 7.5% service fee on groups of 8+ and a 12.5% surcharge on public holidays"],"details":["Get Tropical every weekend at Rosie Campbells.","Our Bottomless Lunch is perfect for your mini getaway for a celebration or catch up with friends!","DJ Kimani on the decks every Saturday.","Get the group together and enjoy 90 minutes of free flowing Daiquiri\'s & Pina Colada\'s, served with a 5 course island banquet for $99pp. Available, Friday/Saturday/Sunday with a start between 12pm-3:15pm.","90 Minute Drink & food package","- Unlimited Daiquiri\'s (3 Flavours available) & Pina Colada\'s","- Sparkling Wine & Tap Beer","- **Plantain Fritters** – Plantains, corn & jalapeno fritters with mango salsa","- **Island Taco** – Choice of jerk chicken or veggie","- **Kingston Prawns** – Coconut Chilli & coriander prawns with coconut pita bread","- **Famous Jerk Chicken** – Flame grilled jerk marinated chicken thigh, pineapple salsa & jerk sauce","- **Rice N Peas -** coconut jasmine rice, turtle peas, thyme, shallots"]},{"times":["all day"],"days":["TUESDAY"],"title":"TUESDAY | $1 JERK WINGS","conditions":[],"details":[]},{"times":["all day"],"days":["WEDNESDAY"],"title":"WEDNESDAY | SEAFOOD BOIL","conditions":[],"details":[]},{"times":["all day"],"days":["SUNDAY"],"title":"SUNDAY | SOUL FOOD PLATTER","conditions":[],"details":[]},{"times":["4-6PM"],"days":["WEEKDAYS"],"title":"WEEKDAYS 4-6PM | HAPPY HOUR","conditions":[],"details":[]}]}';
    const deals = mapDeals(fromJSON(json));
    expect(deals).toHaveLength(5);

    const bottomless = deals.find(
      (d) => d.title === "Bottomless Daiquiri Lunch",
    )!;
    expect(bottomless.days).toEqual(["friday", "saturday", "sunday"]);
    expect(bottomless.times).toEqual([between(12 * 60, 15 * 60 + 15)]);

    const jerkWings = deals.find((d) => d.title === "$1 Jerk Wings")!;
    expect(jerkWings.days).toEqual(["tuesday"]);
    expect(jerkWings.times).toEqual([allDay]);

    const seafoodBoil = deals.find((d) => d.title === "Seafood Boil")!;
    expect(seafoodBoil.days).toEqual(["wednesday"]);
    expect(seafoodBoil.times).toEqual([allDay]);

    const soulFood = deals.find((d) => d.title === "Soul Food Platter")!;
    expect(soulFood.days).toEqual(["sunday"]);
    expect(soulFood.times).toEqual([allDay]);

    const happyHour = deals.find(
      (d) => d.title === "Weekdays 4-6pm | Happy Hour",
    )!;
    expect(happyHour.days).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(happyHour.times).toEqual([between(16 * 60, 18 * 60)]);
  });

  it("parses markdown bold wrapped times from raw deal", () => {
    const json =
      '{"deals":[{"details":["Enjoy $4 wings, $8 select beers, and $11 Boozy Juice while the vibes roll on."],"title":"**Butter Happy Hour**","days":["weekdays"],"times":["**3PM–6PM**"],"conditions":[]},{"details":["Grab a **$20 sando + fries**, **$5 donuts**, and **$15 selected cocktails** to keep the party going."],"title":"**Late Night Feast**","days":["daily"],"times":["**9PM till close**"],"conditions":[]}]}';
    const deals = mapDeals(fromJSON(json));
    expect(deals).toHaveLength(2);

    const happyHour = deals.find((d) => d.title === "Butter Happy Hour")!;
    expect(happyHour.days).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(happyHour.times).toEqual([between(15 * 60, 18 * 60)]);

    const lateNight = deals.find((d) => d.title === "Late Night Feast")!;
    expect(lateNight.times).toEqual([from(21 * 60)]);
  });

  it("maps happy hour with split every-weekday days", () => {
    const json =
      '{"deals":[{"conditions":["* SELECTED RANGE OF BEER & WINE"],"times":["4PM-6PM"],"details":["BEERS","$7-"],"days":["EVERY","WEEKDAY"],"title":"HAPPY HOUR"}]}';
    const deal = first(mapDeals(fromJSON(json)));
    expect(deal.title).toBe("Happy Hour");
    expect(deal.details).toEqual(["Beers", "$7-"]);
    expect(deal.conditions).toEqual(["SELECTED RANGE OF BEER & WINE"]);
    expect(deal.days).toEqual([
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
    ]);
    expect(deal.times).toEqual([between(16 * 60, 18 * 60)]);
  });

  it("lowercases measurement units after numbers in title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "1KG WINGSDAY",
          details: ["All-you-can-eat wings"],
          days: ["WEDNESDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("1kg Wingsday");
  });

  it("lowercases gm after numbers in title", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "200GM SCHNITZEL",
          details: [],
          days: ["MONDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("200gm Schnitzel");
  });

  it("lowercases measurement units with space after numbers in title (ported source behavior)", () => {
    // NOTE: the Swift test asserts "500ml Pint Special", but the Swift source
    // preserves the space between the number and unit. We assert the ported
    // source behavior.
    const deal = first(
      mapDeals([
        raw({
          title: "500 ML PINT SPECIAL",
          details: [],
          days: ["FRIDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("500 ml Pint Special");
  });

  it("lowercases AM/PM after numbers in details", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "Happy Hour",
          details: ["Drinks special from 4PM until 6PM"],
          days: ["WEEKDAYS"],
          times: ["4PM-6PM"],
        }),
      ]),
    );
    expect(deal.details).toEqual(["Drinks special from 4pm until 6pm"]);
  });

  it("lowercases AM/PM left in title when not trimmed", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "WEEKDAYS 4-6PM | HAPPY HOUR",
          details: [],
          days: ["WEEKDAYS"],
          times: ["4-6PM"],
        }),
      ]),
    );
    expect(deal.title).toBe("Weekdays 4-6pm | Happy Hour");
  });

  it("lowercases pp after numbers in title and details", () => {
    const deal = first(
      mapDeals([
        raw({
          title: "BOTTOMLESS LUNCH $99PP",
          details: ["Island banquet for $99PP per person"],
          days: ["FRIDAY"],
          times: ["all day"],
        }),
      ]),
    );
    expect(deal.title).toBe("Bottomless Lunch $99pp");
    expect(deal.details).toEqual(["Island banquet for $99pp per person"]);
  });
});
