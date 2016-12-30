//
//  LogAnalyticsRequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 12/13/16.
//  Copyright © 2016 macys. All rights reserved.
//
import Foundation
class LogAnalyticsRequest{
    static let ssoConnectionURL = "/pos/ApplicationLoggingServices/rest/V1/logMsg";
    static let metricsLog = "analyticMetricsLog";
    
    class func makeServerRequest(data: Data,onCompletion: @escaping (_ result: Bool)->Void) {
        let networkReqURL = "https://"+SharedContainer.getSsp()+ssoConnectionURL;
        let request = NSMutableURLRequest(url: NSURL(string: networkReqURL) as! URL)
        let session = URLSession.shared
        request.httpMethod = "POST"
        var jsonData = JSON(data: data).dictionaryObject
        //print(jsonData?["headers"])
        let headersDict = jsonData?["headers"] as! [String:String]
        request.addValue(headersDict["Content-Type"]!, forHTTPHeaderField: "Content-Type")
        request.addValue(headersDict["Accepts"]!, forHTTPHeaderField: "Accepts")
        request.addValue(headersDict["RequesterInfo.version"]!, forHTTPHeaderField: "RequesterInfo.version")
        request.addValue(headersDict["RequesterInfo.clientId"]!, forHTTPHeaderField: "RequesterInfo.clientId")
        request.addValue(headersDict["RequesterInfo.subclientId"]!, forHTTPHeaderField: "RequesterInfo.subclientId")
        jsonData?.removeValue(forKey: "headers")
        let finalData=try! JSONSerialization.data(withJSONObject: jsonData, options: [])
        
        request.httpBody=finalData;
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
    
    class func logDataTest()-> Void {
        if let file = Bundle.main.path(forResource: "logAnalytics", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                logData(data: data)
            } catch {
            }
        }
    }
    
    class func logData(data:Data)-> Void {
        let defaults = UserDefaults.standard
        
        if let metricsinfo = defaults.value(forKey: metricsLog) {
            var metricsArray =  metricsinfo as! [Data];
            metricsArray.append(data)
            defaults.set(metricsArray, forKey: metricsLog)
        }
        else
        {
            let metricsinfo:[Data]=[data];
            defaults.set(metricsinfo, forKey: metricsLog)
        }
        
        defaults.synchronize()
        var metricsStored =  defaults.value(forKey: metricsLog) as! [Data];
        var isNetworkOn=true;
        var metricsCount=0;
        
        while(isNetworkOn && metricsCount<metricsStored.count)
        {
            isNetworkOn = sendData(data: metricsStored[metricsCount])
            metricsCount=metricsCount+1;
        }
        
        if(!isNetworkOn)
        {
            let metricsRemaining = metricsStored.dropFirst(metricsCount-1)
            defaults.set(Array(metricsRemaining), forKey: metricsLog)
        }
        else {
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
