HJRestClientManager
============

Simple and flexible REST API client based on Hydra framework.

# Installation

You can download the latest framework files from our Release page.
HJRestClientManager also available through CocoaPods. To install it simply add the following line to your Podfile.  
pod 'HJRestClientManager' 

# Simaple Preview

Here is sample code to calling API that 'http://your.apiserver.com/hello?a=1' by GET method.

```swift
HJRestClientManager.request().serverAddress("your.apiserver.com/hello").requestModel(["a":"1"]).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let data = result?[HJRestClientManager.NotificationResponseModel] as? Data, let bodyString = String(data: data, encoding: .utf8) {
        print(bodyString)
    }
    return nil
}
```

# Features

- [x] Support manage multiple protocol easily by protocol dogma concept.
- [x] Support manage group of multiple request methods by serial or concurrent.
- [x] Support chainable reqeust / response methods.
- [x] Support manage custom local job with remote request.
- [x] Support manage connection pool.
- [x] Support manage local cache.
- [x] Support manage reactive shared data machanism.
- [x] Support dummy test environment.

# Setup

HJRestClientManager is a framekwork based on Hydra.
And, it using another library HJResourceManager also based on Hydra.
Add the workers to Hydra as your purpose, first.
In this case, just make two workers and use for each managers.
Now, bind and start, HJResourceManager and HJRestClientManager each others.

```swift
Hydra.default().addNormalWorker(forName: "hjrm")
Hydra.default().addNormalWorker(forName: "hjrc")

let hjrmRepoPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/hjrm"
if HJResourceManager.default().standby(withRepositoryPath: hjrmRepoPath, localJobWorkerName: "hjrm", remoteJobWorkerName: "hjrm") {
    HJResourceManager.default().bind(toHydra: Hydra.default())
}

let hjrcRepoPath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/hjrc"
if HJRestClientManager.shared.standby(withRepositoryPath: hjrcRepoPath, workerName: "hjrc") == true {
    HJRestClientManager.shared.bind(toHydra: Hydra.default())
}

Hydra.default().startAllWorkers()
```

# Implement Dogma

Now, you can call REST API and handling response, as you saw at Simple Preview above.
HJRestClientManager have protocol dogma concept.
It give you can handling protocol more elegantly.
You can define and implement business code for request / response model of API protocol by using HJRestClientDogma.
Here is HJRestClientDogma protocol.

```swift
// HJRestClientDogma protocol
@objc public protocol HJRestClientDogma {
    
    @objc func bodyFromRequestModel(_ requestModel:Any?) -> Data?
    @objc func contentTypeFromRequestModel(_ requestModel:Any?) -> String?
    @objc func responseModel(fromData data:Data, serverAddress:String, endpoint:String?, contentType:String?, requestModel:Any?, responseModelRefer:Any?) -> Any?
    @objc func responseData(fromModel model:Any, serverAddress:String, endpoint:String?, requestModel:Any?) -> Data?
    @objc func didReceiveResponse(response:URLResponse, serverAddress:String, endpoint:String?)
}

// Your dogma class
class SampleDogma: HJRestClientDogam {
    // implement here.
}
```

Let's assume that your REST API use json format for body data of post method, and response body format also json.
And, in this example, we using ObjectMapper library as response model mapper.

Let's see one by one.

bodyFromRequestModel function receive your custom request model object and you need return its' body data.

```swift
func bodyFromRequestModel(_ requestModel:Any?) -> Data? {
    
    if let jsonModel = requestModel as? Mappable, let jsonString = jsonModel.toJSONString() {
        return jsonString.data(using: .utf8)
    }   
    return requestModel as? Data
} 
```

contentTypeFromRequestModel function receive your custom request model object and you need return it's Content-Type.

```swift
func contentTypeFromRequestModel(_ requestModel:Any?) -> String? {
    
    if (requestModel as? Mappable) != nil {
        return "application/json"
    }   
    return "application/octet-stream"
} 
```

responseModel function receive data from server, some additional information about server, content type of data, request model object when it called and desire response model type.
After processing it, you need return response model object.

