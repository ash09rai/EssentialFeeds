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
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completionHandler: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completionHandler(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startIntercepting()
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let error = NSError(domain: "Any error", code: 1)
        URLProtocolStub.stub(from: dummyURL, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "wait for completion")
        
        sut.get(from: dummyURL) { result in
            switch result {
            case let .failure(receivedError as NSError):
                let receivedErrorInfo = NSError(domain: receivedError.domain, code: receivedError.code)
                XCTAssertEqual(receivedErrorInfo, error)
            default:
                XCTFail("Expected failure with \(error) got \(result) insted")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopIntercepting()

    }
    
    //MARK: Helper
    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            var error: Error?
        }
        
        static func stub(from url: URL, error: Error? = nil) {
            stubs[url] = Stub(error: error)
        }
        
        static func startIntercepting() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func stopIntercepting() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
