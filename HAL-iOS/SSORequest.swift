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
            
            let proxyDict : NSDictionary = [ "HTTPEnable": 0, "HTTPSEnable": 0 ];
            let config = URLSessionConfiguration.default;
            let params: [String: String] = [ "associateNumber":associateNumber, "associatePin":associatePin ];
            
            request.httpMethod = "POST";
            config.connectionProxyDictionary = proxyDict as? [AnyHashable : Any];
            let session = URLSession(configuration: config);
            //            let session = URLSession.shared;
            
            do {
                let jsonreqdata = try JSONSerialization.data(withJSONObject: params);
                request.httpBody=jsonreqdata;
            } catch {
                DLog("json error: \(error)");
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type");
            request.addValue("application/json", forHTTPHeaderField: "Accepts");
            request.addValue("0.0.1", forHTTPHeaderField: "RequesterInfo.version");
            request.addValue("POS", forHTTPHeaderField: "RequesterInfo.clientId");
            request.addValue("POS", forHTTPHeaderField: "RequesterInfo.subclientId");
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil) {
                    DLog(error!.localizedDescription);
                    
                    if (!(Int(associateNumber)==nil) && !(Int(associatePin)==nil) && (associateNumber.characters.count==8) && (associatePin.characters.count==4)){
                        CommonUtils.setAuthServiceUnavailableInfo(assocNbr: associateNumber);
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
                    onCompletion(error!.localizedDescription);
                }
                else
                {
                    let defaults = UserDefaults.standard;
                    let resp = response! as? HTTPURLResponse;
                    let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue);
                    let json = JSON(data: data!);
                    let ssoJsonObject : Json4Swift_Base = Json4Swift_Base(dictionary: json)!;
                    
//                    DLog(response.debugDescription);
//                    DLog(strData);
//                    DLog(resp?.statusCode);
                    
                    if( resp != nil && resp?.statusCode == 200 ) {
                        if( ssoJsonObject.associateInfo != nil ) {
                            CommonUtils.setIsSSOAuthenticated(value: true);
                            defaults.setValue(ssoJsonObject.dictionaryRepresentation(), forKey: CommonUtils.ssoAssociateInfo);
                        }
                        else {
                            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by nil ssoJsonObject.", type: "STRING", indexable: true);
                            CommonUtils.setIsSSOAuthenticated(value: false);
                            defaults.setValue([:], forKey: CommonUtils.ssoAssociateInfo);
                        }
                    }
                    else if ( ( ssoJsonObject.code == nil ) && !( Int( associateNumber ) == nil ) &&
                        !( Int( associatePin ) == nil) && ( associateNumber.characters.count == 8 ) &&
                        ( associatePin.characters.count == 4 ) ) {
                        CommonUtils.setAuthServiceUnavailableInfo(assocNbr: associateNumber);
                    }
                    else {
                        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by other.", type: "STRING", indexable: true);
                        CommonUtils.setIsSSOAuthenticated(value: false);
                        defaults.setValue([:], forKey: CommonUtils.ssoAssociateInfo);
                    }
                    onCompletion(strData as! String);
                }
            })
            task.resume();
        }
    }
}
