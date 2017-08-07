//
//  EESRequest.swift
//  HAL-iOS
//
//  Created by Brian Dembinski on 8/3/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

class EESRequest: NSObject, URLSessionDelegate,URLSessionDataDelegate,URLSessionTaskDelegate, XMLParserDelegate {
    var currentElementName:NSString = "";
    
    func getDailyAESKey()
    {
        // build the message
        let divId = "<v1:Division-ID>" + CommonUtils.getDivNum().description + "</v1:Division-ID>";
        let locId = "<v1:Location-ID>" + CommonUtils.getStoreNum().description + "</v1:Location-ID>"
        let keyVersion = "<v1:Key-Version>0</v1:Key-Version>";
        
        let expLength = "<v1:Exponent-Length>4</v1:Exponent-Length>";
        let modulusBitLength = "<v1:Modulus-Bit-Length>2048</v1:Modulus-Bit-Length>";
        let modulusLength = "<v1:Modulus-Length>520</v1:Modulus-Length>";
        let expModulus = "<v1:Exponent-Modulus>" + GenericEncryption.getRsaPublicExpHex() + GenericEncryption.getRsaPublicModulusHex() + "</v1:Exponent-Modulus>";
        let publicKey = "<v1:Public-Key>" + expLength + modulusBitLength + modulusLength + expModulus + "</v1:Public-Key>";
        
        let getEncryptionKey = "<v1:Get-Encryption-Key>" + divId + locId + keyVersion + publicKey + "</v1:Get-Encryption-Key>";
        
        let reqMessage = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:sec='http://schemas.xmlsoap.org/ws/2003/07/secext' xmlns:v1='http://www.macys.com/wsdl/xees120w.request/v1'>" +
                         "<soapenv:Body>" + getEncryptionKey + "</soapenv:Body></soapenv:Envelope>";
        
        
        let endpoint = ( CommonUtils.isPreProd() ? "https://tc2cicd:48059/provider/ees/ees4/xees121w" : "https://icmpropcredit:51492/provider/ees/ees4/xees121w" );
        let url = NSURL(string: endpoint);
        let theRequest = NSMutableURLRequest(url: url! as URL);
        let msgLength = String(reqMessage.characters.count);
        
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type");
        theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length");
        theRequest.httpMethod = "POST";
        theRequest.httpBody = reqMessage.data(using: String.Encoding.utf8, allowLossyConversion: false);
        
        //DLog( "EES Request: " + String(data: theRequest.httpBody!, encoding: .utf8)! );
        
        let config = URLSessionConfiguration.default;
        let session = URLSession(configuration:config, delegate: self, delegateQueue: OperationQueue.main);
        let task = session.dataTask(with: theRequest as URLRequest);
        task.resume();
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
    {
        currentElementName = elementName as NSString;
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        if( currentElementName == "Active-Key-Version" )
        {
            //DLog( "Daily AES key version: " + string );
            Encryption.shared.setDailyAesKeyVersion( version: Int32( string )! );
        }
        
        if( currentElementName == "Active-Key" )
        {
            //DLog( "Daily AES key: " + string );
            //Encryption.shared.setDailyAesKey( key: string.data(using: .utf8 )! );
            Encryption.shared.setDailyAesKey( key: string );
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
//        let strData = NSString(data: data, encoding: String.Encoding.utf8.rawValue);
//        
//        let stringData = strData as String?
//        if (stringData != nil)
//        {
//            DLog( "ESP Response: " + ( stringData! ) );
//        }
        
        let xmlParser = XMLParser(data: data);
        xmlParser.delegate = self;
        xmlParser.parse();
        xmlParser.shouldResolveExternalEntities = true;
    }
}
