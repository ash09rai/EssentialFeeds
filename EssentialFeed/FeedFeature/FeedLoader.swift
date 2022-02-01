//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 23/01/22.
//

import Foundation

public enum LoadFeedResult <Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult: Equatable where Error: Equatable {}

protocol FeedLoader {
    associatedtype Error: Swift.Error
    func loadFeed(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
