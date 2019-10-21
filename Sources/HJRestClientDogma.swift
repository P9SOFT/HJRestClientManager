//
//  HJRestClientDogma.swift
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2019. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import Foundation

@objc public protocol HJRestClientDogma {
    
    @objc func bodyFromRequestModel(_ requestModel:Any?) -> Data?
    @objc func contentTypeFromRequestModel(_ requestModel:Any?) -> String?
    @objc func responseModel(fromData data:Data, serverAddress:String, endpoint:String?, contentType:String?, requestModel:Any?, responseModelRefer:Any?) -> Any?
    @objc func responseData(fromModel model:Any, serverAddress:String, endpoint:String?, requestModel:Any?) -> Data?
    @objc func didReceiveResponse(response:URLResponse, serverAddress:String, endpoint:String?)
}

class HJRestClientDefaultDogma: HJRestClientDogma {
    
    func bodyFromRequestModel(_ requestModel:Any?) -> Data? {
        
        switch requestModel {
        case is Data? :
            return requestModel as? Data
        case is String? :
            return (requestModel as? String)?.data(using: .utf8)
        default :
            break
        }
        return nil
    }
    
    func contentTypeFromRequestModel(_ requestModel:Any?) -> String? {
        
        switch requestModel {
        case is Data? :
            return "application/octet-stream"
        case is String? :
            return "application/json"
        default :
            break
        }
        return nil
    }
    
    func responseModel(fromData data: Data, serverAddress: String, endpoint: String?, contentType:String?, requestModel: Any?, responseModelRefer: Any?) -> Any? {
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
            return jsonObject
        }
        return data
    }
    
    func responseData(fromModel model: Any, serverAddress: String, endpoint: String?, requestModel: Any?) -> Data? {
        
        if ((model as? [String:Any]) != nil) || ((model as? [Any]) != nil) {
            if let data = try? JSONSerialization.data(withJSONObject: model, options: []) {
                return data
            }
        }
        return model as? Data
    }
    
    func didReceiveResponse(response:URLResponse, serverAddress:String, endpoint:String?) {
    }
}
