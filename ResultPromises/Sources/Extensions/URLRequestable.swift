//
//  URLRequestable.swift
//  ResultPromises
//
//  Created by Mykhailo Vorontsov on 9/14/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation


/**
 Helper protocol. Allows to unify entities that can be converted into URL request
 such as URLRequest, URL or even String
 */
public protocol URLRequestable {
  func urlRequest() -> URLRequest?
}

extension URLRequest: URLRequestable {
  public func urlRequest() -> URLRequest? {
    return self
  }
}

extension URL: URLRequestable {
  public func urlRequest() -> URLRequest? {
    return URLRequest(url: self)
  }
}

extension String: URLRequestable {
  public func urlRequest() -> URLRequest? {
    var resolvedPath = self
    if !self.contains("://") {
      resolvedPath = "https://" + resolvedPath
    }
    return URL(string: resolvedPath)?.urlRequest()
  }
}

extension NSString: URLRequestable {
  public func urlRequest() -> URLRequest? {
    return String(self).urlRequest()
  }
}
