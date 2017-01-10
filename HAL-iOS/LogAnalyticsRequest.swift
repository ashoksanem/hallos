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
        if (!(jsonData==nil) && !(jsonData?["headers"]==nil)) {
            
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
        else
        {
            onCompletion(false)
        }
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
    class func logIncorrectDataTest()-> Void {
        if let file = Bundle.main.path(forResource: "logAnalyticsIncorrectData", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                logData(data: data)
            } catch {
            }
        }
    }
    class func logData(data:String)-> Void {
        logData(data: data.data(using: String.Encoding.utf8)!)
    }
    
    class func logData(data:Data)-> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone.current
        let defaults = UserDefaults.standard
        //defaults.removeObject(forKey: metricsLog)
        let metricdata = ["data":data,
                          "count":0,
                          "date": dateFormatter.string(from: Date())] as [String:Any]
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
        logStoredData()
    }
    class func logStoredData()
    {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone.current
        var metricslist =  defaults.value(forKey: metricsLog);
        if(!(metricslist==nil))
        {
        let metricsStored =  defaults.value(forKey: metricsLog) as! [[String:Any]]
        var metricsUndelivered = [[String : Any]]();
        let logCountLimit = CommonUtils.getLogCountLimit();
        let logTimeLimit = CommonUtils.getLogTimeLimit();
        let logRetryCount = CommonUtils.getLogRetryCount();
        for metric in metricsStored
        {
            let dateNow = Date();
            if(!sendData(data: metric["data"] as! Data))
            {
                var metricRetryCount = metric["count"] as! Int;
                let metricDate = metric["date"] as! String;
                let metricTimestamp = dateFormatter.date(from: metricDate)
                let timeGap = dateNow.timeIntervalSince(metricTimestamp!)
                if((metricRetryCount<logRetryCount) && (timeGap<logTimeLimit))
                {
                    metricRetryCount=metricRetryCount+1;
                    var metricTemp = metric;
                    metricTemp["count"]=metricRetryCount;
                    metricsUndelivered.append(metricTemp)
                }
            }
        }
        defaults.removeObject(forKey: metricsLog)
        if(metricsUndelivered.count>0)
        {
            if(metricsUndelivered.count>logCountLimit)
            {
                metricsUndelivered=Array(metricsUndelivered.dropFirst(metricsUndelivered.count-logCountLimit))
            }
            defaults.set(metricsUndelivered, forKey: metricsLog)
        }
        }}
    
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
