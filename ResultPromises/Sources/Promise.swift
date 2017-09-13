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
  /**
   Resolve promise with Result wrapper
   */
  public func resolve(state: Result<Value>) {
    guard nil == self.state else {
      print("Warning: Promise already resolved to \(self.state!)")
      return
    }
    self.state = state
  }
  
  /**
   Resolve promise with success state
   */
  public func resolve(result: Value) {
    self.resolve(state: .success(value: result))
  }
  
  /**
   Resolve promise with error
   */
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
   */
  @discardableResult
  public func onSuccess(handler: @escaping (Value)->()) -> Promise<Value> {
    // If promise already completed
    
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
   */
  @discardableResult
  public func onError(handler: @escaping (Error)->()) -> Promise<Value> {
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
   */
  @discardableResult
  public func onComplete(handler: @escaping (Result<Value>)->()) -> Promise<Value> {
    if let state = state {
      handler(state)
      return self
    }
    let currentQueue = OperationQueue.current ?? .main
    callbacks.append { (state) -> () in
      if OperationQueue.current != currentQueue {
        currentQueue.addOperation { handler(state) }
      } else {x
        handler(state)
      }
    }
    return self
  }
}

//MARK: - Monads
extension Promise {
  
  //*map
  public func then<U>(mapper: @escaping ((Value) throws -> U)) -> Promise<U> {
    let nextPromise = Promise<U>()
    callbacks.append { (state) -> () in
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
    return nextPromise
  }
  
  //*stateFlatMap
  public func then<U>(mapper: @escaping ((Value) -> Result<U>)) -> Promise<U> {
    let nextPromise = Promise<U>()
    callbacks.append { (state) -> () in
      switch state {
      case .success(let result): nextPromise.state = mapper(result)
      case .failure(let error):  nextPromise.state = .failure(error: error)
      }
    }
    return nextPromise
  }
  
  //*promiseFlatMap
  public func then<U>(mapper: @escaping ((Value) -> Promise<U>)) -> Promise<U> {
    let nextPromise = Promise<U>()
    callbacks.append { (state) -> () in
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
    return nextPromise
  }
  
}
