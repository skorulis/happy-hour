export const dealExtractionSchema = {
  type: "object",
  properties: {
    deals: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          details: {
            type: "array",
            items: { type: "string" },
          },
          conditions: {
            type: "array",
            items: { type: "string" },
          },
          days: {
            type: "array",
            items: { type: "string" },
          },
          times: {
            type: "array",
            items: { type: "string" },
          },
          promotionDates: {
            type: ["array", "null"],
            items: { type: "string" },
          },
        },
        required: [
          "title",
          "details",
          "conditions",
          "days",
          "times",
          "promotionDates",
        ],
        additionalProperties: false,
      },
    },
  },
  required: ["deals"],
  additionalProperties: false,
} as const;

export const responseFormat = {
  type: "json_schema",
  json_schema: {
    name: "deal_extraction",
    strict: true,
    schema: dealExtractionSchema,
  },
} as const;
