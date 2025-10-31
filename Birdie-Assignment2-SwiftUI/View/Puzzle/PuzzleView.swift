//
//  PuzzleView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 1/11/2025.
//

import SwiftUI

struct PuzzleView: View {
    @State private var attempt: Int = 1
    @State private var guess: String = ""
    @State private var showSuccess: Bool = false
    @State private var showFailure: Bool = false
    @State private var isLoading: Bool = true
    @State private var loadingError: String?
    @State private var birdPuzzle: BirdPuzzleResponse?
    @State private var currentImage: UIImage?
    @State private var finalImage: UIImage?
    @State private var allBirdNames: [String] = []
    @State private var filteredSuggestions: [String] = []
    @State private var showSuggestions: Bool = false
    @State private var justSelectedSuggestion: Bool = false
    @State private var startTime: Date?
    @State private var timeElapsed: TimeInterval = 0
    @State private var showAlreadyCompleted: Bool = false
    @State private var todayCompletion: History?
    @Environment(\.dismiss) var dismiss
    
    private let dbController = DatabaseManager.shared
    private let easterBilbyService = EasterBilbyService.shared
    
    // normalise properties from api response
    private var correctBirdName: String {
        birdPuzzle?.name ?? ""
    }
    
    private var photographer: String {
        birdPuzzle?.photographer ?? ""
    }
    
    private var license: String {
        birdPuzzle?.license ?? ""
    }
    
    private var wikiLink: String {
        birdPuzzle?.bird_link ?? ""
    }
    
    // Calculate blur based on attempt (starts at 20, decreases by 3 each attempt)
    private var blurAmount: CGFloat {
        max(0, CGFloat(20 - attempt * 3))
    }
    
    // Image index for clues (0-4), final image is index 5
    private var currentImageIndex: Int {
        min(attempt - 1, 4)
    }
    
