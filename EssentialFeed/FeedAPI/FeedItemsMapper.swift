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
        
        var feedItems: [FeedItem] {
            return self.items.map({$0.feedItem})
        }
    }

    private struct RemoteFeedItem: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var feedItem: FeedItem {
            return FeedItem(
                id: id,
                desc: description,
                loc: location,
                url: image
            )
        }
    }

    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return .failure(RemoteFeedLoader.Error.InValidData)
        }
        return .success(root.feedItems)
    }
}
