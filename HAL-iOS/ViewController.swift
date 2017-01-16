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
    
    //@IBOutlet var containerView : UIView? = nil
    var webView: WKWebView?
    var sledBatteryView: UITextView?
    var batteryTimer = Timer()
    override func loadView() {
        super.loadView()
        let contentController = WKUserContentController();
        let messageHandlers: [String] = ["authenticateUser",
                                         "checkScanner",
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
        webView = WKWebView(
            frame: (CGRect(x: 0, y: 20, width: self.view.bounds.width, height: self.view.bounds.height-20)),
            configuration: config
        )
        sledBatteryView = UITextView(frame: CGRect(x: ((self.view.bounds.width/2) - 100), y: -4, width: 80, height: 20))
        sledBatteryView?.textAlignment = NSTextAlignment.center;
        sledBatteryView?.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize);
        self.view.addSubview(sledBatteryView!)
        self.view.addSubview(webView!)
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var url = CommonUtils.getLandingPage();
        
        //for debugging for testing
        //url = Bundle.main.url(forResource: "HALApi/test", withExtension:"html")!
//        url = URL(string: "http://11.120.110.75:10998/")!;
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
            //print(message.body)
            
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
        else if(message.name == "getHalInfo")
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + Assembly.halJson() + " )");
        }
        else if(message.name == "goToLandingPage")
        {
            self.loadWebView(url: CommonUtils.getLandingPage())            
        }
        else if(message.name == "logoutAssociate" )
        {
            let id = message.body as! String;
            CommonUtils.setIsSSOAuthenticated( value: false );
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
        }
        else if(message.name == "getDeviceId" )
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getDeviceId() + " )");
        }
        else if(message.name == "getSledStatus")
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( Sled.isConnected() ) + " )");
        }
        else if( message.name == "getScannerStatus" )
        {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
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
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
        }
        else if(message.name == "disableScanner")
        {
            Sled.disableScanner();
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + String( CommonUtils.isScanEnabled() ) + " )");
        }
        else if(message.name == "saveData")
        {
            let data = message.body as! NSDictionary;
            let id = data["handle"] as! String;
            
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
        else if(message.name == "restoreData")
        {
            let data = message.body as! NSDictionary;
            let id = data["handle"] as! String;
            let key = data["key"] as! String;
            
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + SharedContainer.restoreData(key: key) + " )");
        }
        else if(message.name == "clearData")
        {
            let data = message.body as! NSDictionary;
            let id = data["handle"] as! String;
            let key = data["key"] as! String;
            
            SharedContainer.removeData(key: key)
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
        }
        else if(message.name == "connectToPrinter")
        {
            let data = message.body as! NSDictionary;
            let id = data["handle"] as! String;
            let address = data["data"] as! String;
            if(ZebraBluetooth.connectToDevice(address: address))
            {
                //showAlert(title: "Connected to printer", message: "success")
               evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
            }
            else{
                //showAlert(title: "Could not connect to printer", message: "failed")
                LoggingRequest.logData(name: LoggingRequest.metrics_lost_printer_connection, value: "could not connect to the printer with mac address "+address, type: "STRING", indexable: true);
                evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", true, false )");
            }
        }
        else if(message.name == "disconnectFromPrinter")
        {
            let id = message.body as! String;
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
        else if(message.name == "getPrinterStatus")
        {
            let zb =  ZebraBluetooth.init(address: CommonUtils.getPrinterMACAddress())
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, \"" + zb.getCurrentStatus() + "\" )");
            
            //showAlert(title: "PRINTER STATUS",message:zb.getCurrentStatus())
        }
        else if(message.name == "crashapp"){
            let exc = NSException.init(name: NSExceptionName(rawValue: "exception"), reason: "custom crash", userInfo: nil)
            exc.raise()
        }
        else if(message.name == "printdata"){
            let data = message.body as! NSDictionary;
            let id = data["handle"] as! String;
            let receipt = data["receipt"] as! String;
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
        else if(message.name == "getLocationInformation") {
            let id = message.body as! String;
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, " + CommonUtils.getLocationInformation() + " )");
        }
        else if(message.name == "storeAnalyticsLogs") {
            let _data = message.body as! NSDictionary;
            let id = _data["handle"] as! String;
            let data = _data["data"] as! NSDictionary;
            let stringData = String( describing: data );
            
            LogAnalyticsRequest.logData( data:stringData );
            evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"" + id + "\", false, true )");
        }
        else if(message.name == "initHal")
        {
            let id = message.body as! String;
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
                print(javascriptMessage);                
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
//
//        let callback = CommonUtils.getScannerScanCallback() + "(\"" + barcode + "\");";
//        evaluateJavaScript(javascriptMessage: callback);
        evaluateJavaScript(javascriptMessage: "window.onMessageReceive(\"scanCallback\", false, \"" + barcode + "\" )");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func orientationChanged() {
        if (UIApplication.shared.isStatusBarHidden){
            webView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        } else {
            webView?.frame = CGRect(x: 0, y: 20, width: self.view.bounds.width, height: self.view.bounds.height-20)
        }
    }
    func updateBattery() {
        if(Sled.isConnected())
        {
            sledBatteryView?.text = Sled.getSledBatteryLevel()+"%🔋";
        }
        else
        {
            sledBatteryView?.text = "";
        }
    }
}
