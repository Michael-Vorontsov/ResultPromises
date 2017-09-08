//
//  Result.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Wrapper for results async functions with possible error
 */
public enum Result<T> {
  case success(value: T)
  case failure(error: Error)
}

public extension Result {
  //* Allows to use results wrappers as Monads, to unite them in mapping chain
  public func map<U>(mapper: (T)->U) -> Result<U> {
    switch self {
    case .success(let result): return .success(value: mapper(result))
    case .failure(let error): return .failure(error: error)
    }
  }
  //* Allows to use results wrappers as Monads, to unite them in mapping chain
  public func flatMap<U>(mapper: (T)->Result<U>) -> Result<U> {
    switch self {
    case .success(let result): return mapper(result)
    case .failure(let error): return .failure(error: error)
    }
  }
  
  //* Unwrap result, producing result if available or throwing error otherwise
  public func resolve() throws -> T {
    switch self {
    case .success(let result): return result
    case .failure(let error): throw(error)
    }
  }
}
