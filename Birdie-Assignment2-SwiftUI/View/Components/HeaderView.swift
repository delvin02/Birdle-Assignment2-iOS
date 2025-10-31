//
//  HeaderView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 4/11/2025.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let isLandscape: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isLandscape ? 18 : 20, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isLandscape ? 10 : 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        HeaderView(title: "Today's Puzzle", isLandscape: false)
        Spacer()
    }
}

