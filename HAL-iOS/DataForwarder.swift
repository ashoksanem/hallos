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
    
class func makeServerRequest(method: String, networkReqURL: String, data: Data, onCompletion: @escaping (_ result: Bool,_ error:String)->Void) {
     if let url = NSURL(string: networkReqURL) as URL? {
        let request = NSMutableURLRequest(url: url);
        let proxyDict : NSDictionary = [ "HTTPEnable": 0, "HTTPSEnable": 0 ];
        let config = URLSessionConfiguration.default;
        
        config.connectionProxyDictionary = proxyDict as? [AnyHashable : Any];
        let session = URLSession(configuration: config);
        request.httpMethod = method;
        
        do
        {
            var jsonData = try JSON(data: data).dictionaryObject;
            
            if (!(jsonData==nil) && !(jsonData?["headers"]==nil)) {
            
                if let headersDict = jsonData?["headers"] as? [String:String]
                {
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
                    if(error != nil)
                    {
                        DLog(error.debugDescription);
                        logvalue = "Error in sending data:"+String(describing:jsonData)+" with error: "+error.debugDescription;
                        onCompletion(false,logvalue);
                    }
                    else
                    {
                        let resp=response! as? HTTPURLResponse;
                        if(resp != nil && resp?.statusCode==200)
                        {
                            do {
                                onCompletion(true,logvalue);
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
        catch
        {
            let log = "DataForwarded: Unable to parse jsonData";
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: log, type: "STRING", indexable: true);
            onCompletion(false, log );
        }
    }
}
    
    
    
    class func sendData(data: NSDictionary, isOfflineData:Bool) -> Bool
    {
        let method = data["method"] as? String ?? ""
        let server = data["server"] as? String ?? ""
        let route = data["route"] as? String ?? ""
        var port = data["port"] as? String ?? ""
        if(!(port==""))
        {
            port=":"+port;
        }
        var response = false;
        let payload = data["payload"] as? NSDictionary ?? [:];
        if(JSONSerialization.isValidJSONObject(payload))
        {
        let  requestData = try! JSONSerialization.data(withJSONObject: payload , options: []);
        let sem = DispatchSemaphore(value: 0);
        let networkReqURL = "https://"+server+port+route;
        makeServerRequest(method: method, networkReqURL: networkReqURL, data: requestData) {
            (result: Bool,error: String) in
            response = result;
            if(isOfflineData && response)
            {
                if let storedDataInfo = SharedContainer.getData(key: SharedContainer.webDataKey)[SharedContainer.webDataKey] as? [NSDictionary] {
                    var storedDataArray =  storedDataInfo
                    if let index = storedDataArray.index(of: data)
                    {
                        storedDataArray.remove(at: index)
                        SharedContainer.saveWebData(data: storedDataArray);
                    }
                }
            }
            else if(!response && !isOfflineData)
            {
                LoggingRequest.logError(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
                if let storedDataInfo = SharedContainer.getData(key: SharedContainer.webDataKey)[SharedContainer.webDataKey] as? [NSDictionary] {
                    var storedDataArray =  storedDataInfo
                    storedDataArray.append(data);
                    SharedContainer.saveWebData(data: storedDataArray);
                }
                else
                {
                    let storedDataInfo:[NSDictionary] = [data];
                    SharedContainer.saveWebData(data: storedDataInfo);
                }
            }
            sem.signal();
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture);
        }
        else
        {
            return false;
        }
        return response;
    }
    
    
    class func forwardData(data: NSDictionary)
    {
        DispatchQueue.global(qos: .background).async {
            let handle = data["handle"] as? String ?? ""
            if( sendData(data:data,isOfflineData: false) ) {
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + handle + "\", false, true )");
            }
            else
            {
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + handle + "\", true, false )");
            }
        }
    }
    
    
    class func forwardStoredData()
    {
        if( !sendInProgress ) {
            sendInProgress = true;
            
            if(!( SharedContainer.getData(key: SharedContainer.webDataKey)[SharedContainer.webDataKey] == nil))
            {
                let dataStored =  SharedContainer.getData(key: SharedContainer.webDataKey)[SharedContainer.webDataKey] as? [NSDictionary];
               if dataStored != nil {
                    for data in dataStored!
                    {
                       sendData(data:data, isOfflineData: true)
                    }
                }
            }
        }
        sendInProgress = false;
    }
}
