//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 23/01/22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
