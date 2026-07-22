// Created by Alex Skorulis on 24/5/2026.

import Foundation
import GRDB

final class SQLMigrations {
    
    var migrator = DatabaseMigrator()
    
    init() {
        migrator.registerMigration("v1_create_venue") { db in
            try db.create(table: "venue") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("google_map_id", .text).notNull().unique()
                t.column("name", .text).notNull()
                t.column("lat", .double).notNull()
                t.column("lng", .double).notNull()
                t.column("json", .text).notNull()
            }
        }

        migrator.registerMigration("v2_venue_website_and_crawl_date") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "website_uri", .text)
                t.add(column: "last_crawl_date", .datetime)
            }
        }

        migrator.registerMigration("v3_create_deal_source") { db in
            try db.create(table: "deal_source") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("venue_id", .integer)
                    .notNull()
                    .references("venue", onDelete: .cascade)
                t.column("url", .text).notNull()
                t.column("type", .text).notNull()
                t.column("hash", .text).notNull()
                t.column("status", .text).notNull()
                t.column("date", .datetime).notNull()
                t.uniqueKey(["venue_id", "hash"])
            }
        }

        migrator.registerMigration("v4_create_venue_links") { db in
            try db.create(table: "venue_links") { t in
                t.column("venue_id", .integer)
                    .primaryKey()
                    .references("venue", onDelete: .cascade)
                t.column("whats_on", .text)
                t.column("instagram", .text)
                t.column("facebook", .text)
            }
        }

        migrator.registerMigration("v5_deal_source_text_pieces") { db in
            try db.alter(table: "deal_source") { t in
                t.add(column: "text_pieces", .text)
            }
        }

        migrator.registerMigration("v6_deal_source_drop_hash") { db in
            try db.create(table: "deal_source_new") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("venue_id", .integer)
                    .notNull()
                    .references("venue", onDelete: .cascade)
                t.column("url", .text).notNull()
                t.column("type", .text).notNull()
                t.column("status", .text).notNull()
                t.column("date", .datetime).notNull()
                t.column("text_pieces", .text)
                t.uniqueKey(["venue_id", "url"])
            }
            try db.execute(sql: """
                INSERT INTO deal_source_new (id, venue_id, url, type, status, date, text_pieces)
                SELECT id, venue_id, url, type, status, date, text_pieces FROM deal_source
                """)
            try db.drop(table: "deal_source")
            try db.rename(table: "deal_source_new", to: "deal_source")
        }

        migrator.registerMigration("v7_deal_source_source_url") { db in
            try db.alter(table: "deal_source") { t in
                t.add(column: "source_url", .text)
            }
            try db.execute(sql: "UPDATE deal_source SET source_url = url WHERE source_url IS NULL")
        }

        migrator.registerMigration("v8_create_deal") { db in
            try db.create(table: "deal") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("venue_id", .integer)
                    .notNull()
                    .references("venue", onDelete: .cascade)
                t.column("image_url", .text)
                t.column("source_url", .text)
                t.column("details", .text)
                t.column("conditions", .text)
            }
        }

        migrator.registerMigration("v9_create_deal_schedule") { db in
            try db.create(table: "deal_schedule") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("deal_id", .integer)
                    .notNull()
                    .references("deal", onDelete: .cascade)
                t.column("day_of_week", .integer).notNull()
                t.column("start_minute", .integer).notNull()
                t.column("end_minute", .integer).notNull()
            }
        }

        migrator.registerMigration("v10_add_deal_title") { db in
            try db.alter(table: "deal") { t in
                t.add(column: "title", .text)
            }
        }

        migrator.registerMigration("v11_add_deal_status") { db in
            try db.alter(table: "deal") { t in
                t.add(column: "status", .text).notNull().defaults(to: DealStatus.new.rawValue)
            }
        }

        migrator.registerMigration("v12_create_suburb") { db in
            try db.create(table: "suburb") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("postcode", .text)
                t.uniqueKey(["name", "postcode"])
            }

            try db.alter(table: "venue") { t in
                t.add(column: "suburb_id", .integer)
                    .references("suburb", onDelete: .setNull)
            }
        }

        migrator.registerMigration("v13_deal_creative_url") { db in
            try db.alter(table: "deal") { t in
                t.rename(column: "image_url", to: "creative_url")
            }
        }

        migrator.registerMigration("v14_venue_last_extraction_date") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "last_extraction_date", .datetime)
            }
        }

        migrator.registerMigration("v15_venue_status") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "status", .text).notNull().defaults(to: VenueStatus.normal.rawValue)
            }
        }

        migrator.registerMigration("v16_venue_hero_image") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "hero_image", .text)
            }
        }

        migrator.registerMigration("v17_deal_source_content_hash") { db in
            try db.alter(table: "deal_source") { t in
                t.add(column: "content_hash", .text)
            }
            try db.create(
                index: "deal_source_venue_content_hash",
                on: "deal_source",
                columns: ["venue_id", "content_hash"],
                unique: true
            )
        }

        migrator.registerMigration("v18_suburb_state_and_coordinates") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "state", .text)
                t.add(column: "lat", .double)
                t.add(column: "lng", .double)
            }
        }

        migrator.registerMigration("v19_suburb_sqkm") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "sqkm", .double)
            }
        }

        migrator.registerMigration("v20_venue_last_crawl_url") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "last_crawl_url", .text)
            }
        }

        migrator.registerMigration("v21_suburb_statistic_area") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "statistic_area", .text)
            }
        }

        migrator.registerMigration("v22_suburb_last_crawl_date") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "last_crawl_date", .datetime)
            }
        }

        migrator.registerMigration("v23_venue_blurb") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "blurb", .text)
            }
        }

        migrator.registerMigration("v24_suburb_blurb") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "blurb", .text)
            }
        }

        migrator.registerMigration("v25_deal_update_date") { db in
            try db.alter(table: "deal") { t in
                t.add(column: "update_date", .datetime)
            }
        }

        migrator.registerMigration("v26_deal_start_end_date") { db in
            try db.alter(table: "deal") { t in
                t.add(column: "start_date", .date)
                t.add(column: "end_date", .date)
            }
        }

        migrator.registerMigration("v27_venue_hero_r2_url") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "hero_r2_url", .text)
            }
        }

        migrator.registerMigration("v28_venue_last_update") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "last_update", .datetime)
            }
            try db.execute(sql: "UPDATE venue SET last_update = CURRENT_TIMESTAMP")
        }

        migrator.registerMigration("v29_create_country") { db in
            try db.create(table: "country") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("iso3", .text).notNull().unique()
            }

            try db.alter(table: "suburb") { t in
                t.add(column: "country_id", .integer)
                    .references("country", onDelete: .setNull)
            }
        }

        migrator.registerMigration("v30_suburb_hero_image") { db in
            try db.alter(table: "suburb") { t in
                t.add(column: "hero_image", .text)
                t.add(column: "hero_r2_url", .text)
            }
        }

        migrator.registerMigration("v31_venue_google_rating") { db in
            try db.alter(table: "venue") { t in
                t.add(column: "google_rating", .double)
            }
        }

        migrator.registerMigration("v32_create_geographic_region") { db in
            try db.create(table: "geographic_region") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("country_id", .integer)
                    .notNull()
                    .references("country", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.uniqueKey(["country_id", "name"])
            }

            try db.alter(table: "suburb") { t in
                t.add(column: "region_id", .integer)
                    .references("geographic_region", onDelete: .setNull)
            }
        }

        migrator.registerMigration("v33_rename_greater_sydney_region") { db in
            try db.execute(
                sql: """
                UPDATE geographic_region
                SET name = ?
                WHERE name = ?
                """,
                arguments: [GeographicRegion.sydneyName, "Greater Sydney"]
            )
        }

        migrator.registerMigration("v34_rename_sydney_suburb") { db in
            try db.execute(
                sql: """
                UPDATE suburb
                SET name = 'Sydney CBD'
                WHERE name = 'Sydney' AND postcode = '2000' AND state = 'NSW'
                """
            )
        }
    }
}

