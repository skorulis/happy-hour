// Created by Alex Skorulis on 24/5/2026.

import Foundation
import GRDB

final class SQLStore {
    
    private static let dbURL: URL = docDir.appending(path: "db.sqlite")
    private static var dbPath: String {
        return dbURL.pathComponents.joined(separator: "/")
    }
    
    let dbQueue: DatabaseQueue
    
    init(inMemory: Bool = false) {
        print("SQL STARTED: \(Self.dbPath)")
        if inMemory {
            self.dbQueue = try! DatabaseQueue()
        } else {
            self.dbQueue = try! DatabaseQueue(path: Self.dbPath)
        }
        
        try! migrate()
        try! seedDefaultCountries()
        try! seedDefaultGeographicRegions()
    }
    
    static func `default`() -> SQLStore {
        return .init(inMemory: false)
    }
    
    static func inMemory() -> SQLStore {
        return .init(inMemory: true)
    }
    
    private func migrate() throws {
        let migrations = SQLMigrations()
        try migrations.migrator.migrate(dbQueue)
    }

    private func seedDefaultCountries() throws {
        try dbQueue.write { db in
            for country in Country.defaults {
                let existing = try Country
                    .filter(Column("iso3") == country.iso3)
                    .fetchOne(db)
                if existing == nil {
                    var mutable = country
                    try mutable.insert(db)
                }
            }
        }
    }

    private func seedDefaultGeographicRegions() throws {
        try dbQueue.write { db in
            guard let australia = try Country
                .filter(Column("iso3") == Country.australia.iso3)
                .fetchOne(db),
                let australiaId = australia.id
            else {
                return
            }

            for name in RegionsCatalog.regionNames {
                let existing = try GeographicRegion
                    .filter(Column("country_id") == australiaId)
                    .filter(Column("name") == name)
                    .fetchOne(db)
                if existing == nil {
                    var region = GeographicRegion(countryId: australiaId, name: name)
                    try region.insert(db)
                }
            }
        }
    }
    
    static var docDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
}

