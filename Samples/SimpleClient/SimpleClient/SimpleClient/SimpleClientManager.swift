//
//  SimpleClientManager.swift
//  SimpleClient
//
//  Created by Tae Hyun Na on 2018. 9. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import ObjectMapper

extension Notification.Name {
    static let SimpleClientManager  = Notification.Name("SimpleClientManagerNotificationName")
}

class SimpleClientManager: HJRestClientManager {
    
    static let shared = SimpleClientManager()
    
    override func name() -> String? {
        
        return Notification.Name.SimpleClientManager.rawValue
    }
    
    override func didStandby() {
        
        print("did stand by")
    }
    
    override func bodyFromRequestModel(_ requestModel:Any?) -> Data? {
        
        if let jsonModel = requestModel as? JSONModel {
            return jsonModel.toJSONData()
        } else if let jsonModel = requestModel as? Mappable, let jsonString = jsonModel.toJSONString() {
            return jsonString.data(using: .utf8)
        }
        
        return requestModel as? Data
    }
    
    override func contentTypeFromRequestModel(_ requestModel:Any?) -> String {
        
        if ((requestModel as? JSONModel) != nil) || ((requestModel as? Mappable) != nil) {
            return "application/json"
        }
        
        return "text/plain"
    }
    
    override func responseModel(fromData data: Data, serverAddress: String, endpoint: String?, requestModel: Any?, responseModelRefer: Any?) -> Any? {
        
        if let jsonModelClass = responseModelRefer as? JSONModel.Type {
            return try? jsonModelClass.init(data: data)
        } else if let jsonModelClass = responseModelRefer as? Mappable.Type, let jsonString = String(data: data, encoding:. utf8) {
            return jsonModelClass.init(JSONString: jsonString)
        }
        
        return data
    }
    
    override func responseData(fromModel model: Any, serverAddress: String, endpoint: String?, requestModel: Any?) -> Data? {
        
        if let jsonModel = model as? JSONModel {
            return jsonModel.toJSONData()
        } else if let jsonModel = model as? Mappable, let jsonString = jsonModel.toJSONString() {
            return jsonString.data(using: .utf8)
        }

        return model as? Data
    }
    
    override func didReceiveResponse(_ urlResponse:URLResponse) {
        
        print("did receive response")
    }
}

