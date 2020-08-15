//
//  String++.swift
//  
//
//  Created by Marco Pilloni on 15/08/2020.
//

import Foundation
import CommonCrypto

extension String {
    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
        let data = Data(digest)
        let str = data.base64EncodedString().replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "/", with: "%2F").replacingOccurrences(of: "=", with: "%3D")
        return str
    }
    static func randomString(length: Int) -> String {
        let scalars = [
            UnicodeScalar("a").value...UnicodeScalar("z").value,
            UnicodeScalar("A").value...UnicodeScalar("Z").value,
            UnicodeScalar("0").value...UnicodeScalar("9").value
        ].joined()
        let characters: [Character] = scalars.map { Character(UnicodeScalar($0)!) }
        let string = (0..<length).map { _ in characters.randomElement()! }
        return String(string)
    }
}
