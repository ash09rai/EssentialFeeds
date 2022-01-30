//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 26/01/22.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse?)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

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
                if response?.statusCode == 200,
                   let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items.map({$0.feedItem})))
                } else {
                    completion(.failure(.InValidData))
                }
            case .failure( _):
                completion(.failure(.Connectivity))
            }
        }
    }
}

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

