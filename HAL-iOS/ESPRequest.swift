//
//  ESPRequest.swift
//  HAL-iOS
//
//  Created by Pranitha on 12/30/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class ESPRequest: NSObject, URLSessionDelegate,URLSessionDataDelegate,URLSessionTaskDelegate, XMLParserDelegate {
    var mutableData:NSMutableData  = NSMutableData()
    var currentElementName:NSString = ""
    let sem = DispatchSemaphore(value: 0)
    func getZipCode() {
        
        let clientMessage = "<client_information>        <client_ip_address>"+getWiFiAddress()!+"</client_ip_address>      </client_information>";
        let soapmessageheader = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'>  <soap:Header>    <ns2:requestor_info xmlns:ns4='http://sei.v4.services.esp.macys.com/' xmlns:ns3='http://messages.services.esp.macys.com' xmlns:ns2='http://www.macys.com/enterprise_services'>      <version>01.000.0000</version>      <client_id>Stores</client_id>      <subclient_id>SPOS</subclient_id>    </ns2:requestor_info>  </soap:Header>  <soap:Body>    <ns4:getRequestedParameters xmlns:ns2='http://www.macys.com/enterprise_services' xmlns:ns3='http://messages.services.esp.macys.com' xmlns:ns4='http://sei.v4.services.esp.macys.com/'>";
        
        let requestDescriptionMessage = "      <division>"+CommonUtils.getDivNum().description+"</division>      <store>"+CommonUtils.getStoreNum().description+"</store>      <pad>A</pad>      <requested_parameters>        <requested_parameter_list>          <requested_parameter>MST</requested_parameter>        </requested_parameter_list>      </requested_parameters>    </ns4:getRequestedParameters>  </soap:Body></soap:Envelope>"
        
        let soapMessage = soapmessageheader+clientMessage+requestDescriptionMessage;
        let urlString = "https://fs166asisp01/parm/v4"
        let url = NSURL(string: urlString)
        let theRequest = NSMutableURLRequest(url: url! as URL)
        let msgLength = String(soapMessage.characters.count)
        
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length")
        theRequest.httpMethod = "POST"
        theRequest.httpBody = soapMessage.data(using: String.Encoding.utf8, allowLossyConversion: false)
        print("Request is \(theRequest.allHTTPHeaderFields!)")
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration:config, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: theRequest as URLRequest)
        task.resume()
        
    }
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName as NSString
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElementName == "zip" {
            CommonUtils.setZipCode(value: string)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let strData = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        print(strData)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        xmlParser.shouldResolveExternalEntities = true
    }
    
    func getWiFiAddress() -> String? {
        var address : String?
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
}
