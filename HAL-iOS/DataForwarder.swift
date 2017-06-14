//
//  DataForwarder.swift
//  HAL-iOS
//
//  Created by Pranitha Kota on 6/14/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation
class DataForwarder{
    
static var sendInProgress = false;
static let webDataKey = "webData";
    
class func makeServerRequest(method: String, networkReqURL: String, data: Data, onCompletion: @escaping (_ result: Bool,_ error:String)->Void) {
     if let url = NSURL(string: networkReqURL) as URL? {
        let request = NSMutableURLRequest(url: url);
        let proxyDict : NSDictionary = [ "HTTPEnable": 0, "HTTPSEnable": 0 ];
        let config = URLSessionConfiguration.default;
        
        config.connectionProxyDictionary = proxyDict as? [AnyHashable : Any];
        let session = URLSession(configuration: config);
        
        request.httpMethod = method;
        var jsonData = JSON(data: data).dictionaryObject
        if (!(jsonData==nil) && !(jsonData?["headers"]==nil)) {
            
            if let headersDict = jsonData?["headers"] as? [String:String] {
                for headerkey in headersDict.keys
                {
                    request.addValue(headersDict[headerkey]!,forHTTPHeaderField: headerkey)
                }
                jsonData?.removeValue(forKey: "headers")
                let finalData=try! JSONSerialization.data(withJSONObject: jsonData ?? "" , options: [])
                request.httpBody=finalData
            }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            var logvalue="";
            if(error != nil) {
                DLog(error.debugDescription);
                logvalue = "Error in sending data:"+String(describing:jsonData)+" with error: "+error.debugDescription;
                onCompletion(false,logvalue);
            }
            else
            {
                let resp=response! as? HTTPURLResponse;
                if(resp != nil && resp?.statusCode==200) {
                    do {
                        let json = JSON(data: data!).dictionaryObject;
                        if let reasonCode=json?["reasonCode"] as? String {
                            if(reasonCode=="0")
                            {
                                DLog("Sent message through Data forwarder.");
                                onCompletion(true,logvalue);
                            }
                            else
                            {
                                logvalue = "Failed sending data:"+String(describing:jsonData)+" with response: "+String(describing:json);
                                onCompletion(false,logvalue);
                            }
                        }
                    }
                }
                else
                {
                    DLog(String(data: data!, encoding: String.Encoding.utf8) ?? "failed sending data to server");
                    logvalue = "Error in sending data:"+String(describing:jsonData)+" with response"+String(describing:resp);
                    onCompletion(false,logvalue);
                }
            }})
        task.resume();
        }
    }
}
    
    
    
    class func sendData(data: Data,method: String,server: String,route: String) -> Bool
    {
        var response = false;
        let sem = DispatchSemaphore(value: 0);
        let networkReqURL = "https://"+server+route;
        makeServerRequest(method: method, networkReqURL: networkReqURL, data: data) {
            (result: Bool,error: String) in
            response = result;
            if(!response)
            {
                LoggingRequest.logError(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
            }
            sem.signal();
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture);
        return response;
    }
    
    
    class func forwardData(data: NSDictionary,id:String)
    {
        DispatchQueue.global(qos: .background).async {
            let method = data["method"] as? String ?? ""
            let server = data["server"] as? String ?? ""
            let route = data["route"] as? String ?? ""
            let payload = data["payload"] as? NSDictionary
            let requestData = try! JSONSerialization.data(withJSONObject: payload, options: []);
            if( sendData(data:requestData, method:method, server:server, route:route) ) {
                DLog("Data forwarder data: " + String(data: requestData, encoding: String.Encoding.utf8)!);
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + id + "\", false, true )");
            }
            else
            {
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + id + "\", true, false )");
                let defaults = UserDefaults.standard;
                let storeData = ["payload":payload,
                                 "method":method,
                                 "server":server,
                                 "route":route,
                                 "count":0,
                                 "date": CommonUtils.getDateformatter().string(from: Date())] as [String:Any];
                if let storedDataInfo = defaults.value(forKey: webDataKey) {
                    if var storedDataArray =  storedDataInfo as? [[String:Any]] {
                        storedDataArray.append(storeData);
                        defaults.set(storedDataArray, forKey: webDataKey);
                    }
                }
                else
                {
                    let storedDataInfo:[[String:Any]] = [storeData];
                    defaults.set(storedDataInfo, forKey: webDataKey);
                }
                defaults.synchronize();
            }
        }
    }
    
    
    class func forwardStoredData()
    {
        if( !sendInProgress ) {
            sendInProgress = true;
            let defaults = UserDefaults.standard;
            
            if(!( defaults.value(forKey: webDataKey) == nil))
            {
                let dataStored =  defaults.value(forKey: webDataKey) as? [[String:Any]];
                var dataUndelivered = [[String : Any]]();
                let countLimit = CommonUtils.getLogCountLimit();
                let timeLimit = CommonUtils.getLogTimeLimit();
                let retryCount = CommonUtils.getLogRetryCount();
                
                if dataStored != nil {
                    for data in dataStored!
                    {
                        let method = data["method"] as? String ?? ""
                        let server = data["server"] as? String ?? ""
                        let route = data["route"] as? String ?? ""
                        let payload = data["payload"] as? NSDictionary
                        let requestData = try! JSONSerialization.data(withJSONObject: payload, options: []);
                        if(!sendData(data:requestData, method:method, server:server, route:route))
                        {
                            if var dataRetryCount = data["count"] as? Int {
                                if let dataDate = data["date"] as? String {
                                    let metricTimestamp = CommonUtils.getDateformatter().date(from: dataDate);
                                    let timeGap = Date().timeIntervalSince(metricTimestamp!);
                                    if((dataRetryCount<retryCount) && (timeGap<timeLimit))
                                    {
                                        dataRetryCount = retryCount + 1;
                                        var dataTemp = data;
                                        dataTemp["count"] = dataRetryCount;
                                        dataUndelivered.append(dataTemp);
                                    }
                                }
                            }
                        }
                    }
                }
                
                let dataStoredTemp =  defaults.value(forKey: webDataKey) as? [[String:Any]];
                let dataNewlyAdded = dataStoredTemp?.dropFirst((dataStored?.count)!);
                for data in dataNewlyAdded!
                {
                    dataUndelivered.append(data);
                }
                
                if(dataUndelivered.count > 0)
                {
                    if(dataUndelivered.count>countLimit)
                    {
                        dataUndelivered = Array(dataUndelivered.dropFirst(dataUndelivered.count-countLimit));
                    }
                }
                defaults.set(dataUndelivered, forKey: webDataKey);
                defaults.synchronize();
            }
        }
        sendInProgress = false;
    }
}
