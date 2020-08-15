//
//  OAuth.swift
//
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

public final class OAuth {
    public typealias AuthorizationHeader = (key: String, value: String)
    public typealias Parameters = [String: String]
    
    public static let shared = OAuth()
    
    static private var consumerKey: String = "xxx"
    static private var consumerSecret: String = "xxx"
    
    ///Oauth token
    private var token: String?
    private var tokenSecret: String?
    ///Oauth verifier
    private var verifier: String?
    
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
    
    public func request(url: URL, method: OAuthRequest.HTTPMethod, oauthParameters: Parameters?, parameters: Parameters?) -> OAuthRequest {
        let authorizationHeader = self.authorizationHeader(urlPath: url.absoluteString, requestMethod: method, oauthParameters: oauthParameters)
        var header: [String: String] = [authorizationHeader.key: authorizationHeader.value]
        parameters?.forEach { header[$0.key] = $0.value }
        let request = OAuthRequest(method: method, url: url, header: header)
        
        return request
    }
    
    private func authorizationHeader(urlPath: String, requestMethod: OAuthRequest.HTTPMethod, generateDefaultParameters: Bool = true, oauthParameters: Parameters?) -> AuthorizationHeader {
        //Generate parameters
        let parameters: [String: String] = {
            var parameters = generateDefaultParameters ? defaultParameters : [:]
            oauthParameters?.keys.forEach { parameters[$0] = oauthParameters?[$0] }
            return parameters
        }()
        //Generate signature
        let signature = generateSignature(urlPath: urlPath, oauthParameters: parameters, requestMethod: requestMethod)
        let authParameters = parameters
        //Create header
        let map = authParameters.map { $0.key + "=\"" + $0.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "\"" }
        let authValue = "OAuth \(map.joined(separator: ",")), \(OAuthParameter.signature.rawValue)=\"\(signature)\""
        return ("Authorization", authValue)
    }
    
    private func generateSignature(urlPath: String, oauthParameters: Parameters, requestMethod: OAuthRequest.HTTPMethod) -> String {
        //Sort parameters by key
        //Endode keys and values
        let literal = oauthParameters.sorted(by: { $0.key < $1.key }).map { $0.key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "=" + $0.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! }
            .joined(separator: "&").replacingOccurrences(of: "%", with: "%25").replacingOccurrences(of: "&", with: "%26").replacingOccurrences(of: "=", with: "%3D")
        //Base string
        let baseString = requestMethod.rawValue + "&" + urlPath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&" + literal
        //Signing key
        let signingKey = OAuth.consumerSecret.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        //Signature
        let signature = baseString.hmac(key: signingKey)
        return signature
    }
    
}
