"use client";

import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { searchParamsToMapHref } from "@/lib/search/url";

export function ViewMapRedirect() {
  const router = useRouter();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (searchParams.get("view") !== "map") {
      return;
    }

    router.replace(searchParamsToMapHref(searchParams));
  }, [router, searchParams]);

  return null;
}
