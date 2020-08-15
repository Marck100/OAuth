//
//  PostCenter.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public final class PostCenter {
    static let shared = PostCenter()
    
    private let semaphore: DispatchSemaphore
    
    init() {
        semaphore = DispatchSemaphore(value: 0)
    }
    
    typealias RequestHandler = (Data?, URLResponse?, Error?) -> Void
    func post(_ oauthRequest: OAuthRequest, completionHandler: @escaping(RequestHandler)) {
        var request = URLRequest(url: oauthRequest.url, timeoutInterval: .infinity)
        request.allHTTPHeaderFields = oauthRequest.header
        request.httpMethod = oauthRequest.httpMethod.rawValue
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            self.semaphore.signal()
            completionHandler(data, response, error)
        }
        task.resume()
        semaphore.wait()
    }
    
}