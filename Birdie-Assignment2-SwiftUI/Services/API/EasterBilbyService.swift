//
//  EasterBilbyService.swift
//  Birdie-Assignment2-SwiftUI
//
//  Created by Delvin on 4/11/2025.
//

import Foundation
import UIKit

// MARK: - API Models
struct BirdPuzzleResponse: Codable {
    let name: String
    let image: String
    let photographer: String
    let license: String
    let photographer_link: String
    let bird_link: String
}

struct UploadResponse: Codable {
    let result: String
}

struct BirdListResponse: Codable {
    let date: String
    let birds: [String]
}

// MARK: - Easter Bilby Service
class EasterBilbyService {
    static let shared = EasterBilbyService()
    
    private let baseURL = "https://easterbilby.net/birdle"
    private let apiURL = "https://easterbilby.net/birdle/api.php"
    
    private init() {}
    
    // MARK: - Upload Bird
    /// Uploads a bird to the server
    func uploadBird(
        name: String,
        photographerName: String,
        photographerLink: String,
        license: String,
        birdleLink: String,
        image: UIImage,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let url = URL(string: "\(apiURL)?action=upload") else {
            completion(.failure(EasterBilbyError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart/form-data body
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields as per API specification
        let formFields: [(String, String)] = [
            ("name", name),
            ("photographer_name", photographerName),
            ("photographer_link", photographerLink),
            ("license", license),
            ("birdle_link", birdleLink)
        ]
        
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add image file
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"bird.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Perform request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EasterBilbyError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(EasterBilbyError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(EasterBilbyError.noData))
                return
            }
            
            do {
                let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                // based on API Specification in learnonline
                // it will return result as message
                if uploadResponse.result == "success" {
                    completion(.success(true))
                } else {
                    completion(.failure(EasterBilbyError.uploadFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Fetch Bird Puzzle
    /// Fetches the current bird puzzle
    func fetchCurrentBirdPuzzle(completion: @escaping (Result<BirdPuzzleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiURL)?") else {
            completion(.failure(EasterBilbyError.invalidURL))
            return
        }
        
        fetchBirdPuzzle(from: url, completion: completion)
    }
    
    /// Fetches a specific bird puzzle by ID
    func fetchBirdPuzzle(byId id: Int, completion: @escaping (Result<BirdPuzzleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiURL)?action=download&id=\(id)") else {
            completion(.failure(EasterBilbyError.invalidURL))
            return
        }
        
        // call the API
        fetchBirdPuzzle(from: url, completion: completion)
    }
    
    private func fetchBirdPuzzle(from url: URL, completion: @escaping (Result<BirdPuzzleResponse, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // guard errors
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EasterBilbyError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(EasterBilbyError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(EasterBilbyError.noData))
                return
            }
            
            do {
                // if success, decode the response data to response type
                let birdPuzzle = try JSONDecoder().decode(BirdPuzzleResponse.self, from: data)
                
                // return
                completion(.success(birdPuzzle))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Download Images
    
    /// Downloads a bird image by image code and index (0-5)
    /// - Parameters:
    ///   - imageCode: 4-digit image code from puzzle response
    ///   - index: Image index (0-4 for clues, 5 for final/revealed image)
    ///   - completion: Completion handler with UIImage or Error
    func downloadBirdImage(
        imageCode: String,
        index: Int,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // slowly reveal using index
        guard index >= 0 && index <= 5 else {
            completion(.failure(EasterBilbyError.invalidImageIndex))
            return
        }
        
        let imageURL = "\(baseURL)/\(imageCode)\(index).jpg"
        print("Downloading image \(imageURL)")
        guard let url = URL(string: imageURL) else {
            completion(.failure(EasterBilbyError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EasterBilbyError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(EasterBilbyError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                completion(.failure(EasterBilbyError.invalidImageData))
                return
            }
            
            completion(.success(image))
        }.resume()
    }
    
    /// Downloads all clue images (0-4) for a bird puzzle
    func downloadClueImages(
        imageCode: String,
        completion: @escaping (Result<[UIImage], Error>) -> Void
    ) {
        var images: [UIImage] = []
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for index in 0...4 {
            group.enter()
            downloadBirdImage(imageCode: imageCode, index: index) { result in
                switch result {
                case .success(let image):
                    images.append(image)
                case .failure(let error):
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if images.count == 5 {
                // Sort by index (already in order, but ensure correctness)
                completion(.success(images))
            } else if let firstError = errors.first {
                completion(.failure(firstError))
            } else {
                completion(.failure(EasterBilbyError.incompleteImageDownload))
            }
        }
    }
    
    /// Downloads the final/revealed image (index 5)
    func downloadFinalImage(
        imageCode: String,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        downloadBirdImage(imageCode: imageCode, index: 5, completion: completion)
    }
    
    // MARK: - Fetch Bird List
    
    /// Fetches the list of all bird names
    func fetchBirdList(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(apiURL)?action=list") else {
            completion(.failure(EasterBilbyError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(EasterBilbyError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(EasterBilbyError.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(EasterBilbyError.noData))
                return
            }
            
            do {
                let birdListResponse = try JSONDecoder().decode(BirdListResponse.self, from: data)
                completion(.success(birdListResponse.birds))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Errors helper
enum EasterBilbyError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case uploadFailed
    case invalidImageIndex
    case invalidImageData
    case incompleteImageDownload
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .noData:
            return "No data received from server"
        case .uploadFailed:
            return "Upload failed"
        case .invalidImageIndex:
            return "Image index must be between 0 and 5"
        case .invalidImageData:
            return "Invalid image data"
        case .incompleteImageDownload:
            return "Failed to download all images"
        }
    }
}

