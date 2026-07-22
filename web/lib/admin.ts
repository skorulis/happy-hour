import { isVenueOwner } from "@/lib/venue-ownership/queries";

const ADMIN_EMAIL = "skorulis@gmail.com";

export function isAdmin(email: string): boolean {
  return email === ADMIN_EMAIL;
}

export async function canManageVenue(
  user: { id: string; email: string },
  venueId: number,
): Promise<boolean> {
  if (isAdmin(user.email)) {
    return true;
  }

  return isVenueOwner(user.id, venueId);
}
