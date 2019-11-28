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
        HJRestClientManager.shared.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        HJRestClientManager.shared.addObserver(self, selector: #selector(self.restClientManagerNotificationHandler(notification:)))
        
        HJRestClientManager.shared.setDogma(SampleDogma(), forKey: "sampleDogma")
        HJRestClientManager.shared.defaultDogmaKey = "sampleDogma"
        
        HJRestClientManager.shared.setServerAddresses( ["postmanecho": "postman-echo.com"])
        HJRestClientManager.shared.defaultServerKey = "postmanecho"
        
        HJRestClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/post", forKey: "post")
        HJRestClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/get", forKey: "get")
        HJRestClientManager.shared.setApiWith(serverKey: "postmanecho", endpoint: "/put", forKey: "put")
        
        HJRestClientManager.shared.setReplaceComponents(["$0":""], forEndpoint: "/P9SOFT/$0")
        
        HJRestClientManager.shared.setDummyResponseHanlder({ (extraHeaders:[String : Any]?, requestModel:Any?) -> HJRestClientManager.ResponseNode? in
            let data = try? Data(contentsOf: Bundle.main.url(forResource: "dummy0", withExtension: "json")!)
            return HJRestClientManager.ResponseNode(httpCode: 200, allHeaderFields: [:], body: data)
        }, forServerAddress: "postman-echo.com", endpoint: "get", method: .get, responseDelayTime: 1.2)
        
 //       HJRestClientManager.shared.connectionPoolSize = 1
        
        HJResourceManager.default().setCipher(HJResourceCipherGzip(), forName: "gz")
        
        HJRestClientManager.shared.setCipher(name: "gz", forSharedDataKey: "test")
        HJRestClientManager.shared.setObserver(forSharedDataKey: "test")
        
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
        
    }
    
    @IBAction func testButtonTouchUpInside(_ sender: Any) {
        
//        guard let serverAddress = serverAddressTextField.text, serverAddress.count > 0 else {
//            return
//        }
        
//        let reqm = """
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
        
//        HJRestClientManager.shared.request(method: method, apiKey: "post", extraHeaders: nil, requestModel: reqm, responseModelRefer: ResponseModelB.self, modelDogmaKey: nil) { (result:[String : Any]?) -> [String : Any]? in
//            guard let result = result, let eventValue = result[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
//                return nil
//            }
//
//            switch event {
//            case .loadRemote :
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
        
        let reqZ = HJRestClientManager.RequestNode().get().apiKey("get").requestModel(["req":"z"]).responseModelRefer(ResponseModelA.self)
        
        let reqA = HJRestClientManager.RequestNode().get().apiKey("get").requestModel(reqm).responseModelRefer(ResponseModelA.self).completionHandler { (result:[String : Any]?) -> [String : Any]? in
            print("reqA responsed")
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelA, let url = responseModel.url {
                print("reqA response url \(url)")
            }
            return nil
        }

        let reqB = HJRestClientManager.RequestNode().post().apiKey("post").responseModelRefer(ResponseModelB.self).requestModelFromResultHandler { (result:[String : Any]?) -> Any? in
            print("reqB responsed")
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelA, let url = responseModel.url {
                let reqm = RequestModelA()
                reqm.a = url
                return reqm
            }
            return nil
        }

        let reqC = HJRestClientManager.RequestNode().put().apiKey("put").responseModelRefer(ResponseModelB.self).updateCache(true).requestModelFromResultHandler { (result:[String : Any]?) -> Any? in
            print("reqC responsed")
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelB, let url = responseModel.url {
                return ["a":url]
            }
            return nil
        }

        let reqL = HJRestClientManager.RequestNode().localRequest(name: "local job") { (result:[String : Any]?) -> Any? in
            print("reqL responsed")
            return result?[HJRestClientManager.NotificationResponseModel]
        }

        let reqX = HJRestClientManager.RequestNode().get().apiKey("post").requestModel(reqm).responseModelRefer(ResponseModelA.self).completionHandler { (result:[String : Any]?) -> [String : Any]? in
            print("reqX responsed")
            return nil
        }

        let reqList = [reqZ, reqB, reqA, reqL, reqC, reqX]
        HJRestClientManager.shared.requestConcurrent(reqList, callIdentifier: nil) { (result:[String : Any]?) -> [String : Any]? in
//        HJRestClientManager.shared.requestSerial(reqList, callIdentifier: nil, stopWhenFailed: true) { (result:[String : Any]?) -> [String : Any]? in

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

        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            HJRestClientManager.shared.setShared(data: "hello, world!", forKey: "test")
            DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                HJRestClientManager.shared.removeSharedData(forKey: "test")
            })
        }
        
        HJRestClientManager.request().endpoint("/get").requestModel(["Hello":"World!"]).responseModelRefer(ResponseModelA.self).resume { (result:[String : Any]?) -> [String : Any]? in
            print("gotta simple")
            return nil
        }
        
        HJRestClientManager.request().endpoint("/get").requestModel(["HI":"HO"]).responseModelRefer(ResponseModelA.self).resume { (result:[String : Any]?) -> [String : Any]? in
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? ResponseModelA, let url = responseModel.url {
                print("dummy response url \(url)")
            }
            return nil
        }
        
        HJRestClientManager.request().serverAddress("https://github.com").endpoint("/P9SOFT/$0").requestModel(["$0":"HJRestClientManager"]).resume { (result:[String : Any]?) -> [String : Any]? in
            if let responseModel = result?[HJRestClientManager.NotificationResponseModel] as? Data {
                let s = String.init(data: responseModel, encoding: .utf8) ?? ""
                print("response string is \(s)")
            }
            return nil
        }
    }
    
    @objc func restClientManagerNotificationHandler(notification:Notification) {
        
        guard let userInfo = notification.userInfo, let eventValue = userInfo[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
            return
        }
        
        print("gotta \(event.rawValue)")
        
        switch event {
        case .updateSharedData :
            if let key = userInfo[HJRestClientManager.NotificationSharedDataKey] as? String, let s = userInfo[HJRestClientManager.NotificationSharedDataModel] as? String {
                print("shared data key \(key) updated : \(s)")
            }
        case .removeSharedData :
            if let key = userInfo[HJRestClientManager.NotificationSharedDataKey] as? String {
                print("shared data key \(key) removed")
            }
        default :
            break
        }
    }
}
