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
        session.dataTask(with: url) { _, _, _ in }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(from: dummyURL, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: dummyURL)
        
        XCTAssertEqual(task.resumeCounter, 1)
    }
    
    //MARK: Helper
    private class URLSessionSpy: URLSession {
        private var stubs = [URL: URLSessionDataTask]()
        
        func stub(from url: URL, task: URLSessionDataTask) {
            stubs.updateValue(task, forKey: url)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            return stubs[url] ?? FakeSessionDataTask()
        }
    }
    
    private class FakeSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCounter = 0
        
        override func resume() {
            resumeCounter += 1
        }
    }

}
