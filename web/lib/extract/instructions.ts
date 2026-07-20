import type { ExtractDealsSource, ExtractSourceType } from "./types";

const introduction = `You extract deals from pub and restaurant promotional material for a single venue.`;

const verbatimRule = `Critical rule: never rewrite text. Every title, detail, condition, day, time, and promotion date value must be copied character-for-character as shown in the source. Do not combine lines, change capitalization, fix spelling, expand abbreviations, or paraphrase.`;

const fieldRules = `Rules:
- Return one deal per distinct schedule (same days AND times).
- title: the promotion headline as shown in the source material. Do not use generic phrases that do not describe what the deal is.
- details: supporting text for this deal (prices, items, descriptions). One source line per entry.
- conditions: exclusions, footnotes, terms, or qualifiers such as "dine-in only" or "members only". One source line per entry.
- days: text that mentions which days apply, copied as written, e.g. 'EVERY TUES' or 'MON - FRI'.
- times: text that mentions when the deal applies, copied as written, e.g. '4PM - 6PM'. If no time is mentioned, set times to exactly ['all day'].
- promotionDates: If the promotion includes a date range for validity (e.g. 'Friday, 14 November – Monday, 1 December 2025', 'until 31 December', 'Black Friday only'). Copy as written, one source line per entry. Set to null when the source only describes a recurring weekly schedule with no calendar date limit. Do not put day-of-week schedules here — use days instead.
- Do not split a single promotion into multiple deals.
- Ignore venue names, URLs, social media handles, and addresses — leave them out of all fields.
- Large text is typically the deal title; smaller text is typically supporting details, times, or footers.`;

const imageSourceContext = `You receive one promotional image for the venue. The image is attached either as embedded image data or as an image URL — use whichever form is provided.`;

const webpageSourceContext = `You receive a webpage URL for the venue. Only inspect the visible text on that page. Do not navigate to other pages or follow links. Ignore any images on the page.`;

const markdownSourceContext = `You receive markdown converted from a venue webpage. Only use the visible promotional text in the markdown. Do not invent content. Ignore navigation, footers, and images.`;

const pdfSourceContext = `You receive promotional text extracted from a venue PDF document. Only use the visible promotional text provided. Do not invent content. Ignore headers, footers, and page numbers.`;

export const imageExtractionTask =
  "Extract all deals from the attached image.";
export const webpageExtractionTask =
  "Extract all deals from the visible text on this webpage.";
export const markdownExtractionTask =
  "Extract all deals from the webpage markdown below.";
export const pdfExtractionTask =
  "Extract all deals from the PDF text below. Ignore standard pricing";

function dealExtractionForType(type: ExtractSourceType): string {
  const sourceContext =
    type === "image"
      ? imageSourceContext
      : type === "pdf"
        ? pdfSourceContext
        : webpageSourceContext;

  return `${introduction}

${verbatimRule}

${sourceContext}

${fieldRules}`;
}

function dealExtractionForSource(source: ExtractDealsSource): string {
  if (source.type === "pdf") {
    return dealExtractionForType("pdf");
  }

  if (source.markdown != null && source.markdown.length > 0) {
    return `${introduction}

${verbatimRule}

${markdownSourceContext}

${fieldRules}`;
  }

  return dealExtractionForType(source.type);
}

function promptPreamble(venueName: string, source: ExtractDealsSource): string {
  let typeLabel: string;
  let extractionTask: string;

  if (source.type === "image") {
    typeLabel = "image";
    extractionTask = imageExtractionTask;
  } else if (source.type === "pdf") {
    typeLabel = "PDF text";
    extractionTask = pdfExtractionTask;
  } else if (source.markdown != null && source.markdown.length > 0) {
    typeLabel = "webpage markdown";
    extractionTask = markdownExtractionTask;
  } else {
    typeLabel = "webpage link";
    extractionTask = webpageExtractionTask;
  }

  const index = source.index ?? 1;
  const sourceURL = source.sourceURL ?? source.url;

  return `Venue: ${venueName}

Source ${index} (${typeLabel}): ${source.url} (found on ${sourceURL})

${extractionTask}`;
}

export function buildInstructions(
  venueName: string,
  source: ExtractDealsSource,
): string {
  return `${dealExtractionForSource(source)}

${promptPreamble(venueName, source)}`;
}
