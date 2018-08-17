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
    
    func getParms( _ parms:Array<String>, onCompletion: @escaping (_ result: String) -> Void )
    {
        let timeSinceLastParms = CommonUtils.getLastTimeParmsWereRetrieved().timeIntervalSinceNow * -1;
        let thirtyMinutes = 1*30*60 as Double; //30 minutes
        
        if((timeSinceLastParms < thirtyMinutes && ConfigurationManager.hasCriticalParms()) || CommonUtils.getisBYOD())
        {
            onCompletion(""); //don't get parms if we already got them recently or if we're missing important ones or when the app is in BYOD mode
        }
        else{
            let espVersion = "6";
            
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
            let urlString = "https://" + SharedContainer.getSsp() + "/parm/v" + espVersion;
            let url = NSURL(string: urlString);
            let theRequest = NSMutableURLRequest(url: url! as URL);
            let msgLength = String(soapMessage.count);
            
            theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type");
            theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length");
            theRequest.httpMethod = "POST";
            theRequest.httpBody = soapMessage.data(using: String.Encoding.utf8, allowLossyConversion: false);
            
            //        DLog( "ESP Request: " + String(data: theRequest.httpBody!, encoding: .utf8)! );
            
            let config = URLSessionConfiguration.default;
            config.requestCachePolicy = .reloadIgnoringCacheData;
            let session = URLSession(configuration:config, delegate: self, delegateQueue: OperationQueue.main);
            let task = session.dataTask(with: theRequest as URLRequest, completionHandler: {data, response, error -> Void in
                if(error == nil) {
                    if ( ConfigurationManager.readESPValues(parms: self.parms, data!) )
                    {
                        onCompletion("");
                        CommonUtils.setLastTimeParmsWereRetrieved();
                    }
                    else
                    {
                        onCompletion("error");
                    }
                    self.parms.removeAll();
                }
                else {
                    let error = "***An error occurred obtaining a good response from the ESP service***";
                    DLog(error);
                    LoggingRequest.logData(name: LoggingRequest.metrics_error, value: error, type: "STRING", indexable: false);
                    self.parms.removeAll();
                    onCompletion("error");
                }
            });
            task.resume();
        }
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
