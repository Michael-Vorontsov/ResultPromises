//
//  URLSession+Promises.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Enum of most possible errors
 */
public enum NetworkError: Error {
  case request
  case network(error: Error?)
  case deserilisation(error: Error?)
  case missedData
  case wrongData
  case http(code: Int)
  case other(error: Error)
}

extension URLSession {
  
  public func fetch(from request: URLRequest) -> Promise<(Data?, HTTPURLResponse)> {
    let promise = Promise<(Data?, HTTPURLResponse)>()
    self.dataTask(with: request) { (data, response, error) in
      guard error == nil else {
        promise.resolve(error: NetworkError.network(error: error))
        return
      }
      // If network code in `success` range
      guard let response = response as? HTTPURLResponse else {
        promise.resolve(error: NetworkError.missedData)
        return
      }
      promise.resolve(result: (data, response))
    }.resume()
    return promise
  }
  
  /**
   Fetch general data using request.
  */
  public func fetchData(from request: URLRequest) -> Promise<Data> {
    return self.fetch(from: request).then { (data, response) -> Data in
      guard (200 ... 299 ~= response.statusCode) else {
        throw NetworkError.http(code: response.statusCode)
      }
      
      guard let data = data, data.count > 0 else {
          throw NetworkError.missedData
      }
      return data
    }
  }
  
  /**
   Generic function for Fetching JSON data and converting it into expected object
   */
  public func fetchRESTObject<O: Decodable>(from request: URLRequest, decoder: JSONDecoder = JSONDecoder()) -> Promise<O> {
    return fetchData(from: request).then{ (data) -> O in
      do {
        return try decoder.decode(O.self, from: data)
      } catch {
        throw NetworkError.deserilisation(error: error)
      }
    }
  }
  
}
