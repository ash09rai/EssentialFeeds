//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 24/01/22.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesnotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        XCTAssertNil(client.requestedURL)
    }

}
