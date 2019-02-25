//
//  HJRestClientManager.swift
//  Hydra Jelly Box
//
//  Created by Tae Hyun Na on 2015. 12. 7.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import Foundation
import CommonCrypto
#if canImport(Hydra)
import Hydra
#endif
#if canImport(HJResourceManager)
import HJResourceManager
#endif
#if canImport(HJHttpApiExecutor)
import HJHttpApiExecutor
#endif

/*!
 @abstract Notification name of HJRestClientManager.
 */
extension Notification.Name {
    static let HJRestClientManager  = Notification.Name("HJRestClientManagerNotificationName")
}
@objc extension NSNotification {
    public static let HJRestClientManager = Notification.Name.HJRestClientManager
}

public typealias HJRestClientPreProcessBlock = (_ requestModel:Any?, _ responseModel:Any?) -> Any?
public typealias HJRestClientPostProcessBlock = (_ requestModel:Any?, _ responseModel:Any?) -> Void
public typealias HJRestClientCompletionBlock = @convention(block) (_ resultDict:[String:Any]?) -> [String:Any]?
public typealias HJRestClientRequestModelFromResultBlock = (_ resultDict:[String:Any]?) -> Any?

public typealias HJRestClientBodyFromRequestModelBlock = (_ requestModel:Any?) -> Data?
public typealias HJRestClientContentTypeFromRequestModelBlock = (_ requestModel:Any?) -> String
public typealias HJRestClientResponseModelFromDataBlock = (_ data:Data, _ serverAddress:String, _ endpoint:String?, _ requestModel:Any?, _ responseModelRefer:Any?) -> Any?
public typealias HJRestClientResponseDataFromModelBlock = (_ model:Any, _ serverAddress:String, _ endpoint:String?, _ requestModel:Any?) -> Data?
public typealias HJRestClientDidReceiveResponseBlock = (_ urlResponse:URLResponse) -> Void

open class HJRestClientManager : HYManager {
    
    fileprivate enum InterestedHttpStatus:Int {
        case dontcareJustLikeError = 0
        case ok = 200
        case notModified = 304
        case serviceUnavailable = 503
        case unauthorized = 401
    }
    
    fileprivate enum InterestedHeaderName:String {
        case etag = "Etag"
        case ifNoneMatch = "If-None-Match"
        case cacheControl = "Cache-Control"
    }
    
    @objc public static let NotificationEvent = "HJRestClientManagerNotificationEvent"
    @objc public static let NotificationServerAddress = "HJRestClientManagerNotificationServerAddress"
    @objc public static let NotificationEndpoint = "HJRestClientManagerNotificationEndpoint"
    @objc public static let NotificationRequestModel = "HJRestClientManagerNotificationRequestModel"
    @objc public static let NotificationCallIdentifier = "HJRestClientManagerNotificationCallIdentifier"
    @objc public static let NotificationCompletion = "HJRestClientManagerNotificationCompletion"
    @objc public static let NotificationResponseModel = "HJRestClientManagerNotificationResponseModel"
    @objc public static let NotificationTimestamp = "HJRestClientManagerNotificationTimestamp"
    @objc public static let NotificationHttpStatus = "HJRestClientManagerNotificationHttpStatus"
    @objc public static let NotificationHttpHeaders = "HJRestClientManagerNotificationHttpHeaders"
    @objc public static let NotificationSharedDataKey = "HJRestClientManagerNotificationSharedDatakey"
    @objc public static let NotificationSharedDataModel = "HJRestClientManagerNotificationSharedDataModel"
    @objc public static let NotificationRequestGroupResults = "HJRestClientManagerNotificationRequestGroupResults"
    @objc public static let NotificationRequestGroupStopped = "HJRestClientManagerNotificationRequestGroupStopped"
    @objc public static let NotificationCustomEventIdentifier = "HJRestClientManagerNotificationCustomEventIdentifier"
    fileprivate static let NotificationGruopIdentifier = "HJRestClientManagerNotificationGruopIdentifier"
    fileprivate static let NotificationRequestIdentifier = "HJRestClientManagerNotificationRequestIdentifier"
    
    @objc(HJRestClientManagerEvent) public enum Event: Int {
        case loadRemote
        case loadCache
        case loadSkip
        case updateCache
        case updateSharedData
        case removeCache
        case removeSharedData
        case failInternalError
        case failNetworkError
        case failServerUnavailable
        case failServerUnathorized
        case doneRequestGroup
        case custom
    }
    
    @objc(HJRestClientRequest) public class RequestNode : NSObject {
        
        fileprivate let identifier:String = UUID().uuidString
        fileprivate var resultDict:[String:Any]?
        fileprivate var isLocalRequest:Bool = false
        fileprivate var localRequestName:String = ""
        
