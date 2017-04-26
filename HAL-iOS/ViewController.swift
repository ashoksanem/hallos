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
                                         "saveData",
                                         "sendSSOAuthenticationMessageToWeb",
                                         "storeAnalyticsLogs",
                                         "restoreData",
                                         "storeLog",
                                         "captureIncorrectLog"];
        
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
                if let val = change[.newKey] as? Bool {
                    if val {
                        
                        DLog("Starting webview loading.")
                        CommonUtils.setWebviewLoading(value: true);
                    } else {
                        
                        DLog("Stopping webview loading.")
                        CommonUtils.setWebviewLoading(value: false);
                    }
                }
            default:break;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var url = CommonUtils.getLandingPage();
        //let url = Bundle.main.url(forResource: "HALApi/test", withExtension:"html")!
        //for debugging for testing
//        url = Bundle.main.url(forResource: "HALApi/test", withExtension:"html")!
//        url = URL(string: "http://node1.sdpd.c4d.devops.fds.com:9001/")!;
        CommonUtils.setCurrentPage(value: url);
        loadWebView(url: url);
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        DLog("Website calling: " + message.name);
        
        if(message.name == "launchSSOPage") {
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
                LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by logoutAssociate.", type: "STRING", indexable: true);
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
                        SharedContainer.saveData(data: mutDict as NSDictionary);
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                    }
                    else
                    {
                        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
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
            let exc = NSException.init(name: NSExceptionName(rawValue: "exception"), reason: "custom crash", userInfo: nil)
            exc.raise()
        }
        else if(message.name == "printdata"){
            if let data = message.body as? NSDictionary {
                if let id = data["handle"] as? String {
                    if let receipt = data["receipt"] as? String {
                        if(ZebraBluetooth.printData(receiptMarkUp: receipt))
                        {
                            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
                        }
                        else
                        {
                            LoggingRequest.logData(name: LoggingRequest.metrics_print_failed, value: "could not print receipt in the printer", type: "STRING", indexable: true);
                            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
                        }
                    }
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
            if let id = message.body as? String {
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
        else if(message.name == "storeLog")
        {
            LogAnalyticsRequest.logDataTest()
        }
    }
    
    func loadWebView(url: URL){
        let req = NSURLRequest(url:url);
        let req2 = req as URLRequest;
        
        ViewController.webView!.navigationDelegate = self;
        ViewController.webView!.load(req2);
    }
    
    func loadPreviousWebPage(){
        loadWebView(url: CommonUtils.getCurrentPage())
    }
    
    //Function to authenticate user based on the associate number and associatePin
    func authenticateUser(associateNumber: String,associatePin: String){
        SSORequest.makeSSORequest(associateNumber: associateNumber, associatePin: associatePin){
            (result: String) in
            if(CommonUtils.isSSOAuthenticated()){
                self.loadPreviousWebPage()
            }
            else {
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
}
