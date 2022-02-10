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
    
    struct UnxpectedValueRepresentation: Error {}
    
    func get(from url: URL, completionHandler: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                completionHandler(.failure(UnxpectedValueRepresentation()))
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
        let dummyURL: URL = anyURL()
        let exp = expectation(description: "wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, dummyURL)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: dummyURL) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = NSError(domain: "Any error", code: 1)
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        XCTAssertEqual((receivedError as NSError?)?.code, requestError.code)
        XCTAssertEqual((receivedError as NSError?)?.domain, requestError.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let urlResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let urlHttpResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let data = Data([1,2,3])
        let requestError = NSError(domain: "Any error", code: 1)
        XCTAssertNotNil(resultErrorFor(data: nil, response:nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response:nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response:urlResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response:urlHttpResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response:nil, error: requestError))
        XCTAssertNotNil(resultErrorFor(data: nil, response:urlResponse, error: requestError))
        XCTAssertNotNil(resultErrorFor(data: nil, response:urlHttpResponse, error: requestError))
        XCTAssertNotNil(resultErrorFor(data: data, response:urlResponse, error: requestError))
        XCTAssertNotNil(resultErrorFor(data: data, response:urlHttpResponse, error: requestError))
        XCTAssertNotNil(resultErrorFor(data: data, response:urlResponse, error: nil))

    }
    
    
    
    //MARK: SUT Helper
    func resultErrorFor(data: Data?, response: URLResponse?, error: NSError?, line: UInt = #line, file: StaticString = #filePath) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = expectation(description: "wait for completion")
        var receivedError: Error?
        let sut = makeSUT(line: line, file: file)
       
        sut.get(from: anyURL()) { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) insted on file: \(file) and line: \(line)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return receivedError
    }
    
    private func makeSUT(line: UInt = #line, file: StaticString = #filePath) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        checkPotentialMemoryLeaks(sut, line: line, file: file)
        return URLSessionHTTPClient()
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-test.com")!
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
