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
        
        var request = URLRequest(url: oauthRequest.url)
        request.allHTTPHeaderFields = oauthRequest.header
        request.httpMethod = oauthRequest.httpMethod.rawValue
        
        
        if let body = oauthRequest.body, let bodyData = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]) {
            
          
            request.httpBody = bodyData
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
        }
        
        
        //self.semaphore.signal()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            completionHandler(data, response, error)
        }
        
        //self.semaphore.wait()
        
        task.resume()
    }
    
}
