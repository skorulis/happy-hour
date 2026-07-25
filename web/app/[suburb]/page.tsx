import { notFound, permanentRedirect, redirect } from "next/navigation";
import type { Metadata } from "next";
import {
  dayNumberToPathSlug,
  stripDaySuffix,
} from "@/lib/search/day-path";
import {
  NEARBY_WHERE_SLUG,
  suburbWhereRedirectPath,
} from "@/lib/search/slugs";
import {
  appendFiltersToPath,
  legacyDaysRedirectHref,
  parseWhatTokens,
  stripCatalogWhatFromParams,
} from "@/lib/search/url";
import { splitWhatForPath } from "@/lib/search/what-path";
import {
  generateWhereListMetadata,
  renderWhereListPage,
} from "@/lib/search/where-list-page";

type SuburbSearchPageProps = {
  params: Promise<{ suburb: string }>;
  searchParams: Promise<{ days?: string; q?: string }>;
};

export async function generateMetadata({
  params,
  searchParams,
}: SuburbSearchPageProps): Promise<Metadata> {
  const { suburb: rawWhereSlug } = await params;
  const { q: whatParam } = await searchParams;
  const { base: whereSlug, day } = stripDaySuffix(rawWhereSlug);
  const days = day !== null ? [day] : [];
  const what = whatParam ? parseWhatTokens(whatParam) : [];
  return generateWhereListMetadata(whereSlug, days, what);
}

export default async function SuburbSearchPage({
  params,
  searchParams,
}: SuburbSearchPageProps) {
  const { suburb: rawWhereSlug } = await params;
  const resolvedSearchParams = await searchParams;
  const { days: daysParam, q: whatParam } = resolvedSearchParams;
  const { base: whereSlug, day: pathDay } = stripDaySuffix(rawWhereSlug);

  const search = new URLSearchParams();
  if (daysParam) {
    search.set("days", daysParam);
  }
  if (whatParam) {
    search.set("q", whatParam);
  }

  const daysRedirect = legacyDaysRedirectHref(`/${rawWhereSlug}`, search);
  if (daysRedirect) {
    permanentRedirect(daysRedirect);
  }

  // Legacy hyphenated day suffix → `/{base}/{day}` path segment.
  if (pathDay !== null) {
    const daySlug = dayNumberToPathSlug(pathDay);
    if (!daySlug) {
      permanentRedirect(`/${whereSlug}`);
    }

    if (whereSlug === "map") {
      const cleaned = new URLSearchParams();
      if (whatParam) {
        cleaned.set("q", whatParam);
      }
      const qs = cleaned.toString();
      permanentRedirect(qs ? `/map?${qs}` : "/map");
    }

    const queryWhat = whatParam ? parseWhatTokens(whatParam) : [];
    const { pathTokens, queryTokens } = splitWhatForPath(queryWhat);
    const aliasRedirect = suburbWhereRedirectPath(whereSlug, {
      day: pathDay,
      what: pathTokens,
      q: queryTokens.length > 0 ? queryTokens.join(",") : undefined,
    });
    if (aliasRedirect) {
      redirect(aliasRedirect);
    }

    const path = appendFiltersToPath(`/${whereSlug}`, [pathDay], pathTokens);
    const cleaned = new URLSearchParams();
    if (queryTokens.length > 0) {
      cleaned.set("q", queryTokens.join(","));
    }
    const qs = cleaned.toString();
    permanentRedirect(qs ? `${path}?${qs}` : path);
  }

  // Move catalog `?q=` tokens into a filter path segment.
  if (whatParam) {
    const queryWhat = parseWhatTokens(whatParam);
    const { pathTokens, queryTokens } = splitWhatForPath(queryWhat);
    if (pathTokens.length > 0) {
      const aliasRedirect = suburbWhereRedirectPath(whereSlug, {
        what: pathTokens,
        q: queryTokens.length > 0 ? queryTokens.join(",") : undefined,
      });
      if (aliasRedirect) {
        redirect(aliasRedirect);
      }

      const path = appendFiltersToPath(`/${whereSlug}`, [], pathTokens);
      const cleaned = stripCatalogWhatFromParams(search);
      const qs = cleaned.toString();
      permanentRedirect(qs ? `${path}?${qs}` : path);
    }
  }

  const redirectPath = suburbWhereRedirectPath(whereSlug, {
    q: whatParam,
  });
  if (redirectPath) {
    redirect(redirectPath);
  }

  // Exact `/nearby` is a dedicated route; day-filtered nearby is `/nearby/{day}`.
  if (whereSlug === NEARBY_WHERE_SLUG) {
    notFound();
  }

  const what = whatParam ? parseWhatTokens(whatParam) : [];
  return renderWhereListPage(whereSlug, [], what);
}
