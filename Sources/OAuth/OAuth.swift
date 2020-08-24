//
//  OAuth.swift
//
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation

final class OAuth {
    
    public typealias AuthorizationHeader = (key: String, value: String)
    public typealias Parameters = [String: String]
    
    public static let shared = OAuth()
    
    public var openURL: (_ url: URL) -> Void = { _ in }
    
    static private var consumerKey: String = "xxx"
    static private var consumerSecret: String = "xxx"
    
    ///Oauth token
    public private(set) var token: String?
    public private(set) var tokenSecret: String?
    ///User identifier
    public private(set) var userIdentifier: String?
    ///Oauth verifier
    public private(set) var verifier: String?
    
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
    
    public init() {
        
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

//MARK:- Login Flow
extension OAuth {
    
    public typealias TokensHandler = (_ token: String?, _ tokenSecret: String?) -> Void
    public func askForTokens(completionHandler: @escaping(TokensHandler)) {
        
        let url = URL(string: "https://api.twitter.com/oauth/request_token")!
        let request = self.request(url: url, method: .get, oauthParameters: nil, parameters: nil)
        
        PostCenter.shared.post(request) { (data, response, error) in
            
            var token: String?
            var tokenSecret: String?
            
            defer {
                completionHandler(token, tokenSecret)
            }
            
            guard let data = data, let str = String(data: data, encoding: .utf8) else { return }
            
            let parameters = str.components(separatedBy: "&").map { (string) -> (key: String, value: String) in
                let split = string.split(separator: "=")
                let key = String(split[0])
                let value = String(split[1])
                return (key, value)
            }
            
            token = parameters.first(where: { $0.key == OAuthParameter.token.rawValue })?.value
            tokenSecret = parameters.first(where: { $0.key == OAuthParameter.tokenSecret.rawValue })?.value
        }
        
    }
    
    public func authorizeURL() -> URL? {
        guard let token = self.token else { return nil }
        
        let path = "https://api.twitter.com/oauth/authorize"
        guard var urlComponents = URLComponents(string: path) else { return nil }
        
        urlComponents.queryItems = [
            .init(name: OAuthParameter.token.rawValue, value: token)
        ]
        
        return urlComponents.url
    }
    
    public func observeURL(url: URL) -> Bool {
        guard let verifier = parseVerifier(url: url) else { return false }
        
        NotificationCenter.default.post(name: .init("didReceiveResponse"), object: verifier)
        return true
    }
    
    public func parseVerifier(url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        
        let verifier = components.queryItems?.first(where: { $0.name == OAuthParameter.verifier.rawValue })?.value
        
        return verifier
    }
    
    public func askForAccessToken(completionHandler: @escaping(TokensHandler)) {
        
        guard let token = self.token, let verifier = self.verifier else {
            completionHandler(nil, nil)
            return
        }
        
        let path = "https://api.twitter.com/oauth/access_token"
        var urlComponents = URLComponents(string: path)!
        urlComponents.queryItems = [
            .init(name: OAuthParameter.token.rawValue, value: token),
            .init(name: OAuthParameter.verifier.rawValue, value: verifier)
        ]
        let url = urlComponents.url!
        
        let request = self.request(url: url, method: .post, oauthParameters: nil, parameters: nil)
        PostCenter.shared.post(request) { (data, response, error) in
        
            var token: String?
            var tokenSecret: String?
            
            defer {
                completionHandler(token, tokenSecret)
            }
            
            guard let data = data, let str = String(data: data, encoding: .utf8) else { return }
            
            let parameters = str.components(separatedBy: "&").map { (string) -> (key: String, value: String) in
                let split = string.split(separator: "=")
                let key = String(split[0])
                let value = String(split[1])
                return (key: key, value: value)
            }
            
            token = parameters.first(where: { $0.key == OAuthParameter.token.rawValue })?.value
            tokenSecret = parameters.first(where: { $0.key == OAuthParameter.tokenSecret.rawValue })?.value
        }
        
    }
    
    // 1) Set consumer
    // 2) Set openURL
    // 3) Add observeURL to main application
    public func login(completionHandler: @escaping(Bool) -> Void) {
        
        askForTokens { (token, tokenSecret) in
            
            guard let token = token, let tokenSecret = tokenSecret else {
                completionHandler(false)
                return
            }
            
            self.setToken(token: token, tokenSecret: tokenSecret)
            
            guard let url = self.authorizeURL() else {
                completionHandler(false)
                return
            }
            self.openURL(url)
        }
        
        NotificationCenter.default.addObserver(forName: .init("didReceiveResponse"), object: nil, queue: nil) { (notification) in
            NotificationCenter.default.removeObserver(self, name: .init("didReceiveResponse"), object: nil)
            
            guard let verifier = notification.object as? String else {
                completionHandler(false)
                return
            }
            self.setVerifier(verifier: verifier)
            
            self.askForAccessToken { (token, tokenSecret) in
                guard let token = token, let tokenSecret = tokenSecret else {
                    completionHandler(false)
                    return
                }
                self.setToken(token: token, tokenSecret: tokenSecret)
                completionHandler(true)
            }
        }
        
    }
    
}

extension String {
    
}
