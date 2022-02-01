//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 26/01/22.
//

import Foundation


public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case Connectivity
        case InValidData
    }
    
    public typealias Result = LoadFeedResult<Error>

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                completion(FeedItemMapper.map(data, response))
            case .failure( _):
                completion(.failure(.Connectivity))
            }
        }
    }
}



