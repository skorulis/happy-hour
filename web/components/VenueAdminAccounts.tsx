"use client";

import type { VenueOwner } from "@/lib/venue-ownership/queries";
import { useRouter } from "next/navigation";
import { type FormEvent, useState } from "react";

const inputClassName =
  "w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-foreground outline-none ring-accent focus:ring-2 sm:max-w-sm";

const addButtonClassName =
  "rounded-lg bg-accent px-3 py-2 text-sm font-medium text-accent-fg transition-colors hover:bg-accent-hover disabled:cursor-not-allowed disabled:opacity-60";

const removeButtonClassName =
  "rounded-lg border border-border bg-surface px-3 py-1.5 text-sm font-medium text-danger transition-colors hover:bg-surface-elevated disabled:cursor-not-allowed disabled:opacity-60";

type VenueAdminAccountsProps = {
  venueId: number;
  owners: VenueOwner[];
  currentUserId: string;
};

export function VenueAdminAccounts({
  venueId,
  owners,
  currentUserId,
}: VenueAdminAccountsProps) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [adding, setAdding] = useState(false);
  const [removingUserId, setRemovingUserId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleAdd(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setAdding(true);
    setError(null);

    try {
      const response = await fetch(`/api/venues/${venueId}/owners`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      if (!response.ok) {
        const data = (await response.json().catch(() => null)) as {
          error?: string;
        } | null;
        setError(data?.error ?? "Something went wrong");
        return;
      }

      setEmail("");
      router.refresh();
    } catch {
      setError("Something went wrong");
    } finally {
      setAdding(false);
    }
  }

  async function handleRemove(owner: VenueOwner) {
    const confirmed = window.confirm(
      `Remove ${owner.email} as an admin?`,
    );
    if (!confirmed) {
      return;
    }

    setRemovingUserId(owner.userId);
    setError(null);

    try {
      const response = await fetch(`/api/venues/${venueId}/owners`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: owner.userId }),
      });

      if (!response.ok) {
        const data = (await response.json().catch(() => null)) as {
          error?: string;
        } | null;
        setError(data?.error ?? "Something went wrong");
        return;
      }

      router.refresh();
    } catch {
      setError("Something went wrong");
    } finally {
      setRemovingUserId(null);
    }
  }

  return (
    <section className="space-y-4">
      {owners.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-muted">
          No venue admins yet
        </p>
      ) : (
        <ul className="divide-y divide-border-subtle rounded-xl border border-border">
          {owners.map((owner) => {
            const isSelf = owner.userId === currentUserId;
            return (
              <li
                key={owner.userId}
                className="flex items-center justify-between gap-4 px-4 py-4"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-foreground">
                    {owner.name}
                  </p>
                  <p className="truncate text-sm text-muted">{owner.email}</p>
                </div>
                {isSelf ? null : (
                  <button
                    type="button"
                    className={removeButtonClassName}
                    disabled={removingUserId !== null || adding}
                    onClick={() => handleRemove(owner)}
                  >
                    {removingUserId === owner.userId ? "Removing…" : "Remove"}
                  </button>
                )}
              </li>
            );
          })}
        </ul>
      )}

      <form onSubmit={handleAdd} className="space-y-3">
        <label className="block space-y-1.5">
          <span className="text-sm font-medium text-secondary">
            Add admin by email
          </span>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="user@example.com"
              className={inputClassName}
              disabled={adding || removingUserId !== null}
            />
            <button
              type="submit"
              className={addButtonClassName}
              disabled={adding || removingUserId !== null}
            >
              {adding ? "Adding…" : "Add admin"}
            </button>
          </div>
        </label>
      </form>

      {error ? <p className="text-sm text-danger">{error}</p> : null}
    </section>
  );
}