```swift
func responseModel(fromData data: Data, serverAddress: String, endpoint: String?, contentType:String?, requestModel: Any?, responseModelRefer: Any?) -> Any? {
    
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
        return nil 
    }   
    if let list = jsonObject as? [Any] {
        var modelList:[Any] = []
        for item in list {
            if let item = item as? [String:Any], let jsonModelClass = responseModelRefer as? Mappable.Type, let model = try? jsonModelClass.init(dictionary: item) {
                modelList.append(model)
            }   
        }
        return modelList
    }   
    if let item = item as? [String:Any], let jsonModelClass = responseModelRefer as? Mappable.Type, let model = try? jsonModelClass.init(dictionary: item) {
        return model;
    }
    return nil
} 
```

responseData function receive your custom response model object, some additional information about server and request model object when it called.
You need return data object of response model to local caching.

```swift
func responseData(fromModel model: Any, serverAddress: String, endpoint: String?, requestModel: Any?) -> Data? {
    
    if let jsonModel = model as? Mappable, let jsonString = jsonModel.toJSONString() {
        return jsonString.data(using: .utf8)
    }   
    return model as? Data
}
```

didRecieveResponse function receive response object and some additional server information.
It called when you got receive something every time, so you need some check with response object then do it here.

```swift
func didReceiveResponse(response: URLResponse, serverAddress: String, endpoint: String?) {

    if let urlResponse = response as? HTTPURLResponse {
        print(urlResponse.allHeaderFields)
    }
}
```

After define and implement your dogma, you need register it with key before use.

```swift
HJRestClientManager.shared.setDogma(SampleDogma(), forKey: "sampleDogma")
```

Now you can call your REST API with your dogma.
Here is sample code to calling API that 'http://postman-echo.com/get?a=1' by GET method.

```swift
// Your request model class
class Req: Mappable {
    // ...
}

// Your response model class
class Res: Mappable {
    // ...
}

let req = Req(JSONString: "{\"name\":\"gandalf\"}")

HJRestClientManager.request().dogmaKey("sampleDogma").serverAddress("your.apiserver.com/hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

You can define and implement multiple dogmas and use it just describe simply.

```swift
HJRestClientManager.request().dogmaKey("sampleDogma").serverAddress("your.apiserver.com/v1/hello").post().req...

HJRestClientManager.request().dogmaKey("anotherDogma").serverAddress("your.apiserver.com/v2/hello").post().req...
```

You can set default dogam to HJRestClientManager and it reduce your typing.
If some request don't have its' dogoma key then HJRestClientManager will use default dogma key.

```swift
HJRestClientManager.shared.defaultDogmaKey = "sampleDogma"

