//
//  NFTModels.swift
//  LunchXrplSwift
//
//  Created by 한상범 on 12/27/24.
//

import Foundation

struct NFTAttributes: Codable {
    public var traitType: String
    public var value: String
    
    private enum CodingKeys: String, CodingKey {
        case traitType = "trait_type"
        case value = "value"
    }
}

struct NFTCollection: Codable {
    public var name: String?
    public var family: String?
}

struct NFTMetaData: Codable {
    public var name: String
    public var description: String
    public var image: String
    public var edition: String?
    public var date: Int?
    public var creator: String?
    public var artist: String?
    public var attributes: [NFTAttributes]
    public var externalLink: String?
    public var category: String?
    public var collection: NFTCollection?
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case description = "description"
        case image = "image"
        case edition = "edition"
        case date = "date"
        case creator = "creator"
        case artist = "artist"
        case attributes = "attributes"
        case externalLink = "external_link"
        case category = "category"
        case collection = "collection"
    }
}
