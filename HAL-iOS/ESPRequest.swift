//
//  ESPRequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 12/30/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class ESPRequest: NSObject, URLSessionDelegate,URLSessionDataDelegate,URLSessionTaskDelegate, XMLParserDelegate {
    var parms = [String]();
    
    func getParms( _ parms:Array<String> )
    {
        let espVersion = "5";
        
        var parmsXML = "";
        for parm in parms
        {
            self.parms.append(parm);
            parmsXML += "<requested_parameter>" + parm + "</requested_parameter>";
        }
        
        let soapClientMessage = "<client_information><client_ip_address>" + getWiFiAddress()! + "</client_ip_address></client_information>";
        
        let soapMessageHeader = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ent='http://www.macys.com/enterprise_services' xmlns:sei='http://sei.v" + espVersion + ".services.esp.macys.com/'><soapenv:Header><ent:requestor_info><version>" + Assembly.halVersion() + "</version><client_id>Stores</client_id><subclient_id>SPOS</subclient_id></ent:requestor_info></soapenv:Header>"
        
        let soapMessageBody = "<soapenv:Body><sei:getRequestedParameters>" + soapClientMessage + "<requested_parameters><requested_parameter_list>" + parmsXML + "</requested_parameter_list></requested_parameters></sei:getRequestedParameters></soapenv:Body></soapenv:Envelope>";
     
        let soapMessage = soapMessageHeader + soapMessageBody;
        let urlString = "https://" + SharedContainer.getIsp() + "/parm/v" + espVersion;
        let url = NSURL(string: urlString);
        let theRequest = NSMutableURLRequest(url: url! as URL);
        let msgLength = String(soapMessage.characters.count);
        
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type");
        theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length");
        theRequest.httpMethod = "POST";
        theRequest.httpBody = soapMessage.data(using: String.Encoding.utf8, allowLossyConversion: false);
        
//        DLog( "ESP Request: " + String(data: theRequest.httpBody!, encoding: .utf8)! );
        
        let config = URLSessionConfiguration.default;
        let session = URLSession(configuration:config, delegate: self, delegateQueue: OperationQueue.main);
        let task = session.dataTask(with: theRequest as URLRequest, completionHandler: {data, response, error -> Void in
            self.processESPResponse(data!);
        });
        task.resume();
    }
    
    
    func processESPResponse( _ data:Data )
    {
//        response from esp in readable format
//        let readableESPResponse = String(data: data, encoding: String.Encoding.utf8);
//        DLog(readableESPResponse ?? "");
        do{
            let jsonDictionary = try XMLReader.dictionary(forXMLData: data);
            var jsonData = JSON(jsonDictionary).dictionaryObject;
            let parmsDictionary = ((((jsonData?["soap:Envelope"] as? NSDictionary)?["soap:Body"] as? NSDictionary)?["ns2:getRequestedParametersResponse"] as? NSDictionary)?["parameterResponse"] as? NSDictionary)?["data"] as? NSDictionary;
            
            for parm in self.parms
            {
                if(parm == "MST")
                {
                    let masterStoreParms = parmsDictionary?["master_store_v5"] as? NSDictionary;
                    
                    // access any master store parm using the syntax: (masterStoreParms?["parm_name"] as? NSDictionary)?["text"]
                    let zipCode = (masterStoreParms?["zip"] as? NSDictionary)?["text"];
                    CommonUtils.setZipCode(value: zipCode as? String ?? "");
                }
                else if(parm == "L4P")
                {
                    let lvl4 = ((parmsDictionary?["level_4_parms_list_v5"] as? NSDictionary)?["level_4_parms_list"] as? NSDictionary)?["level_4_parms"] as? [NSDictionary];
                    
                    for lvl4Parm in lvl4!
                    {
                        let parmName = (lvl4Parm["name"] as? NSDictionary)?["text"];
                        // access any level 4 parm using the syntax: parmName as! String == "PARM_NAME"
                        if(parmName as! String == "HAL_IOS_CLIENT_VERSION")
                        {
                            if let delegate = UIApplication.shared.delegate as? AppDelegate
                            {
                                let versionNum = (lvl4Parm["value"] as? NSDictionary)?["text"] as! String;
                                delegate.verifyAppVersion(version: versionNum);
                            }
                        }
                    }
                }
                else
                {
                    DLog("The parm handler hasn't been written for this parm yet");
                }
            }
        }
        catch
        {
            let error = "***An error occurred parsing the ESP service response***";
            DLog(error);
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
        }
        self.parms.removeAll();
    }
    
    func getWiFiAddress() -> String?
    {
        var address : String?;
        var ifaddr : UnsafeMutablePointer<ifaddrs>?;
        guard getifaddrs(&ifaddr) == 0 else { return nil };
        guard let firstAddr = ifaddr else { return nil };
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next })
        {
            let interface = ifptr.pointee;
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family;
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6)
            {
                // Check interface name:
                let name = String(cString: interface.ifa_name);
                if  name == "en0" {
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee;
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST));
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST);
                    address = String(cString: hostname);
                }
            }
        }
        
        freeifaddrs(ifaddr);
        
        if(address==nil)
        {
            return "";
        }
        else
        {
            return address;
        }
    }
}
