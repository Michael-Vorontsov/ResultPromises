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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
      XCTFail("Execption should be thrown earlier")
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
          return stringToTest.characters.count
        }.resolve()
      XCTAssertEqual(stringToTest.characters.count, result)
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
      XCTFail("Execption should be thrown earlier")
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
        return .success(value: string.characters.count)
        }.resolve()
      XCTAssertEqual(stringToTest.characters.count, result)
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
      XCTFail("Execption should be thrown earlier")
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
