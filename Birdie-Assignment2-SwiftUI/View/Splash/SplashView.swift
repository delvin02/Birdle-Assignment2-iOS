//
//  SplashView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 5/11/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.purple,
                    Color.blue.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon/Bird Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Image(systemName: "bird.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // app name 
                Text("Birdle")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .offset(y: isAnimating ? 0 : 20)
                
                // tagline
                Text("Daily bird guessing puzzle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(opacity)
                    .offset(y: isAnimating ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}

