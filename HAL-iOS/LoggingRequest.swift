//
//  LoggingRequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/22/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class LoggingRequest{
    static var sendInProgress = false;
    static let ssoConnectionURL = "/pos/ApplicationLoggingServices/rest/V1/logMsg";
    static let metricsLog = "metricsLog";
    static let metrics_error = "Error";
    static let metrics_warning = "Warning";
    static let metrics_info = "Info";
    static let metrics_app_startup = "AppStartUp";
    static let metrics_app_shutdown = "AppShutDown";
    static let metrics_app_crash = "AppCrash";
    static let metrics_lost_network = "LostNetwork";
    static let metrics_lost_peripheral_connection = "LostPeripheralConnection";
    static let metrics_lost_printer_connection = "LostPrinterConnection";
    static let metrics_print_failed = "PrintFailed";
    
    class func makeServerRequest(data: Data, onCompletion: @escaping (_ result: Bool)->Void) {
        let networkReqURL = "https://"+SharedContainer.getSsp()+ssoConnectionURL;
        
        if let url = NSURL(string: networkReqURL) as? URL {
            let request = NSMutableURLRequest(url: url);
            let proxyDict : NSDictionary = [ "HTTPEnable": 0, "HTTPSEnable": 0 ];
            let config = URLSessionConfiguration.default;
            
            config.connectionProxyDictionary = proxyDict as? [AnyHashable : Any];
            let session = URLSession(configuration: config);

            request.httpMethod = "POST";
            request.addValue("application/json", forHTTPHeaderField: "Content-Type");
            request.addValue("application/json", forHTTPHeaderField: "Accept");
            request.addValue("01.000.0000", forHTTPHeaderField: "RequesterInfo.version");
            request.addValue("Stores", forHTTPHeaderField: "RequesterInfo.clientId");
            request.addValue("SPOS", forHTTPHeaderField: "RequesterInfo.subclientId");
            request.httpBody=data;
        
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil) {
                    DLog(error.debugDescription);
                    onCompletion(false);
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
                                    DLog("Sent message through LoggingRequest.");
                                    onCompletion(true);
                                }
                                else
                                {
                                    onCompletion(false);
                                }
                            }
                        } catch {
                            DLog(error as! String);
                            onCompletion(false);
                        }
                        
                    }
                    else
                    {
                        DLog(String(data: data!, encoding: String.Encoding.utf8) ?? "failed sending data to server");
                        onCompletion(false);
                    }
                }})
            task.resume();
        }
    }
    
    class func logData(name:String,value:String,type:String,indexable:Bool)-> Void {
        DispatchQueue.global(qos: .background).async {
            var value=value;
            var metricDataArray = [[String:Any]]();
            metricDataArray.append(["name": "AppEventType","value": name,"type": "STRING","indexable":indexable]);
            
            if(!(value.characters.count==0))
            {
                metricDataArray.append(["name": "AppEventValue","value": value,"type": type,"indexable":indexable]);
            }
            
            metricDataArray.append(contentsOf: CommonUtils.getCommonLogMetrics());
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            dateFormatter.timeZone = TimeZone.current;
        
            let metricdata = ["data":metricDataArray,
                              "count":0,
                              "date": dateFormatter.string(from: Date())] as [String:Any];
        
            let val = [
                "application": "Stores",
                "logLevel": "INFO",
                "dateTime": metricdata["date"] as! String ,
                "message": "This is a log message",
                "serviceVersion": 1,
                "messageLevel": "ENTERPRISE",
                "metaData":[
                    "transType":"Mobile",
                    "componentName": "EnterpriseTest",
                    "correlationID": "1",
                    "metricList": [
                        "metrics":  metricdata["data"]
                    ]
                ]
                ] as [String : Any];
            
            let requestData = try! JSONSerialization.data(withJSONObject: val, options: []);

            if( sendData(data:requestData) ) {
                
                DLog("LoggingRequest logData: " + String(data: requestData, encoding: String.Encoding.utf8)!);
            }
            else
            {
                let defaults = UserDefaults.standard;
                if let metricsinfo = defaults.value(forKey: metricsLog) {
                    if var metricsArray =  metricsinfo as? [[String:Any]] {
                        metricsArray.append(metricdata);
                        defaults.set(metricsArray, forKey: metricsLog);
                    }
                }
                else
                {
                    let metricsinfo:[[String:Any]] = [metricdata];
                        defaults.set(metricsinfo, forKey: metricsLog);
                }
                defaults.synchronize();
            }
            
        }
    }
    
    class func logStoredData()
    {
        if( !sendInProgress ) {
            sendInProgress = true;
            
            let defaults = UserDefaults.standard;
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            dateFormatter.timeZone = TimeZone.current;
        
            if(!( defaults.value(forKey: metricsLog) == nil))
            {
                let metricsStored =  defaults.value(forKey: metricsLog) as? [[String:Any]];
                var metricsUndelivered = [[String : Any]]();
                let logCountLimit = CommonUtils.getLogCountLimit();
                let logTimeLimit = CommonUtils.getLogTimeLimit();
                let logRetryCount = CommonUtils.getLogRetryCount();
                
                if metricsStored != nil {
                    for  metric in metricsStored!
                    {
                        let metadata = [
                            "application": "Stores",
                            "logLevel": "INFO",
                            "dateTime": metric["date"] as! String ,
                            "message": "This is a log message",
                            "serviceVersion": 1,
                            "messageLevel": "ENTERPRISE",
                            "metaData":[
                                "transType":"Mobile",
                                "componentName": "EnterpriseTest",
                                "correlationID": "1",
                                "metricList": [
                                    "metrics":  metric["data"]
                                ]
                            ]
                        ] as [String : Any];

                        let dateNow = Date();
                        let requestData = try! JSONSerialization.data(withJSONObject: metadata, options: []);
                        
                        DLog("LoggingRequest logStoredData: " + String(data: requestData, encoding: String.Encoding.utf8)!);

                        if(!sendData(data: requestData))
                        {
                            if var metricRetryCount = metric["count"] as? Int {
                                if let metricDate = metric["date"] as? String {
                                    let metricTimestamp = dateFormatter.date(from: metricDate);
                                    let timeGap = dateNow.timeIntervalSince(metricTimestamp!);
                                    
                                    if((metricRetryCount<logRetryCount) && (timeGap<logTimeLimit))
                                    {
                                        metricRetryCount = metricRetryCount + 1;
                                        var metricTemp = metric;
                                        metricTemp["count"] = metricRetryCount;
                                        metricsUndelivered.append(metricTemp);
                                    }
                                }
                            }
                        }
                  }
                }
                let metricsStoredTemp =  defaults.value(forKey: metricsLog) as? [[String:Any]];
                let metricsNewlyAdded = metricsStoredTemp?.dropFirst((metricsStored?.count)!);
                for metric in metricsNewlyAdded!
                {
                    metricsUndelivered.append(metric);
                }
                
                if(metricsUndelivered.count > 0)
                {
                    if(metricsUndelivered.count>logCountLimit)
                    {
                        metricsUndelivered = Array(metricsUndelivered.dropFirst(metricsUndelivered.count-logCountLimit));
                    }
                    defaults.set(metricsUndelivered, forKey: metricsLog);
                }
                
                defaults.synchronize();
            }
        }
        else {
            
            DLog("I'm already sending logs.");
        }
        sendInProgress = false;
    }
    
    class func sendData(data: Data) -> Bool
    {
        var response = false;
        let sem = DispatchSemaphore(value: 0);
        
        makeServerRequest(data: data) {
            (result: Bool) in
            response = result;
            sem.signal();
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture);
        
        return response;
    }
}
