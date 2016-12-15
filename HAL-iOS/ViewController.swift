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
    
    @IBOutlet var containerView : UIView? = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        let contentController = WKUserContentController();
        let messageHandlers: [String] = ["amInHal",
                                         "authenticateUser",
                                         "checkScanner",
                                         "clearData",
                                         "connectToPrinter",
                                         "crashapp",
                                         "disableScanner",
                                         "disconnectFromPrinter",
                                         "enableScanner",
                                         "getDeviceBatteryLevel",
                                         "getDeviceId",
                                         "getIsAuthenticated",
                                         "getLocationInformation",
                                         "getPrinterStatus",
                                         "getScannerStatus",
                                         "getSledBatteryLevel",
                                         "getSledStatus",
                                         "goToLandingPage",
                                         "launchSSOPage",
                                         "logoutAssociate",
                                         "isSSOAuthenticated",
                                         "passDataToWeb",
                                         "printdata",
                                         "saveData",
                                         "sendSSOAuthenticationMessageToWeb",
                                         "storeAnalyticsLogs",
                                         "restoreData"];
        
        for message in messageHandlers
        {
            contentController.add(
                self,
                name: message
            )
        }
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        self.webView = WKWebView(
            frame: (self.containerView?.bounds)!,
            configuration: config
        )
        self.view = self.webView!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var url = CommonUtils.getLandingPage();
        
        //for debugging for testing
        if( true ) // load test webpage
        {
            url = Bundle.main.url(forResource: "HALApi/test", withExtension:"html")!
        }
        //url = URL(string: "http://ln001xsssp0004:10998/")!;
        CommonUtils.setCurrentPage(value: url)
        loadWebView(url: url)
        
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "launchSSOPage") {
            let url = Bundle.main.url(forResource: "sso/index", withExtension:"html")
            loadWebView(url: url!)
        }
        else if(message.name == "authenticateUser")
        {
            print(message.body)
            
            if let messageBody:NSDictionary = message.body as? NSDictionary
            {
                let associateNumber:String = messageBody["associateNumber"] as! String
                let associatePin:String = messageBody["associatePin"] as! String
                authenticateUser(associateNumber: associateNumber,associatePin: associatePin)
            }
        }
        else if(message.name == "isSSOAuthenticated" )
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.isSSOAuthenticatedMessage() + " )");
        }
        else if(message.name == "amInHal")
        {
            let callback = message.body as! NSString;
            let callback2 = "(\(Assembly.halJson()));";
            let junk = (callback as String) + callback2;
            print("callback for amInHal: " + junk);
            evaluateJavaScript(javascriptMessage: junk);
        }
        else if(message.name == "goToLandingPage")
        {
            self.loadWebView(url: CommonUtils.getLandingPage())
        }
        else if(message.name == "logoutAssociate" )
        {
            CommonUtils.setIsSSOAuthenticated( value: false );
        }
        else if(message.name == "getDeviceId" )
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getDeviceId() + " )");
        }
        else if(message.name == "getSledStatus")
        {
            let callback = message.body as! NSString;
            let callback2 = "(\(Sled.isConnected()));";
            let junk = (callback as String) + callback2;
            print("callback for getSledStatus: " + junk);
            evaluateJavaScript(javascriptMessage: junk);
        }
        else if( message.name == "getScannerStatus" )
        {
            let callback = message.body as! NSString;
            let callback2 = "(\(CommonUtils.isScanEnabled()));";
            let junk = (callback as String) + callback2;
            print("callback for getScannerStatus: " + junk);
            evaluateJavaScript(javascriptMessage: junk);
        }
        else if(message.name == "getSledBatteryLevel")
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Sled.getSledBatteryLevel() + " )");
        }
        else if(message.name == "getDeviceBatteryLevel")
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Sled.getDeviceBatteryLevel() + " )");
        }
        else if(message.name == "enableScanner")
        {
            Sled.enableScanner();
           
            let data = message.body as! NSDictionary;
            let enabledCallback = data["enabledCallback"] as! String;
            let scanCallback = data["scanCallback"] as! String;

            CommonUtils.setScannerEnabledCallback(value: enabledCallback);
            CommonUtils.setScannerScanCallback(value: scanCallback);
            
            let callback = enabledCallback;
            let callback2 = "(\(CommonUtils.isScanEnabled()));";
            let junk = (callback as String) + callback2;
            print("callback for enableScanner: " + junk);
            evaluateJavaScript(javascriptMessage: junk);
        }
        else if(message.name == "disableScanner")
        {
            Sled.disableScanner();
            let callback = CommonUtils.getScannerEnabledCallback();
            let callback2 = "(\(CommonUtils.isScanEnabled()));";
            let junk = (callback as String) + callback2;
            print("callback for disableScanner: " + junk);
            evaluateJavaScript(javascriptMessage: junk);
        }
        else if(message.name == "saveData")
        {
            if let messageBody:NSDictionary = message.body as? NSDictionary
            {
                SharedContainer.saveData(data: messageBody)
            }
        }
        else if(message.name == "clearData")
        {
            SharedContainer.removeData(key: (message.body as? String)!)
        }
        else if(message.name == "connectToPrinter")
        {
            if(ZebraBluetooth.connectToDevice(address: message.body as! String))
            {
                showAlert(title: "Connected to printer", message: "success")
            }
            else{
                showAlert(title: "Could not connect to printer", message: "failed")
            }
        }
        else if(message.name == "disconnectFromPrinter")
        {
            if(ZebraBluetooth.disconnectFromDevice())
            {
                showAlert(title: "Disconnected from printer", message: "success")
            }
            else{
                showAlert(title: "Could not disconnect from printer", message: "failed")
            }
        }
        else if(message.name == "getPrinterStatus")
        {
            let zb =  ZebraBluetooth.init(address: CommonUtils.getPrinterMACAddress())
            showAlert(title: "PRINTER STATUS",message:zb.getCurrentStatus())
        }
        else if(message.name == "restoreData")
        {
            let data = message.body as! NSDictionary;
            let callback = data["callback"]
            let key = data["key"]
            let callbackInput = "(\(SharedContainer.restoreData(key: key as! String)));";
            let javascriptMessage = (callback as! String) + callbackInput;
            print("callback for restoreData: " + javascriptMessage);
            evaluateJavaScript(javascriptMessage: javascriptMessage);
        }
        else if(message.name == "crashapp"){
            let exc = NSException.init(name: NSExceptionName(rawValue: "exception"), reason: "custom crash", userInfo: nil)
            exc.raise()
        }
        else if(message.name == "printdata"){
            ZebraBluetooth.printData();
        }
        else if(message.name == "getLocationInformation") {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getLocationInformation() + " )");
        }
        else if(message.name == "storeAnalyticsLogs") {
            LogAnalyticsRequest.logDataTest()
        }
    }
    
    func loadWebView(url: URL){
        let req = NSURLRequest(url:url)
        self.webView!.navigationDelegate = self
        self.webView!.load(req as URLRequest)
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
    
    func evaluateJavaScript(javascriptMessage: String){
        self.webView?.evaluateJavaScript(javascriptMessage) { result, error in
            guard error == nil else {
                print(error as Any)
                return
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
        print("Received scanner data: " + barcode);
        
        let callback = CommonUtils.getScannerScanCallback() + "(\"" + barcode + "\");";
        evaluateJavaScript(javascriptMessage: callback);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
