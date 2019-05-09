//
//  SampleDogma.swift
//  SimpleClient
//
//  Created by Tae Hyun Na on 2019. 5. 2.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import ObjectMapper

class SampleDogma: HJRestClientDogma {
    
    fileprivate func modelFromObject(object:[String:Any], responseModelRefer: Any?) -> Any? {
        
        if let jsonModelClass = responseModelRefer as? JSONModel.Type {
            if let model = try? jsonModelClass.init(dictionary: object) {
                return model
            }
        } else if let jsonModelClass = responseModelRefer as? Mappable.Type {
            if let model = jsonModelClass.init(JSON: object) {
                return model
            }
        }
        return object
    }
    
    func bodyFromRequestModel(_ requestModel:Any?) -> Data? {
        
        if let jsonModel = requestModel as? JSONModel {
            return jsonModel.toJSONData()
        } else if let jsonModel = requestModel as? Mappable, let jsonString = jsonModel.toJSONString() {
            return jsonString.data(using: .utf8)
        }
        
        return requestModel as? Data
    }
    
    func contentTypeFromRequestModel(_ requestModel:Any?) -> String? {
        
        if ((requestModel as? JSONModel) != nil) || ((requestModel as? Mappable) != nil) {
            return "application/json"
        }
        
        return "application/octet-stream"
    }
    
    func responseModel(fromData data: Data, serverAddress: String, endpoint: String?, contentType:String?, requestModel: Any?, responseModelRefer: Any?) -> Any? {
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        
        if let list = jsonObject as? [Any] {
            var modelList:[Any] = []
            for item in list {
                if let item = item as? [String:Any], let model = modelFromObject(object: item, responseModelRefer: responseModelRefer) {
                    modelList.append(model)
                }
            }
            return modelList
        }
        if let item = jsonObject as? [String:Any] {
            return modelFromObject(object: item, responseModelRefer: responseModelRefer)
        }
        
        return data
    }
    
    func responseData(fromModel model: Any, serverAddress: String, endpoint: String?, requestModel: Any?) -> Data? {
        
        if let jsonModel = model as? JSONModel {
            return jsonModel.toJSONData()
        } else if let jsonModel = model as? Mappable, let jsonString = jsonModel.toJSONString() {
            return jsonString.data(using: .utf8)
        }
        
        return model as? Data
    }
}
