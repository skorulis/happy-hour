-- Dedupe suburbs that share (name, postcode) where postcode IS NULL.
-- For each duplicate group, keep the row with the most venue references
-- (tie-break: lowest id), then repoint venue and search_queries FKs to the
-- keeper and delete the extras.
DO $$
DECLARE
  rec RECORD;
  keeper_id INTEGER;
BEGIN
  FOR rec IN
    SELECT name, postcode
    FROM suburb
    GROUP BY name, postcode
    HAVING COUNT(*) > 1
  LOOP
    -- Pick keeper: most venues, then lowest id.
    SELECT s.id INTO keeper_id
    FROM suburb s
    LEFT JOIN venue v ON v.suburb_id = s.id
    WHERE s.name = rec.name
      AND (
        (rec.postcode IS NULL AND s.postcode IS NULL)
        OR s.postcode = rec.postcode
      )
    GROUP BY s.id
    ORDER BY COUNT(v.id) DESC, s.id ASC
    LIMIT 1;

    -- Repoint venues pointing at any duplicate to the keeper.
    UPDATE venue
    SET suburb_id = keeper_id
    WHERE suburb_id IN (
      SELECT id FROM suburb
      WHERE name = rec.name
        AND (
          (rec.postcode IS NULL AND postcode IS NULL)
          OR postcode = rec.postcode
        )
        AND id <> keeper_id
    );

    -- Repoint search_queries pointing at any duplicate to the keeper.
    UPDATE search_queries
    SET suburb_id = keeper_id
    WHERE suburb_id IN (
      SELECT id FROM suburb
      WHERE name = rec.name
        AND (
          (rec.postcode IS NULL AND postcode IS NULL)
          OR postcode = rec.postcode
        )
        AND id <> keeper_id
    );

    -- Delete the duplicate rows.
    DELETE FROM suburb
    WHERE name = rec.name
      AND (
        (rec.postcode IS NULL AND postcode IS NULL)
        OR postcode = rec.postcode
      )
      AND id <> keeper_id;
  END LOOP;
END $$;
--> statement-breakpoint
DROP INDEX "suburb_name_postcode_idx";--> statement-breakpoint
ALTER TABLE "suburb" ADD CONSTRAINT "suburb_name_postcode_idx" UNIQUE NULLS NOT DISTINCT("name","postcode");