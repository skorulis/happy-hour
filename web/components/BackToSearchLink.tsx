"use client";

import { useRouter } from "next/navigation";

export function BackToSearchLink() {
  const router = useRouter();

  function handleClick() {
    if (window.history.length > 1) {
      router.back();
      return;
    }

    router.push("/");
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      className="text-sm font-medium text-amber-700 hover:underline dark:text-amber-400"
    >
      ← Back to search
    </button>
  );
}
