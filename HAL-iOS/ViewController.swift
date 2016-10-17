//
//  ViewController.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/27/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler,WKNavigationDelegate {
    
    @IBOutlet var containerView : UIView? = nil
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        let contentController = WKUserContentController();
        contentController.add(
            self,
            name: "launchSSOPage"
        )
        contentController.add(
            self,
            name: "passDataToWeb"
        )
        contentController.add(
            self,
            name: "amInHal"
        )
        contentController.add(
            self,
            name: "isSSOAuthenticated"
        )
        contentController.add(
            self,
            name: "authenticateUser"
        )
        contentController.add(
            self,
            name: "sendSSOAuthenticationMessageToWeb"
        )
        
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
        let url = Bundle.main.url(forResource: "webAssets/test", withExtension:"html")
        loadWebView(url: url!)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("passDataToWeb(\(Assembly.halJson()));") { result, error in
            guard error == nil else {
                print(error)
                return
            }
            
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "launchSSOPage") {
            let url = Bundle.main.url(forResource: "sso/index", withExtension:"html")
            loadWebView(url: url!)
        }
        
        if(message.name == "authenticateUser") {
            print(message.body)
            if let messageBody:NSDictionary = message.body as? NSDictionary {
                let associateNumber:String = messageBody["associateNumber"] as! String
                let associatePin:String = messageBody["associatePin"] as! String
                authenticateUser(associateNumber: associateNumber,associatePin: associatePin)
            }
            //authenticateUser(associateNumber: "7123456",associatePin: "1001")
        }
        if(message.name == "isSSOAuthenticated") {
            print(CommonUtils.isSSOAuthenticatedMessage())
            self.webView?.evaluateJavaScript("sendSSOAuthenticationMessageToWeb(\(CommonUtils.isSSOAuthenticatedMessage()));") { result, error in
                guard error == nil else {
                    print(error)
                    return
                }
            }
        }
        
        if(message.name == "amInHal") {
            showAlert(title: "Message from HAL",message: "hello user")
        }
    }
    
    func loadWebView(url: URL){
        if(!(self.webView!.url==nil)){
            CommonUtils.setCurrentPage(value: self.webView!.url!)}
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
            //printing SSO response in console
            print("sso response: \(result)")
            if(CommonUtils.isSSOAuthenticated()){
                self.loadPreviousWebPage()
            }
            else{
                self.showAlert(title: "Authentication Failed", message: "Please enter valid credentials")
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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
