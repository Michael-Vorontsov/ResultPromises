//
//  ResultTests.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/13/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import ResultPromises

final private class ResultTests: XCTestCase {
  
  enum TestError: Error {
    case test
  }
  
  func testResolutionToSuccess() {
    let stringToTest = "TestString"
    let toTest = Result<String>.success(value: stringToTest)
    do {
      let resolution = try toTest.resolve()
      XCTAssertEqual(resolution, stringToTest)
    }
    catch {
      XCTFail("Unexpected swift exception: \(error)")
    }
  }
  
  func testResolutionToError() {
    let toTest = Result<String>.failure(error: TestError.test)
    do {
      _ = try toTest.resolve()
      XCTFail("Exception should be thrown earlier")
    } catch {
      switch error {
      case TestError.test:
        break;
      default:
        XCTFail("Wrong error thrown: \(error)")
      }
    }
  }
  
  func testSuccessMapToSuccess() {
    let stringToTest = "TestString"
    let toTest = Result<String>.success(value: stringToTest)
    
    do {
      let result = try toTest.map { (string) -> Int in
        return stringToTest.count
        }.resolve()
      XCTAssertEqual(stringToTest.count, result)
    }
    catch {
      XCTFail("Unexpected swift exception: \(error)")
    }
    
  }
  
  func testSuccessMapToFail() {
    let stringToTest = "TestString"
    let toTest = Result<String>.success(value: stringToTest)
    
    do {
      _ = try toTest.map { (string) -> Int in
        throw TestError.test
        }.resolve()
      XCTFail("Exception should be thrown earlier")
    }
    catch {
      switch error {
      case TestError.test:
        break;
      default:
        XCTFail("Wrong error thrown: \(error)")
      }
    }
  }
  
  func testFailMapToFail() {
    let toTest = Result<String>.failure(error: TestError.test)
    
    do {
      _ = try toTest.map { (string) -> Int in
        XCTFail("Unreachable code!")
        return 0
        }.resolve()
      XCTFail("Unreachable code!")
    }
    catch {
      switch error {
      case TestError.test:
        break;
      default:
        XCTFail("Wrong error thrown: \(error)")
      }
    }
    
  }
  
  func testSuccessFlatToSuccess() {
    let stringToTest = "TestString"
    let toTest = Result<String>.success(value: stringToTest)
    
    do {
      let result = try toTest.flatMap{ (string) -> Result<Int> in
        return .success(value: string.count)
        }.resolve()
      XCTAssertEqual(stringToTest.count, result)
    }
    catch {
      XCTFail("Unexpected swift exception: \(error)")
    }
    
  }
  
  func testSuccessFlatMapToFail() {
    let stringToTest = "TestString"
    let toTest = Result<String>.success(value: stringToTest)
    
    do {
      _ = try toTest.flatMap{ (string) -> Result<Int> in
        return .failure(error: TestError.test)
        }.resolve()
      XCTFail("Exception should be thrown earlier")
    }
    catch {
      switch error {
      case TestError.test:
        break;
      default:
        XCTFail("Wrong error thrown: \(error)")
      }
    }
  }
  
  func testFailFlatMapToFail() {
    let toTest = Result<String>.failure(error: TestError.test)
    
    do {
      _ = try toTest.flatMap{ (string) -> Result<Int> in
        XCTFail("Unreachable code!")
        return .success(value: 0)
        }.resolve()
      XCTFail("Unreachable code!")
    }
    catch {
      switch error {
      case TestError.test:
        break;
      default:
        XCTFail("Wrong error thrown: \(error)")
      }
    }
    
  }
  
  
}
