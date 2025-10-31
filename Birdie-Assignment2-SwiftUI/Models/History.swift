//
//  History.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 3/11/2025.
//

import Foundation

struct History: Codable, Identifiable {
    let id: Int64?
    let birdName: String
    let attempts: Int
    let success: Bool
    let completedAt: Date
    
    init(id: Int64? = nil, birdName: String, attempts: Int, success: Bool, completedAt: Date = Date()) {
        self.id = id
        self.birdName = birdName
        self.attempts = attempts
        self.success = success
        self.completedAt = completedAt
    }
    
    // formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: completedAt)
    }
}