        private(set) var method:HJHttpApiExecutorHttpMethodType = .get
        private(set) var apiKey:String?
        private(set) var serverAddress:String?
        private(set) var endpoint:String?
        private(set) var requestModel:Any?
        private(set) var responseModelRefer:Any?
        private(set) var updateCache:Bool = false
        private(set) var requestModelFromResultHandler:HJRestClientRequestModelFromResultBlock?
        private(set) var completion:HJRestClientCompletionBlock?
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?, updateCache:Bool, completion:HJRestClientCompletionBlock?) {
            self.method = method
            self.apiKey = apiKey
            self.requestModel = requestModel
            self.responseModelRefer = responseModelRefer
            self.updateCache = updateCache
            self.completion = completion
        }
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?) {
            self.method = method
            self.apiKey = apiKey
            self.requestModel = requestModel
            self.responseModelRefer = responseModelRefer
        }
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModelFromResultHandler:@escaping HJRestClientRequestModelFromResultBlock, responseModelRefer:Any?, updateCache:Bool, completion:HJRestClientCompletionBlock?) {
            
            self.method = method
            self.apiKey = apiKey
            self.requestModelFromResultHandler = requestModelFromResultHandler
            self.responseModelRefer = responseModelRefer
            self.updateCache = updateCache
            self.completion = completion
        }
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?, updateCache:Bool, completion:HJRestClientCompletionBlock?) {
            self.method = method
            self.serverAddress = serverAddress
            self.endpoint = endpoint
            self.requestModel = requestModel
            self.responseModelRefer = responseModelRefer
            self.updateCache = updateCache
            self.completion = completion
        }
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?) {
            self.method = method
            self.serverAddress = serverAddress
            self.endpoint = endpoint
            self.requestModel = requestModel
            self.responseModelRefer = responseModelRefer
        }
        
        @objc public init(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModelFromResultHandler:@escaping HJRestClientRequestModelFromResultBlock, responseModelRefer:Any?, updateCache:Bool, completion:HJRestClientCompletionBlock?) {
            
            self.method = method
            self.serverAddress = serverAddress
            self.endpoint = endpoint
            self.requestModelFromResultHandler = requestModelFromResultHandler
            self.responseModelRefer = responseModelRefer
            self.updateCache = updateCache
            self.completion = completion
        }
        
        @objc public init(requestName:String, localProcessHandler:@escaping HJRestClientRequestModelFromResultBlock) {
            
            self.isLocalRequest = true
            self.localRequestName = requestName
            self.requestModelFromResultHandler = localProcessHandler
        }
    }
    
    fileprivate class RequestGroup {
        
        let identifier:String = UUID().uuidString
        var stopWhenFailed:Bool = false
        var order:[RequestNode] = []
        var queueing:[RequestNode] = []
        var waiting:[String:RequestNode] = [:]
        var done:[String:RequestNode] = [:]
        var callIdentifier:String?
        var completion:HJRestClientCompletionBlock?
        
        init(requests:[RequestNode], callIdentifier:String?, stopWhenFailed:Bool, completion:HJRestClientCompletionBlock?) {
            self.stopWhenFailed = stopWhenFailed
            self.order = requests
            self.queueing = requests
            self.callIdentifier = callIdentifier
            self.completion = completion
        }
        
        func allQueuingToWaiting() {
            queueing.forEach { (req) in
                waiting[req.identifier] = req
            }
            queueing.removeAll()
        }
        
        func popQueueing() -> RequestNode? {
            if let first = queueing.first {
                waiting[first.identifier] = first
                queueing.removeFirst()
                return first
            }
            return nil
        }
        
        func waitingToDone(identifier:String) -> Int {
            if let req = waiting[identifier] {
                done[req.identifier] = req
                waiting.removeValue(forKey: req.identifier)
            }
            return (queueing.count + waiting.count)
        }
        
        func setResultToWaiting(identifier:String, resultDict:[String:Any]) {
            if let req = waiting[identifier] {
                req.resultDict = resultDict
            }
        }
        
        func allQueuingToDoneWithFail() {
            queueing.forEach { (req) in
                done[req.identifier] = req
            }
            queueing.removeAll()
        }
    }
    
    static fileprivate let singleton = HJRestClientManager()
    @objc static public func shared() -> HJRestClientManager {
        
        return HJRestClientManager.singleton
    }
    
    fileprivate let apiExecutor:HJRestClientExecutor = HJRestClientExecutor()
    fileprivate let sharedDataDirectoryName = "shared"
    fileprivate lazy var lockData = DispatchQueue(label: "lockdata.manager.\(name() ?? "hjrestclient")", attributes: [])
    fileprivate lazy var lockQueue = DispatchQueue(label: "lockqueue.manager.\(name() ?? "hjrestclient")", attributes: [])
    fileprivate var standby:Bool = false
    fileprivate var repositoryPath:String?
    fileprivate var workerName:String?
    fileprivate var sharedDatas:[String:Any] = [:]
    fileprivate var observingSharedDataKeys:[String:Bool] = [:]
    fileprivate var cipherNameForSharedDataKeys:[String:String] = [:]
    fileprivate var etagForResourceKeys:[String:String] = [:]
    fileprivate var maxAgeForResourceKeys:[String:TimeInterval] = [:]
    fileprivate var lastUpdatedTimestampForResourceKeys:[String:TimeInterval] = [:]
    fileprivate var servers:[String:String] = [:]
    fileprivate var apis:[String:(serverKey:String, endpoint:String)] = [:]
    fileprivate var apiKeyForServerAddressEndpointCache:[String:String] = [:]
    fileprivate var requestingGroups:[String:RequestGroup] = [:]
    fileprivate var preProcessBlockForApis:[String:HJRestClientPreProcessBlock] = [:]
    fileprivate var postProcessBlockForApis:[String:HJRestClientPostProcessBlock] = [:]
    
    fileprivate var processBlockForBodyFromRequestModel:HJRestClientBodyFromRequestModelBlock?
    fileprivate var processBlockForContentTypeFromRequestModel:HJRestClientContentTypeFromRequestModelBlock?
    fileprivate var processBlockForResponseModelFromData:HJRestClientResponseModelFromDataBlock?
    fileprivate var processBlockForResponseDataFromModel:HJRestClientResponseDataFromModelBlock?
    fileprivate var processBlockForDidReceiveResponse:HJRestClientDidReceiveResponseBlock?
    
    @objc public var useEtag:Bool = true
    
    @objc public var timeoutInterval:TimeInterval {
        get {
            return apiExecutor.timeoutInterval
        }
        set {
            apiExecutor.timeoutInterval = newValue
        }
    }
    
    @objc public func standby(withRepositoryPath repositoryPath:String, workerName:String) -> Bool {
        
        if standby == true {
            return false
        }
        
        var isDirectory:ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: repositoryPath, isDirectory:&isDirectory) == false {
            do {
                try FileManager.default.createDirectory(atPath: repositoryPath, withIntermediateDirectories:true, attributes:nil)
            } catch {
                return false
            }
        } else {
            if isDirectory.boolValue == false {
                return false
            }
        }
        
        self.repositoryPath = repositoryPath
        self.workerName = workerName
        registExecuter(apiExecutor, withWorkerName:workerName, action:#selector(HJRestClientManager.apiExecutorHandlerWithResult(_:)))
        standby = true
        
        didStandby()
        
        return true
    }
    
    @discardableResult fileprivate func request(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?, callIdentifier:String?, updateCache:Bool, groupIdentifier:String?, requestIdentifier:String?, completion:HJRestClientCompletionBlock?) -> Bool {
        
        guard standby == true else {
            return false
        }
        
        let resourceKey = cacheKey(forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
        
        if let info = maxAgeAndLastUpdatedTimestamp(forResourcekey: resourceKey), (Date().timeIntervalSinceReferenceDate - info.lastUpdatedTimestamp) <= info.maxAge {
            var resultDict:[String:Any] = [:]
            resultDict[HJRestClientManager.NotificationEvent] = Event.loadSkip.rawValue
            resultDict[HJRestClientManager.NotificationServerAddress] = serverAddress
            resultDict[HJRestClientManager.NotificationEndpoint] = endpoint
            resultDict[HJRestClientManager.NotificationRequestModel] = requestModel
            resultDict[HJRestClientManager.NotificationCallIdentifier] = callIdentifier
            DispatchQueue.main.async(execute: {
                if let completion = completion {
                    _ = completion(resultDict)
                }
                self.postNotify(withParamDict: resultDict)
                if let groupIdentifier = groupIdentifier, let requestIdentifier = requestIdentifier {
                    self.popNextOf(groupIdentifier: groupIdentifier, doneRequestIdentifier: requestIdentifier, doneRequestResult: resultDict)
                }
            })
            return true
        }
        
        guard let query = HYQuery(workerName:workerName, executerName:apiExecutor.name()) else {
            return false
        }
        query.setParameter(requestModel, forKey: HJRestClientManager.NotificationRequestModel)
        query.setParameter(groupIdentifier, forKey: HJRestClientManager.NotificationGruopIdentifier)
        query.setParameter(requestIdentifier, forKey: HJRestClientManager.NotificationRequestIdentifier)
        query.setParameter(serverAddress, forKey:HJRestClientExecutor.Parameter.serverAddress.rawValue)
        query.setParameter(endpoint, forKey:HJRestClientExecutor.Parameter.endpoint.rawValue)
        query.setParameter(method, forKey: HJRestClientExecutor.Parameter.httpMethod.rawValue)
        if let parameters = requestModel as? [String:Any] {
            query.setParameter(parameters, forKey:HJRestClientExecutor.Parameter.parameters.rawValue)
        } else if let body = bodyFromRequestModel(requestModel) {
            query.setParameter(body, forKey:HJRestClientExecutor.Parameter.customBody.rawValue)
            query.setParameter(contentTypeFromRequestModel(requestModel), forKey:HJRestClientExecutor.Parameter.customConentType.rawValue)
        }
        query.setParameter(callIdentifier, forKey:HJRestClientExecutor.Parameter.callIdentifier.rawValue)
        query.setParameter(updateCache, forKey: HJRestClientExecutor.Parameter.updateCache.rawValue)
        query.setParameter(unsafeBitCast(completion, to: AnyObject.self), forKey:HJRestClientExecutor.Parameter.completionBlock.rawValue)
        query.setParameter(responseModelRefer, forKey: HJRestClientExecutor.Parameter.responseModelRefer.rawValue)
        if let etag = etag(forResourceKey: resourceKey) {
            query.setParameter([InterestedHeaderName.ifNoneMatch:etag], forKey:HJRestClientExecutor.Parameter.headers.rawValue)
        }
        Hydra.default().pushQuery(query)
        
        return true
    }
    
    @objc @discardableResult public func request(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?, callIdentifier:String?, updateCache:Bool, completion:HJRestClientCompletionBlock?) -> Bool {
        
        return request(method: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer, callIdentifier: callIdentifier, updateCache: updateCache, groupIdentifier:nil, requestIdentifier:nil, completion: completion)
    }
    
    @objc @discardableResult public func request(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?, completion:HJRestClientCompletionBlock?) -> Bool {
        
        return request(method: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer, callIdentifier: nil, updateCache: false, completion: completion)
    }
    
    @discardableResult fileprivate func request(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?, callIdentifier:String?, updateCache:Bool, groupIdentifier:String?, requestIdentifier:String?, completion:HJRestClientCompletionBlock?) -> Bool {
        
        guard let info = serverAddressAndEndpoint(forApiKey: apiKey) else {
            return false
        }
        
        return request(method: method, serverAddress: info.serverAddress, endpoint: info.endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer, callIdentifier: callIdentifier, updateCache: updateCache, groupIdentifier: groupIdentifier, requestIdentifier: requestIdentifier, completion: completion)
    }
    
    @objc @discardableResult public func request(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?, callIdentifier:String?, updateCache:Bool, completion:HJRestClientCompletionBlock?) -> Bool {
        
        return request(method: method, apiKey: apiKey, requestModel: requestModel, responseModelRefer: responseModelRefer, callIdentifier: callIdentifier, updateCache: updateCache, groupIdentifier: nil, requestIdentifier: nil, completion: completion)
    }
    
    @objc @discardableResult public func request(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?, completion:HJRestClientCompletionBlock?) -> Bool {
        
        return request(method: method, apiKey: apiKey, requestModel: requestModel, responseModelRefer: responseModelRefer, callIdentifier: nil, updateCache: false, completion: completion)
    }
    
    fileprivate func processRequest(req:RequestNode, group:RequestGroup, doneRequestResult:[String:Any]?) {
        
        if req.isLocalRequest == false {
            if let apiKey = req.apiKey {
                if let reqHandler = req.requestModelFromResultHandler {
                    request(method: req.method, apiKey: apiKey, requestModel: reqHandler(doneRequestResult), responseModelRefer: req.responseModelRefer, callIdentifier: group.callIdentifier, updateCache: req.updateCache, groupIdentifier: group.identifier, requestIdentifier: req.identifier, completion: req.completion)
                } else {
                    request(method: req.method, apiKey: apiKey, requestModel: req.requestModel, responseModelRefer: req.responseModelRefer, callIdentifier: group.callIdentifier, updateCache: req.updateCache, groupIdentifier: group.identifier, requestIdentifier: req.identifier, completion: req.completion)
                }
            } else if let serverAddress = req.serverAddress {
                if let reqHandler = req.requestModelFromResultHandler {
                    request(method: req.method, serverAddress: serverAddress, endpoint: req.endpoint, requestModel: reqHandler(doneRequestResult), responseModelRefer: req.responseModelRefer, callIdentifier: group.callIdentifier, updateCache: req.updateCache, groupIdentifier: group.identifier, requestIdentifier: req.identifier, completion: req.completion)
                } else {
                    request(method: req.method, serverAddress: serverAddress, endpoint: req.endpoint, requestModel: req.requestModel, responseModelRefer: req.responseModelRefer, callIdentifier: group.callIdentifier, updateCache: req.updateCache, groupIdentifier: group.identifier, requestIdentifier: req.identifier, completion: req.completion)
                }
            }
        } else {
            DispatchQueue.global(qos: .background).async {
                var responseModel:Any?
                if let reqHandler = req.requestModelFromResultHandler {
                    responseModel = reqHandler(doneRequestResult)
                }
                var resultDict:[String:Any] = [:]
                resultDict[HJRestClientManager.NotificationEvent] = Event.custom.rawValue
                resultDict[HJRestClientManager.NotificationCustomEventIdentifier] = req.localRequestName
                if let responseModel = responseModel {
                    resultDict[HJRestClientManager.NotificationResponseModel] = responseModel
                }
                self.raiseCustomEvent(req.localRequestName, withParameter: (responseModel != nil ? [HJRestClientManager.NotificationResponseModel:responseModel!] : nil))
                DispatchQueue.main.async(execute: {
                    self.popNextOf(groupIdentifier: group.identifier, doneRequestIdentifier: req.identifier, doneRequestResult: resultDict)
                })
            }
        }
    }
    
    @objc @discardableResult public func requestConcurrent(_ requests:[RequestNode], callIdentifier:String?, completion:HJRestClientCompletionBlock?) -> Bool {
        
        guard standby == true else {
            return false
        }
        
        let group = RequestGroup(requests: requests, callIdentifier: callIdentifier, stopWhenFailed: false, completion: completion)
        lockQueue.sync {
            requestingGroups[group.identifier] = group
            group.allQueuingToWaiting()
        }
        
        requests.forEach { (req) in
            processRequest(req: req, group: group, doneRequestResult: nil)
        }
        
        return true
    }
    
    @objc @discardableResult public func requestSerial(_ requests:[RequestNode], callIdentifier:String?, stopWhenFailed:Bool, completion:HJRestClientCompletionBlock?) -> Bool {
        
        guard standby == true else {
            return false
        }
        
        let group = RequestGroup(requests: requests, callIdentifier: callIdentifier, stopWhenFailed: stopWhenFailed, completion: completion)
        var req:RequestNode?
        lockQueue.sync {
            requestingGroups[group.identifier] = group
            req = group.popQueueing()
        }
        
        if let req = req {
            processRequest(req: req, group: group, doneRequestResult: nil)
        }
        
        return true
    }
    
    @objc public func cachedResponseModel(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?, expireTimeInterval:TimeInterval) -> Any? {
        
        guard standby == true else {
            return nil
        }
        
        let resourceKey = cacheKey(forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
        let resourceQuery:[String:Any] = [HJResourceQueryKeyRequestValue:resourceKey]
        if expireTimeInterval > 0, HJResourceManager.default().checkValidationOfResource(withExpireTimeInterval: expireTimeInterval, forQuery:resourceQuery) == false {
            return nil
        }
        if let filePath = HJResourceManager.default().filePath(fromReosurceQuery: resourceQuery), let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            if let model = responseModel(fromData: data, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer) {
                if let endpoint = endpoint, let apiKey = apiKey(forServerAddress: serverAddress, endpoint: endpoint), let preProcessBlock = preProcessBlock(forApiKey: apiKey) {
                    return preProcessBlock(requestModel, model)
                }
                return model
            }
        }
        
        return nil
    }
    
    @objc public func cachedResponseModel(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?, responseModelRefer:Any?, expireTimeInterval:TimeInterval) -> Any? {
        
        guard let info = serverAddressAndEndpoint(forApiKey: apiKey) else {
            return nil
        }
        
        return cachedResponseModel(method: method, serverAddress: info.serverAddress, endpoint: info.endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer, expireTimeInterval: expireTimeInterval)
    }
    
    @objc @discardableResult public func updateCachedResponseModel(_ responseModel:Any, forMethod method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?) -> Bool {
        
        guard standby == true else {
            return false
        }
        guard let data = responseData(fromModel: responseModel, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel) else {
            return false
        }
        
        let resourceKey = cacheKey(forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
        let resourceQuery:[String:Any] = [HJResourceQueryKeyRequestValue:resourceKey, HJResourceQueryKeyDataValue:data]
        HJResourceManager.default().updateCachedResource(forQuery: resourceQuery) { (resultDict:[AnyHashable : Any]?) in
            var resultDict:[String:Any] = resultDict as? [String:Any] ?? [:]
            resultDict[HJRestClientManager.NotificationEvent] = Event.updateCache.rawValue
            resultDict[HJRestClientManager.NotificationServerAddress] = serverAddress
            resultDict[HJRestClientManager.NotificationEndpoint] = endpoint
            resultDict[HJRestClientManager.NotificationRequestModel] = requestModel
            resultDict[HJRestClientManager.NotificationResponseModel] = responseModel
            self.postNotify(withParamDict: resultDict)
        }
        
        return true
    }
    
    @objc @discardableResult public func updateCachedResponseModel(_ responseModel:Any, forMethod method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?) -> Bool {
        
        guard let info = serverAddressAndEndpoint(forApiKey: apiKey) else {
            return false
        }
        
        return updateCachedResponseModel(responseModel, forMethod: method, serverAddress: info.serverAddress, endpoint: info.endpoint, requestModel: requestModel)
    }
    
    @objc public func clearCache(method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?) {
        
        guard standby == true else {
            return
        }
        
        let resourceKey = cacheKey(forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
        let resourceQuery:[String:Any] = [HJResourceQueryKeyRequestValue:resourceKey]
        
        HJResourceManager.default().removeResource(forQuery: resourceQuery, completion:nil)
        
        HJResourceManager.default().removeResource(forQuery: resourceQuery) { (resultDict:[AnyHashable : Any]?) in
            var resultDict:[String:Any] = resultDict as? [String:Any] ?? [:]
            resultDict[HJRestClientManager.NotificationEvent] = Event.removeCache.rawValue
            resultDict[HJRestClientManager.NotificationServerAddress] = serverAddress
            resultDict[HJRestClientManager.NotificationEndpoint] = endpoint
            resultDict[HJRestClientManager.NotificationRequestModel] = requestModel
            self.postNotify(withParamDict: resultDict)
        }
    }
    
    @objc public func clearCache(method:HJHttpApiExecutorHttpMethodType, apiKey:String, requestModel:Any?) {
        
        guard let info = serverAddressAndEndpoint(forApiKey: apiKey) else {
            return
        }
        
        clearCache(method: method, serverAddress: info.serverAddress, endpoint: info.endpoint, requestModel: requestModel)
    }
    
    @objc func apiExecutorHandlerWithResult(_ result:HYResult) -> [String:Any]? {
        
        guard let statusNumber = result.parameter(forKey: HJHttpApiExecutorParameterKeyStatus) as? NSNumber,
              let status = HJHttpApiExecutorStatus(rawValue: statusNumber.intValue),
              let serverAddress = result.parameter(forKey: HJRestClientExecutor.Parameter.serverAddress.rawValue) as? String,
              let method = result.parameter(forKey: HJRestClientExecutor.Parameter.httpMethod.rawValue) as? HJHttpApiExecutorHttpMethodType else {
            return nil
        }
        let urlResponse = result.parameter(forKey: HJAsyncHttpDelivererParameterKeyResponse) as? HTTPURLResponse
        let endpoint = result.parameter(forKey: HJRestClientExecutor.Parameter.endpoint.rawValue) as? String
        let requestModel = result.parameter(forKey: HJRestClientManager.NotificationRequestModel)
        let callIdentifier = result.parameter(forKey: HJRestClientExecutor.Parameter.callIdentifier.rawValue) as? String
        let updateCache = result.parameter(forKey: HJRestClientExecutor.Parameter.updateCache.rawValue) as? Bool ?? false
        let receivedData = result.parameter(forKey: HJRestClientExecutor.Parameter.receivedData.rawValue) as? Data
        let completion = result.parameter(forKey: HJRestClientExecutor.Parameter.completionBlock.rawValue) as AnyObject?
        let responseModelRefer = result.parameter(forKey: HJRestClientExecutor.Parameter.responseModelRefer.rawValue)
        let groupIdentifier = result.parameter(forKey: HJRestClientManager.NotificationGruopIdentifier) as? String
        let requestIdentifier = result.parameter(forKey: HJRestClientManager.NotificationRequestIdentifier) as? String
        var resultDict:[String:Any] = [:]
        
        switch status {
            case .requested :
                break
            case .canceled, .expired, .invalidParameter, .internalError, .networkError, .failedResponse, .dataParsingError :
                resultDict[HJRestClientManager.NotificationServerAddress] = serverAddress
                resultDict[HJRestClientManager.NotificationEndpoint] = endpoint
                resultDict[HJRestClientManager.NotificationRequestModel] = requestModel
                resultDict[HJRestClientManager.NotificationCallIdentifier] = callIdentifier
                resultDict[HJRestClientManager.NotificationHttpStatus] = urlResponse?.statusCode
                resultDict[HJRestClientManager.NotificationHttpHeaders] = urlResponse?.allHeaderFields
                resultDict[HJRestClientManager.NotificationEvent] = (status == .networkError) ? Event.failNetworkError.rawValue : Event.failInternalError.rawValue
            case .emptyData, .received :
                resultDict[HJRestClientManager.NotificationServerAddress] = serverAddress
                resultDict[HJRestClientManager.NotificationEndpoint] = endpoint
                resultDict[HJRestClientManager.NotificationRequestModel] = requestModel
                resultDict[HJRestClientManager.NotificationCallIdentifier] = callIdentifier
                resultDict[HJRestClientManager.NotificationHttpStatus] = urlResponse?.statusCode
                resultDict[HJRestClientManager.NotificationHttpHeaders] = urlResponse?.allHeaderFields
                let resourceKey = cacheKey(forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
                let httpStatus = (urlResponse != nil) ? InterestedHttpStatus(rawValue: urlResponse!.statusCode) ?? .dontcareJustLikeError : .dontcareJustLikeError
                switch httpStatus {
                case .ok :
                    var skipByEtags = false
                    if useEtag == true, let receivedEtag = urlResponse?.allHeaderFields[InterestedHeaderName.etag.rawValue] as? String {
                        if let previousTag = etag(forResourceKey: resourceKey), previousTag == receivedEtag {
                            skipByEtags = true
                        }
                        setEtag(receivedEtag, forResourceKey: resourceKey)
                    }
                    if let cacheControl = urlResponse?.allHeaderFields[InterestedHeaderName.cacheControl.rawValue] as? String {
                        let items = cacheControl.components(separatedBy: ",")
                        for item in items {
                            let pair = item.components(separatedBy: "=")
                            if pair.count == 2, pair[0].trimmingCharacters(in: .whitespaces) == "max-age", let value = Double(pair[1].trimmingCharacters(in: .whitespaces)) {
                                setMaxAge(value: TimeInterval(value), forResourceKey: resourceKey)
                                break
                            }
                        }
                    }
                    resultDict[HJRestClientManager.NotificationEvent] = (skipByEtags == true) ? Event.loadSkip.rawValue : Event.loadRemote.rawValue
                    if let receivedData = receivedData {
                        if updateCache == true {
                            updateCachedResponseModel(receivedData, forMethod: method, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel)
                        }
                        if let model = responseModel(fromData: receivedData, serverAddress: serverAddress, endpoint: endpoint, requestModel: requestModel, responseModelRefer: responseModelRefer) {
                            if let endpoint = endpoint, let apiKey = apiKey(forServerAddress: serverAddress, endpoint: endpoint), let preProcessBlock = preProcessBlock(forApiKey: apiKey) {
                                resultDict[HJRestClientManager.NotificationResponseModel] = preProcessBlock(requestModel, model)
                            } else {
                                resultDict[HJRestClientManager.NotificationResponseModel] = model
                            }
                        } else {
                            resultDict[HJRestClientManager.NotificationResponseModel] = receivedData
                        }
                    }
                    if let urlResponse = urlResponse {
                        didReceiveResponse(urlResponse)
                    }
                case .notModified :
                    resultDict[HJRestClientManager.NotificationEvent] = Event.loadSkip.rawValue
                case .serviceUnavailable :
                    resultDict[HJRestClientManager.NotificationEvent] = Event.failServerUnavailable.rawValue
                case .unauthorized :
                    resultDict[HJRestClientManager.NotificationEvent] = Event.failServerUnathorized.rawValue
                default :
                    resultDict[HJRestClientManager.NotificationEvent] = (status == .networkError) ? Event.failNetworkError.rawValue : Event.failInternalError.rawValue
                }
            default :
                break
        }
        
        if resultDict.count > 0 {
            if let completion = completion {
                let completionBlock:HJRestClientCompletionBlock = unsafeBitCast(completion, to: HJRestClientCompletionBlock.self)
                if let updatedResultDict = completionBlock(resultDict) {
                    resultDict = updatedResultDict
                }
            }
            if let groupIdentifier = groupIdentifier, let requestIdentifier = requestIdentifier {
                DispatchQueue.main.async(execute: {
                    self.popNextOf(groupIdentifier: groupIdentifier, doneRequestIdentifier: requestIdentifier, doneRequestResult: resultDict)
                })
            }
            if let endpoint = endpoint, let apiKey = apiKey(forServerAddress: serverAddress, endpoint: endpoint), let postProcessBlock = postProcessBlock(forApiKey: apiKey) {
                postProcessBlock(requestModel, resultDict[HJRestClientManager.NotificationResponseModel])
            }
            return resultDict
        }
        
        return nil
    }
}

extension HJRestClientManager {
    
    @objc override open func name() -> String? {
        return Notification.Name.HJRestClientManager.rawValue
    }
    
    @objc open func didStandby() {
    }
    
    @objc open func bodyFromRequestModel(_ requestModel:Any?) -> Data? {
        
        if let processBlock = processBlockForBodyFromRequestModel {
            return processBlock(requestModel)
        }
        if let requestModel = requestModel as? Data {
            return requestModel
        }
        return nil
    }
    
    @objc open func contentTypeFromRequestModel(_ requestModel:Any?) -> String {
        
        if let processBlock = processBlockForContentTypeFromRequestModel {
            return processBlock(requestModel)
        }
        return "application/json"
    }
    
    @objc open func responseModel(fromData data:Data, serverAddress:String, endpoint:String?, requestModel:Any?, responseModelRefer:Any?) -> Any? {
        
        if let processBlock = processBlockForResponseModelFromData {
            return processBlock(data, serverAddress, endpoint, requestModel, responseModelRefer)
        }
        return try? JSONSerialization.jsonObject(with: data, options:.mutableContainers)
    }
    
    @objc open func responseData(fromModel model:Any, serverAddress:String, endpoint:String?, requestModel:Any?) -> Data? {
        
        if let processBlock = processBlockForResponseDataFromModel {
            return processBlock(model, serverAddress, endpoint, requestModel)
        }
        if let model = model as? Data {
            return model
        }
        return try? JSONSerialization.data(withJSONObject: model, options:JSONSerialization.WritingOptions.prettyPrinted)
    }
    
    @objc open func didReceiveResponse(_ urlResponse:URLResponse) {
        
        if let processBlock = processBlockForDidReceiveResponse {
            processBlock(urlResponse)
        }
    }
}

extension HJRestClientManager {
    
    @objc public func setProcessBlock(forBodyFromRequestModel block: @escaping HJRestClientBodyFromRequestModelBlock) {
        
        processBlockForBodyFromRequestModel = block
    }
    
    @objc public func setProcessBlock(forContentTypeFromRequestModel block: @escaping HJRestClientContentTypeFromRequestModelBlock) {
        
        processBlockForContentTypeFromRequestModel = block
    }
    
    @objc public func setProcessBlock(forResponseModelFromData block: @escaping HJRestClientResponseModelFromDataBlock) {
        
        processBlockForResponseModelFromData = block
    }
    
    @objc public func setProcessBlock(forResponseDataFromModel block: @escaping HJRestClientResponseDataFromModelBlock) {
        
        processBlockForResponseDataFromModel = block
    }
    
    @objc public func setProcessBlock(forDidReceiveResponse block: @escaping HJRestClientDidReceiveResponseBlock) {
        
        processBlockForDidReceiveResponse = block
    }
}

extension HJRestClientManager {
    
    fileprivate func serverAddressAndEndpoint(forApiKey key:String) -> (serverAddress:String, endpoint:String)? {
        
        var info:(serverAddress:String, endpoint:String)?
        lockData.sync {
            if let api = apis[key], let serverAddress = servers[api.serverKey] {
                info = (serverAddress: serverAddress, endpoint: api.endpoint)
            }
        }
        
        return info
    }
    
    fileprivate func apiKey(forServerAddress serverAddress:String, endpoint:String) -> String? {
        
        var apiKey:String?
        var serverKey:String?
        let cacheKey = "\(serverAddress)\(endpoint)"
        
        lockData.sync {
            if let foundKey = apiKeyForServerAddressEndpointCache[cacheKey] {
                apiKey = foundKey
            } else {
                for (key, value) in servers {
                    if value == serverAddress {
                        serverKey = key
                        break
                    }
                }
                if let serverKey = serverKey {
                    for( key, value) in apis {
                        if value.serverKey == serverKey, value.endpoint == endpoint {
                            apiKey = key
                            break
                        }
                    }
                }
                apiKeyForServerAddressEndpointCache[cacheKey] = apiKey
            }
        }
        
        return apiKey
    }
    
    fileprivate func maxAgeAndLastUpdatedTimestamp(forResourcekey key:String) -> (maxAge:TimeInterval, lastUpdatedTimestamp:TimeInterval)? {
        
        var info:(maxAge:TimeInterval, lastUpdatedTimestamp:TimeInterval)?
        lockData.sync {
            if let maxAge = maxAgeForResourceKeys[key], let lastUpdatedTimestamp = lastUpdatedTimestampForResourceKeys[key] {
                info = (maxAge: maxAge, lastUpdatedTimestamp: lastUpdatedTimestamp)
            }
        }
        
        return info
    }
    
    fileprivate func setMaxAge(value:TimeInterval, forResourceKey key:String) {
        
        lockData.sync {
            maxAgeForResourceKeys[key] = value
        }
    }
    
    fileprivate func etag(forResourceKey key:String) -> String? {
        
        var etag:String?
        lockData.sync {
            etag = etagForResourceKeys[key]
        }
        
        return etag
    }
    
    fileprivate func setEtag(_ etag:String, forResourceKey key:String) {
        
        lockData.sync {
            etagForResourceKeys[key] = etag
        }
    }
    
    fileprivate func hashKey(fromString string:String) -> String {
        
        guard let data = string.data(using: .utf8) else {
            return string
        }
        return hashKey(fromData: data)
    }
    
    fileprivate func hashKey(fromData data:Data) -> String {
        
        let length = data.count
        let bytes = [UInt8](data)
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let digest = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        CC_MD5(bytes, CC_LONG(length), digest)
        let hashKey = NSMutableString()
        for i in 0..<digestLength {
            hashKey.appendFormat("%02x", digest[i])
        }
        digest.deallocate()
        
        return NSString(format: hashKey) as String
    }
    
    fileprivate func reportRequestGroup(_ group:RequestGroup) {
        
        var results:[[String:Any]] = []
        var stopped:Bool = false
        group.order.forEach { (req) in
            results.append(req.resultDict ?? [:])
            if req.resultDict == nil {
                stopped = true
            }
        }
        var resultDict:[String:Any] = [:]
        resultDict[HJRestClientManager.NotificationEvent] = Event.doneRequestGroup.rawValue
        resultDict[HJRestClientManager.NotificationGruopIdentifier] = group.identifier
        resultDict[HJRestClientManager.NotificationRequestGroupResults] = results
        resultDict[HJRestClientManager.NotificationRequestGroupStopped] = stopped
        if let completion = group.completion {
            _ = completion(resultDict)
        }
        postNotify(withParamDict: resultDict)
    }
    
    fileprivate func popNextOf(groupIdentifier:String, doneRequestIdentifier:String, doneRequestResult:[String:Any]?) {
        
        var groupForIdentifier:RequestGroup?
        lockQueue.sync {
            groupForIdentifier = requestingGroups[groupIdentifier]
        }
        guard let group = groupForIdentifier else {
            return
        }
        
        group.setResultToWaiting(identifier: doneRequestIdentifier, resultDict: doneRequestResult ?? [:])
        
        if group.stopWhenFailed == true, let result = doneRequestResult, let eventValue = result[HJRestClientManager.NotificationEvent] as? Int, let event = Event(rawValue: eventValue) {
            switch event {
            case .loadRemote, .loadSkip, .loadCache, .custom :
                break
            default :
                lockQueue.sync {
                    group.allQueuingToDoneWithFail()
                    requestingGroups.removeValue(forKey: group.identifier)
                }
                reportRequestGroup(group)
                return
            }
        }
        
        var left:Int = 0
        var req:RequestNode?
        lockQueue.sync {
            left = group.waitingToDone(identifier: doneRequestIdentifier)
            if left == 0 {
                requestingGroups.removeValue(forKey: group.identifier)
            }
            req = group.popQueueing()
        }
        if left == 0 {
            reportRequestGroup(group)
            return
        }
        if let req = req {
            processRequest(req: req, group: group, doneRequestResult: doneRequestResult)
        }
    }
}

extension HJRestClientManager {
    
    @objc @discardableResult public func setServerAddresses(_ serverAddresses:[String:String]) -> Bool {
        
        guard serverAddresses.count > 0 else {
            return false
        }
        
        lockData.sync {
            serverAddresses.forEach { (key, value) in
                if value.count > 0, let last = value.last {
                    let address = (value.hasPrefix("http://") || value.hasPrefix("https://")) ? value : "http://\(value)"
                    servers[key] = (last == "/" ? String(address.dropLast()) : address)
                }
            }
            apiKeyForServerAddressEndpointCache.removeAll()
        }
        
        return true
    }
    
    @objc @discardableResult public func setApiWith(serverKey:String, endpoint:String, forKey key:String) -> Bool {
        
        lockData.sync {
            apis[key] = (serverKey: serverKey, endpoint: (endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"))
            apiKeyForServerAddressEndpointCache.removeValue(forKey: key)
        }
        
        return true
    }
    
    @objc public func serverAddressOfApi(forKey key:String) -> String? {
        
        var serverAddress:String?
        lockData.sync {
            if let api = apis[key] {
                serverAddress = servers[api.serverKey]
            }
        }
        
        return serverAddress
    }
    
    @objc public func endpointOfApi(forKey key:String) -> String? {
        
        var endpoint:String?
        lockData.sync {
            if let api = apis[key] {
                endpoint = api.endpoint
            }
        }
        
        return endpoint
    }
    
    @objc public func urlStringOfApi(forKey key: String) -> String? {
        
        var urlString:String?
        lockData.sync {
            if let api = apis[key], let serverAddress = servers[api.serverKey] {
                urlString = "\(serverAddress)\(api.endpoint)"
            }
        }
        
        return urlString
    }
    
    @objc public func replaceComponents(forEndpoint endpoint:String) -> [String:String]? {
        
        var components:[String:String]?
        lockData.sync {
            components = apiExecutor.replacePathComponentsForEndpoints[endpoint]
        }
        
        return components
    }
    
    @objc public func setReplaceComponents(_ components:[String:String], forEndpoint endpoint:String) {
        
        lockData.sync {
            apiExecutor.replacePathComponentsForEndpoints[endpoint] = components
        }
    }
    
    @objc public func removeReplaceComponents(forEndpoint endpoint:String) {
        
        lockData.sync {
            _ = apiExecutor.replacePathComponentsForEndpoints.removeValue(forKey: endpoint)
        }
    }
    
    @objc public func removeAllReplaceComponents() {
        
        lockData.sync {
            apiExecutor.replacePathComponentsForEndpoints.removeAll()
        }
    }
    
    @objc public func preProcessBlock(forApiKey apiKey:String) -> HJRestClientPreProcessBlock? {
        
        var processBlock:HJRestClientPreProcessBlock?
        lockData.sync {
            processBlock = preProcessBlockForApis[apiKey]
        }
        
        return processBlock
    }
    
    @objc @discardableResult public func setPreProcessBlock(_ processBlock:@escaping HJRestClientPreProcessBlock, forApiKeys apiKeys:[String]) -> Bool {
        
        lockData.sync {
            apiKeys.forEach({ (apiKey) in
                preProcessBlockForApis[apiKey] = processBlock
            })
        }
        
        return true
    }
    
    @objc public func removePreProcessBlock(forApiKey apiKey:String) {
        
        lockData.sync {
            _ = preProcessBlockForApis.removeValue(forKey: apiKey)
        }
    }
    
    @objc public func removeAllPreProcessBlocks() {
        
        lockData.sync {
            preProcessBlockForApis.removeAll()
        }
    }
    
    @objc public func postProcessBlock(forApiKey apiKey:String) -> HJRestClientPostProcessBlock? {
        
        var processBlock:HJRestClientPostProcessBlock?
        lockData.sync {
            processBlock = postProcessBlockForApis[apiKey]
        }
        
        return processBlock
    }
    
    @objc @discardableResult public func setPostProcessBlock(_ processBlock:@escaping HJRestClientPostProcessBlock, forApiKeys apiKeys:[String]) -> Bool {
        
        lockData.sync {
            apiKeys.forEach({ (apiKey) in
                postProcessBlockForApis[apiKey] = processBlock
            })
        }
        
        return true
    }
    
    @objc public func removePostProcessBlock(forApiKey apiKey:String) {
        
        lockData.sync {
            _ = postProcessBlockForApis.removeValue(forKey: apiKey)
        }
    }
    
    @objc public func removeAllPostProcessBlocks() {
        
        lockData.sync {
            postProcessBlockForApis.removeAll()
        }
    }
    
    @objc public func autoSettingValue(forHeaderField headerField:String) -> String? {
        
        var value:String?
        lockData.sync {
            value = apiExecutor.autoSettingHeaders[headerField]
        }
        return value
    }
    
    @objc public func setAutoSetting(value:String, forHeaderField headerField:String) {
        
        lockData.sync {
            apiExecutor.autoSettingHeaders[headerField] = value
        }
    }
    
    @objc public func removeAutoSettingValue(forHeaderField headerField:String) {
        
        lockData.sync {
            _ = apiExecutor.autoSettingHeaders.removeValue(forKey: headerField)
        }
    }
    
    @objc public func removeAllAutoSettingHeaderFieldValues() {
        
        lockData.sync {
            apiExecutor.autoSettingHeaders.removeAll()
        }
    }
    
    @objc public func resetMaxAges() {
        
        lockData.sync {
            maxAgeForResourceKeys.removeAll()
            lastUpdatedTimestampForResourceKeys.removeAll()
        }
    }
    
    @objc public func cipherName(forSharedDataKey key:String) -> String? {
        
        var name:String?
        lockData.sync {
            name = cipherNameForSharedDataKeys[key]
        }
        
        return name
    }
    
    @objc @discardableResult public func setCipher(name:String, forSharedDataKey key:String) -> Bool {
        
        if HJResourceManager.default().cipher(forName: name) == nil {
            return false
        }
        lockData.sync {
            cipherNameForSharedDataKeys[key] = name
        }
        
        return true
    }
    
    @objc public func removeCipher(forSharedDataKey key:String) {
        
        lockData.sync {
            _ = cipherNameForSharedDataKeys.removeValue(forKey: key)
        }
    }
    
    @objc public func removeAllCipherForSharedData() {
        
        lockData.sync {
            cipherNameForSharedDataKeys.removeAll()
        }
    }
    
    @objc public func isObserving(forSharedDataKey key:String) -> Bool {
        
        var observing:Bool = false
        lockData.sync {
            observing = observingSharedDataKeys[key] ?? false
        }
        
        return observing
    }
    
    @objc @discardableResult public func setObserver(forSharedDataKey key:String) -> Bool {
        
        lockData.sync {
            observingSharedDataKeys[key] = true
        }
        
        return true
    }
    
    @objc public func removeObserver(forSharedDataKey key:String) {
        
        lockData.sync {
            _ = observingSharedDataKeys.removeValue(forKey: key)
        }
    }
    
    @objc public func removeAllObservesForSharedData() {
        
        lockData.sync {
            observingSharedDataKeys.removeAll()
        }
    }
    
    @objc public func sharedData(forKey key:String) -> Any? {
        
        guard standby == true else {
            return nil
        }
        
        var data:Any? = nil
        if let filePath = filePathOfSharedData(forKey: key) {
            lockData.sync {
                data = sharedDatas[key]
                if data == nil {
                    if let cipherName = cipherNameForSharedDataKeys[key] {
                        data = HJResourceManager.default().decryptData(fromFilePath: filePath, forName:cipherName)
                    } else {
                        data = NSKeyedUnarchiver.unarchiveObject(withFile: filePath)
                    }
                    if data != nil {
                        sharedDatas[key] = data
                    }
                }
            }
        }
        
        return data
    }
    
    @objc @discardableResult public func setShared(data:Any, forKey key:String) -> Bool {
        
        guard standby == true else {
            return false
        }
        
        var saved:Bool = false
        if let filePath = filePathOfSharedData(forKey: key) {
            lockData.sync {
                if let cipherName = cipherNameForSharedDataKeys[key] {
                    saved = HJResourceManager.default().encryptData(NSKeyedArchiver.archivedData(withRootObject: data), toFilePath: filePath, forName: cipherName)
                } else {
                    saved = NSKeyedArchiver.archiveRootObject(data, toFile:filePath)
                }
                if saved == true {
                    sharedDatas[key] = data
                }
            }
        }
        if saved == false {
            return false
        }
        
        if let notify = observingSharedDataKeys[key], notify == true {
            var resultDict:[String:Any] = [:]
            resultDict[HJRestClientManager.NotificationEvent] = Event.updateSharedData.rawValue
            resultDict[HJRestClientManager.NotificationSharedDataKey] = key
            resultDict[HJRestClientManager.NotificationSharedDataModel] = data
            DispatchQueue.main.async(execute: { () -> Void in
                self.postNotify(withParamDict: resultDict)
            })
        }
        
        return true
    }
    
    @objc @discardableResult public func removeSharedData(forKey key:String) -> Bool {
        
        guard standby == true else {
            return false
        }
        
        var removed:Bool = false
        var previousData:Any?
        
        if let filePath = filePathOfSharedData(forKey: key) {
            lockData.sync {
                previousData = sharedDatas[key]
                if FileManager.default.fileExists(atPath: filePath) == true {
                    removed = true
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        removed = false
                    }
                }
                if removed == true {
                    sharedDatas.removeValue(forKey: key)
                }
            }
        }
        if removed == false {
            return false
        }
        
        if let notify = observingSharedDataKeys[key], notify == true {
            var resultDict:[String:Any] = [:]
            resultDict[HJRestClientManager.NotificationEvent] = Event.removeSharedData.rawValue
            resultDict[HJRestClientManager.NotificationSharedDataKey] = key
            resultDict[HJRestClientManager.NotificationSharedDataModel] = previousData
            DispatchQueue.main.async(execute: { () -> Void in
                self.postNotify(withParamDict: resultDict)
            })
        }
        
        return true
    }
    
    @objc public func removeAllSharedData() {
        
        guard standby == true else {
            return
        }
        
        var dumpKeys:[String]?
        lockData.sync {
            dumpKeys = Array(sharedDatas.keys)
            sharedDatas.removeAll()
        }
        
        dumpKeys?.forEach({ (key) in
            removeSharedData(forKey: key)
        })
    }
    
    @objc public func filePathOfSharedData(forKey key:String) -> String! {
        
        if let repositoryPath = self.repositoryPath {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                return repositoryPath + "/\(encodedKey)"
            }
        }
        
        return nil
    }
    
    @objc public func cacheKey(forMethod method:HJHttpApiExecutorHttpMethodType, serverAddress:String, endpoint:String?, requestModel:Any?) -> String {
        
        var cacheKey = "\(name() ?? "hjrestclientmanager"):\(method.rawValue):\(serverAddress)"
        
        if let parameters = requestModel as? [String:Any] {
            var subKey:String = ""
            let keys = parameters.keys.sorted()
            keys.forEach { (key) in
                subKey += ":\(key)=\(parameters[key]!)"
            }
            cacheKey += hashKey(fromString: subKey)
        } else if let body = bodyFromRequestModel(requestModel) {
            cacheKey += hashKey(fromData: body)
        }
        
        return cacheKey
    }
    
    @objc public func addObserver(_ observer: Any, selector aSelector: Selector) {
        
        NotificationCenter.default.addObserver(observer, selector: aSelector, name: NSNotification.Name.init(name() ?? Notification.Name.HJRestClientManager.rawValue), object: nil)
    }
    
    @objc public func removeObserver(_ observer: Any) {
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    @objc public func raiseCustomEvent(_ identifier:String, withParameter parameter:[String:Any]?) {
        
        var resultDict:[String:Any] = parameter ?? [:]
        resultDict[HJRestClientManager.NotificationEvent] = Event.custom.rawValue
        resultDict[HJRestClientManager.NotificationCustomEventIdentifier] = identifier;
        DispatchQueue.main.async(execute: { () -> Void in
            self.postNotify(withParamDict: resultDict)
        })
    }
}
