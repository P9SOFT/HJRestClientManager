//
//  HJRestClientExecutor.swift
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2015. 12. 7.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import Foundation
#if canImport(HJHttpApiExecutor)
import HJHttpApiExecutor
#endif

class HJRestClientExecutor: HJHttpApiExecutor {
    
    enum Parameter: String {
        case serverAddress
        case endpoint
        case httpMethod
        case headers
        case parameters
        case postContentType
        case customBody
        case customConentType
        case receivedContentType
        case receivedData
        case callIdentifier
        case updateCache
        case completionBlock
        case responseModelRefer
        case dogma
    }
    
    var replacePathComponentsForEndpoints:[String:[String:String]] = [:]
    var autoSettingHeaders:[String:String] = [:]
    var timeoutInterval:TimeInterval = 8
    var limiterCount:Int = 0
    
    override func name() -> String? {
        
        return "HJRestClientExecutorName"
    }
    
    override func timeoutInterval(fromQuery anQuery: Any?) -> TimeInterval {
        
        return timeoutInterval
    }
    
    override func activeLimiterName() -> String? {
        
        return self.name()
    }
    
    override func activeLimiterCount() -> Int {
        
        return limiterCount
    }
    
    override func apiUrl(fromQuery anQuery:Any?) -> String? {
        
        guard let anQuery = anQuery as? HYQuery, let serverAddress = anQuery.parameter(forKey: Parameter.serverAddress.rawValue) as? String, serverAddress.count > 0 else {
            return nil
        }
        
        var apiUrlString = (serverAddress.hasPrefix("http://") || serverAddress.hasPrefix("https://")) ? serverAddress : "http://\(serverAddress)"
        
        if let endpointString = anQuery.parameter(forKey: Parameter.endpoint.rawValue) as? String, endpointString.count > 0, let last = apiUrlString.last {
            var postfix = endpointString
            if last == "/" {
                if endpointString.hasPrefix("/") == true {
                    postfix = String(endpointString.dropFirst())
                }
            } else {
                if endpointString.hasPrefix("/") == false {
                    postfix = "/\(endpointString)"
                }
            }
            apiUrlString += postfix
            if let replacePathCompoents = replacePathComponentsForEndpoints[endpointString], let parameters = anQuery.parameter(forKey: HJRestClientExecutor.Parameter.parameters.rawValue) as? [String:Any] {
                replacePathCompoents.forEach { (key, value) in
                    if let replaceValue = parameters[key] as? String {
                        apiUrlString = apiUrlString.replacingOccurrences(of: key, with: replaceValue)
                    } else {
                        apiUrlString = apiUrlString.replacingOccurrences(of: "/\(key)", with:value)
                    }
                }
            }
        }
        
        return apiUrlString
    }
    
    override func isUsingCustomBody(forQuery anQuery: Any?) -> Bool {
        
        guard let anQuery = anQuery as? HYQuery else {
            return false
        }
        
        return (anQuery.parameter(forKey: HJRestClientExecutor.Parameter.customBody.rawValue) != nil)
    }
    
    override func apiParameter(fromQuery anQuery:Any?) -> [AnyHashable: Any]? {
        
        guard let anQuery = anQuery as? HYQuery else {
            return nil
        }
        
        var paramDict:[String:Any] = [:]
        
        if let parameters = anQuery.parameter(forKey: HJRestClientExecutor.Parameter.parameters.rawValue) as? [String:Any] {
            parameters.forEach { (key, value) in
                paramDict[key] = value
            }
        }
        if let endpoint = anQuery.parameter(forKey: HJRestClientExecutor.Parameter.endpoint.rawValue) as? String, let replacePathCompoents = replacePathComponentsForEndpoints[endpoint] {
            replacePathCompoents.forEach { (key, value) in
                paramDict.removeValue(forKey: key)
            }
        }
        
        return (paramDict.count > 0) ? paramDict : nil
    }
    
    override func customBody(fromQuery anQuery: Any?) -> Data? {
        
        guard let anQuery = anQuery as? HYQuery else {
            return nil
        }
        
        return anQuery.parameter(forKey: HJRestClientExecutor.Parameter.customBody.rawValue) as? Data
    }
    
    override func contentTypeForCustomBody(fromQuery anQuery: Any?) -> String? {
        
        guard let anQuery = anQuery as? HYQuery else {
            return nil
        }
        
        return anQuery.parameter(forKey: HJRestClientExecutor.Parameter.customConentType.rawValue) as? String ?? "text/plain"
    }
    
    override func httpMethodType(_ anQuery:Any?) -> HJHttpApiExecutorHttpMethodType {
        
        if let anQuery = anQuery as? HYQuery, let httpMethod = anQuery.parameter(forKey: HJRestClientExecutor.Parameter.httpMethod.rawValue) as? HJHttpApiExecutorHttpMethodType {
            return httpMethod
        }
        
        return .get
    }
    
    override func additionalSetup(with deliverer:HJAsyncHttpDeliverer?, fromQuery anQuery:Any?) -> Bool {
        
        guard let deliverer = deliverer, let anQuery = anQuery as? HYQuery else {
            return true
        }
        
        autoSettingHeaders.forEach { (key, value) in
            deliverer.setValue(value, forHeaderField:key)
        }
        if let headers = anQuery.parameter(forKey: HJRestClientExecutor.Parameter.headers.rawValue) as? [String:String] {
            headers.forEach { (key, value) in
                deliverer.setValue(value, forHeaderField:key)
            }
        }
        deliverer.cachePolicy = .reloadIgnoringLocalCacheData
        
        return true
    }
    
    override func postContentType(fromQuery anQuery:Any?) -> HJAsyncHttpDelivererPostContentType {
        
        if let queryObject = anQuery as? HYQuery, let contentType = queryObject.parameter(forKey: HJRestClientExecutor.Parameter.postContentType.rawValue) as? HJAsyncHttpDelivererPostContentType {
            return contentType
        }
        return .applicationJson
    }
    
    override func receiveBodyType(fromQuery anQuery:Any?) -> HJHttpApiExecutorReceiveBodyType {
        
        if let queryObject = anQuery as? HYQuery, let response = queryObject.parameter(forKey: HJAsyncHttpDelivererParameterKeyResponse) as? HTTPURLResponse {
            if let contentType = response.allHeaderFields["Content-Type"] as? String {
                queryObject.setParameter(contentType, forKey: HJRestClientExecutor.Parameter.receivedContentType.rawValue)
            }
        }
        return .custom
    }
    
    override func object(from data: NSMutableData?, fromQuery anQuery: Any?) -> Any? {
        
        guard let _ = anQuery as? HYQuery else {
            return nil
        }
        
        return data
    }
    
    override func appendResultParameter(toQuery anQuery:Any?, withParsedObject parsedObject:Any?) -> Bool {
        
        if let queryObject = anQuery as? HYQuery, let parsedObject = parsedObject {
            queryObject.setParameter(parsedObject, forKey:HJRestClientExecutor.Parameter.receivedData.rawValue)
        }
        
        return true
    }
}
