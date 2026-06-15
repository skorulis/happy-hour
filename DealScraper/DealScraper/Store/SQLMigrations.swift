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
    }
}
