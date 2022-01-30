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
        expect(sut, toCompleteWithResult: .failure(.Connectivity)) {
            let clienterror = NSError(domain: "Test Error", code: 0)
            client.complete(with : clienterror)
        }
    }
    
    func test_load_ErrorDeliveryOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let sampleHTTPStatusCode = [199,201,403, 404, 1099, 500, 300, 280]
        sampleHTTPStatusCode.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(.InValidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
    }
    
    func test_load_ErrorDeliveryOn200HTTPResponseButInValidaJson() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithResult: .failure(.InValidData)) {
            let inValidJson = Data("InValid Json".utf8)
            client.complete(withStatusCode: 200, data: inValidJson)
        }
    }
    
    func test_load_DeliversNoItemOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyResponseModel = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyResponseModel)
        }
    }
    
    func test_load_DeliversItemArrayOn200HTTPResponseWithValidJsonList() {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://a-url.com")!
        )
        
        let item1JSON = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(
            id: UUID(),
            description: "A description",
            location: "A location",
            imageURL: URL(string: "https://b-url.com")!
        )
        
        let item2Json = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJson = [
            "items": [item1JSON, item2Json]
        ]
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let itemsJsonData: Data = try! JSONSerialization.data(withJSONObject: itemsJson)
            client.complete(withStatusCode: 200, data: itemsJsonData)
        }
        
    }
    
    //MARK:- Helper
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult result: RemoteFeedLoader.Result,
                        onAction action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        var composedResults = [RemoteFeedLoader.Result]()
        sut.load() {composedResults.append($0)}
        
        action()
        
        XCTAssertEqual(composedResults, [result], file: file, line: line)
    }
    
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
