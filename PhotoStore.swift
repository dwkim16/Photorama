//
//  PhotoStore.swift
//  Photorama
//
//  Created by Dowon Kim on 8/16/18.
//  Copyright © 2018 Do Won Kim. All rights reserved.
//

import UIKit

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}

enum PhotoError: Error {
    case imageCreationError
}

enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

class PhotoStore {
    
    let imageStore = ImageStore()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return FlickrAPI.photos(fromJSON: jsonData)
    }
    
    func fetchPhotos(for method: Method, completion: @escaping (PhotosResult) -> Void) {
        //    let url = FlickrAPI.interestingPhotosURL
        let url = FlickrAPI.photosURL(for: method)
        
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            // Bronze Challenge
            self.printHTTPHeader(for: response)
            
            let result = self.processPhotosRequest(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    
    // MARK: - Bronze Challenge: Printing the Response Information
    func printHTTPHeader(for response: URLResponse?) {
        guard let aHTTPURLResponse = response as? HTTPURLResponse  else {
            return
        }
        
        let statusCode = aHTTPURLResponse.statusCode
        print("HTTP Status Code: \(statusCode)")
        print("Message: \(HTTPURLResponse.localizedString(forStatusCode: statusCode))")
        print("All HTTP Header Fields:")
        for (key, value) in aHTTPURLResponse.allHeaderFields {
            print("\(key) : \(value)")
        }
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        
        let photoKey = photo.photoID
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        let photoURL = photo.remoteURL
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error)
            
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                
                // Couldn't create an image
                if data == nil {
                    return .failure(error!)
                } else {
                    return .failure(PhotoError.imageCreationError)
                }
        }
        
        return .success(image)
    }
}
