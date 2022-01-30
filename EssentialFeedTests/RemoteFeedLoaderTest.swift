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
                let jsonData = getData(from: [])
                client.complete(withStatusCode: code, data: jsonData, at: index)
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
            let emptyResponseModel = getData(from: [])
            client.complete(withStatusCode: 200, data: emptyResponseModel)
        }
    }
    
    func test_load_DeliversItemArrayOn200HTTPResponseWithValidJsonList() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItems(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://a-url.com")!
        )
        
        let item2 = makeItems(
            id: UUID(),
            description: "A description",
            location: "A location",
            imageURL: URL(string: "https://b-url.com")!
        )
        
        let items = [item1.model, item2.model]
        expect(sut, toCompleteWithResult: .success(items)) {
            let itemData = getData(from: [item1.json, item2.json])
            client.complete(withStatusCode: 200, data: itemData)
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
    
    private func getData(from array: [[String: Any]]) -> Data {
        let itemJsonArray = ["items": array]
        return try! JSONSerialization.data(withJSONObject: itemJsonArray)
    }
    
    private func makeItems(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues({$0})
        
        return (item, json)
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
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
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
