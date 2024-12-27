//
//  NFTTool.swift
//  LunchXrplSwift
//
//  Created by 한상범 on 12/27/24.
//

import Foundation

enum NFTToolError : Error {
    case noData
}

enum Endpoint: String {
    case metadata = "/api/v1/ipfs/metadata/"
    case image = "/api/v1/ipfs/image/"
}

class NFTTool {
    public var host: String
    public var metadataEndpoint: String
    public var imageEndpoint: String
    
    public init(
        host: String,
        metadataEndpoint: String = Endpoint.metadata.rawValue,
        imageEndpoint: String = Endpoint.image.rawValue
    ) {
        self.host = host
        self.metadataEndpoint = metadataEndpoint
        self.imageEndpoint = imageEndpoint
    }
    
    public func getMetadataUri(hexUri: String) -> String {
        let decodedAddress = self.convertHexToUri(hexUri: hexUri)
        
        let fullIpfsUri = if decodedAddress.hasPrefix("http://") || decodedAddress.hasPrefix("https://") {
            decodedAddress
        } else {
            self.host + self.metadataEndpoint + decodedAddress
        }
        
        return fullIpfsUri
    }
    
    public func getImageUri(_ data: NFTMetaData) -> String {
        if data.image.hasPrefix("ipfs://") {
            let uri = data.image.deletingPrefix("ipfs://")
            return self.host + self.imageEndpoint + uri
        } else if data.image.hasPrefix("http://") || data.image.hasPrefix("https://") {
            return data.image
        } else {
            return self.host + self.imageEndpoint + data.image
        }
    }
    
    func convertHexToUri(hexUri: String) -> String {
        let decodedAddress = hexUri.hexToStr()
        
        if decodedAddress.hasPrefix("ipfs://") {
            let uri = decodedAddress.deletingPrefix("ipfs://")
            return uri
        } else {
            return decodedAddress
        }
    }
}