HJRestClientManager.request().serverAddress("your.apiserver.com/hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

# Managing server address, endpoint and path components

We usually do sepratate server address and endpoint of API.
You can do it with describe endpoint by dividing address.

```swift
HJRestClientManager.request().serverAddress("your.apiserver.com").endpoint("/v1/hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

Server address also can manage with key in HJRestClientManager, and you can describe server address by key simply.

```swift
HJRestClientManager.shared.setServerAddresses( ["apisvr": "your.server.com"] )

HJRestClientManager.request().serverKey("apisvr").endpoint("/v1/hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

Default server key also settable.
If some request don't have its' server address information then HJRestClientManager will use default server key.

```swift
HJRestClientManager.shared.defaultServerKey = "apisvr"

HJRestClientManager.request().endpoint("/v1/hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

You can also make alias for server address key and endpoint to API key.
So, all of with it, you could call like this,

```swift
HJRestClientManager.shared.setApiWith(serverKey: "apisvr", endpoint: "/v1/hello", forKey: "hello")

HJRestClientManager.request().apiKey("hello").post().requestModel(req).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

Sometimes, you may want to replace some endpoint's path components by request information.
For instance, API /api/hello allow nickname and message by last two components.

http://your.apiserver.com/api/hello/&ltnickname&gt/&ltmessage&gt

You can make url string before call request, or reserve replace components and pass the parameters like this.
The key $0 and $1 below is not reserved word, so you can use any key word as you wish.

setReplaceComponents function receive key / value collection consist of finding key value and default value if not receive replacing value from request parameters and endpoint format.

```swift
HJRestClientManager.shared.setReplaceComponents(["$0":"", "$1":""], forEndpoint: "/api/hello/$0/$1")


HJRestClientManager.request().endpoint("/api/hello/$0/$1").post().requestModel(["$0":"gandalf"]).responseModelRefer: Res.self).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

If given key value exist in request parameter then it will replace its' value,
If not exist then it will replace given default value.
So, above code request endpoint will be "/api/hello/gandalf".

# Multiple request at the same time, and wait all done.

Before you do multiple requests, you need make request nodes and its' business code for response if need.

```swift
let reqA = HJRestClientManager.RequestNode().apiKey("hello").requestModel(["$0":"gandalf"]).responseModelRefer(Res.self)

let reqB = HJRestClientManager.RequestNode().apiKey("hello").requestModel(["$0":"balrog"]).responseModelRefer(Res.self).completionHandler { (result:[String : Any]?) -> [String : Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        // here will be placed some business code if you want to handle the response additionally or doing something indpendently without combined response handler.
    }
    return nil
}

HJRestClientManager.shared.requestConcurrent([reqA, reqB], callIdentifier: nil) { (result:[String : Any]?) -> [String : Any]? in
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
```

# Chaining request

Before you do chaining requests, you need make request nodes like doing multiple requests.
And calling it by requestSerial function as do calling requestConcurrent.
Then, HJRestClientManager request it by one by one, step by step.
But, the point of chaining request is using response data of previous request to next request.
You can describe it by requestModelFromResultHandler function.

```swift
let reqA = HJRestClientManager.RequestNode().apiKey("hello").requestModel(["$0":"gandalf"]).responseModelRefer(Res.self)

let reqB = HJRestClientManager.RequestNode().apiKey("hello").responseModelRefer(Res.self).requestModelFromResultHandler { (result:[String : Any]?) -> Any? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        let reqm = ["$0":"\(Res.name)"]
        return reqm
    }
    return nil
}

HJRestClientManager.shared.requestSerial([reqA, reqB], callIdentifier: nil, stopWhenFailed: true) { (result:[String : Any]?) -> [String : Any]? in

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
```

# Local job

Sometimes, you want to make indepent local business logic.
Or, you want to do pre or post process with remote request.
Also, you want to put it between the remote requests.
Local job is ready for this.

Make local job request like below.

```swift
let reqL = HJRestClientManager.RequestNode().localRequest(name: "local job") { (result:[String : Any]?) -> Any? in

    // get response model from previous request like this, if you this local job using on serial request processing.
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        // do some processing.
        return localJobResult
    }

    // you can also use local job to doing independantly on concurrent request processing or single request.
    // do some processing.
    return localJobResult
}
```

You can get result model of previous requests from local job parameter and pass preprocessed result to next job on serial request processing.

# Connection pool

By default, HJRestClientManager doesn't limit connection count. It depends on hardware limit.
But, if you want to handling on your hand, simple change connection pool size in real time by this.

```swift

HJRestClientManager.shared.connectionPoolSize = 64

```

# Local cache

You can manage the local cache data of all every remote requests automatically by giving update cache flag.
Set default activity of caching by global setting. (Default value is false)

```swift
HJRestClientManager.shared.useUpdateCacheDefault = false
```

And, give update cache flag for every single request as your wish.


```swift
HJRestClientManager.request().endpoint("/api/hello").requestModel(["name":"gandalf"]).responseModelRefer(Res.self).updateCache(true).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let model = result?[HJRestClientManager.NotificationResponseModel] as? Res {
        print("gotta")
    }
    return nil
}
```

Local cache data saved with key of its' request information as below.
request method, server address, endpoint, reqeust model.
So you can get local cached data by giving same reqeust information.

One more thing you need to check is expireTimeInterval.
If you need to handling expire time of local cached data, then you give time duration value of data validation.
You can't get local cached data that it saved before given time duration from now, even if it exist.
If not, just give zero. You can get data always if it exist.

For example, you can get local cached data of above example like this by giving 1 hour expire time interval.

```swift
if let res = HJRestClientManager.shared.cachedResponseModel(method: .get, endpoint: "/api/hello", requestModel: ["name":"gandalf"], responseModelRefer: Res.self, expireTimeInterval: 60*60) as? Res {
    print("gotta")
}
```

You can also managing local cached data with action update and clear directly.

# Shared data

Shared data in HJRestClientManager is key/value style permanent storage mechanism can observable and encryptable.
You can get and set shared data with key simply.

```swift
HJRestClientManager.shared.setShared(data: "hello, world!", forKey: "helloKey")
if let message = HJRestClientManager.shared.sharedData(forKey: "helloKey") {
    print(message)
}
```

If you active observer to some shared data by key, you can get notify when its' data changed.

```swift
// reserve observing
HJRestClientManager.shared.setObserver(forSharedDataKey: "helloKey")

// update shared data at some other place or time passed.
HJRestClientManager.shared.setShared(data: "hello, world!", forKey: "helloKey")

// observing notification and do what you want.
@objc func restClientManagerNotificationHandler(notification:Notification) {
    guard let userInfo = notification.userInfo, let eventValue = userInfo[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
        return
    }
    switch event {
    case .updateSharedData :
        if let sharedDataKey = userInfo[HJRestClientManager.NotificationSharedDataKey] as? String {
            print("shared data for key \(sharedDataKey) updated.")
        }
        break
    default :
        break
    }
}
```

If you reserve encryption method for shared data key, HJRestClientManager managing store encryption and restore decryption automatically.
Here is an example below, your shared data for key "test" will store by enrypted by gz.

```swift
// register cipher moudle to HJResourceManager somewhere in initial process.
HJResourceManager.default().setCipher(HJResourceCipherGzip(), forName: "gz")

// reserve ecryption method for shared data key that you want.
HJRestClientManager.shared.setCipher(name: "gz", forSharedDataKey: "secretHelloKey")
```

# Dummy test environment

Sometimes, we need offline test environment.
Protocol description is ready but Api server is not ready,
Need to test some custom response for part of APIs, and so on.

First, you need set on dummy test environment. (Default value is false)

```swfit
HJRestClientManager.shared.useDummyResponse = true
```

Register dummy response handler for server address, endpoint and method.
ResponseHandler get extraHeaders and requestModel from request call for given server address, endpoint and method.
You just write some business code and return the response data.

```swift
HJRestClientManager.shared.setDummyResponseHanlder({ (extraHeaders:[String : Any]?, requestModel:Any?) -> Data? in
    return "{\"name\":\"debugPlayer\"}".data(using: .utf8)
}, forServerAddress: "your.apiserver.com", endpoint: "/api/hello", method: .get, responseDelayTime: 0.8)
```

After register the handler,
Your request call for given server address, endpoint and method will get the response data from dummy response handler.

```swift
HJRestClientManager.request().serverAddress("your.apiserver.com").endpoint("/api/hello").requestModel(["name":"gandalf"]).resume() { (result:[String: Any]?) -> [String: Any]? in
    if let data = result?[HJRestClientManager.NotificationResponseModel] as? Data, let s = String(data: data, encoding: .utf8) {
        // this response string is {"name":"debugPlayer"} from dummy response handler.
        print(s)
    }
    return nil
}
```

If your testing is done. Just set off dummy test environment.
Your don't need change any other original businees code.

```swfit
HJRestClientManager.shared.useDummyResponse = false
```

# Notification Observating

You can also observe HJRestClientManager event to deal with business logic.

```swift
HJRestClientManager.shared.addObserver(self, selector: #selector(self.restClientManagerNotificationHandler(notification:)))

@objc func restClientManagerNotificationHandler(notification:Notification) {
    guard let userInfo = notification.userInfo, let eventValue = userInfo[HJRestClientManager.NotificationEvent] as? Int, let event = HJRestClientManager.Event(rawValue: eventValue) else {
        return
    }
    switch event {
    case .loadRemote :
        let dogmaKey = userInfo[HJRestClientManager.NotificationDogma] as? String // dogma key
        let serverAddress = userInfo[HJRestClientManager.NotificationServerAddress] as? String // server address
        let endpoint = userInfo[HJRestClientManager.NotificationEndpoint] as? String // endpoint
        let requestModel = userInfo[HJRestClientManager.NotificationRequestModel] // request model as you given model when request call
        let callIdentifier = userInfo[HJRestClientManager.NotificationCallIdentifier] as? String // call identifier as you given when request call
        let groupIdentifier = userInfo[HJRestClientManager.NotificationGruopIdentifier] as? String // unique group identifier if it belongs to a group request
        let statusCode = userInfo[HJRestClientManager.NotificationHttpStatus] as? Int // responsed http status code
        let allHeaderFields = userInfo[HJRestClientManager.NotificationHttpHeaders] as? [AnyHashable:Any] // responsed http all headers
        let responseModel = userInfo[HJRestClientManager.NotificationResponseModel] // responsed model casted as you given when request call
    case .loadSkip, .failInternalError, .failNetworkError, .failServerUnavailable, .failServerUnathorized :
        let dogmaKey = userInfo[HJRestClientManager.NotificationDogma] as? String // dogma key
        let serverAddress = userInfo[HJRestClientManager.NotificationServerAddress] as? String // server address
        let endpoint = userInfo[HJRestClientManager.NotificationEndpoint] as? String // endpoint
        let requestModel = userInfo[HJRestClientManager.NotificationRequestModel] // request model as you given model when request call
        let callIdentifier = userInfo[HJRestClientManager.NotificationCallIdentifier] as? String // call identifier as you given when request call
        let groupIdentifier = userInfo[HJRestClientManager.NotificationGruopIdentifier] as? String // unique group identifier if it belongs to a group request
        let statusCode = userInfo[HJRestClientManager.NotificationHttpStatus] as? Int // responsed http status code
        let allHeaderFields = userInfo[HJRestClientManager.NotificationHttpHeaders] as? [AnyHashable:Any] // responsed http all headers
    case .updateCache :
        let dogmaKey = userInfo[HJRestClientManager.NotificationDogma] as? String // dogma key
        let serverAddress = userInfo[HJRestClientManager.NotificationServerAddress] as? String // server address
        let endpoint = userInfo[HJRestClientManager.NotificationEndpoint] as? String // endpoint
        let requestModel = userInfo[HJRestClientManager.NotificationRequestModel] // request model as you given model when request call
        let responseModel = userInfo[HJRestClientManager.NotificationResponseModel] // updated response model casted as you given when request call
    case .removeCache :
        let dogmaKey = userInfo[HJRestClientManager.NotificationDogma] as? String // dogma key
        let serverAddress = userInfo[HJRestClientManager.NotificationServerAddress] as? String // server address
        let endpoint = userInfo[HJRestClientManager.NotificationEndpoint] as? String // endpoint
        let requestModel = userInfo[HJRestClientManager.NotificationRequestModel] // request model as you given model when request call
    case .updateSharedData :
        let sharedDataKey = userInfo[HJRestClientManager.NotificationSharedDataKey] as? String // shared data key
        let sharedData = userInfo[HJRestClientManager.NotificationSharedDataModel] // updated shared data
    case .removeSharedData :
        let sharedDataKey = userInfo[HJRestClientManager.NotificationSharedDataKey] as? String // shared data key
        let sharedData = userInfo[HJRestClientManager.NotificationSharedDataModel] // removed shared data
    case .doneReqeustGroup :
        let callIdentifier = userInfo[HJRestClientManager.NotificationCallIdentifier] as? String // call identifier as you given when request call
        let groupIdentifier = userInfo[HJRestClientManager.NotificationGruopIdentifier] as? String // unique group identifier
        let results = userInfo[HJRestClientManager.NotificationRequestGroupResults] as? [[String:Any]] // all result list in group request.
        let stopped = userInfo[HJRestClientManager.NotificationRequestGroupStopped] as? Bool // flag to detect all group request done or stopped by some point.
    case .custom :
        let customEventIdentifier = resultDict[HJRestClientManager.NotificationCustomEventIdentifier] as? String // custom event identifier as you defined
        let callIdentifier = userInfo[HJRestClientManager.NotificationCallIdentifier] as? String // call identifier as you given when request call
        let groupIdentifier = userInfo[HJRestClientManager.NotificationGruopIdentifier] as? String // unique group identifier if it belongs to a group request
        // and any other parameters you setted
    default :
        break
    }
}
```

# License

MIT License, where applicable. http://en.wikipedia.org/wiki/MIT_License
