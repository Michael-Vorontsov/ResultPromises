//
//  URLRequest+ExtensionTests.swift
//  ResultPromisesTests
//
//  Created by Mykhailo Vorontsov on 9/14/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest

class URLRequestExtensionTests: XCTestCase {
  
  let defaultPath = "http://google.com"
  
  func testSimpleRequestFromPath() {
    let requestPromise = URLRequest.requestFor(path: defaultPath)
    let exp = expectation(description: "Request generation")
    requestPromise
      .onSuccess { (request) in
        XCTAssertEqual(request.url?.absoluteString, self.defaultPath)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertEqual(request.allHTTPHeaderFields?.count ?? 0, 0)
        exp.fulfill()
      }
    wait(for: [exp], timeout: 1.0)
  }
  
  func testRequestWithHeaders() {
    let exp = expectation(description: "Request generation")
    URLRequest.requestFor(path: defaultPath, headers: ["key" : "value"]).onSuccess { (request) in
      
      XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
      XCTAssertEqual(request.allHTTPHeaderFields?["key"], "value")
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
  
  func testGetRequestWithParameters() {
    let exp = expectation(description: "Request generation")
    URLRequest.requestFor(path: defaultPath, parameters: ["param1" : 0, "param 2" : "string with space"])
      .onSuccess { (request) in
        guard let fullPath = request.url?.absoluteString else { XCTFail("path expected!"); return }
        
        XCTAssertTrue(fullPath.contains(self.defaultPath))
        XCTAssertTrue(fullPath.contains("?"))
        XCTAssertTrue(fullPath.contains("&"))
        XCTAssertTrue(fullPath.contains("param1=0"))
        XCTAssertTrue(fullPath.contains("param%202=string%20with%20space"))
      }
        .onError{ error in
            XCTFail("Unexpected error: \(error)")
      }
      .onComplete { (_) in
        exp.fulfill()
      }
    wait(for: [exp], timeout: 1.0)
  }
  
  func testPostRequestWithParameters() {
    let exp = expectation(description: "Request generation")
    URLRequest.requestFor(
      path: defaultPath,
      method: .post,
      parameters: ["param1" : 0, "param 2" : "string with space"]
    )
      .onSuccess { (request) in

        XCTAssertEqual(request.url?.absoluteString, self.defaultPath)
        //FixMe: Check body
      }
      .onError { (error) in
        XCTFail("Unexpected error: \(error)")
      }
      .onComplete { (_) in
        exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
  }
  
}
