//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 24/01/22.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    func get(from url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?

    override func get(from url: URL) {
        self.requestedURL = url
    }
}

class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesnotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        _ = RemoteFeedLoader()
        XCTAssertNil(client.requestedURL)
    }
    
    func test_init_requestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = RemoteFeedLoader()
        sut.load()
        XCTAssertNotNil(client.requestedURL)
    }

}
