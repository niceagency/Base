//
//  Pagination.swift
//  NABase
//
//  Created by Wain on 29/09/2016.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public protocol PaginatedContent {
    associatedtype ResourceItemType
    
    var  contents: ResourceItemType? { get }
    
    init(data: Data, contents: ResourceItemType?)
}

/**
Example of how pagination might be used as a wrapper around a resource
 
public extension Resource {
    typealias ResourceItemType = A
    
    public func paginated(from currentPage: PaginatedContent?) -> Resource<PaginatedContent> {
        let contentsParse = self.parse
        
        var query = self.query ?? []
        
        if let pagination = currentPage {
            query.append(URLQueryItem(name: "limit", value: "\(defaultPageLimit)"))
            query.append(URLQueryItem(name: "offset", value: "\(pagination.offset + pagination.limit)"))
        } else {
            query.append(URLQueryItem(name: "limit", value: "\(firstPageLimit)"))
            query.append(URLQueryItem(name: "offset", value: "\(0)"))
        }
        
        let resource = Resource<PaginatedContent>(endpoint: self.endpoint,
                                                  method: self.method,
                                                  query: query,
                                                  headerProvider: self.headerProvider,
                                                  errorResponseHandler: self.errorResponseHandler,
                                                  parse: { (data) -> (PaginatedContent?, Error?) in
                                                    let (contents, error) = contentsParse(data)
                                                    let pagination = PaginatedContent(data: data, contents: contents)
                                                    
                                                    return (pagination, error)
        })
        
        return resource
    }
 */
