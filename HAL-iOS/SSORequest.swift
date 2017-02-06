//
//  SSORequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/5/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class SSORequest{
    static let ssoConnectionURL = "/pos/AssociateAuthenticateService/rest/V2/pinAuthenticate";
    
    //this method takes associate number and associate pin and makes rest call to get response
    class func makeSSORequest(associateNumber: String,associatePin: String,onCompletion: @escaping (_ result: String)->Void) {
        let networkReqURL = "https://"+SharedContainer.getSsp()+ssoConnectionURL;

        if let url = NSURL(string: networkReqURL) as? URL {
        
            let request = NSMutableURLRequest(url: url);
            let proxyHost = "11.48.43.71";
            let proxyPort = 8080;
            let proxyDict : NSDictionary = ["HTTPEnable": 0, "HTTPProxy": proxyHost, "HTTPPort": proxyPort, "HTTPSEnable": 0, "HTTPSProxy": proxyHost, "HTTPSPort": proxyPort]
            let config = URLSessionConfiguration.default
            config.connectionProxyDictionary=proxyDict as? [AnyHashable : Any];
            let session = URLSession(configuration: config)

            //let session = URLSession.shared
            request.httpMethod = "POST"
            let params: [String: [String: String]] = [ "pinlogon":  [
                    "associateNumber":associateNumber, "associatePin":associatePin
                ]   ]
            
            do {
                let jsonreqdata = try JSONSerialization.data(withJSONObject: params)
                request.httpBody=jsonreqdata
                } catch {
                    print("json error: \(error)")
                }
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accepts")
                request.addValue("0.0.1", forHTTPHeaderField: "RequesterInfo.version")
                request.addValue("POS", forHTTPHeaderField: "RequesterInfo.clientId")
                request.addValue("POS", forHTTPHeaderField: "RequesterInfo.subclientId")
        
                let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                    if(error != nil) {
                        print(error!.localizedDescription)
                        if (!(Int(associateNumber)==nil) && !(Int(associatePin)==nil) && (associateNumber.characters.count==8) && (associatePin.characters.count==4)){
                            CommonUtils.setAuthServiceUnavailableInfo(assocNbr: associateNumber)
                        }
                
                        /*test code for dummy data*/
                        /* if let file = Bundle.main.path(forResource: "ssosuccess", ofType: "json") {
                         do {
                                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                                let strData = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
                                print("dummy data: \(strData)")
                                CommonUtils.setSSOData(value: data)
                                } catch {
                                //viewController.json = JSON.null
                            }
                         }
                         */
                        /*test code for dummy data*/
                        onCompletion(error!.localizedDescription)
                    }
                    else
                    {
                        let resp=response! as? HTTPURLResponse;
                        let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                        CommonUtils.setSSOData(value: data!)
                        print(response.debugDescription)
                        print(strData)
                        if(resp != nil && resp?.statusCode==200){
                            onCompletion(strData as! String)
                        }
                        else
                        {
                            if (!(Int(associateNumber)==nil) && !(Int(associatePin)==nil) && (associateNumber.characters.count==8) && (associatePin.characters.count==4)){
                                CommonUtils.setAuthServiceUnavailableInfo(assocNbr: associateNumber)
                            }
                            onCompletion(strData as! String)
                        }
                    }
                })
                task.resume();
        }
    }
}
