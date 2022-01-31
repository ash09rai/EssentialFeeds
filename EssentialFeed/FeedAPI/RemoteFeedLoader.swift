//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 26/01/22.
//

import Foundation


public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case Connectivity
        case InValidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(let data, let response):
                do {
                    let feedArray = try FeedItemMapper.map(data, response)
                    completion(.success(feedArray))
                } catch {
                    completion(.failure(.InValidData))
                }
            case .failure( _):
                completion(.failure(.Connectivity))
            }
        }
    }
}



