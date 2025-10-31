//
//  ContentView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 31/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: String.self) { route in
                    switch route {
                    case "puzzle":
                        PuzzleView()
                    case "help":
                        HelpView()
                    case "history":
                        HistoryView()
                    case "about":
                        AboutView()
                    case "upload":
                        UploadView()
                    default:
                        EmptyView()
                    }
                }
        }
    }
}




#Preview {
    ContentView()
}
