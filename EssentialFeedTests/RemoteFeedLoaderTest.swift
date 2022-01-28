//
//  RemoteFeedLoaderTest.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 24/01/22.
//

import XCTest
@testable import EssentialFeed

class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesnotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_init_requestsDataFromURL() {
        let url = URL(string: "https://agiven-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in  })
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_initTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://agiven-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in  })
        sut.load(completion: { _ in  })

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_ErrorDeliveryOnClientError() {
        let (sut, client) = makeSUT()
        var composedError = [RemoteFeedLoader.Error]()
        
        sut.load() {composedError.append($0)}
        let clienterror = NSError(domain: "Test Error", code: 0)
        client.complete(with : clienterror)
        
        XCTAssertEqual(composedError, [.Connectivity])
    }
    
    //MARK:- Helper
    private func makeSUT(url: URL = URL(string: "https://agiven-url.com")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messaged =  [(url: URL, completion: (Error) -> Void)]()
        
        var requestedURLs: [URL] {
            return self.messaged.map({$0.url})
        }

        func get(from url: URL, completion: @escaping (Error) -> Void) {
            self.messaged.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            self.messaged[index].completion(error)
        }
    }

}
