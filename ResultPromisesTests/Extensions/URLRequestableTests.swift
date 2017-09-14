//
//  URLRequestable.swift
//  ResultPromisesTests
//
//  Created by Mykhailo Vorontsov on 9/14/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest

class URLRequestableTests: XCTestCase {
  
  let testAddress = "https://google.com"
  let shortTestdAddress = "google.com"
  
  func testURLToRequest() {
    let url = URL(string: testAddress)!
    XCTAssertEqual(url.urlRequest(), URLRequest(url: url))
  }
  
  func testStringToRequest() {
    let url = URL(string: testAddress)!
    XCTAssertEqual(testAddress.urlRequest(), URLRequest(url: url))
  }
  
  func testShortStringToRequest() {
    let url = URL(string: testAddress)!
    XCTAssertEqual(shortTestdAddress.urlRequest(), URLRequest(url: url))
  }

  func testNSStringToRequest() {
    let url = URL(string: testAddress)!
    XCTAssertEqual(NSString(string: testAddress).urlRequest(), URLRequest(url: url))
  }

  func testRequestToRequest() {
    let url = URL(string: testAddress)!
    let request = URLRequest(url: url)
    XCTAssertEqual(request.urlRequest(), request)
  }
  
}
