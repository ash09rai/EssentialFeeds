//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 23/01/22.
//

import Foundation

public struct FeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, desc: String?, loc: String?, url: URL) {
        self.id = id
        self.description = desc
        self.location = loc
        self.imageURL = url
    }
}
