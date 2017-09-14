//
//  URLRequest+ExtensionTests.swift
//  ResultPromisesTests
//
//  Created by Mykhailo Vorontsov on 9/14/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest

class URLRequestExtensionTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  let defaultPath = "http://google.com"
  
  func testSimpleRequestFromPath() {
    let requestPromise = URLRequest.requestFor(path: defaultPath)
    let exp = expectation(description: "Request generation")
    requestPromise.onSuccess { (request) in
      XCTAssertEqual(request.url?.absoluteString, self.defaultPath)
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertNil(request.httpBody)
      XCTAssertEqual(request.allHTTPHeaderFields?.count ?? 0, 0)
      exp.fulfill()
      }
    wait(for: [exp], timeout: 0.1)
  }
  
  func testRequestWithHeaders() {
    let exp = expectation(description: "Request generation")
    URLRequest.requestFor(path: defaultPath, headers: ["key" : "value"]).onSuccess { (request) in
      
      XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
      XCTAssertEqual(request.allHTTPHeaderFields?["key"], "value")
      exp.fulfill()
    }
    wait(for: [exp], timeout: 0.1)
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
      .onError { (error) in
        XCTFail("Unexpected error: \(error)")
      }
      .onComplete { (_) in
        exp.fulfill()
      }
    wait(for: [exp], timeout: 0.1)
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
    wait(for: [exp], timeout: 0.1)
  }
  
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
