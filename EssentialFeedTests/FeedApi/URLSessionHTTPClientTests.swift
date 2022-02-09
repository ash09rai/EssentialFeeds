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
    override func setUp() {
        super.setUp()
        URLProtocolStub.startIntercepting()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopIntercepting()
    }
    
    func test_getFromURL_performGetRequestWithURls() {
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let exp = expectation(description: "wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, dummyURL)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        URLSessionHTTPClient().get(from: dummyURL) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let dummyURL: URL = URL(string: "http://any-test.com")!
        let error = NSError(domain: "Any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
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
    }
    
    //MARK: Helper
    private class URLProtocolStub: URLProtocol {
        private static var stubs : Stub?
        private static var requestObserver : ((URLRequest) -> Void)?

        private struct Stub {
            var data: Data?
            var response: URLResponse?
            var error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stubs = Stub(data: data, response: response, error: error)
        }
        
        static func startIntercepting() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func stopIntercepting() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stubs = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
           return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            requestObserver?(request)
            return request
        }
        
        override func startLoading() {
            if let error = URLProtocolStub.stubs?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            if let data = URLProtocolStub.stubs?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stubs?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
