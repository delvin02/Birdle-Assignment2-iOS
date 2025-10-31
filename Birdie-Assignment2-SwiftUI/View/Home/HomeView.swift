//
//  HomeView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 31/10/2025.
//

import SwiftUI


struct HomeView: View {
    @State private var historyEntries: [History] = []
    @State private var isLoading: Bool = true
    
    private let dbController = DatabaseManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ScrollView {
                VStack(spacing: isLandscape ? 12 : 0) {
                    // Header
                    headerView(isLandscape: isLandscape)
                    
                    if isLandscape {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemBackground))
            .onAppear {
                loadHistory()
            }
        }
    }
    
    // MARK: - Statistics Calculations
    
    private var playedCount: Int {
        historyEntries.count
    }
    
    private var winRate: String {
        guard !historyEntries.isEmpty else { return "0%" }
        let successfulCount = historyEntries.filter { $0.success }.count
        let percentage = Int((Double(successfulCount) / Double(historyEntries.count)) * 100)
        return "\(percentage)%"
    }
    
    private var avgTries: String {
        guard !historyEntries.isEmpty else { return "0" }
        let totalTries = historyEntries.reduce(0) { $0 + $1.attempts }
        let average = Double(totalTries) / Double(historyEntries.count)
        return String(format: "%.1f", average)
    }
    
    // MARK: - Data Loading
    
    private func loadHistory() {
        DispatchQueue.global(qos: .userInitiated).async {
            let history = dbController.readAllHistory()
            DispatchQueue.main.async {
                self.historyEntries = history
                self.isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Birdle")
                    .font(.system(size: isLandscape ? 28 : 34, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(value: "help") {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: isLandscape ? 36 : 40, height: isLandscape ? 36 : 40)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.system(size: isLandscape ? 14 : 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            Text("Daily bird guessing puzzle")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, isLandscape ? 16 : 20)
        .padding(.top, isLandscape ? 12 : 18)
        .padding(.bottom, isLandscape ? 6 : 8)
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Puzzle Card
            puzzleCard
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Stats")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    statCard(value: "\(playedCount)", label: "Played", color: .blue)
                    statCard(value: winRate, label: "Win Rate", color: .purple)
                    statCard(value: avgTries, label: "Avg Tries", color: .orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            
            // Menu buttons
            VStack(spacing: 12) {
                menuButton(title: "History", icon: "clock.arrow.circlepath", tint: .blue)
                menuButton(title: "Upload Bird", icon: "square.and.arrow.up", tint: .purple)
                menuButton(title: "About", icon: "info.circle", tint: .orange)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
    
    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side: Puzzle Card
            puzzleCard
                .frame(maxWidth: .infinity)
            
            // Right side: Stats and Menu
            VStack(alignment: .leading, spacing: 16) {
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Stats")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        statCard(value: "\(playedCount)", label: "Played", color: .blue)
                        statCard(value: winRate, label: "Win Rate", color: .purple)
                        statCard(value: avgTries, label: "Avg Tries", color: .orange)
                    }
                }
                
                // Menu buttons
                VStack(spacing: 10) {
                    menuButton(title: "History", icon: "clock.arrow.circlepath", tint: .blue)
                    menuButton(title: "Upload Bird", icon: "square.and.arrow.up", tint: .purple)
                    menuButton(title: "About", icon: "info.circle", tint: .orange)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var puzzleCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Puzzle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("October 28, 2025")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "bird.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            
            NavigationLink(value: "puzzle") {
                Text("Start Puzzle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .font(.system(size: 16, weight: .semibold))
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(14)
            }
        }
        .padding(20)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .cornerRadius(28)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func menuButton(title: String, icon: String, tint: Color) -> some View {
        let route: String = {
            switch title {
            case "History": return "history"
            case "Upload Bird": return "upload"
            case "About": return "about"
            default: return ""
            }
        }()
        
        NavigationLink(value: route) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tint)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}
