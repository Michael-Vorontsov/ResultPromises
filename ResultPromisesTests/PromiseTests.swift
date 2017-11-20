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
  
  func testThenAtoTypeB() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> (Int) in
      promiseAResult = string
      return string.count
    }
    var promiseBResult: Int? = nil
    promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.count)
  }
  
  func testAFileThenBFail() {

    let promiseA = Promise<String>()
    var promiseBNotExecuted = true
    let promiseB = promiseA.then { string -> (Int) in
      promiseBNotExecuted = false
      return 0
    }
    var promiseBExpectedError: Error?  = nil
    promiseB.onError { (error) in
      promiseBExpectedError = error
    }
    promiseA.resolve(error: TestError.test)
    XCTAssertTrue(promiseBNotExecuted)
    XCTAssertNotNil(promiseBExpectedError)
  }
  
  
  func testCompletionOnSucceess() {
    
    var completionState: Result<String>?
    let promiseA = Promise<String>()
    promiseA.onComplete { (state) in
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
    promiseA.onComplete { (state) in
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
  
  func testSuccesNotExecutedOnFail() {
    
    let promiseA = Promise<String>()
    var successTriggered = false
    promiseA.onSuccess{ _ in
      successTriggered = true
    }
    
    promiseA.resolve(error: TestError.test)
    XCTAssertFalse(successTriggered)
  }
  
  func testFailNotExecutedOnSuccess() {
    
    let promiseA = Promise<String>()
    var errorTriggered = false
    promiseA.onError{ _ in
      errorTriggered = true
    }
    
    promiseA.resolve(result: "Test")
    XCTAssertFalse(errorTriggered)
  }
  
  func testCompletionOrderOnSuccess() {
    
    var callbackOrder = [String]()
    
    let promiseA = Promise<String>()
    promiseA
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
        return string.count
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
        return string.count
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
      return string.count
    }
    var promiseBResult: Int? = nil
    let exp = self.expectation(description: "Success!")
    promiseB.onSuccess{ result in
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
    XCTAssertEqual(promiseBResult, testString.count)
    XCTAssertEqual(succesInMainThread, true)
    XCTAssertEqual(thenInMainThread, false)
  }
  
  // FlatMap
  
  func testFlatThenAtoB() {
    var promiseAResult: String? = nil
    
    let promiseA = Promise<String>()
    let promiseB = promiseA.then { string -> Result<Int> in
      promiseAResult = string
      return .success(value: string.count)
    }
    var promiseBResult: Int? = nil
    promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.count)
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
        return .success(value: string.count)
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
        return string.count
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
      promiseBInner.resolve(result: string.count)
      return promiseBInner
    }
    var promiseBResult: Int? = nil
    promiseB.onSuccess{ result in
      promiseBResult = result
    }
    let testString = "Test"
    promiseA.resolve(result: testString)
    XCTAssertEqual(promiseAResult, testString)
    XCTAssertEqual(promiseBResult, testString.count)
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
        promiseBInner.resolve(result: string.count)
        return promiseBInner
    }
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
        promiseBInner.resolve(result: string.count)
        return promiseBInner
    }
    
    var promiseBResult: Int? = nil
    var promiseBError: Error? = nil
    promiseB
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
  
  func testResolutionHandlersAfterSuccess() {
    
    var completionState: Result<String>?
    var successString: String?
    var failError: Error?
    let testString = "Test"
    let promiseA = Promise<String>()
    promiseA.resolve(result: testString)
    
    promiseA
      .onSuccess { (string) in
        successString = string
      }
      .onComplete { (state) in
        completionState = state
      }
      .onError{ (error) in
        failError = error
    }
    
    guard let state = completionState else {
      XCTFail("completion state not given")
      return
    }
    
    XCTAssertNotNil(successString)
    XCTAssertNotNil(completionState)
    XCTAssertNil(failError)
    if case Result<String>.success(let string) = state {
      XCTAssertEqual(string, testString)
    }
    else {
      XCTFail("completion state should be Result.succees")
    }
  }
  
  func testThenSequenceAfterSuccess() {
    
    let testString = "Test"
    let promiseA = Promise<String>()
    promiseA.resolve(result: testString)
    let exp = expectation(description: "Chain executed")
    
    promiseA
      .then { (string) -> String in
        return string
      }
      .then { (string) -> Result<String> in
        return .success(value: string)
      }
      .then { (string) -> Promise<String> in
        let newPromise = Promise<String>()
        newPromise.resolve(result: string)
        return newPromise
      }
      .onSuccess { (string) in
        XCTAssertEqual(testString, string)
        exp.fulfill()
    }
    wait(for: [exp], timeout: 0.01)
  }
  
  func testThenSequenceAfterError() {
    
    let promiseA = Promise<String>()
    promiseA.resolve(error: TestError.test)
    let exp = expectation(description: "Chain executed")
    
    promiseA
      .then { (string) -> String in
        XCTFail("Unexpected call")
        return string
      }
      .then { (string) -> Result<String> in
        XCTFail("Unexpected call")
        return .success(value: string)
      }
      .then { (string) -> Promise<String> in
        XCTFail("Unexpected call")
        return Promise<String>()
      }
      .onError { (error) in
        exp.fulfill()
    }
    
    wait(for: [exp], timeout: 0.01)
  }
  
  func testResolutionHandlersAfterFail() {
    
    var completionState: Result<String>?
    var successString: String?
    var failError: Error?
    let promiseA = Promise<String>()
    promiseA.resolve(error: TestError.test)
    
    promiseA
      .onSuccess { (string) in
        successString = string
      }
      .onComplete { (state) in
        completionState = state
      }
      .onError{ (error) in
        failError = error
    }
    
    XCTAssertNil(successString)
    XCTAssertNotNil(completionState)
    XCTAssertNotNil(failError)
  }
  
  func testFailResolutionAfterSuccessDoNothing() {
    var completionState: Result<String>?
    var successString: String?
    var failError: Error?
    let testString = "Test"
    let promiseA = Promise<String>()
    
    promiseA
      .onSuccess { (string) in
        successString = string
      }
      .onComplete { (state) in
        completionState = state
      }
      .onError{ (error) in
        failError = error
    }
    promiseA.resolve(result: testString)
    promiseA.resolve(error: TestError.test)
    
    guard let state = completionState else {
      XCTFail("completion state not given")
      return
    }
    
    XCTAssertNotNil(successString)
    XCTAssertNotNil(completionState)
    XCTAssertNil(failError)
    if case Result<String>.success(let string) = state {
      XCTAssertEqual(string, testString)
    }
    else {
      XCTFail("completion state should be Result.succees")
    }
  }
  
  func testSuccessResolutionAfterFailDoNothing() {
    var completionState: Result<String>?
    var successString: String?
    var failError: Error?
    let testString = "Test"
    let promiseA = Promise<String>()
    
    promiseA
      .onSuccess { (string) in
        successString = string
      }
      .onComplete { (state) in
        completionState = state
      }
      .onError{ (error) in
        failError = error
    }
    promiseA.resolve(error: TestError.test)
    promiseA.resolve(result: testString)
    
    XCTAssertNil(successString)
    XCTAssertNotNil(completionState)
    XCTAssertNotNil(failError)
  }
  
  func testSuccessResolutionAfterSuccessDoNothing() {
    var completionState: Result<String>?
    var successString: String?
    var failError: Error?
    let testStringA = "TestA"
    let testStringB = "TestA"
    let promiseA = Promise<String>()
    
    promiseA
      .onSuccess { (string) in
        successString = string
      }
      .onComplete { (state) in
        completionState = state
      }
      .onError{ (error) in
        failError = error
    }
    promiseA.resolve(result: testStringA)
    promiseA.resolve(result: testStringB)
    
    guard let state = completionState else {
      XCTFail("completion state not given")
      return
    }
    
    XCTAssertNotNil(successString)
    XCTAssertNotNil(completionState)
    XCTAssertNil(failError)
    if case Result<String>.success(let string) = state {
      XCTAssertEqual(string, testStringA)
    }
    else {
      XCTFail("completion state should be Result.succees")
    }
  }
  
  
  func testResolutionHandlersOnMainThread() {
    
    let promiseA = Promise<String>()
    let expMain = expectation(description: "Completion called on main")
    
    promiseA
      .onSuccess { (string) in
        XCTAssertTrue(Thread.current.isMainThread)
      }
      .onComplete { (state) in
        XCTAssertTrue(Thread.current.isMainThread)
      }
      .then { (string) -> Int in
        // then executing on same thread as resolution
        XCTAssertFalse(Thread.current.isMainThread)
        throw TestError.test
      }
      .onError { (error) in
        expMain.fulfill()
        XCTAssertTrue(Thread.current.isMainThread)
    }
    
    DispatchQueue.global(qos: .default).async {
      promiseA.resolve(error: TestError.test)
    }
    waitForExpectations(timeout: 1000.0, handler: nil)
  }
  
}

