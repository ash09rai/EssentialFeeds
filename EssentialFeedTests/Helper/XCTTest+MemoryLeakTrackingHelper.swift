//
//  XCTTest+MemoryLeakTrackingHelper.swift
//  EssentialFeedTests
//
//  Created by Ashish Rai on 09/02/22.
//

import Foundation
import XCTest

extension XCTestCase {
    func checkPotentialMemoryLeaks(_ instance: AnyObject, line: UInt = #line, file: StaticString = #filePath) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Check for potential memory leaks in the test....", file: file, line: line)
        }
    }
}
