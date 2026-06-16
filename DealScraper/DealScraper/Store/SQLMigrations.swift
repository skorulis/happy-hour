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
    }
}
