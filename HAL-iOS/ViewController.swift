//
//  ViewController.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/27/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

//import DTDevices.h
class ViewController: UIViewController, DTDeviceDelegate, WKScriptMessageHandler,WKNavigationDelegate {
    
    static var webView: WKWebView?;
    static var storedJS = [String]();
    var sledBatteryView: UITextView?;
    var printerData:NSDictionary = [:];
    var progressView: UIView?;
    var activityIndicator: UIActivityIndicatorView?;
    override func loadView() {
        super.loadView()
        let contentController = WKUserContentController();
        let messageHandlers: [String] = ["checkScanner",
                                         "clearData",
                                         "connectToPrinter",
                                         "crashapp",
                                         "disableScanner",
                                         "disconnectFromPrinter",
                                         "enableScanner",
                                         "getDeviceBatteryLevel",
                                         "getDeviceId",
                                         "getHalInfo",
                                         "getIsAuthenticated",
                                         "getLocationInformation",
                                         "getPrinterStatus",
                                         "getScannerStatus",
                                         "getScannerInfo",
                                         "getSledBatteryLevel",
                                         "getSledStatus",
                                         "goToLandingPage",
                                         "launchSSOPage",
                                         "logoutAssociate",
                                         "initHal",
                                         "isSSOAuthenticated",
                                         "makeAuthenticationRequest",
                                         "passDataToWeb",
                                         "printdata",
                                         "hasSavedPrinter",
                                         "saveData",
                                         "sendSSOAuthenticationMessageToWeb",
                                         "storeAnalyticsLogs",
                                         "forwardMsg",
                                         "restoreData",
                                         "storeLog",
                                         "getMsrStatus",
                                         "enableMsr",
                                         "disableMsr",
                                         "getCardReaderStatus",
                                         "enableCardReader",
                                         "disableCardReader",
                                         "getConfigurationParams",
                                         "captureIncorrectLog",
                                         "isFixedRegister",
                                         "queryMsgs",
                                         "getCRUInfo"];
        
        for message in messageHandlers
        {
            contentController.add(
                self,
                name: message
            )
        }
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        /*self.webView = WKWebView(
         frame: (self.containerView?.bounds)!,
         configuration: config
         )
         self.view = self.webView!*/
        
        ViewController.webView = WKWebView(
            frame: (CGRect(x: 0, y: 20, width: self.view.bounds.width, height: self.view.bounds.height-20)),
            configuration: config
        );
        
//        ViewController.webView?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil); observer for the change of the progress of a GET request
        
        sledBatteryView = UITextView(frame: CGRect(x: ((self.view.bounds.width/2) - 100), y: -4, width: 80, height: 20));
        sledBatteryView?.textAlignment = NSTextAlignment.center;
        sledBatteryView?.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize);
        self.view.addSubview(sledBatteryView!);
        self.view.addSubview(ViewController.webView!);
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return; };
        guard let change = change else { return; };
        
        switch keyPath {
            case "loading": // new:1 or 0
                if let val = change[.newKey] as? Bool
                {
                    if( val )
                    {
                        
                        DLog("Starting webview loading.")
                        CommonUtils.setWebviewLoading(value: true);
                    } else
                    {
                        
                        DLog("Stopping webview loading.")
                        CommonUtils.setWebviewLoading(value: false);
                    }
                }
//            case "estimatedProgress": // to have ui implemented with a future story, see UIProgressView @ https://developer.apple.com/documentation/uikit/uiprogressview
//                if let val = change[.newKey] as? Double
//                {
//                    DLog("progress " + String(val)); outputs a double from 0.0 to 1.0 indicating how far along the get request to a web page is
//                }
            default:break;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeProgressView()
        let url = CommonUtils.getLandingPage();
        if(!CommonUtils.isDefaultLandingPage(url))
        {
//            let url = URL(string: "http://11.120.166.30:10100/purchase")!; //for debugging local web app
//            url = Bundle.main.url(forResource: "HALApi/test", withExtension:"html")!; //for debugging hal api
            loadWebView(url: url);
        }
        else
        {
            CommonUtils.setCurrentPage(value: url);
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        DLog("Website calling: " + message.name);
        
        if(message.name == "launchSSOPage") {
            var returnBackUrl = (ViewController.webView?.url)!;
            if let messageBody = message.body as? NSDictionary
            {
                if let redirectUrl = URL(string:messageBody["redirectURL"] as? String ?? "")
                {
                    returnBackUrl = redirectUrl;
                    CommonUtils.setSSORedirectURL(value: true);
                }
            }
            CommonUtils.setCurrentPage(value: returnBackUrl);
            let url = Bundle.main.url(forResource: "sso/index", withExtension:"html")
            loadWebView(url: url!)
        }
        else if(message.name == "makeAuthenticationRequest")
        {
            //print(message.body)
            
            if let messageBody:NSDictionary = message.body as? NSDictionary
            {
                let associateNumber = messageBody["associateNumber"] as? String;
                let associatePin = messageBody["associatePin"] as? String;

                if( associateNumber != nil && associatePin != nil ) {
                    authenticateUser(associateNumber: associateNumber!, associatePin: associatePin!);
                }
            }
        }
        else if(message.name == "isSSOAuthenticated" )
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.isSSOAuthenticatedMessage() + " )");
            }
        }
        else if(message.name == "getHalInfo")
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Assembly.halJson() + " )");
            }
        }
        else if(message.name == "goToLandingPage")
        {
            self.loadWebView(url: CommonUtils.getLandingPage())
        }
        else if(message.name == "logoutAssociate" )
        {
            if let id = message.body as? String {
                LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by logoutAssociate JavaScript call.", type: "STRING", indexable: true);
                Heap.track("AssociateLogout", withProperties:[AnyHashable("reason"):"logoutAssociate JavaScript call",
                                                              AnyHashable("associateNumber"):CommonUtils.getCurrentAssociateNum(),
                                                              AnyHashable("duration"):CommonUtils.getSSODuration(),
                                                              AnyHashable("divNum"):CommonUtils.getDivNum(),
                                                              AnyHashable("storeNum"):CommonUtils.getStoreNum()]);
                
                CommonUtils.setIsSSOAuthenticated( value: false );
                
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
            }
        }
        else if(message.name == "getDeviceId" )
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getDeviceId() + " )");
            }
        }
        else if(message.name == "getSledStatus")
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( Sled.isConnected() ) + " )");
            }
        }
        else if( message.name == "getScannerStatus" )
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
            }
        }
        else if( message.name == "getScannerInfo" )
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.getScannerInfo() ) + " )");
            }
        }
        else if(message.name == "getSledBatteryLevel")
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Sled.getSledBatteryLevel() + " )");
            }
        }
        else if(message.name == "getDeviceBatteryLevel")
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Sled.getDeviceBatteryLevel() + " )");
            }
        }
        else if(message.name == "enableScanner")
        {
            CommonUtils.setScannerModeFromWeb(value: true);
            Sled.enableScanner();
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
            }
        }
        else if(message.name == "disableScanner")
        {
            Sled.disableScanner();
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
            }
        }
        else if(message.name == "saveData")
        {
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
            
                    if let messageBody:NSDictionary = message.body as? NSDictionary
                    {
                        let mutDict: NSMutableDictionary = messageBody.mutableCopy() as! NSMutableDictionary;
                        mutDict.removeObject(forKey: "handle");
                        let rc = SharedContainer.saveData(data: mutDict as NSDictionary);
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + ( rc ? "true" : "false" ) + " )");
                    }
                    else
                    {
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
                    }
                }
            }
        }
        else if(message.name == "queryMsgs")
        {
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
                    if let key = data["key"] as? String {
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + SharedContainer.getStoredDataCount(dataCollectKey: key.lowercased()) + " )");
                    }
                }
            }
        }
        else if(message.name == "restoreData")
        {
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
                    if let key = data["key"] as? String {
            
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + SharedContainer.restoreData(key: key) + " )");
                    }
                }
            }
        }
        else if(message.name == "clearData")
        {
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
                    if let key = data["key"] as? String {
            
                        SharedContainer.removeData(key: key)
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                    }
                }
            }
        }
        else if(message.name == "connectToPrinter")
        {
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
                    if let address = data["data"] as? String {
            
                        if(ZebraBluetooth.connectToDevice(address: address))
                        {
                            //showAlert(title: "Connected to printer", message: "success")
                            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                        }
                        else{
                            //showAlert(title: "Could not connect to printer", message: "failed")
                            LoggingRequest.logData(name: LoggingRequest.metrics_lost_printer_connection, value: "could not connect to the printer with mac address " + address, type: "STRING", indexable: true);
                            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
                        }
                    }
                }
            }
        }
        else if(message.name == "disconnectFromPrinter")
        {
            if let id = message.body as? String {
                if(ZebraBluetooth.disconnectFromDevice())
                {
                    //showAlert(title: "Disconnected from printer", message: "success")
                    evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                }
                else{
                    //showAlert(title: "Could not disconnect from printer", message: "failed")
                    evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                }
            }
        }
        else if(message.name == "getPrinterStatus")
        {
            let zb =  ZebraBluetooth.init(address: CommonUtils.getPrinterMACAddress())
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, \"" + zb.getCurrentStatus() + "\" )");
            }
            
            //showAlert(title: "PRINTER STATUS",message:zb.getCurrentStatus())
        }
        else if(message.name == "crashapp"){
            let exc = NSException.init(name: NSExceptionName(rawValue: "exception"), reason: "custom crash", userInfo: nil);
            exc.raise();
        }
        else if(message.name == "printdata"){
            printData(message: message)
        }
        else if(message.name == "hasSavedPrinter"){
            if let id = message.body as? String {
                if(CommonUtils.getPrinterMACAddress()=="")
                {
                    evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, false )");
                }
                else
                {
                    evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                }
            }
        }
        else if(message.name == "getLocationInformation") {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getLocationInformation() + " )");
            }
        }
        else if(message.name == "storeAnalyticsLogs") {
            if let _data = message.body as? NSDictionary {
                if let id = _data["handle"] as? String {
                    if let data = _data["data"] as? String {
                        let stringData = String( describing: data );
            
                        LogAnalyticsRequest.logData( data:stringData );
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                    }
                }
            }
        }
        else if(message.name == "initHal")
        {
            if let id = message.body as? String
            {
                let data = [
                    "hostInformation":[
                        "isp": SharedContainer.getIsp(),
                        "ssp": SharedContainer.getSsp(),
                        "cloud": SharedContainer.getCloud()
                    ] ]as [String : Any]
            
                let dataData = try! JSONSerialization.data(withJSONObject: data, options: [])
                let dataString = String(data: dataData, encoding: String.Encoding.utf8)
            
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + dataString! + " )");
            }
        }
        else if(message.name == "captureIncorrectLog")
        {
            LogAnalyticsRequest.logIncorrectDataTest()
        }
        else if(message.name == "getConfigurationParams")
        {
            if let id = message.body as? String
            {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.getConfigurationParams() ) + " )");
            }
        }
        else if(message.name == "storeLog")
        {
            LogAnalyticsRequest.logDataTest()
        }
        else if(message.name == "forwardMsg")
        {
            if let data = message.body as? NSDictionary
            {
                if let id = data["handle"] as? String
                {
                    
                    if let messageBody:NSDictionary = message.body as? NSDictionary
                    {
                        let mutDict: NSMutableDictionary = messageBody.mutableCopy() as! NSMutableDictionary;
                        if( JSONSerialization.isValidJSONObject( mutDict ) )
                        {
                            if let storedDataInfo = SharedContainer.getData(key: SharedContainer.webDataKey)[SharedContainer.webDataKey] as? [NSDictionary]
                            {
                                var storedDataArray =  storedDataInfo
                                storedDataArray.append(mutDict);
                                SharedContainer.saveWebData(data: storedDataArray);
                            }
                            else
                            {
                                var storedDataArray =  [NSDictionary]()
                                storedDataArray.append(mutDict);
                                SharedContainer.saveWebData(data: storedDataArray);
                            }
                            DataForwarder.forwardStoredData();
                            ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + id + "\", false, true )");
                        }
                        else
                        {
                            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
                        }
                    }
                    else
                    {
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
                    }
                }
            }
        }
        else if((message.name == "enableMsr") || (message.name ==  "enableCardReader"))
        {
            Sled.enableMsr();
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", " +
                    String( !CommonUtils.isMsrEnabled() ) + ", " + String( CommonUtils.isMsrEnabled() ) + " )");
            }
        }
        else if((message.name == "disableMsr") || (message.name ==  "disableCardReader"))
        {
            Sled.disableMsr();
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", " +
                    String( CommonUtils.isMsrEnabled() ) + ", " + String( CommonUtils.isMsrEnabled() ) + " )");
            }
        }
        else if((message.name == "getMsrStatus") || (message.name == "getCardReaderStatus"))
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isMsrEnabled() ) + " )");
            }
        }
        else if(message.name == "isFixedRegister")
        {
            //ios isn't a fixed register....Ever.
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, false )");
            }
        }
        else if(message.name == "getCRUInfo")
        {
            if let id = message.body as? String {
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, false )");
            }
        }
    }
    
    func loadWebView(url: URL)
    {
            let req = NSURLRequest(url: url);
            let req2 = req as URLRequest;
            
            ViewController.webView!.navigationDelegate = self;
            ViewController.webView!.load(req2);
    }
    
    func loadPreviousWebPage()
    {
        if let currentPage = CommonUtils.getCurrentPage()
        {
            loadWebView(url: currentPage);
        }
    }
    
    //Function to authenticate user based on the associate number and associatePin
    func authenticateUser(associateNumber: String,associatePin: String)
    {
        SSORequest.makeSSORequest(associateNumber: associateNumber, associatePin: associatePin)
        {
            (result: String) in
            if(CommonUtils.isSSOAuthenticated())
            {
                if((result=="prevAuth") || CommonUtils.hasSSORedirectURL())
                {
                    self.loadPreviousWebPage();
                }
                else
                {
                    self.loadWebView(url: CommonUtils.getLandingPage());
                }
                CommonUtils.setSSORedirectURL(value: false);
            }
            else
            {
                self.evaluateJavaScript(javascriptMessage: "switchErrorState(true);"); // it's okay this one is hard coded
            }
        }
    }
    
    func showAlert(title: String,message:String)
    {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func evaluateJavaScript(javascriptMessage: String) {
        func eval()
        {
            ViewController.webView?.evaluateJavaScript(javascriptMessage) { result, error in
                guard error == nil else {
                    ViewController.storedJS.append(javascriptMessage);
                    
                    DLog("evaluateJavaScript message: " + javascriptMessage);
                    
                    if( error != nil ) {
                        let junk = error?.localizedDescription;
                        if( junk != nil ) {
                            
                            DLog("evaluateJavaScript error: " + junk! );
                        }
                    }
                    return;
                }
            }
        }
        
        
        //iOS 11+, WKWebView.evaluateJavascript is required to run on the main thread, otherwise app crashes -> thanks, apple
        if(!Thread.isMainThread)
        {
            DispatchQueue.main.async
            {
                eval();
            }
        }
        else
        {
            eval();
        }
    }
    
    //    func connectionState(_ state: Int32) {
    //        evaluateJavaScript(javascriptMessage: "updateSledStatus(\(Sled.isConnected()));");
    //        evaluateJavaScript(javascriptMessage: "passDataToWeb(\(Assembly.halJson()));");
    //        evaluateJavaScript(javascriptMessage: "updateSledBattery(\(Sled.getSledBatteryLevel()));");
    //        evaluateJavaScript(javascriptMessage: "updateDeviceBattery(\(Sled.getDeviceBatteryLevel()));");
    //    }
    
    func updateBarcodeData(barcode: String)
    {
        
        DLog("Received scanner data: " + barcode);
        //
        //        let callback = CommonUtils.getScannerScanCallback() + "(\"" + barcode + "\");";
        //        evaluateJavaScript(javascriptMessage: callback);
        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"scanCallback\", false, \"" + barcode + "\" )");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    func orientationChanged() {
        if (UIApplication.shared.isStatusBarHidden) {
            ViewController.webView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height);
        } else {
            ViewController.webView?.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: self.view.bounds.height-20);
        }
    }
    
    func updateBattery() {
        if(Sled.isConnected()) {
            sledBatteryView?.text = Sled.getSledBatteryLevel()+"%🔋";
        }
        else {
            sledBatteryView?.text = "";
        }
    }
    
    func updateMsrData(msrData: String)
    {
        DLog("Received MSR data: " + msrData);
        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"msrCallback\", false, " + msrData + " )");
        
        let cardData = [
            "type": "msr",
            "data": msrData
            ] as [String : Any]
        let cardReaderJsonData = try! JSONSerialization.data(withJSONObject: cardData, options: [])
        let finalCardReaderData = String(data: cardReaderJsonData, encoding: String.Encoding.utf8)
        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"cardReaderCallback\", false, " + finalCardReaderData! + " )");
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if(CommonUtils.isCertificatePinningEnabled())
        {
            if(challenge.protectionSpace.authenticationMethod==NSURLAuthenticationMethodServerTrust)
            {
                let serverTrust = challenge.protectionSpace.serverTrust;
                if((serverTrust) != nil)
                {
                    var trusted:Bool = false;
                    let rootCaPath = Bundle.main.paths(forResourcesOfType: "der", inDirectory: "Certificates");
                    for cert in rootCaPath
                    {
                        if let rootCaData: NSData = NSData(contentsOfFile: cert ) {
                            let cfData = CFDataCreate(kCFAllocatorDefault, rootCaData.bytes.assumingMemoryBound(to: UInt8.self), rootCaData.length)
                            let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, cfData!)
                            let certs: [CFTypeRef] = [rootCert as CFTypeRef] 
                            let certArrayRef : CFArray = CFBridgingRetain(certs as NSArray) as! CFArray
                            SecTrustSetAnchorCertificates(serverTrust!, certArrayRef)
                            SecTrustSetAnchorCertificatesOnly(serverTrust!, true)
                        }
                        var trustResult: SecTrustResultType = SecTrustResultType(rawValue: 0)!
                        SecTrustEvaluate(serverTrust!, &trustResult)
                        if (Int(trustResult.rawValue) == 1 || Int(trustResult.rawValue) == 4) {
                            trusted = true;
                            break;
                        }
                    }
                    if( !trusted )
                    {
                        let secTrustCertificate =   SecTrustGetCertificateAtIndex(serverTrust!,0);
                        LoggingRequest.logError(name: LoggingRequest.metrics_unAuthorizedCertificate, value: secTrustCertificate.debugDescription, type: "STRING", indexable: false);
                        let alertController = UIAlertController(title: "UnAuthorized certificate", message:
                            "The certificate accessed is unauthorized.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Close App", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in exit(0)}))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        completionHandler(.useCredential, nil);
    }
    
    func printData(message:WKScriptMessage)
    {
        if let data = message.body as? NSDictionary
        {
            printerData = data;
            let addPrinter = data["addPrinter"] as? Bool ?? false;
            let skipPrinting = data["skipPrinting"] as? Bool ?? false;
            if(addPrinter)
            {
                CommonUtils.setPrinterMACAddress(value: "")
                CommonUtils.setSavedPrinterMACAddress(value: "")
            }   
            
            Sled.enableScanner();
            if((CommonUtils.getSavedPrinterMACAddress()==""))
            {
                performSegue(withIdentifier: "showPrinter", sender: self);
            }
            else
            {
                self.progressView?.isHidden = false;
                self.activityIndicator?.startAnimating();
                DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                let printStatus = PrinterViewController.connectAndPrintReceipt(address: CommonUtils.getSavedPrinterMACAddress(),printerData: self.printerData);
                if( !(printStatus=="success") )
                    {
                        self.activityIndicator?.stopAnimating();
                        self.progressView?.isHidden = true;
                        let alertController = UIAlertController(title: "", message:
                            PrinterViewController.getPrinterErrorMessage(status: printStatus), preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction(
                            title: "Try Again",
                            style: UIAlertActionStyle.cancel) { (action) in
                                self.performSegue(withIdentifier: "showPrinter", sender: self);
                        }
                        alertController.addAction(okAction);
                        if(skipPrinting)
                        {
                        let skipAction = UIAlertAction(
                            title: "Skip Printing",
                            style: UIAlertActionStyle.destructive) { (action) in
                        }
                        alertController.addAction(skipAction);
                        }
                        self.present(alertController, animated: true, completion: nil)
                    }
                    else
                    {
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                            self.activityIndicator?.stopAnimating();
                            self.progressView?.isHidden = true;
                        }
                    }
                }
            }
        }
    }
    
    func initializeProgressView()
    {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge);
        activityIndicator?.center = self.view.center;
        progressView = UIView(frame: self.view.frame);
        progressView?.backgroundColor = UIColor.init(white: 0.333, alpha: 0.5);
        let progressTextView = UITextView(frame: CGRect.init(x: 0, y: self.view.center.y+20, width: self.view.frame.width, height: self.view.frame.width/10))
        progressTextView.backgroundColor = UIColor.clear;
        progressTextView.textColor = UIColor.white;
        progressTextView.textAlignment = NSTextAlignment.center;
        progressTextView.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize);
        progressTextView.text = "Printing..";
        progressView?.addSubview(activityIndicator!);
        progressView?.addSubview(progressTextView);
        self.view.addSubview(self.progressView!);
        progressView?.isHidden = true;
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let printerViewController = segue.destination as! PrinterViewController
        printerViewController.printerData = printerData;
    }

}
