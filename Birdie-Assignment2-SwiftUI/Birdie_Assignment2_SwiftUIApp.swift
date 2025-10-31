//
//  Birdie_Assignment2_SwiftUIApp.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 31/10/2025.
//

import SwiftUI

@main
struct Birdie_Assignment2_SwiftUIApp: App {
    // initialise database on app launch
    init() {
        // ensure database is initialized before app started
        _ = DatabaseManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            // add splash screen
            SplashScreenView()
        }
    }
}

struct SplashScreenView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Show splash screen for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
