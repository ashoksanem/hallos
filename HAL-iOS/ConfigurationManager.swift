//
//  ConfigurationManager.swift
//  HAL-iOS
//
//  Created by Scott Williams on 10/17/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

class ConfigurationManager : NSObject {
    
    class func readESPValues(parms:Array<String>, _ data:Data) -> Bool
    {
//        response from esp in readable format
//        let readableESPResponse = String(data: data, encoding: String.Encoding.utf8);
//        DLog(readableESPResponse ?? "");
        do{
            let jsonDictionary = try XMLReader.dictionary(forXMLData: data);
            var jsonData = JSON(jsonDictionary).dictionaryObject;
            let parmsDictionary = ((((jsonData?["soap:Envelope"] as? NSDictionary)?["soap:Body"] as? NSDictionary)?["ns2:getRequestedParametersResponse"] as? NSDictionary)?["parameterResponse"] as? NSDictionary)?["data"] as? NSDictionary;
            
            for parm in parms
            {
                if(parm == "MST")
                {
                    //as of now, all master store parms are required, so we will return false if they're missing or empty strings
                    let masterStoreParms = parmsDictionary?["master_store_v5"] as? NSDictionary;
                    
                    func getMstParm(_ parmName: String) -> String
                    {
                        if let localParm = (masterStoreParms?[parmName] as? NSDictionary)?["text"]
                        {
                            return localParm as! String;
                        }
                        return "";
                    }
                    
                    let zipCode = getMstParm("zip");
                    if(zipCode == "")
                    {
                        return false;
                    }
                    CommonUtils.setZipCode(value: zipCode);
                    
                    if let storeNum = Int(getMstParm("store_num"))
                    {
                        CommonUtils.setStoreNum(value: storeNum);
                    }
                    else
                    {
                        return false;
                    }
                    
                    if let divNum = Int(getMstParm("div_num"))
                    {
                        CommonUtils.setDivNum(value: divNum);
                    }
                    else
                    {
                        return false;
                    }
                    
                }
                else if(parm == "L4P")
                {
                    if let lvl4 = ((parmsDictionary?["level_4_parms_list_v5"] as? NSDictionary)?["level_4_parms_list"] as? NSDictionary)?["level_4_parms"] as? [NSDictionary]
                    {
                        //closure func to abstract redundant code
                        func getL4Parm(_ parmDictionary: NSDictionary) -> String
                        {
                            if let parmVal = (parmDictionary["value"] as? NSDictionary)?["text"]
                            {
                                return parmVal as! String;
                            }
                            return "";
                        }
                        
                        for lvl4Parm in lvl4
                        {
                            let parmName = (lvl4Parm["name"] as? NSDictionary)?["text"];
                            let parmValue = getL4Parm(lvl4Parm);
                            
                            if(parmName as! String == "HAL_IOS_CLIENT_VERSION")
                            {
                                //no need to provide fallback because if we don't get this, there's no point in verifying the app version
                                if(parmValue != "")
                                {
                                    if let delegate = UIApplication.shared.delegate as? AppDelegate
                                    {
                                        delegate.verifyAppVersion(version: parmValue);
                                    }
                                }
                            }
                            else if(parmName as! String == "HAL_IOS_INACTIVITY_TIMEOUT")
                            {
                                if let inactivityTimeout = Int(parmValue)
                                {
                                    CommonUtils.setInactivityTimeInterval(inactivityTimeout);
                                }
                            }
                            else if(parmName as! String == "HAL_IOS_AUTHENTICATED_INACTIVITY_TIMEOUT")
                            {
                                if let authenticatedInactivityTimeout = Int(parmValue)
                                {
                                    CommonUtils.setAuthenticatedInactivityTimeInterval(authenticatedInactivityTimeout);
                                }
                            }
                            else if(parmName as! String == "HAL_AUTO_LOGOUT" && !existsInMDM("autoLogout"))
                            {
                                if let autoLogoutPeriod = Int(parmValue)
                                {
                                    CommonUtils.setAutoLogoutTimeinterval(autoLogoutPeriod);
                                }
                            }
                            else if(parmName as! String == "HAL_LOG_RETRY_COUNT" && !existsInMDM("LogRetryCount"))
                            {
                                if let logRetryCountLimit = Int(parmValue)
                                {
                                    CommonUtils.setLogRetryCount(logRetryCountLimit);
                                }
                            }
                            else if(parmName as! String == "HAL_LOG_RETRY_FREQUENCY" && !existsInMDM("LogRetryFrequency"))
                            {
                                if let logRetryFrequency = Int(parmValue)
                                {
                                    CommonUtils.setLogRetryFrequency(Double(logRetryFrequency));
                                }
                            }
                            else if(parmName as! String == "HAL_LOG_RETRY_TIME_LIMIT" && !existsInMDM("LogStorageTimeLimit"))
                            {
                                if let logRetryTimeLimit = Int(parmValue)
                                {
                                    CommonUtils.setLogTimeLimit(Double(logRetryTimeLimit));
                                }
                            }
                            else if(parmName as! String == "HAL_LOG_STORAGE_COUNT_LIMIT" && !existsInMDM("LogStorageCountLimit"))
                            {
                                if let logStorageCountLimit = Int(parmValue)
                                {
                                    CommonUtils.setLogCountLimit(logStorageCountLimit);
                                }
                            }
                            else if(parmName as! String == "HAL_MOBILE_LANDING_PAGE" && !existsInMDM("landingPage"))
                            {
                                if(parmValue != "")
                                {
                                    CommonUtils.setLandingPage(URL(string: parmValue)!);
                                }
                            }
                            else if(parmName as! String == "SSP_NAME" && !existsInMDM("ssp"))
                            {
                                if(parmValue != "")
                                {
                                    SharedContainer.setSsp(value: parmValue);
                                }
                            }
                        }
                    }
                    else {
                        let error = "***An error occurred parsing the ESP service response***";
                        DLog(error);
                        LoggingRequest.logData(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
                        return false;
                    }
                }
                else
                {
                    DLog("The parm handler hasn't been written for this parm yet");
                }
            }
            
            return true;
        }
        catch
        {
            let error = "***An error occurred parsing the ESP service response***";
            DLog(error);
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
        }
        return false;
    }
    
