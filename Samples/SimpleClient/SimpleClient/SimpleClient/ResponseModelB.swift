//
//  ResponseModelB.swift
//  SimpleClient
//
//  Created by Tae Hyun Na on 2018. 9. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import ObjectMapper

class ResponseModelB: Mappable {
    
    var headers: [String:String]?
    var url: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        headers <- map["headers"]
        url     <- map["url"]
    }
}
