//
//  ViewController.swift
//  SimpleClient
//
//  Created by Tae Hyun Na on 2018. 9. 11.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var serverAddressTextField: UITextField!
    @IBOutlet weak var methodGetButton: UIButton!
    @IBOutlet weak var methodPostButton: UIButton!
    @IBOutlet weak var methodPutButton: UIButton!
    @IBOutlet weak var methodDeleteButton: UIButton!
    @IBOutlet weak var endpointTextField: UITextField!
    @IBOutlet weak var requestHeaderTextView: UITextView!
    @IBOutlet weak var requestParameterTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var responseHeaderTextView: UITextView!
    @IBOutlet weak var responseBodyTextView: UITextView!
    
    var method:HJHttpApiExecutorHttpMethodType = .get {
        didSet {
            methodGetButton.isSelected = (method == .get)
            methodPostButton.isSelected = (method == .post)
            methodPutButton.isSelected = (method == .put)
            methodDeleteButton.isSelected = (method == .delete)
        }
    }
    
    deinit {
        SimpleClientManager.shared.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        SimpleClientManager.shared.addObserver(self, selector: #selector(self.simpleClientManagerNotificationHandler(notification:)))
        SimpleClientManager.shared.setServerAddresses( ["postmanecho": "postman-echo.com"])
        SimpleClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/post", forKey: "post")
        SimpleClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/get", forKey: "get")
        SimpleClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/put", forKey: "put")
        
        SimpleClientManager.shared.setPreProcessBlock({ (requestModel, responseModel) -> Any? in
            print("#### API get pre process done.")
            return responseModel
        }, forApiKeys: ["get"])
        
        SimpleClientManager.shared.setPostProcessBlock({ (requestModel, responseModel) in
            if let res = responseModel as? ResponseModelB {
                print("#### API post got url \(res.url ?? "-")" )
            }
        }, forApiKeys: ["post"])
        
        method = .get
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func methodButtonTouchUpInside(_ sender: UIButton) {
        
        switch sender {
        case methodGetButton :
            method = .get
        case methodPostButton :
            method = .post
        case methodPutButton :
            method = .put
        case methodDeleteButton :
            method = .delete
        default :
            break
        }
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender: Any) {
        
//        guard let serverAddress = serverAddressTextField.text, serverAddress.count > 0 else {
//            return
//        }
        
//        let body = """
//                   <?xml version = \"1.0\"?>
//                   <SOAP-ENV:Envelope
//                   xmlns:SOAP-ENV = \"http://www.w3.org/2001/12/soap-envelope\"
//                   SOAP-ENV:encodingStyle = \"http://www.w3.org/2001/12/soap-encoding\">
//                   <SOAP-ENV:Body xmlns:m = \"http://www.xyz.org/quotations\">
//                   <m:GetQuotation>
//                   <m:QuotationsName>MiscroSoft</m:QuotationsName>
//                   </m:GetQuotation>
//                   </SOAP-ENV:Body>
//                   </SOAP-ENV:Envelope>
//                   """.data(using: .utf8)
//        let contentType = "text/xml; application/soap+xml; charset=utf-8"
        
        let reqm = ["a":1]
//        let reqm = RequestModelA()
//        reqm.a = "x"
//        let reqm = RequestModelB(JSONString: "{\"a\":\"x\"}")
        
//        SimpleClientManager.shared.request(method: method, apiKey: "post", requestModel: reqm, responseModelRefer: ResponseModelB.self) { (result:[String : Any]?) -> [String : Any]? in
//
        //            guard let result = result, let eventValue = result[HJRestClientManager.NotificationEvent] as? Int, let evnet = HJRestClientManager.Event(rawValue: eventValue) else {
//                return nil
//            }
//
//            switch event {
//            case .loadRemote, .loadCache :
//                var text:String = ""
//                if let httpStatus = result[HJRestClientManager.NotificationHttpStatus] as? Int {
//                    text = "HTTP STATUS \(httpStatus)"
//                }
//                if let headers = result[HJRestClientManager.NotificationHttpHeaders] as? [AnyHashable : Any] {
//                    headers.forEach({ (key, value) in
//                        if text.count > 0 {
//                            text += "\n"
//                        }
//                        text += "\(key) : \(value)"
//                    })
//                }
//                self.responseHeaderTextView.text = text
//                if let responseModelA = result[HJRestClientManager.NotificationResponseModel] as? ResponseModelA {
//                    self.responseBodyTextView.text = responseModelA.toJSONString()
//                } else if let responseModelB = result[HJRestClientManager.NotificationResponseModel] as? ResponseModelB {
//                    self.responseBodyTextView.text = responseModelB.toJSONString()
//                }
//                break
//            case .loadSkip :
//                break
//            case .failInternalError, .failNetworkError, .failServerUnathorized, .failServerUnavailable :
//                break
//            default :
//                break
//            }
//
//            return nil
//        }
        
        let reqA = SimpleClientManager.RequestNode(method: .get, apiKey: "get", requestModel: reqm, responseModelRefer: ResponseModelA.self, updateCache: false) { (result:[String : Any]?) -> [String : Any]? in
            print("done reqA")
            return nil
        }
        
//        let reqB = SimpleClientManager.Request(method: .post, apiKey: "post", requestModel: reqm, responseModelRefer: ResponseModelB.self, updateCache: false) { (result:[String : Any]?) -> [String : Any]? in
//            print("done reqB")
//            return nil
//        }
//        let reqC = SimpleClientManager.Request(method: .put, apiKey: "put", requestModel: reqm, responseModelRefer: ResponseModelB.self, updateCache: false) { (result:[String : Any]?) -> [String : Any]? in
//            print("done reqC")
//            return nil
//        }
        
        let reqB = SimpleClientManager.RequestNode(method: .post, apiKey: "post", requestModelFromResultHandler: { (result:[String : Any]?) -> Any? in
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelA, let url = responseModel.url {
                let reqm = RequestModelA()
                reqm.a = url
                return reqm
            }
            return nil
        }, responseModelRefer: ResponseModelB.self, updateCache: false, completion: nil)

        let reqC = SimpleClientManager.RequestNode(method: .put, apiKey: "put", requestModelFromResultHandler: { (result:[String : Any]?) -> Any? in
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelB, let url = responseModel.url {
                return ["a":url]
            }
            return nil
        }, responseModelRefer: ResponseModelB.self, updateCache: true, completion: nil)
        
        let reqL = SimpleClientManager.RequestNode(requestName: "local job") { (result:[String : Any]?) -> Any? in
            print("local job done.")
            return result?[HJRestClientManager.NotificationResponseModel]
        }

        let reqX = SimpleClientManager.RequestNode(method: .get, apiKey: "post", requestModel: reqm, responseModelRefer: ResponseModelA.self, updateCache: false) { (result:[String : Any]?) -> [String : Any]? in
            print("done reqX")
            return nil
        }
        
        let reqList = [reqA, reqB, reqL, reqC, reqX]
//        SimpleClientManager.shared.requestConcurrent(reqList, callIdentifier: nil) { (result:[String : Any]?) -> [String : Any]? in
        SimpleClientManager.shared.requestSerial(reqList, callIdentifier: nil, stopWhenFailed: true) { (result:[String : Any]?) -> [String : Any]? in

            guard let result = result, let eventValue = result[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
                return nil
            }

            switch event {
            case .doneRequestGroup :
                let stopped = result[HJRestClientManager.NotificationRequestGroupStopped] as? Bool ?? false
                if stopped == true {
                    print("request group stopped")
                }
                if let results = result[HJRestClientManager.NotificationRequestGroupResults] as? [[String:Any]] {
                    for res in results {
                        if res[HJRestClientManager.NotificationResponseModel] == nil {
                            print("request have no response.")
                        }
                    }
                    print("all group req done.")
                } else {
                    print("something wrong in group!")
                }
            default :
                break
            }
            return nil
        }
        
        SimpleClientManager.shared.setObserver(forSharedDataKey: "test")

        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            SimpleClientManager.shared.setShared(data: true, forKey: "test")
            DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                SimpleClientManager.shared.removeSharedData(forKey: "test")
            })
        }
    }
    
    @objc func simpleClientManagerNotificationHandler(notification:Notification) {
        
        guard let userInfo = notification.userInfo, let eventValue = userInfo[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
            return
        }
        
        print("gotta \(event.rawValue)")
    }
}

