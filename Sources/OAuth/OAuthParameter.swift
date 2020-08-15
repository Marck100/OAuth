//
//  OAuthParameter.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

public enum OAuthParameter: String {
    case consumerKey = "oauth_consumer_key"
    case signatureMethod = "oauth_signature_method"
    case signature = "oauth_signature"
    case timestamp = "oauth_timestamp"
    case nonce = "oauth_nonce"
    case version = "oauth_version"
    case callback = "oauth_callback"
    case token = "oauth_token"
    case tokenSecret = "oauth_token_secret"
    case verifier = "oauth_verifier"
}
