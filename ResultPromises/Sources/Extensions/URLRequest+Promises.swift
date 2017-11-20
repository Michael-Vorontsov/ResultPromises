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
    // FIXME: Implement support for additional methods
}

public enum RequestsError: Error {
  case URLGeneration
  case serialization
  case toBeDone // Functionality not implemented yet
}

extension String {
  /**
   Helper to provide allowed characters for URL path encoding
   */
  func httpEncodedString() -> String {
    let generalDelimitersToEncode = ":#[]@"
    let subDelimitersToEncode = "!$&'()*+,;="
    // does not include "?" or "/" due to RFC 3986 - Section 3.4
    var allowedCharacterSet = CharacterSet.urlQueryAllowed
    allowedCharacterSet.remove(charactersIn: generalDelimitersToEncode)
    allowedCharacterSet.remove(charactersIn: subDelimitersToEncode)
    return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? self
  }
}

extension URLRequest {

  ///  Generate request asynchronously.
  /// Can be useful if big data had be serialized
  ///
  /// - Parameters:
  ///   - path: full remote path
  ///   - method: http method (GET, POST, PUT etc.)
  ///   - parameters: Dictionary of parameters
  ///   - headers: Dictionary of Headers
  ///   - dispatchQueue: queue for performing request into
  /// - Returns: Promise for generating URL request shcduled for in BG thread
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
      
      if let parameters = parameters, parameters.count > 0 {
        switch method {
        case .post, .put:
          // Add parameters as JSON in body
          guard let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            return promise.resolve(error: RequestsError.serialization)
          }
          request.httpBody = body
          
        case .get, .delete:
          // Add parameters to URL
          var parametersString = path.contains("?") ? "&" : "?"

          for (key, value) in parameters {
            parametersString.append("\(key.httpEncodedString())=\(String(describing: value).httpEncodedString())&")
          }
          parametersString.removeLast()
          if let extendedURL = URL(string: path + parametersString) {
            request.url = extendedURL
          }
        }
      }
      promise.resolve(result: request)
    }
    return promise
  }
}
