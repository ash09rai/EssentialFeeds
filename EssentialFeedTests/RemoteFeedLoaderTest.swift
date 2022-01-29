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
    
    func test_load_ErrorDeliveryOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let sampleHTTPStatusCode = [199,201,403, 404, 1099, 500, 300, 280]
        sampleHTTPStatusCode.enumerated().forEach { index, code in
            var composedError = [RemoteFeedLoader.Error]()
            sut.load() {composedError.append($0)}
            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(composedError, [.InValidData])
        }
    }
    
    func test_load_ErrorDeliveryOn200HTTPResponseButInValidaJson() {
        let (sut, client) = makeSUT()
        var composedError = [RemoteFeedLoader.Error]()
        sut.load() {composedError.append($0)}
        let inValidJson = Data(bytes: "Invalid Json".utf8)
        client.complete(withStatusCode: 200, data: inValidJson)
        XCTAssertEqual(composedError, [.InValidData])
        
    }
    
    //MARK:- Helper
    private func makeSUT(url: URL = URL(string: "https://agiven-url.com")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut: RemoteFeedLoader = .init(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messaged =  [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return self.messaged.map({$0.url})
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            self.messaged.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            self.messaged[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let status = HTTPURLResponse(
                                    url: requestedURLs[index],
                                    statusCode: code,
                                    httpVersion: nil,
                                    headerFields: nil
                                )!
            
            self.messaged[index].completion(.success(data, status))
        }
    }

}