    private var isGuessValid: Bool {
        !guess.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
                
                // Loading State
                if isLoading {
                    loadingView(isLandscape: isLandscape)
                }
                
                // Error State
                if let error = loadingError {
                    errorView(error: error, isLandscape: isLandscape)
                }
                
                // Success Modal
                if showSuccess {
                    successModal(isLandscape: isLandscape)
                }
                
                // Failure Modal
                if showFailure {
                    failureModal(isLandscape: isLandscape)
                }
                // Already Completed Modal
                if showAlreadyCompleted {
                    alreadyCompletedModal(isLandscape: isLandscape)
                }
            }
            .onAppear {
                checkTodayCompletion()
            }
            .onChange(of: attempt) { _, newAttempt in
                loadClueImage(for: newAttempt)
            }
            .onChange(of: guess) { _, newValue in
                filterSuggestions(for: newValue)
            }
        }
    }
    
    // MARK: - Layout Views
    
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            // Header
            headerView(isLandscape: false)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Attempt Indicators
                    attemptIndicators(isLandscape: false)
                    
                    // Bird Image
                    birdImageSection(isLandscape: false)
                    
                    // Guess Input with Suggestions
                    VStack(alignment: .leading, spacing: 0) {
                        guessInputSection(isLandscape: false)
                        
                        // Suggestions List
                        if showSuggestions && !filteredSuggestions.isEmpty {
                            suggestionsList(isLandscape: false)
                        }
                    }
                    
                    // Submit Button
                    submitButton(isLandscape: false)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var landscapeLayout: some View {
        VStack(spacing: 0) {
            // Header
            headerView(isLandscape: true)
            
            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    // Left Column: Bird Image
                    VStack(spacing: 0) {
                        birdImageSection(isLandscape: true)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column: Hints and Input
                    VStack(spacing: 20) {
                        // Attempt Indicators (Hints)
                        attemptIndicators(isLandscape: true)
                        
                        Spacer()
                            .frame(height: 8)
                        
                            // Guess Input with Suggestions
                            VStack(alignment: .leading, spacing: 8) {
                                guessInputSection(isLandscape: true)
                                
                                // Suggestions List
                                if showSuggestions && !filteredSuggestions.isEmpty {
                                    suggestionsList(isLandscape: true)
                                        .zIndex(1)
                                }
                            }
                        
                        // Submit Button
                        submitButton(isLandscape: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Data Loading - for suggestions
    private func loadBirdList() {
        easterBilbyService.fetchBirdList { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let birds):
                    self.allBirdNames = birds
                case .failure(let error):
                    print("Failed to load bird list: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// filter on key stroke
    private func filterSuggestions(for input: String) {
        // dont filter if user just selected a suggestion
        guard !justSelectedSuggestion else {
            return
        }
        
        let trimmedInput = input.trimmingCharacters(in: .whitespaces).lowercased()
        
        if trimmedInput.isEmpty {
            filteredSuggestions = []
            showSuggestions = false
        } else {
            filteredSuggestions = allBirdNames.filter { birdName in
                birdName.lowercased().contains(trimmedInput)
            }
            showSuggestions = !filteredSuggestions.isEmpty
        }
    }
    
    /// check if today is completed
    private func checkTodayCompletion() {
        DispatchQueue.global(qos: .userInitiated).async {
            let completedToday = self.dbController.hasCompletedToday()
            let todayCompletion = self.dbController.getTodayCompletion()
            
            DispatchQueue.main.async {
                if completedToday {
                    self.todayCompletion = todayCompletion
                    self.showAlreadyCompleted = true
                    self.isLoading = false
                } else {
                    // Start puzzle if not completed today
                    self.startTime = Date()
                    self.loadPuzzle()
                    self.loadBirdList()
                }
            }
        }
    }
    
    private func loadPuzzle() {
        isLoading = true
        loadingError = nil
        
        easterBilbyService.fetchCurrentBirdPuzzle { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let puzzle):
                    self.birdPuzzle = puzzle
                    // Load first clue image - for the first time
                    self.loadClueImage(for: 1)
                case .failure(let error):
                    self.loadingError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// load clue image, attempts param to determine the index
    private func loadClueImage(for attempt: Int) {
        guard let imageCode = birdPuzzle?.image else { return }
        
        let imageIndex = min(attempt - 1, 4)
        
        easterBilbyService.downloadBirdImage(imageCode: imageCode, index: imageIndex) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.currentImage = image
                    self.isLoading = false
                case .failure(let error):
                    // If we fail to load clue, keep showing previous image
                    print("Failed to load clue image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadFinalImage() {
        guard let imageCode = birdPuzzle?.image else { return }
        
        easterBilbyService.downloadFinalImage(imageCode: imageCode) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.finalImage = image
                case .failure(let error):
                    print("Failed to load final image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func loadingView(isLandscape: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading puzzle...")
                    .font(.system(size: isLandscape ? 14 : 16))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
    
    @ViewBuilder
    private func errorView(error: String, isLandscape: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Failed to Load Puzzle")
                    .font(.system(size: isLandscape ? 18 : 20, weight: .semibold))
                
                Text(error)
                    .font(.system(size: isLandscape ? 13 : 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    loadPuzzle()
                }) {
                    Text("Retry")
                        .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        HeaderView(title: "Today's Puzzle", isLandscape: isLandscape)
    }
    
    @ViewBuilder
    private func attemptIndicators(isLandscape: Bool) -> some View {
        HStack(spacing: 8) {
            ForEach(1...6, id: \.self) { num in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        num < attempt ? Color.red :
                            num == attempt ? Color.blue :
                            Color(.systemGray4)
                    )
                    .frame(width: isLandscape ? 28 : 32, height: 8)
                    .animation(.easeInOut, value: attempt)
            }
        }
        .padding(.vertical, isLandscape ? 8 : 12)
    }
    
    @ViewBuilder
    private func birdImageSection(isLandscape: Bool) -> some View {
        ZStack {
            //  gradient
            RoundedRectangle(cornerRadius: isLandscape ? 20 : 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cyan.opacity(0.3), Color.green.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Bird image with blur
            ZStack {
                if let image = currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Placeholder while loading
                    RoundedRectangle(cornerRadius: isLandscape ? 20 : 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.brown.opacity(0.6), Color.orange.opacity(0.4)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "bird.fill")
                                .font(.system(size: isLandscape ? 100 : 120))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .blur(radius: blurAmount)
            .clipped()
            
            // Attempt badge
            VStack {
                HStack {
                    Spacer()
                    Text("Attempt \(attempt)/6")
                        .font(.system(size: isLandscape ? 12 : 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, isLandscape ? 10 : 12)
                        .padding(.vertical, isLandscape ? 6 : 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .fill(Color.black.opacity(0.3))
                                )
                        )
                        .padding(.top, isLandscape ? 12 : 16)
                        .padding(.trailing, isLandscape ? 12 : 16)
                }
                Spacer()
            }
        }
        .aspectRatio(contentMode: .fit)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func guessInputSection(isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What bird is this?")
                .font(.system(size: isLandscape ? 13 : 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Enter bird name...", text: $guess)
                .font(.system(size: isLandscape ? 15 : 16))
                .padding(.horizontal, 16)
                .padding(.vertical, isLandscape ? 12 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isGuessValid ? Color.blue.opacity(0.3) : Color(.separator),
                            lineWidth: isGuessValid ? 2 : 0.5
                        )
                )
                .autocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    if isGuessValid {
                        submitGuess()
                    }
                }
                .onTapGesture {
                    showSuggestions = !guess.isEmpty
                }
        }
    }
    
    @ViewBuilder
    private func suggestionsList(isLandscape: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(filteredSuggestions.prefix(5), id: \.self) { suggestion in
                    Button(action: {
                        // Set the guess and close suggestions immediately
                        justSelectedSuggestion = true
                        showSuggestions = false
                        guess = suggestion
                        
                        // Reset the flag after a short delay to allow normal filtering again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            justSelectedSuggestion = false
                        }
                    }) {
                        HStack {
                            Text(suggestion)
                                .font(.system(size: isLandscape ? 14 : 15))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: isLandscape ? 12 : 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(Color(.secondarySystemBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if suggestion != filteredSuggestions.prefix(5).last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private func submitButton(isLandscape: Bool) -> some View {
        Button(action: {
            submitGuess()
        }) {
            Text("Submit Guess")
                .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isLandscape ? 12 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isGuessValid ? Color.blue : Color.gray)
                )
        }
        .disabled(!isGuessValid)
        .opacity(isGuessValid ? 1.0 : 0.5)
    }
    
    @ViewBuilder
    private func successModal(isLandscape: Bool) -> some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showSuccess = false
                }
            
            // Modal Content
            VStack(spacing: isLandscape ? 16 : 20) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: isLandscape ? 56 : 64, height: isLandscape ? 56 : 64)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: isLandscape ? 28 : 32, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                // Title
                Text("Correct!")
                    .font(.system(size: isLandscape ? 24 : 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Attempt count and time
                VStack(spacing: 4) {
                    Text("You guessed it in \(attempt) tries")
                        .font(.system(size: isLandscape ? 14 : 16))
                        .foregroundColor(.secondary)
                    
                    if timeElapsed > 0 {
                        Text("Time: \(formattedTimeElapsed())")
                            .font(.system(size: isLandscape ? 13 : 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Final Bird Image (if loaded)
                if let finalImage = finalImage {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: isLandscape ? 150 : 200)
                        .cornerRadius(12)
                }
                
                // Bird Info Card
                VStack(alignment: .leading, spacing: 8) {
                    Text(correctBirdName)
                        .font(.system(size: isLandscape ? 16 : 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Photo by \(photographer) (\(license))")
                        .font(.system(size: isLandscape ? 12 : 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(isLandscape ? 14 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Learn More Link
                if !wikiLink.isEmpty, let url = URL(string: wikiLink) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Learn more about this bird")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // Copy/Share Buttons
                HStack(spacing: 12) {
                    // Copy Button
                    Button(action: {
                        let text = generateResultsText()
                        UIPasteboard.general.string = text
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Copy")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    // Share Button
                    ShareLink(item: generateResultsText()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Share")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // Back Button
                Button(action: {
                    showSuccess = false
                    // Navigate back to home after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    Text("Back to Home")
                        .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 12 : 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(isLandscape ? 20 : 24)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 24 : 28)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSuccess)
    }
    
    @ViewBuilder
    private func failureModal(isLandscape: Bool) -> some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showFailure = false
                }
            
            // modal content
            VStack(spacing: isLandscape ? 16 : 20) {
                // Failure Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: isLandscape ? 56 : 64, height: isLandscape ? 56 : 64)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: isLandscape ? 28 : 32, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                // Title
                Text("Out of Attempts")
                    .font(.system(size: isLandscape ? 24 : 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Message and time
                VStack(spacing: 4) {
                    Text("You've used all 6 attempts. The bird was:")
                        .font(.system(size: isLandscape ? 14 : 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if timeElapsed > 0 {
                        Text("Time: \(formattedTimeElapsed())")
                            .font(.system(size: isLandscape ? 13 : 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Final Bird Image (if loaded)
                if let finalImage = finalImage {
                    Image(uiImage: finalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: isLandscape ? 150 : 200)
                        .cornerRadius(12)
                }
                
                // Bird Info Card
                VStack(alignment: .leading, spacing: 8) {
                    Text(correctBirdName)
                        .font(.system(size: isLandscape ? 16 : 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Photo by \(photographer) (\(license))")
                        .font(.system(size: isLandscape ? 12 : 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(isLandscape ? 14 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Learn More Link
                if !wikiLink.isEmpty, let url = URL(string: wikiLink) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Learn more about this bird")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // Copy/Share buttons
                HStack(spacing: 12) {
                    // Copy Button
                    Button(action: {
                        let text = generateResultsText()
                        UIPasteboard.general.string = text
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Copy")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    // share button
                    ShareLink(item: generateResultsText()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: isLandscape ? 13 : 14))
                            Text("Share")
                                .font(.system(size: isLandscape ? 14 : 15, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 10 : 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // back button
                Button(action: {
                    showFailure = false
                    // navigate back to home after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    Text("Back to Home")
                        .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 12 : 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(isLandscape ? 20 : 24)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 24 : 28)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showFailure)
    }
    
    private func submitGuess() {
        let trimmedGuess = guess.trimmingCharacters(in: .whitespaces)
        
        guard !correctBirdName.isEmpty else { return }
        
        // Hide suggestions when submitting
        showSuggestions = false
        
        // Calculate time elapsed
        if let start = startTime {
            timeElapsed = Date().timeIntervalSince(start)
        }
        
        // Check if guess is correct (case-insensitive comparison)
        if trimmedGuess.lowercased() == correctBirdName.lowercased() {
            // Correct guess - load final image, save history and show success modal
            loadFinalImage()
            saveHistory(success: true)
            showSuccess = true
        } else {
            // Wrong guess - move to next attempt
            if attempt < 6 {
                attempt += 1
                guess = ""
            } else {
                // Max attempts reached - load final image, save history and show failure modal
                loadFinalImage()
                saveHistory(success: false)
                showFailure = true
                guess = ""
            }
        }
    }
    
    private func saveHistory(success: Bool) {
        let history = History(
            birdName: correctBirdName,
            attempts: success ? attempt : 6,
            success: success
        )
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.dbController.createHistory(history)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formattedTimeElapsed() -> String {
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%d seconds", seconds)
        }
    }
    
    private func generateResultsText() -> String {
        var text = "Birdle Puzzle Results\n\n"
        
        if showSuccess {
            text += "✅ Success!\n"
            text += "Bird: \(correctBirdName)\n"
            text += "Attempts: \(attempt)/6\n"
        } else {
            text += "❌ Out of Attempts\n"
            text += "Bird: \(correctBirdName)\n"
            text += "Attempts: 6/6\n"
        }
        
        if timeElapsed > 0 {
            text += "Time: \(formattedTimeElapsed())\n"
        }
        
        text += "\nPhoto by \(photographer) (\(license))"
        
        if !wikiLink.isEmpty {
            text += "\nLearn more: \(wikiLink)"
        }
        
        return text
    }
    
    // MARK: - Already Completed Modal
    
    @ViewBuilder
    private func alreadyCompletedModal(isLandscape: Bool) -> some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showAlreadyCompleted = false
                    dismiss()
                }
            
            // modal content
            VStack(spacing: isLandscape ? 16 : 20) {
                // info icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: isLandscape ? 56 : 64, height: isLandscape ? 56 : 64)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: isLandscape ? 28 : 32, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                // title
                Text("Already Completed")
                    .font(.system(size: isLandscape ? 24 : 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // message
                if let completion = todayCompletion {
                    VStack(spacing: 12) {
                        Text("You've already completed today's puzzle!")
                            .font(.system(size: isLandscape ? 14 : 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Result:")
                                .font(.system(size: isLandscape ? 13 : 14, weight: .semibold))
                            
                            Text("Bird: \(completion.birdName)")
                                .font(.system(size: isLandscape ? 13 : 14))
                                .foregroundColor(.secondary)
                            
                            Text("Attempts: \(completion.attempts)/6")
                                .font(.system(size: isLandscape ? 13 : 14))
                                .foregroundColor(.secondary)
                            
                            Text("Result: \(completion.success ? "✅ Success" : "❌ Out of Attempts")")
                                .font(.system(size: isLandscape ? 13 : 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(isLandscape ? 14 : 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                } else {
                    Text("You've already completed today's puzzle!")
                        .font(.system(size: isLandscape ? 14 : 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Back Button
                Button(action: {
                    showAlreadyCompleted = false
                    dismiss()
                }) {
                    Text("Back to Home")
                        .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLandscape ? 12 : 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue)
                        )
                }
            }
            .padding(isLandscape ? 20 : 24)
            .background(
                RoundedRectangle(cornerRadius: isLandscape ? 24 : 28)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAlreadyCompleted)
    }
}


#Preview {
    NavigationStack {
        PuzzleView()
    }
}

