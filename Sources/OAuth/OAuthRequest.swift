//
//  OAuthRequest.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public struct OAuthRequest {
    public typealias Header = [String: String]
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    var url: URL
    var header: Header
    var httpMethod: HTTPMethod
    
    init(method: HTTPMethod, url: URL, header: Header) {
        self.url = url
        self.header = header
        self.httpMethod = method
    }
}
