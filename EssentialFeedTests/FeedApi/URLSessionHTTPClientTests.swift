//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 07/02/22.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURl_createDataTaskWithURL() {
        let urls: URL = URL(string: "http://any-test.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: urls)
        XCTAssertEqual(session.receivedURLs, [urls])
    }
    
    //MARK: Helper
    private class URLSessionSpy: URLSession {
        var receivedURLs: [URL] = []
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeSessionDataTask()
        }
    }
    
    private class FakeSessionDataTask: URLSessionDataTask {}
}
