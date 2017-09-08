//
//  ResultPromisesTests.swift
//  ResultPromisesTests
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import ResultPromises

final private class PromiseTests: XCTestCase {
  
  private enum TestError: Error {
    case test
  }
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testThenAtoB() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> (Int) in
      promiseAResult = string
      return string.characters.count
    }
    var promiseBResult: Int? = nil
    _ = promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.characters.count)
  }
  
  func testCompletionOnSucceess() {
    
    var completionState: Result<String>?
    let promiseA = Promise<String>()
    _ = promiseA.onComplete { (state) in
      completionState = state
    }
    
    let testString = "Test"
    promiseA.resolve(result: testString)
    guard let state = completionState else {
      XCTFail("completion state not given")
      return
      
    }
    if case Result<String>.success(let string) = state {
      XCTAssertEqual(string, testString)
    }
    else {
      XCTFail("completion state should be Result.succees")
    }
  }
  
  func testCompletionOnFail() {
    
    var completionState: Result<String>?
    let promiseA = Promise<String>()
    _ = promiseA.onComplete { (state) in
      completionState = state
    }
    
    promiseA.resolve(error: TestError.test)
    guard let state = completionState else {
      XCTFail("completion state not given")
      return
    }
    if case Result<String>.failure(let error) = state {
      XCTAssertEqual(error as? TestError, TestError.test)
    }
    else {
      XCTFail("completion state should be Result.succees")
    }
  }
  
  func testCompletionOrderOnSuccess() {
    
    var callbackOrder = [String]()
    
    let promiseA = Promise<String>()
    _ = promiseA
      .onComplete { _ in
        callbackOrder.append("onCompletion1")
      }
      .onSuccess{ _ in
        callbackOrder.append("onSuccess")
      }
      .onError{ _ in
        callbackOrder.append("onError")
      }
      .onComplete{ _ in
        callbackOrder.append("onCompletion2")
    }
    
    
    let testString = "Test"
    promiseA.resolve(result: testString)
    
    guard callbackOrder.count == 3 else {
      XCTFail("3 callbacks expected")
      return
    }
    XCTAssertEqual(callbackOrder[0], "onCompletion1")
    XCTAssertEqual(callbackOrder[1], "onSuccess")
    XCTAssertEqual(callbackOrder[2], "onCompletion2")
    
  }
  
  func testFailure() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    var thenAtoBIngnored = true
    var onSuccessAIgonred = true
    
    let promiseB = promiseA
      .onSuccess { (string) in
        onSuccessAIgonred = false
      }
      .then { string -> (Int) in
        promiseAResult = string
        thenAtoBIngnored = true
        return string.characters.count
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
    XCTAssertTrue(thenAtoBIngnored)
    XCTAssertTrue(onSuccessAIgonred)
  }
  
  func testThenAfterSuccess() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA
      .onSuccess{ (string) in
        promiseAResult = string
      }
      .then { string -> Int in
        XCTAssertEqual(promiseAResult, string)
        return string.characters.count
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
  }
  
  func testOnSuccessOnBGThread() {
    var promiseAResult: String? = nil
    
    var thenInMainThread: Bool? = nil
    var succesInMainThread: Bool? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> (Int) in
      promiseAResult = string
      thenInMainThread = Thread.isMainThread
      return string.characters.count
    }
    var promiseBResult: Int? = nil
    let exp = self.expectation(description: "Success!")
    _ = promiseB.onSuccess{ result in
      promiseBResult = result
      succesInMainThread =  Thread.isMainThread
      exp.fulfill()
    }
    let testString = "AsyncTest"
    DispatchQueue.global(qos: .default).async {
      promiseA.resolve(result: testString)
    }
    wait(for: [exp], timeout: 0.1)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.characters.count)
    XCTAssertEqual(succesInMainThread, true)
    XCTAssertEqual(thenInMainThread, false)
  }
  
  // FlatMap
  
  func testFlatThenAtoB() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> Result<Int> in
      promiseAResult = string
      return .success(value: string.characters.count)
    }
    var promiseBResult: Int? = nil
    _ = promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.characters.count)
  }
  
  func testFlatAFailure() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    var thenAtoBIngnored = true
    var onSuccessAIgonred = true
    
    let promiseB = promiseA
      .onSuccess { (string) in
        onSuccessAIgonred = false
      }
      .then { string -> Result<Int> in
        promiseAResult = string
        thenAtoBIngnored = true
        return .success(value: string.characters.count)
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
    XCTAssertTrue(thenAtoBIngnored)
    XCTAssertTrue(onSuccessAIgonred)
  }
  
  func testFlatThenAfterSuccess() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA
      .onSuccess{ (string) in
        promiseAResult = string
      }
      .then { string -> (Int) in
        XCTAssertEqual(promiseAResult, string)
        return string.characters.count
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
  }
  
  // FlatMap Promise
  
  func testFlatPromiseThenAtoB() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> Promise<Int> in
      promiseAResult = string
      let promiseBInner = Promise<Int>()
      promiseBInner.resolve(result: string.characters.count)
      return promiseBInner
    }
    var promiseBResult: Int? = nil
    _ = promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.characters.count)
  }
  
  func testFlatPromiseAFailure() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    var onSuccessAIgonred = true
    
    let promiseB = promiseA
      .onSuccess { (string) in
        onSuccessAIgonred = false
      }
      .then { string -> Promise<Int> in
        promiseAResult = string
        let promiseBInner = Promise<Int>()
        promiseBInner.resolve(result: string.characters.count)
        return promiseBInner
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
    XCTAssertTrue(onSuccessAIgonred)
  }
  
  func testFlatPromiseThenAfterSuccess() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA
      .onSuccess{ (string) in
        promiseAResult = string
      }
      .then { string -> Promise<Int> in
        XCTAssertEqual(promiseAResult, string)
        let promiseBInner = Promise<Int>()
        promiseBInner.resolve(result: string.characters.count)
        return promiseBInner
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    _ = promiseB
      .onSuccess{ result in
        promiseBResult = result
      }
      .onError { (error) in
        promiseBError = error
    }
    
    promiseA.resolve(error: TestError.test)
    XCTAssertNil(promiseAResult)
    XCTAssertNil(promiseBResult)
    XCTAssertNotNil(promiseBError)
  }
  
}

