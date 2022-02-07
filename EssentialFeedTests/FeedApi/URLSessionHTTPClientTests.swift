//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 07/02/22.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completionHandler: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let err = error {
                completionHandler(.failure(err))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(from: dummyURL, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: dummyURL) { _ in}
        
        XCTAssertEqual(task.resumeCounter, 1)
    }
    
    func test_getFromURL_failsonRequestError() {
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let error = NSError(domain: "Any error", code: 1)
        let session = URLSessionSpy()
        session.stub(from: dummyURL, error: error)
        
        let sut = URLSessionHTTPClient(session: session)
        let exp = expectation(description: "wait for completion")
        sut.get(from: dummyURL) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with \(error) got \(result) insted")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: Helper
    private class URLSessionSpy: URLSession {
        private var stubs = [URL: Stub]()
        
        private struct Stub {
            var task: URLSessionDataTask
            var error: Error?
        }
        
        func stub(from url: URL, task: URLSessionDataTask = FakeSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("couldn't find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
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
