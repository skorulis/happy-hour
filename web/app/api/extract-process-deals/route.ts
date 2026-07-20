import { handleExtractDealsPost } from "@/lib/extract/extract-route";
import { processExtractedDeals } from "@/lib/extract/process";

export async function POST(request: Request) {
  return handleExtractDealsPost(request, (result, body) => ({
    deals: processExtractedDeals(result.deals, body.source),
  }));
}
