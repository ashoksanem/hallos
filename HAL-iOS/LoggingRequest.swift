//
//  LoggingRequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/22/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class LoggingRequest{
    static let ssoConnectionURL = "https://macyssp/pos/ApplicationLoggingServices/rest/V1/logMsg";
    static let metricsLog = "metricsLog";
    static let metrics_app_startup = "AppStartUp";
    static let metrics_app_shutdown = "AppShutDown";
    static let metrics_app_crash = "AppCrash";
    static let metrics_lost_network = "LostNetwork";
    static let metrics_lost_peripheral_connection = "LostPeripheralConnection";
    static let metrics_lost_printer_connection = "LostPrinterConnection";
    static let metrics_print_failed = "PrintFailed";
    class func makeServerRequest(data: Data,onCompletion: @escaping (_ result: Bool)->Void) {
        let request = NSMutableURLRequest(url: NSURL(string: ssoConnectionURL) as! URL)
        let session = URLSession.shared
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accepts")
        request.addValue("01.000.0000", forHTTPHeaderField: "RequesterInfo.version")
        request.addValue("Stores", forHTTPHeaderField: "RequesterInfo.clientId")
        request.addValue("SPOS", forHTTPHeaderField: "RequesterInfo.subclientId")
        request.httpBody=data;
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if(error != nil) {
                print(error.debugDescription)
                onCompletion(false)
            }
            else
            {
                let resp=response! as! HTTPURLResponse;
                if(resp.statusCode==200){
                do {
                    let json = JSON(data: data!).dictionaryObject
                    let reasonCode=json?["reasonCode"] as! String
                    if(reasonCode=="0")
                    {
                       print("success")
                       onCompletion(true)
                    }
                    else
                    {
                       onCompletion(false)
                    }
                } catch {
                    print(error)
                    onCompletion(false)
                }
                
                }
                else
                {
                  print(String(data: data!, encoding: String.Encoding.utf8) ?? "failed sending data to server");
                  onCompletion(false)
                }
            }})
        task.resume()
    }
    
    class func logData(name:String,value:String,type:String,indexable:Bool)-> Void {
        var value=value;
        if(value.characters.count==0)
        {
            value=name
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone.current

        let metricdata = ["data":[
            "name": name,
            "value": value,
            "type": type,
            "indexable":indexable
            ],
            "date": dateFormatter.string(from: Date())] as [String:Any]
        
        let defaults = UserDefaults.standard
       if let metricsinfo = defaults.value(forKey: metricsLog) {
            var metricsArray =  metricsinfo as! [[String:Any]];
            metricsArray.append(metricdata)
            defaults.set(metricsArray, forKey: metricsLog)
        }
        else
        {
            let metricsinfo:[[String:Any]]=[metricdata];
            defaults.set(metricsinfo, forKey: metricsLog)
        }
        defaults.synchronize()
        var metricsStored =  defaults.value(forKey: metricsLog) as! [[String:Any]];
        var isNetworkOn=true;
        var metricsCount=0;
        while(isNetworkOn && metricsCount<metricsStored.count)
        {
            let metadata = [
            "application": "Stores",
            "logLevel": "INFO",
            "dateTime": metricdata["date"] ,
            "message": "This is a log message",
            "serviceVersion": 1,
            "messageLevel": "ENTERPRISE",
            "metaData":[
                "componentName": "EnterpriseTest",
                "correlationID": "1",
                "metricList": [
                    "metrics":  [metricsStored[metricsCount]["data"]]               ]
            ]
            ] as [String : Any]
        
        let requestData = try! JSONSerialization.data(withJSONObject: metadata, options: [])
            print(metadata)
        isNetworkOn = sendData(data: requestData)
        metricsCount=metricsCount+1;
        }
        if(!isNetworkOn)
        {
            let metricsRemaining = metricsStored.dropFirst(metricsCount-1)
            defaults.set(Array(metricsRemaining), forKey: metricsLog)
        }
        else{
            defaults.removeObject(forKey: metricsLog)
        }
        
    }
    
    class func sendData(data: Data) -> Bool
    {
        var response=false;
        let sem = DispatchSemaphore(value: 0)
        
        makeServerRequest(data: data){
            (result: Bool) in
            response = result
            sem.signal()
        }
        sem.wait(timeout: DispatchTime.distantFuture)
        
        return response
    }
}
