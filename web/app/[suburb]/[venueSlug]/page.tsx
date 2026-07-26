import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound, permanentRedirect, redirect } from "next/navigation";
import { VenuePageContent } from "@/components/VenuePageContent";
import { canManageVenue } from "@/lib/admin";
import { auth } from "@/lib/auth";
import {
  dayNumberToHash,
  stripDaySuffix,
} from "@/lib/search/day-path";
import { getVenueDetailBySlug } from "@/lib/search/queries";
import {
  suburbWhereRedirectPath,
  venuePath,
  venueRedirectPath,
} from "@/lib/search/slugs";
import {
  appendFiltersToPath,
  legacyDaysRedirectHref,
  parseDaysParam,
  parseWhatTokens,
} from "@/lib/search/url";
import {
  parseFilterSegment,
  splitWhatForPath,
} from "@/lib/search/what-path";
import {
  generateWhereListMetadata,
  renderWhereListPage,
} from "@/lib/search/where-list-page";

type VenuePageProps = {
  params: Promise<{ suburb: string; venueSlug: string }>;
  searchParams: Promise<{ days?: string; q?: string }>;
};

export async function generateMetadata({
  params,
  searchParams,
}: VenuePageProps): Promise<Metadata> {
  const { suburb, venueSlug: rawVenueSlug } = await params;
  const { q: whatParam } = await searchParams;
  const filter = parseFilterSegment(rawVenueSlug);

  if (filter) {
    const queryWhat = whatParam ? parseWhatTokens(whatParam) : [];
    const days = filter.day !== null ? [filter.day] : [];
    const what = [...filter.what];
    for (const token of queryWhat) {
      if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
        what.push(token);
      }
    }
    return generateWhereListMetadata(suburb, days, what);
  }

  const { base: venueSlug } = stripDaySuffix(rawVenueSlug);
  const venue =
    (await getVenueDetailBySlug(suburb, rawVenueSlug)) ??
    (await getVenueDetailBySlug(suburb, venueSlug));

  if (!venue) {
    return {};
  }

  const dealCount = venue.deals.length;
  const description =
    dealCount > 0
      ? `Browse ${dealCount} happy hour ${dealCount === 1 ? "deal" : "deals"} at ${venue.name}${venue.suburbName ? ` in ${venue.suburbName}` : ""}.`
      : `Happy hour deals and specials at ${venue.name}${venue.suburbName ? ` in ${venue.suburbName}` : ""}.`;

  const title = `${venue.name}${venue.suburbName ? `, ${venue.suburbName}` : ""}`;
  const path = venuePath(venue.suburbName, venue.name);
  const ogImages = venue.heroImage ? [{ url: venue.heroImage }] : undefined;

  return {
    title,
    description,
    alternates: {
      canonical: path,
    },
    openGraph: {
      title,
      description,
      type: "website",
      url: path,
      ...(ogImages ? { images: ogImages } : {}),
    },
    twitter: {
      card: ogImages ? "summary_large_image" : "summary",
      title,
      description,
      ...(ogImages ? { images: ogImages.map((image) => image.url) } : {}),
    },
  };
}

export default async function VenuePage({ params, searchParams }: VenuePageProps) {
  const { suburb, venueSlug: rawVenueSlug } = await params;
  const resolvedSearchParams = await searchParams;
  const { days: daysParam, q: whatParam } = resolvedSearchParams;
  const filter = parseFilterSegment(rawVenueSlug);

  // `/{where}/{filter}` list URLs share this dynamic segment with venues.
  if (filter) {
    const search = new URLSearchParams();
    if (daysParam) {
      search.set("days", daysParam);
    }
    if (whatParam) {
      search.set("q", whatParam);
    }

    const daysRedirect = legacyDaysRedirectHref(
      `/${suburb}/${rawVenueSlug}`,
      search,
    );
    if (daysRedirect) {
      permanentRedirect(daysRedirect);
    }

    const queryWhat = whatParam ? parseWhatTokens(whatParam) : [];
    const { pathTokens, queryTokens } = splitWhatForPath(queryWhat);
    if (pathTokens.length > 0) {
      const days = filter.day !== null ? [filter.day] : [];
      const mergedWhat = [...filter.what];
      for (const token of pathTokens) {
        if (
          !mergedWhat.some((item) => item.toLowerCase() === token.toLowerCase())
        ) {
          mergedWhat.push(token);
        }
      }
      const path = appendFiltersToPath(`/${suburb}`, days, mergedWhat);
      const cleaned = new URLSearchParams();
      if (queryTokens.length > 0) {
        cleaned.set("q", queryTokens.join(","));
      }
      const qs = cleaned.toString();
      permanentRedirect(qs ? `${path}?${qs}` : path);
    }

    const days = filter.day !== null ? [filter.day] : [];
    const aliasRedirect = suburbWhereRedirectPath(suburb, {
      day: filter.day ?? undefined,
      what: filter.what,
      q: whatParam,
    });
    if (aliasRedirect) {
      redirect(aliasRedirect);
    }

    const what = [...filter.what];
    for (const token of queryWhat) {
      if (!what.some((item) => item.toLowerCase() === token.toLowerCase())) {
        what.push(token);
      }
    }
    return renderWhereListPage(suburb, days, what);
  }

  const { base: pathBase, day: pathDay } = stripDaySuffix(rawVenueSlug);

  // Legacy path-suffixed venue URLs → canonical path + day hash.
  if (pathDay !== null) {
    const venue = await getVenueDetailBySlug(suburb, pathBase);
    if (venue) {
      const hash = dayNumberToHash(pathDay) ?? "";
      permanentRedirect(`/${suburb}/${pathBase}${hash}`);
    }
  }

  // Legacy ?days= query → day hash (or bare path for multi-day).
  if (daysParam !== undefined) {
    const days = parseDaysParam(daysParam);
    const hash =
      days.length === 1 ? (dayNumberToHash(days[0]!) ?? "") : "";
    permanentRedirect(`/${suburb}/${rawVenueSlug}${hash}`);
  }

  const redirectPath = venueRedirectPath(suburb, rawVenueSlug);
  if (redirectPath) {
    redirect(redirectPath);
  }

  const venue = await getVenueDetailBySlug(suburb, rawVenueSlug);

  if (!venue) {
    notFound();
  }

  const session = await auth.api.getSession({
    headers: await headers(),
  });
  const showAdminLink = session
    ? await canManageVenue(session.user, venue.id)
    : false;

  return (
    <VenuePageContent venue={venue} showAdminLink={showAdminLink} />
  );
}
