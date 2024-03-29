//
//  OAuthRequest.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public struct OAuthRequest {
    public typealias Header = [String: String]
    public typealias Body = [String: Any]
    
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    public var url: URL
    public var header: Header
    public var httpMethod: HTTPMethod
    
    public var body: Body?
    
    public init(method: HTTPMethod, url: URL, header: Header, body: Body?) {
        self.url = url
        self.header = header
        self.httpMethod = method
        
        self.body = body
    }
}
