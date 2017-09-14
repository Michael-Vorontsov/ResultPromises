//
//  URLSession+ExtensionTets.swift
//  ResultPromisesTests
//
//  Created by Mykhailo Vorontsov on 9/14/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import ResultPromises

private final class URLSession_ExtensionTets: XCTestCase {
  
  struct TestReminder: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
  }
  
  let session = URLSession.shared
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testCorrectJSONObjectRetrival() {
    let request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/todos")!)
    
    let fetchPromise: Promise<[TestReminder]> = session.fetchRESTObject(from: request)
    
    let exp = expectation(description: "Network request")
    
    fetchPromise
      .onSuccess { (listOfReminders) in
        XCTAssertEqual(listOfReminders.count , 200)
      }
      .onError { (error) in
        switch error {
        // If network error happened - perhaps it means that no connection established
        case NetworkError.network(let embeddedError):
          print("WARKING: Unexpected network error encoutered. It is not indication of failing test yet.\n \(embeddedError?.localizedDescription ?? "<Empty>")")
        default:
          XCTFail("Unexpected exception: \(error.localizedDescription)")
          
        }
      }
      .onComplete { _ in
        exp.fulfill()
    }
    wait(for: [exp], timeout: 5.0)
  }

  func testIncorrectJSONObjectRetrival() {
    let request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users")!)
    
    let fetchPromise: Promise<[TestReminder]> = session.fetchRESTObject(from: request)
    
    let exp = expectation(description: "Network request")
    
    fetchPromise
      .onSuccess { (listOfReminders) in
        XCTFail("Expectipn expected!")
      }
      .onError { (error) in
        switch error {
        // If network error happened - perhaps it means that no connection established
        case NetworkError.network(let embeddedError):
          print("WARKING: Unexpected network error encoutered. It is not indication of failing test yet.\n \(embeddedError?.localizedDescription ?? "<Empty>")")
        case NetworkError.deserilisation(_):
          // Expected error
          break
        default:
          XCTFail("Unexpected exception: \(error.localizedDescription)")
        }
      }
      .onComplete { _ in
        exp.fulfill()
    }
    wait(for: [exp], timeout: 5.0)
  }

  func testServersideErrorRetrival() {
    let request = URLRequest(url: URL(string: "http://google.co.uk/unexpected_request")!)
    
    let fetchPromise: Promise<[TestReminder]> = session.fetchRESTObject(from: request)
    
    let exp = expectation(description: "Network request")
    
    fetchPromise
      .onSuccess { (listOfReminders) in
        XCTFail("Expectipn expected!")
      }
      .onError { (error) in
        switch error {
        // If network error happened - perhaps it means that no connection established
        case NetworkError.network(let embeddedError):
          print("WARKING: Unexpected network error encoutered. It is not indication of failing test yet.\n \(embeddedError?.localizedDescription ?? "<Empty>")")
        case NetworkError.http(let errorCode):
          XCTAssertEqual(errorCode, 404)
          // Expected error
          break
        default:
          XCTFail("Unexpected exception: \(error.localizedDescription)")
        }
      }
      .onComplete { _ in
        exp.fulfill()
    }
    wait(for: [exp], timeout: 5.0)
  }
  
}
