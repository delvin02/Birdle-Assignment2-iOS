//
//  DatabaseManager.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 5/11/2025.
//

import Foundation
import UIKit
import SQLite3

// helper function to bind text safely
// Uses NSString to get a C string pointer that stays valid
private func bindText(_ statement: OpaquePointer?, _ index: Int32, _ text: String) {
    _ = (text as NSString).utf8String.flatMap { cString in
        sqlite3_bind_text(statement, index, cString, -1, nil)
    }
}

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        // Set database path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("BirdieDB.sqlite").path
        
        // Initialize database and create tables if missing
        initializeDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Initialization
    
    /// initialise the database connection and creates tables if they don't exist.
    private func initializeDatabase() {
        // Ensure documents directory exists
        let dbDirectory = (dbPath as NSString).deletingLastPathComponent
        print("Database directory: \(dbDirectory)")
        if !FileManager.default.fileExists(atPath: dbDirectory) {
            try? FileManager.default.createDirectory(atPath: dbDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Open or create database file
        let result = sqlite3_open(dbPath, &db)
        guard result == SQLITE_OK, db != nil else {
            let errorMessage = db != nil ? String(cString: sqlite3_errmsg(db)) : "Unknown error"
            print("❌ Failed to open database. Error: \(errorMessage)")
            if db != nil {
                sqlite3_close(db)
                db = nil
            }
            return
        }
        
        // create tables if they don't exist (CREATE TABLE IF NOT EXISTS is safe)
        createTablesIfNeeded()
        
        // Insert dummy data for history if database is empty
        insertDummyDataIfNeeded()
    }
    
    /// Creates database tables only if they don't exist. No fetching or data operations.
    private func createTablesIfNeeded() {
        guard db != nil else {
            print("❌ Cannot create tables: database not open")
            return
        }
        
        // History table url
        let createHistorySQL = """
            CREATE TABLE IF NOT EXISTS History (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                birdName TEXT NOT NULL,
                attempts INTEGER NOT NULL,
                success INTEGER NOT NULL,
                completedAt TEXT NOT NULL
            );
        """
        
        executeCreateTable(createHistorySQL, tableName: "History")
    }
    
    /// Executes a CREATE TABLE IF NOT EXISTS statement. Safe to call multiple times.
    private func executeCreateTable(_ sql: String, tableName: String) {
        guard let db = db else { return }
        
        var statement: OpaquePointer?
        let sqlCString = sql.cString(using: .utf8)
        
        guard let sqlCString = sqlCString else {
            print("❌ Failed to convert SQL to C string for \(tableName)")
            return
        }
        
        if sqlite3_prepare_v2(db, sqlCString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                // Table created or already exists
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("⚠️ Failed to create \(tableName) table. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare SQL for \(tableName). Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
    }
    
    private func closeDatabase() {
        if let db = db {
            sqlite3_close(db)
            self.db = nil
        }
    }
    
    /// Deletes the database file and reinitializes it
    func deleteAndReinitializeDatabase() {
        // Close current database connection
        closeDatabase()
        
        // Delete the database file if it exists
        if FileManager.default.fileExists(atPath: dbPath) {
            do {
                try FileManager.default.removeItem(atPath: dbPath)
                print("✅ Database file deleted successfully")
            } catch {
                print("❌ Failed to delete database file: \(error.localizedDescription)")
                return
            }
        }
        
        // Reinitialize the database
        initializeDatabase()
        print("✅ Database reinitialized successfully")
    }
    
    // MARK: - History CRUD Operations
    /// Creates a new history record in the database
    func createHistory(_ history: History) -> Int64? {
        guard let db = db else {
            print("❌ Database not open")
            return nil
        }
        
        let insertSQL = """
        INSERT INTO History (birdName, attempts, success, completedAt)
        VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        var historyId: Int64?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            bindText(statement, 1, history.birdName)
            sqlite3_bind_int(statement, 2, Int32(history.attempts))
            sqlite3_bind_int(statement, 3, history.success ? 1 : 0)
            
            // Bind date as ISO8601 string
            let dateFormatter = ISO8601DateFormatter()
            let dateString = dateFormatter.string(from: history.completedAt)
            bindText(statement, 4, dateString)
            
            // Execute statement
            if sqlite3_step(statement) == SQLITE_DONE {
                historyId = sqlite3_last_insert_rowid(db)
                print("✅ History created successfully with ID: \(historyId ?? -1)")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("❌ Failed to create history. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare insert statement. Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return historyId
    }
    
    /// Reads all history records from the database, ordered by completion date (newest first)
    func readAllHistory() -> [History] {
        guard let db = db else {
            print("❌ Database not open")
            return []
        }
        
        let querySQL = "SELECT id, birdName, attempts, success, completedAt FROM History ORDER BY completedAt DESC;"
        var statement: OpaquePointer?
        var historyEntries: [History] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let birdName = String(cString: sqlite3_column_text(statement, 1))
                let attempts = Int(sqlite3_column_int(statement, 2))
                let success = sqlite3_column_int(statement, 3) == 1
                
                var completedAt = Date()
                if let dateText = sqlite3_column_text(statement, 4) {
                    let dateString = String(cString: dateText)
                    let dateFormatter = ISO8601DateFormatter()
                    completedAt = dateFormatter.date(from: dateString) ?? Date()
                }
                
                let history = History(
                    id: id,
                    birdName: birdName,
                    attempts: attempts,
                    success: success,
                    completedAt: completedAt
                )
                
                historyEntries.append(history)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare query statement. Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return historyEntries
    }
    
    /// Gets the total count of history records
    func getHistoryCount() -> Int {
        guard let db = db else {
            return 0
        }
        
        let countSQL = "SELECT COUNT(*) FROM History;"
        var statement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare count statement. Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return count
    }
    
    /// Checks if a puzzle was already completed today
    func hasCompletedToday() -> Bool {
        guard let db = db else {
            return false
        }
        
        // Get today's start and end date
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            return false
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startOfDay)
        let endString = dateFormatter.string(from: endOfDay)
        
        let querySQL = """
        SELECT COUNT(*) FROM History 
        WHERE completedAt >= ? AND completedAt <= ?;
        """
        
        var statement: OpaquePointer?
        var count = 0
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            bindText(statement, 1, startString)
            bindText(statement, 2, endString)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare today's completion check. Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return count > 0
    }
    
    /// Gets today's puzzle completion if it exists
    func getTodayCompletion() -> History? {
        guard let db = db else {
            return nil
        }
        
        // Get today's start and end date
        let calendar = Calendar.current
        let now = Date()
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let startString = dateFormatter.string(from: startOfDay)
        let endString = dateFormatter.string(from: endOfDay)
        
        let querySQL = """
        SELECT id, birdName, attempts, success, completedAt 
        FROM History 
        WHERE completedAt >= ? AND completedAt <= ?
        ORDER BY completedAt DESC
        LIMIT 1;
        """
        
        var statement: OpaquePointer?
        var history: History?
        
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            bindText(statement, 1, startString)
            bindText(statement, 2, endString)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let birdName = String(cString: sqlite3_column_text(statement, 1))
                let attempts = Int(sqlite3_column_int(statement, 2))
                let success = sqlite3_column_int(statement, 3) == 1
                
                var completedAt = Date()
                if let dateText = sqlite3_column_text(statement, 4) {
                    let dateString = String(cString: dateText)
                    completedAt = dateFormatter.date(from: dateString) ?? Date()
                }
                
                history = History(
                    id: id,
                    birdName: birdName,
                    attempts: attempts,
                    success: success,
                    completedAt: completedAt
                )
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("❌ Failed to prepare today's completion query. Error: \(errorMessage)")
        }
        
        sqlite3_finalize(statement)
        return history
    }
    
    // MARK: - Dummy Data Insertion
    
    /// Checks if database is empty and inserts dummy data if needed
    private func insertDummyDataIfNeeded() {
        guard db != nil else { return }
        
        // Check if database already has data
        let historyCount = getHistoryCount()
        
        // Only insert dummy data if both tables are empty
        if historyCount == 0 {
            print("📦 Inserting dummy data into database...")
            insertDummyHistory()
            print("✅ Dummy data inserted successfully")
        }
    }
    
    /// Inserts dummy history records
    private func insertDummyHistory() {
        let dummyHistory: [(birdName: String, attempts: Int, success: Bool, daysAgo: Int)] = [
            ("American Robin", 3, true, 1),
            ("Blue Jay", 6, false, 2),
            ("Cardinal", 2, true, 3),
            ("Goldfinch", 5, true, 5),
            ("Sparrow", 4, true, 7),
            ("American Robin", 1, true, 10),
            ("Blue Jay", 6, false, 12),
            ("Cardinal", 3, true, 15),
            ("Sparrow", 6, false, 18),
            ("Goldfinch", 2, true, 20)
        ]
        
        for historyInfo in dummyHistory {
            let completedAt = Date().addingTimeInterval(-Double(historyInfo.daysAgo) * 24 * 3600)
            let history = History(
                birdName: historyInfo.birdName,
                attempts: historyInfo.attempts,
                success: historyInfo.success,
                completedAt: completedAt
            )
            _ = createHistory(history)
        }
    }
}
