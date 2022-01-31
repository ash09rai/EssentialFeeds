//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 31/01/22.
//

import Foundation

internal final class FeedItemMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    private struct RemoteFeedItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var feedItem: FeedItem {
            return FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: image
            )
        }
    }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.InValidData
        }
        return try JSONDecoder().decode(Root.self, from: data).items.map({$0.feedItem})
    }
}
