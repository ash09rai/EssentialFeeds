//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ashish Rai on 23/01/22.
//

import Foundation

protocol FeedLoader {
    func loadFeed(completion: @escaping (Result<[FeedItem], Error>) -> Void)
}
