//
//  Promise.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Promise
 
 Provide reach possibilities to provide multyple completion handlers for sync operations separate for results and errors, and to chain as monads multyple async operations.
 */
public final class Promise<Value> {
  
  fileprivate typealias Callback = ((Result<Value>) -> ())
  
  private var lock = NSLock()
  
  fileprivate var callbacks = [Callback]()
  
  fileprivate var state: Result<Value>? = nil {
    didSet {
      guard let state = self.state else { return }
      callbacks.forEach { $0(state) }
    }
  }
  
  public init () { }
}

//MARK: -Resolution
extension Promise
{
  /// Resolve promise with Result wrapper
  ///
  /// - Parameter state: Result state with wrapped object. (success or failure)
  public func resolve(state: Result<Value>) {
    lock.lock()
    defer {
      self.lock.unlock()
    }
    guard nil == self.state else {
      print("Warning: Promise already resolved to \(self.state!)")
      return
    }
    self.state = state
  }
  
  /// Resolve promise to success with object
  ///
  /// - Parameter result: result object
  public func resolve(result: Value) {
    self.resolve(state: .success(value: result))
  }
  
  /// Resolve promise to failure with error
  ///
  /// - Parameter error: error
  public func resolve(error: Error) {
    self.resolve(state: .failure(error: error))
  }
}

//MARK: - Completion blocks
extension Promise {
  
  /**
   Provide completion block to be called when promise resolved to success state.
   Usefull for presenting results to user.
   Mutiple completion blocks can be chained.
   
   Completion block had to be executed on current queue.
   
   - Parameter handler: success handler with resolved parameter
   - Returns: self (discardable)
   */
  @discardableResult
  public func onSuccess(handler: @escaping (Value)->()) -> Promise<Value> {
    // If promise already completed
    lock.lock()
    defer {
      self.lock.unlock()
    }
    if let state = self.state {
      switch state {
      case .success(let value):
        handler(value)
        return self
      case .failure(_):
        return self
      }
    }
    let currentQueue = OperationQueue.current ?? OperationQueue.main
    callbacks.append { (state) -> () in
      if case .success(let result) = state {
        if OperationQueue.current != currentQueue {
          currentQueue.addOperation { handler(result) }
        } else {
          handler(result)
        }
      }
    }
    return self
    
  }
  
  /**
   Provide completion block to be called when promise resolved to error state.
   Usefull for presenting error message.
   Mutiple completion blocks can be chained.
   
   Completion block had to be executed on current queue.
   
   - Parameter handler: error handler with error parameter in it called in case of error
   - Returns: self (discardable)
   */
  @discardableResult
  public func onError(handler: @escaping (Error)->()) -> Promise<Value> {
    lock.lock()
    defer {
      self.lock.unlock()
    }
    if let state = self.state {
      switch state {
      case .success(_):
        return self
      case .failure(let error):
        handler(error)
        return self
      }
    }
    
    let currentQueue = OperationQueue.current ?? OperationQueue.main
    callbacks.append { (state) -> () in
      if case .failure(let error) = state {
        if OperationQueue.current != currentQueue {
          currentQueue.addOperation { handler(error) }
        } else {
          handler(error)
        }
      }
    }
    return self
  }
  
  /**
   Provide completion block to be called when promise resolved to any state.
   Usefull for changing activity indicator.
   Mutiple completion blocks can be chained.
   
   Completion block had to be executed on current queue.
   
   - Parameter handler: resolution handler with Result parameter.
   - Returns: self (discardable)
   */
  @discardableResult
  public func onComplete(handler: @escaping (Result<Value>)->()) -> Promise<Value> {
    lock.lock()
    defer {
      self.lock.unlock()
    }
    if let state = state {
      handler(state)
      return self
    }
    let currentQueue = OperationQueue.current ?? .main
    callbacks.append { (state) -> () in
      if OperationQueue.current != currentQueue {
        currentQueue.addOperation { handler(state) }
      } else {
        handler(state)
      }
    }
    return self
  }
}

//MARK: - Monads
extension Promise {
  
  /// Result map for simple convertion on result into another.
  /// Usable when sychronous convertion needed with different throwable calls.
  ///
  /// If self resolved to Error, promise created by this function will be resolved to same error automatically
  /// without invoking provided mapper
  ///
  /// - Parameter mapper: Generic mapper to convert one result into another, with possibility to throw an exception
  /// - Returns: Promise to return Generic object
  public func then<U>(mapper: @escaping ((Value) throws -> U)) -> Promise<U> {
    lock.lock()
    defer {
      self.lock.unlock()
    }
    let nextPromise = Promise<U>()
    let callback: Callback = { (state) -> () in
      switch state {
      case .success(let result):
        do {
          let mappedValue = try mapper(result)
          nextPromise.resolve(result: mappedValue)
        }
        catch {
          nextPromise.resolve(error: error)
        }
      case .failure(let error):  nextPromise.state = .failure(error: error)
      }
    }
    if let state = state {
      callback(state)
    }
    else {
      callbacks.append(callback)
    }
    return nextPromise
  }
  
  /// Result map for promise.
  /// Usable when synchronous code with complecated logic and and possible error combinations
  ///
  /// If self resolved to Error, promise created by this function will be resolved to same error automatically
  /// without invoking provided mapper
  ///
  /// - Parameter mapper: Generic mapper to convert current success value into new Result
  /// - Returns: Promise to return Generic object
  public func then<U>(mapper: @escaping ((Value) -> Result<U>)) -> Promise<U> {
    lock.lock()
    defer {
      self.lock.unlock()
    }

    let nextPromise = Promise<U>()
    let callback: Callback = { (state) -> () in
      switch state {
      case .success(let result): nextPromise.state = mapper(result)
      case .failure(let error):  nextPromise.state = .failure(error: error)
      }
    }
    if let state = state {
      callback(state)
    }
    else {
      callbacks.append(callback)
    }
    return nextPromise
  }
  
  //*promiseFlatMap
  /// Flat map for promise.
  /// Usable when asynchronous call needed
  ///
  /// If self resolved to Error, promise created by this function will be resolved to same error automatically
  /// without invoking provided mapper
  ///
  /// - Parameter mapper: Handler that had to return new promise based on successful resolution of current one
  /// - Returns: Promise to return Generic object.
  public func then<U>(mapper: @escaping ((Value) -> Promise<U>)) -> Promise<U> {
    lock.lock()
    defer {
      self.lock.unlock()
    }

    let nextPromise = Promise<U>()
    let callback: Callback = { (state) -> () in
      switch state {
      case .success(let result):
        _ = mapper(result)
          .onSuccess { (secondResult) in
            nextPromise.resolve(result: secondResult)
          }
          .onError{ (error) in
            nextPromise.resolve(error: error)
        }
        
      case .failure(let error):  nextPromise.state = .failure(error: error)
      }
    }
    if let state = state {
      callback(state)
    }
    else {
      callbacks.append(callback)
    }
    return nextPromise
  }
  
}
