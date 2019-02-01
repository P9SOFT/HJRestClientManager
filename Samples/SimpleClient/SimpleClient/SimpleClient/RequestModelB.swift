//
//  RequestModelB.swift
//  SimpleClient
//
//  Created by Tae Hyun Na on 2018. 9. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit
import ObjectMapper

class RequestModelB: Mappable {
    
    var a: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        a <- map["a"]
    }
}
