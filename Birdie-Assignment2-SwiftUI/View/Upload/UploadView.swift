//
//  UploadView.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 1/11/2025.
//

import SwiftUI
import PhotosUI

struct UploadView: View {
    @State private var birdName: String = ""
    @State private var photographerName: String = ""
    @State private var photographerLink: String = ""
    @State private var license: String = "CC BY 2.0"
    @State private var birdleLink: String = ""
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSubmitting: Bool = false
    
    private let licenses = ["CC BY 2.0", "CC BY-SA 2.0", "CC BY-NC 2.0", "CC0 1.0 (Public Domain)"]
    private let easterBilbyService = EasterBilbyService.shared
    
    private var isFormValid: Bool {
        !birdName.isEmpty && !photographerName.isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    headerView(isLandscape: isLandscape)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: isLandscape ? 16 : 20) {
                        // Description
                        descriptionText(isLandscape: isLandscape)
                        
                        // Image Upload
                        imageUploadSection(isLandscape: isLandscape)
                        
                        // Form Fields
                        VStack(spacing: isLandscape ? 14 : 18) {
                            // Bird Name
                            formField(
                                label: "Bird Name",
                                placeholder: "e.g., American Robin",
                                text: $birdName,
                                isLandscape: isLandscape
                            )
                            
                            // Photographer Name
                            formField(
                                label: "Photographer Name",
                                placeholder: "Your name or photographer's name",
                                text: $photographerName,
                                isLandscape: isLandscape
                            )
                            
                            // Photographer Link
                            formField(
                                label: "Photographer Link",
                                placeholder: "https://en.wikipedia.org/wiki/User:...",
                                text: $photographerLink,
                                isLandscape: isLandscape,
                                keyboardType: .URL
                            )
                            
                            // License
                            licensePicker(isLandscape: isLandscape)
                            
                            // Bird Link
                            formField(
                                label: "Bird Link",
                                placeholder: "https://en.wikipedia.org/wiki/...",
                                text: $birdleLink,
                                isLandscape: isLandscape,
                                keyboardType: .URL
                            )
                        }
                        
                        // Submit Button
                        submitButton(isLandscape: isLandscape)
                        
                        // Disclaimer
                        disclaimerText(isLandscape: isLandscape)
                    }
                        .padding(.horizontal, 20)
                        .padding(.vertical, isLandscape ? 16 : 24)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    resetForm()
                }
            } message: {
                Text("Bird uploaded successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func headerView(isLandscape: Bool) -> some View {
        HeaderView(title: "Upload Bird", isLandscape: isLandscape)
    }
    
    @ViewBuilder
    private func descriptionText(isLandscape: Bool) -> some View {
        Text("Contribute to Birdle by uploading bird images. Your submissions help create new daily puzzles!")
            .font(.system(size: isLandscape ? 13 : 14))
            .foregroundColor(.secondary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func imageUploadSection(isLandscape: Bool) -> some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            VStack(spacing: 12) {
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: isLandscape ? 100 : 120, height: isLandscape ? 100 : 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: isLandscape ? 48 : 64, height: isLandscape ? 48 : 64)
                        
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: isLandscape ? 28 : 32))
                            .foregroundColor(.blue)
                    }
                }
                
                if selectedImage == nil {
                    VStack(spacing: 4) {
                        Text("Tap to upload image")
                            .font(.system(size: isLandscape ? 13 : 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("PNG, JPG up to 10MB")
                            .font(.system(size: isLandscape ? 11 : 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Tap to change image")
                        .font(.system(size: isLandscape ? 12 : 13))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLandscape ? 24 : 32)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        selectedImage != nil ? Color.blue.opacity(0.3) : Color(.separator),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedImage != nil ? Color.blue.opacity(0.05) : Color(.secondarySystemBackground))
                    )
            )
        }
    }
    
    @ViewBuilder
    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isLandscape: Bool,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: isLandscape ? 13 : 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                .font(.system(size: isLandscape ? 15 : 16))
                .padding(.horizontal, 16)
                .padding(.vertical, isLandscape ? 10 : 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
    
    @ViewBuilder
    private func licensePicker(isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("License")
                .font(.system(size: isLandscape ? 13 : 14, weight: .medium))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(licenses, id: \.self) { licenseOption in
                    Button(action: {
                        license = licenseOption
                    }) {
                        HStack {
                            Text(licenseOption)
                            if license == licenseOption {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(license)
                        .font(.system(size: isLandscape ? 15 : 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isLandscape ? 10 : 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            }
        }
    }
    
    @ViewBuilder
    private func submitButton(isLandscape: Bool) -> some View {
        Button(action: {
            submitBird()
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isSubmitting ? "Submitting..." : "Submit Bird")
                    .font(.system(size: isLandscape ? 15 : 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLandscape ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFormValid && !isSubmitting ? Color.blue : Color.gray)
            )
        }
        .disabled(!isFormValid || isSubmitting)
        .opacity(isFormValid && !isSubmitting ? 1.0 : 0.5)
    }
    
    @ViewBuilder
    private func disclaimerText(isLandscape: Bool) -> some View {
        Text("By submitting, you confirm you have the right to share this image and agree to our terms of use.")
            .font(.system(size: isLandscape ? 10 : 12))
            .foregroundColor(.secondary)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
    
    private func submitBird() {
        guard isFormValid else { return }
        
        guard let image = selectedImage else {
            errorMessage = "Please select an image to upload."
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        
        let trimmedName = birdName.trimmingCharacters(in: .whitespaces)
        let trimmedPhotographerName = photographerName.trimmingCharacters(in: .whitespaces)
        let trimmedPhotographerLink = photographerLink.trimmingCharacters(in: .whitespaces)
        let trimmedBirdleLink = birdleLink.trimmingCharacters(in: .whitespaces)
        
        // Upload to server
        easterBilbyService.uploadBird(
            name: trimmedName,
            photographerName: trimmedPhotographerName,
            photographerLink: trimmedPhotographerLink,
            license: license,
            birdleLink: trimmedBirdleLink,
            image: image
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Upload succeeded for bird: \(trimmedName)")
                    self.isSubmitting = false
                    self.showSuccessAlert = true
                case .failure(let error):
                    print("❌ Upload failed for bird: \(trimmedName)")
                    print("🪶 Error: \(error.localizedDescription)")
                    self.isSubmitting = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func resetForm() {
        birdName = ""
        photographerName = ""
        photographerLink = ""
        license = "CC BY 2.0"
        birdleLink = ""
        selectedImage = nil
        photosPickerItem = nil
    }
}

#Preview {
    NavigationStack {
        UploadView()
    }
}

