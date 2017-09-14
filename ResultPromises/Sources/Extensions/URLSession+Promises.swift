//
//  URLSession+Promises.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/8/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/// Enum of most possible errors
///
/// - request: Request related errors
/// - network: Errors related to executing network request by URLSession. Original error embedded, if available.
/// - deserialisation: Errors related to converting Data into Decodable object. Original error embedded, if available.
/// - missedData: Expected raw data is empty.
/// - http: Server answer code is out of Success range (200...299) Original network code embedded.
/// - other: Wrapper for all other Errors.
public enum NetworkError: Error {
  case request
  case network(error: Error?)
  case deserialisation(error: Error?)
  case missedData
  case http(code: Int)
  case other(error: Error)
}

extension URLSession {
  
  /// Fetch raw data and URL response
  ///
  /// - Parameter request: URL request. Can be URLRequest, URL or even Path
  /// - Returns: Promise to fetch optional Data and HTTPResponse
  public func fetch(from request: URLRequestable) -> Promise<(Data?, HTTPURLResponse)> {
    let promise = Promise<(Data?, HTTPURLResponse)>()
    guard let request = request.urlRequest() else {
      promise.resolve(error: NetworkError.request)
      return promise
    }
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
  
  /// Fetch raw data from URL request.
  ///
  /// - Parameter request: URL request. Can be URLRequest, URL or even Path
  /// - Returns: Promise to fetch raw Data from network
  public func fetchData(from request: URLRequestable) -> Promise<Data> {
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
  
  /// Fetching JSON data and converting it into expected object
  ///
  /// - Parameters:
  ///   - request: URL requestable. Can be URLRequest, URL or even Path
  ///   - decoder: decoder (additional setup can be required), Standard JSONDecoder by default
  /// - Returns: Promise to fetch decodable object
  public func fetchRESTObject<O: Decodable>(from request: URLRequestable, decoder: JSONDecoder = JSONDecoder()) -> Promise<O> {
    return fetchData(from: request).then{ (data) -> O in
      do {
        return try decoder.decode(O.self, from: data)
      } catch {
        throw NetworkError.deserialisation(error: error)
      }
    }
  }
  
}
