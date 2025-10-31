//
//  HelpView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 31/10/2025.
//
import SwiftUI

struct HelpView: View {
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            VStack(spacing: 0) {
                // Header
                headerView(isLandscape: isLandscape)
                
                // Content
                ScrollView {
                    VStack(spacing: isLandscape ? 16 : 24) {
                        // Welcome Section
                        welcomeSection(isLandscape: isLandscape)
                        
                        // Cards
                        Group {
                            if isLandscape {
                                HStack(alignment: .top, spacing: 12) {
                                    InfoCard(
                                        number: "1",
                                        title: "Start the Puzzle",
                                        body: "Each day features a new bird. Tap \"Start Puzzle\" to begin your daily challenge.",
                                        icon: "play.circle.fill",
                                        gradient: LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    InfoCard(
                                        number: "2",
                                        title: "Make Your Guess",
                                        body: "The first image is heavily blurred. Type your guess and submit. Each wrong answer reveals a clearer image.",
                                        icon: "text.bubble.fill",
                                        gradient: LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.12), Color.orange.opacity(0.12)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    InfoCard(
                                        number: "3",
                                        title: "Win or Learn",
                                        body: "Guess correctly to win! After 6 attempts or a correct guess, you'll see the full image and learn more about the bird.",
                                        icon: "trophy.fill",
                                        gradient: LinearGradient(
                                            gradient: Gradient(colors: [Color.orange.opacity(0.12), Color.blue.opacity(0.12)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 8)
                            } else {
                                infoCards
                            }
                        }
                        
                        // Tips
                        tipsSection(isLandscape: isLandscape)
                    }
                    .padding(.top, isLandscape ? 12 : 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        HeaderView(title: "How to Play", isLandscape: isLandscape)
    }
    
    @ViewBuilder
    private func welcomeSection(isLandscape: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isLandscape ? 48 : 56, height: isLandscape ? 48 : 56)
                    
                    Image(systemName: "bird.fill")
                        .font(.system(size: isLandscape ? 24 : 28))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to Birdle!")
                        .font(.system(size: isLandscape ? 20 : 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Guess the bird from progressively clearer images. You have 6 attempts to identify the correct bird species.")
                        .font(.system(size: isLandscape ? 14 : 16))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var infoCards: some View {
        VStack(spacing: 16) {
            InfoCard(
                number: "1",
                title: "Start the Puzzle",
                body: "Each day features a new bird. Tap \"Start Puzzle\" to begin your daily challenge.",
                icon: "play.circle.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            InfoCard(
                number: "2",
                title: "Make Your Guess",
                body: "The first image is heavily blurred. Type your guess and submit. Each wrong answer reveals a clearer image.",
                icon: "text.bubble.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.12), Color.orange.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            InfoCard(
                number: "3",
                title: "Win or Learn",
                body: "Guess correctly to win! After 6 attempts or a correct guess, you'll see the full image and learn more about the bird.",
                icon: "trophy.fill",
                gradient: LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.12), Color.blue.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    @ViewBuilder
    private func tipsSection(isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: isLandscape ? 16 : 18))
                    .foregroundColor(.orange)
                
                Text("Tips")
                    .font(.system(size: isLandscape ? 18 : 20, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 14) {
                tipRow(icon: "eye.fill", text: "Look for distinctive features like beak shape, size, and coloring")
                tipRow(icon: "mountain.2.fill", text: "Consider the habitat visible in the background")
                tipRow(icon: "calendar", text: "You can only attempt each puzzle once per day")
                tipRow(icon: "clock.arrow.circlepath", text: "Check your history to review past puzzles")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
            .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct InfoCard: View {
    let number: String
    let title: String
    let bodyText: String
    let icon: String
    let gradient: LinearGradient

    init(number: String, title: String, body: String, icon: String, gradient: LinearGradient) {
        self.number = number
        self.title = title
        self.bodyText = body
        self.icon = icon
        self.gradient = gradient
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(badgeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Step")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(number)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(badgeColor)
                    }
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }

            Text(bodyText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(badgeColor.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private var badgeColor: Color {
        switch number {
        case "1": return .blue
        case "2": return .purple
        case "3": return .orange
        default: return .gray
        }
    }
}
