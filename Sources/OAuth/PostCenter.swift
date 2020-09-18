//
//  PostCenter.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public final class PostCenter {
    public static let shared = PostCenter()
    
    private let semaphore: DispatchSemaphore
    
    init() {
        semaphore = DispatchSemaphore(value: 0)
    }
    
    public typealias RequestHandler = (Data?, URLResponse?, Error?) -> Void
    public func post(_ oauthRequest: OAuthRequest, completionHandler: @escaping(RequestHandler)) {
        
        var request = URLRequest(url: oauthRequest.url, timeoutInterval: .infinity)
        request.allHTTPHeaderFields = oauthRequest.header
        request.httpMethod = oauthRequest.httpMethod.rawValue
      
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "unavailable")
            }
            
            if let error = error {
                print("error:", error)
            }
            
            //self.semaphore.signal()
            completionHandler(data, response, error)
        }
        task.resume()
        
        //semaphore.wait()
    }
    
}
