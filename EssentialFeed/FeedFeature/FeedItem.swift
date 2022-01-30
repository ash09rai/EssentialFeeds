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
}
