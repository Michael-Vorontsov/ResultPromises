//
//  URLRequest+Promises.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Usable HTTP methods
 */
public enum HttpMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

public enum RequestsError: Error {
  case URLGeneration
  case serialization
  case toBeDone // Functionality not implemented yet
}

extension URLRequest {
  /**
   Generate request asynchronously.
   Can be useful if big data had be serialized
 */
  public static func requestFor(
    path: String,
    method: HttpMethod = .get,
    parameters: [String : Any]? = nil,
    headers: [String : String]? = nil,
    dispatchQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
  ) -> Promise<URLRequest> {
  
    let promise = Promise<URLRequest>()
    // Can depends on data and parameters, so better to run at background
    dispatchQueue.async {
      guard
        let url = URL(string: path)
        else {
          return promise.resolve(error: RequestsError.URLGeneration)
      }

      var request = URLRequest(url: url)
      request.httpMethod = method.rawValue
      
      if let headers = headers {
        for (key, value) in headers {
          request.addValue(value, forHTTPHeaderField: key)
        }
      }
      
      if let parameters = parameters {
        switch method {
        case .post, .put:
          guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            return promise.resolve(error: RequestsError.serialization)
          }
          request.httpBody = body
          
        case .get, .delete:
          // TODO: Implement
          return promise.resolve(error: RequestsError.toBeDone)
        }
      }
      promise.resolve(result: request)
    }
    return promise
  }
}
