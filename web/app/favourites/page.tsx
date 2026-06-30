import type { Metadata } from "next";
import { FavouritesPageContent } from "@/components/FavouritesPageContent";

export const metadata: Metadata = {
  title: "Favourites",
  description: "Your saved happy hour deals.",
};

export default function FavouritesPage() {
  return <FavouritesPageContent />;
}