    class func readMDMValues()
    {
        let userDefaults = UserDefaults.standard;
        if let answersSaved = userDefaults.dictionary(forKey: CommonUtils.managedAppConfig)
        {
            if let delegate = UIApplication.shared.delegate as? AppDelegate
            {
                NotificationCenter.default.removeObserver(delegate, name: UserDefaults.didChangeNotification, object: nil);
            }
//            answersSaved.removeAll(); //use this line to clear all airwatch values for a device, don't push into master
            if let val = answersSaved["landingPage"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    let url = URL(string: trimmed)!;
                    CommonUtils.setLandingPage(url);
                    
                    DLog("Setting landingPage to: " + trimmed);
                }
            }
            
            if let val = answersSaved["autoLogout"]
            {
                if(val as? Int != nil)
                {
                    CommonUtils.setAutoLogoutTimeinterval(val as! Int);
                    let val = "Setting autoLogout to: " + String(describing:val);
                    
                    DLog( val );
                }
            }
            
            if let val = answersSaved["divNum"]
            {
                if(val as? Int != nil)
                {
                    CommonUtils.setDivNum(value: val as! Int);
                    
                    DLog("Setting divNum to: " + String(describing:val));
                }
            }
            
            if let val = answersSaved["storeNum"]
            {
                if(val as? Int != nil)
                {
                    CommonUtils.setStoreNum(value: val as! Int);
                    
                    DLog("Setting storeNum to: " + String(describing:val));
                }
            }
            
            if let val = answersSaved["isp"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setIsp(value: trimmed);
                    
                    DLog("Setting isp to: " + trimmed);
                }
            }
            
            if let val = answersSaved["ssp"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setSsp(value: trimmed);
                    
                    DLog("Setting ssp to: " + trimmed);
                }
            }
            
            if let val = answersSaved["cloud"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setCloud(value: trimmed);
                    
                    DLog("Setting cloud to: " + trimmed);
                }
            }
            
            if let val = answersSaved["LogRetryCount"]
            {
                if(val as? Int != nil)
                {
                    CommonUtils.setLogRetryCount(val as! Int);
                }
            }
            
            if let val = answersSaved["LogStorageCountLimit"]
            {
                if(val as? Int != nil)
                {
                    CommonUtils.setLogCountLimit(val as! Int);
                }
            }
            
            if let val = answersSaved["LogRetryFrequency"]
            {
                if(val as? Double != nil)
                {
                    CommonUtils.setLogRetryFrequency(val as! Double);
                }
            }
            
            if let val = answersSaved["LogStorageTimeLimit"]
            {
                if(val as? Double != nil)
                {
                    CommonUtils.setLogTimeLimit(val as! Double);
                }
            }
            
            if let val = answersSaved["CertificatePinning"]
            {
                if(val as? Bool != nil)
                {
                    CommonUtils.setCertificatePinningEnabled(value: val as! Bool);
                }
            }
            
            if let val = answersSaved["GroupID"]
            {
                if let _val = val as? String  {
                    if _val == "byoddev" || _val == "byodprod" {
                        CommonUtils.setisBYOD(value: true);
                        SharedContainer.setIsp(value: "isp01");
                        DLog("Setting isp in BYOD mode to: isp01");
                    }
                }
            }
        }
        
        CommonUtils.isPreProd() ? Heap.setAppId("282132961") : Heap.setAppId("1675328291");   //282132961 = development  1675328291 = production
        //Heap.enableVisualizer();  // let's keep this here for future research but don't want it turned on now.
    }
    
    class func existsInMDM(_ param:String) -> Bool
    {
        let userDefaults = UserDefaults.standard;
        if let answersSaved = userDefaults.dictionary(forKey: CommonUtils.managedAppConfig)
        {
            if (answersSaved[param] != nil)
            {
                return true;
            }
            return false;
        }
        return false;
    }
    
    class func hasCriticalParms() -> Bool
    {
        if( CommonUtils.isDefaultLandingPage(CommonUtils.getLandingPage()) ||
            CommonUtils.isBlankPage(CommonUtils.getLandingPage()) ||
            CommonUtils.getDivNum() == -1 ||
            CommonUtils.getStoreNum() == -1
            )
        {
            return false;
        }
        return true;
    }
}
