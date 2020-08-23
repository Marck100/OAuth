//
//  OAuth.swift
//
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public class OAuth {
    public typealias AuthorizationHeader = (key: String, value: String)
    public typealias Parameters = [String: String]
    
    public static let shared = OAuth()
    
    static private var consumerKey: String = "xxx"
    static private var consumerSecret: String = "xxx"
    
    ///Oauth token
    public private(set) var token: String?
    public private(set) var tokenSecret: String?
    ///User identifier
    public private(set) var userIdentifier: String?
    ///Oauth verifier
    private var verifier: String?
    
    private var signingKey: String {
        let consumer = OAuth.consumerSecret
        let token = tokenSecret ?? ""
        return "\(consumer)&\(token)"
    }
    
    public var defaultParameters: Parameters {
        var dict = [
            OAuthParameter.consumerKey.rawValue : OAuth.consumerKey,
            OAuthParameter.signatureMethod.rawValue : "HMAC-SHA1",
            OAuthParameter.timestamp.rawValue : String(Int(Date().timeIntervalSince1970)),
            OAuthParameter.nonce.rawValue : String.randomString(length: 42),
            OAuthParameter.version.rawValue : "1.0"
        ]
    
        if let token = token {
            dict[OAuthParameter.token.rawValue] = token
        }
        if let tokenSecret = tokenSecret {
            dict[OAuthParameter.tokenSecret.rawValue] = tokenSecret
        }
        if let verifier = verifier {
            dict[OAuthParameter.verifier.rawValue] = verifier
        }
        
        return dict
    }
    
    public static func setConsumer(consumerKey: String, consumerSecret: String) {
        OAuth.consumerKey = consumerKey
        OAuth.consumerSecret = consumerSecret
    }
    
    public func setToken(token: String, tokenSecret: String) {
        self.token = token
        self.tokenSecret = tokenSecret
    }
    
    public func setVerifier(verifier: String) {
        self.verifier = verifier
    }
    
    public func setUserIdentifier(identifier: String) {
        self.userIdentifier = identifier
    }
    
    public func request(url: URL, method: OAuthRequest.HTTPMethod, oauthParameters: Parameters?, parameters: Parameters?) -> OAuthRequest {
        let authorizationHeader = self.authorizationHeader(urlPath: url.absoluteString, requestMethod: method, oauthParameters: oauthParameters)
        var header: [String: String] = [authorizationHeader.key: authorizationHeader.value]
        parameters?.forEach { header[$0.key] = $0.value }
        let request = OAuthRequest(method: method, url: url, header: header)
        
        return request
    }
    
    private func authorizationHeader(urlPath: String, requestMethod: OAuthRequest.HTTPMethod, generateDefaultParameters: Bool = true, oauthParameters: Parameters?) -> AuthorizationHeader {
        //Generate parameters
        var parameters: [String: String] = {
            var parameters = generateDefaultParameters ? defaultParameters : [:]
            oauthParameters?.keys.forEach { parameters[$0] = oauthParameters?[$0] }
            return parameters
        }()
        //Generate signature
        let signature = generateSignature(urlPath: urlPath, oauthParameters: &parameters, requestMethod: requestMethod)
        let authParameters = parameters
        //Create header
        let map = authParameters.map { $0.key + "=\"" + $0.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "\"" }
        let authValue = "OAuth \(map.joined(separator: ",")), \(OAuthParameter.signature.rawValue)=\"\(signature)\""
        return ("Authorization", authValue)
    }
    
    private func generateSignature(urlPath: String, oauthParameters: inout Parameters, requestMethod: OAuthRequest.HTTPMethod) -> String {
        var components = URLComponents(string: urlPath)!
        components.queryItems?.forEach { oauthParameters[$0.name] = $0.value }
        components.query = nil
        let path = components.url!.absoluteString
        
        let literal = oauthParameters.sorted(by: { $0.key < $1.key }).map { $0.key.urlEncoded() + "=" + $0.value.urlEncoded() }
            .joined(separator: "&").urlEncoded()
        let baseString = requestMethod.rawValue + "&" + path.urlEncoded() + "&" + literal
        
        let signature = baseString.hmac(key: signingKey)
        return signature
    }
    
}

extension String {
    func urlEncoded() -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = self.addingPercentEncoding(withAllowedCharacters: allowed)!
        return encoded
    }
}
