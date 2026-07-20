import { handleExtractDealsPost } from "@/lib/extract/extract-route";

export async function POST(request: Request) {
  return handleExtractDealsPost(request);
}
