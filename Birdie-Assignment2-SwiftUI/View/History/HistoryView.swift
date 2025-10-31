//
//  HistoryView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 3/11/2025.
//

import SwiftUI

// MARK: - History View
struct HistoryView: View {
    @State private var historyEntries: [History] = []
    private let dbController = DatabaseManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            VStack(spacing: 0) {
                // Header
                headerView(isLandscape: isLandscape)
                
                // Content
                if historyEntries.isEmpty {
                    emptyStateView(isLandscape: isLandscape)
                } else {
                    historyListView(isLandscape: isLandscape)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadHistory()
            }
        }
    }
    
    private func loadHistory() {
        DispatchQueue.global(qos: .userInitiated).async {
            let history = dbController.readAllHistory()
            DispatchQueue.main.async {
                historyEntries = history
            }
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        HeaderView(title: "History", isLandscape: isLandscape)
    }
    
    @ViewBuilder
    private func historyListView(isLandscape: Bool) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(historyEntries) { entry in
                    historyRow(entry: entry, isLandscape: isLandscape)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.secondarySystemBackground).opacity(0.3))
    }
    
    @ViewBuilder
    private func historyRow(entry: History, isLandscape: Bool) -> some View {
        HStack(spacing: 16) {
            // left: date and bird info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.formattedDate)
                    .font(.system(size: isLandscape ? 11 : 12))
                    .foregroundColor(.secondary)
                
                Text(entry.birdName)
                    .font(.system(size: isLandscape ? 16 : 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // right: result and status
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(entry.success ? "\(entry.attempts)" : "—")
                            .font(.system(size: isLandscape ? 20 : 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("/6")
                            .font(.system(size: isLandscape ? 14 : 16))
                            .foregroundColor(.secondary)
                    }
                }
                
                // status icon
                ZStack {
                    Circle()
                        .fill((entry.success ? Color.green : Color.red).opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: entry.success ? "checkmark" : "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(entry.success ? .green : .red)
                }
            }
        }
        .padding(isLandscape ? 14 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private func emptyStateView(isLandscape: Bool) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: isLandscape ? 70 : 80, height: isLandscape ? 70 : 80)
                
                Image(systemName: "book.closed")
                    .font(.system(size: isLandscape ? 36 : 40))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Puzzles Yet")
                    .font(.system(size: isLandscape ? 16 : 18, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Start playing to see your history here")
                    .font(.system(size: isLandscape ? 13 : 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}

