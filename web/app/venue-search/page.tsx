import type { Metadata } from "next";
import { VenueSearchPageContent } from "@/components/VenueSearchPageContent";

export const metadata: Metadata = {
  title: "Venue search",
  description: "Search for venues by name.",
};

export default function VenueSearchPage() {
  return <VenueSearchPageContent />;
}
