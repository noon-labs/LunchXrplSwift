//
//  String+ext.swift
//  LunchXrplSwift
//
//  Created by 한상범 on 12/27/24.
//

import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func hexToStr() -> String {
        let regex = try! NSRegularExpression(pattern: "(0x)?([0-9A-Fa-f]{2})", options: .caseInsensitive)
        let textNS = self as NSString
        let matchesArray = regex.matches(in: textNS as String, options: [], range: NSMakeRange(0, textNS.length))

        let characters = matchesArray.map {
            Character(UnicodeScalar(UInt32(textNS.substring(with: $0.range(at: 2)), radix: 16)!)!)
        }

        return String(characters)
    }
    
    func strToHex() -> String {
        let data = self.data(using: .utf8)!
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        
        return hexString
    }
}
