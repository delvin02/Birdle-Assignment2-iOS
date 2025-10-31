//
//  AboutView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 1/11/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            VStack(spacing: 0) {
                // header
                headerView(isLandscape: isLandscape)
                
                // content
                ScrollView {
                    VStack(spacing: isLandscape ? 20 : 24) {
                        // app icon
                        appIconSection(isLandscape: isLandscape)
                        
                        // app info
                        appInfoSection(isLandscape: isLandscape)
                        
                        // developer card
                        infoCard(
                            title: "Developer",
                            content: VStack(alignment: .leading, spacing: 8) {
                                Text("WEEI WAAI KHOR")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                Text("Student ID: 110453086")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                Text("Email: khowy006@mymail.unisa.edu.au")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            },
                            isLandscape: isLandscape
                        )
                        
                        // disclaimer card
                        infoCard(
                            title: "Disclaimer",
                            content: Text("All images and content used in this application are for educational purposes only. Bird photographs are used under Creative Commons licenses and are credited to their respective photographers.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4),
                            isLandscape: isLandscape
                        )
                        
                        // Acknowledgments Card
                        infoCard(
                            title: "Acknowledgments",
                            content: VStack(alignment: .leading, spacing: 12) {
                                Text("Special thanks to all the photographers who contributed bird images under Creative Commons licenses.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                
                                Text("Inspired by Wordle and other daily puzzle games.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            },
                            isLandscape: isLandscape
                        )
                        
                        // Footer
                        footerSection(isLandscape: isLandscape)
                    }
                    .padding(.top, isLandscape ? 16 : 24)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        HeaderView(title: "About", isLandscape: isLandscape)
    }
    
    @ViewBuilder
    private func appIconSection(isLandscape: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: isLandscape ? 20 : 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isLandscape ? 80 : 96, height: isLandscape ? 80 : 96)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: "bird.fill")
                    .font(.system(size: isLandscape ? 44 : 56))
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, isLandscape ? 12 : 16)
    }
    
    @ViewBuilder
    private func appInfoSection(isLandscape: Bool) -> some View {
        VStack(spacing: 8) {
            Text("Birdle")
                .font(.system(size: isLandscape ? 24 : 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Version 1.0.0")
                .font(.system(size: isLandscape ? 14 : 16))
                .foregroundColor(.secondary)
            
            Text("Daily Bird Guessing Puzzle")
                .font(.system(size: isLandscape ? 13 : 14))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, isLandscape ? 8 : 12)
    }
    
    // reusable info card
    @ViewBuilder
    private func infoCard<Content: View>(
        title: String,
        content: Content,
        isLandscape: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: isLandscape ? 16 : 17, weight: .semibold))
                .foregroundColor(.primary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isLandscape ? 16 : 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func footerSection(isLandscape: Bool) -> some View {
        VStack(spacing: 8) {
            Text("© 2025 Birdle. All rights reserved.")
                .font(.system(size: isLandscape ? 11 : 12))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text("Made with")
                    .font(.system(size: isLandscape ? 11 : 12))
                    .foregroundColor(.secondary)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: isLandscape ? 10 : 11))
                    .foregroundColor(.red)
                
                Text("for bird enthusiasts")
                    .font(.system(size: isLandscape ? 11 : 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, isLandscape ? 12 : 16)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

