import type { Metadata } from "next";
import { VenueSearchPageContent } from "@/components/VenueSearchPageContent";

export const metadata: Metadata = {
  title: "Venue search",
  description: "Search for venues by name.",
  alternates: {
    canonical: "/venue-search",
  },
  openGraph: {
    title: "Venue search",
    description: "Search for venues by name.",
    type: "website",
    url: "/venue-search",
  },
};

export default function VenueSearchPage() {
  return <VenueSearchPageContent />;
}
