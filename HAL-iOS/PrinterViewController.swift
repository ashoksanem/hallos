//
//  PrinterViewController.swift
//  HAL-iOS
//
//  Created by Pranitha Kota on 7/17/17.
//  Copyright © 2017 macys. All rights reserved.
//

import UIKit

class PrinterViewController: UIViewController {
    @IBOutlet weak var macAddress: UILabel!;
    @IBOutlet weak var printButton: UIButton!;
    var printerData = NSDictionary();
    var c: UITextView?;
    var sledBatteryView: UITextView?;
    var activityIndicator:UIActivityIndicatorView?;
    var progressView: UIView?;
    @IBAction func printButton(_ sender: UIButton) {
        //printResult = PrinterViewController.connectAndPrintReceipt(address: macAddress.text!, printerData: printerData);
        //dismiss(animated: true, completion: nil)
        displayPrinterAlert();
    };
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        initializeProgressView()
        updateBattery();
        
        if(CommonUtils.getPrinterMACAddress()=="")
        {
            macAddress.text = "MAC: _________________";
            printButton.isHidden = true;
        }
        else
        {
            printButton.isHidden = false;
            macAddress.text = "MAC: " + CommonUtils.getPrinterMACAddress();
        }
    }
    
    override func loadView() {
        super.loadView();

        sledBatteryView = UITextView(frame: CGRect(x: ((self.view.bounds.width/2) - 100), y: -4, width: 80, height: 20));
        sledBatteryView?.textAlignment = NSTextAlignment.center;
        sledBatteryView?.font = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize);
        self.view.addSubview(sledBatteryView!);
    }
    
    func updateBattery()
    {
        if(Sled.isConnected())
        {
            sledBatteryView?.text = Sled.getSledBatteryLevel() + "%🔋";
        }
        else
        {
            sledBatteryView?.text = "";
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
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func updateMacAddress(barcode: String)
    {
        macAddress.text = barcode;
        CommonUtils.setPrinterMACAddress(value: barcode);
        CommonUtils.setSavedPrinterMACAddress(value: "");
        printButton.isHidden = false;
    }
    
    func displayPrinterAlert()
    {
        self.view.addSubview(self.progressView!)
        self.activityIndicator?.startAnimating();
        
        let alertController = UIAlertController(title: "", message:
            "Save this printer for later?", preferredStyle: UIAlertControllerStyle.alert);
        let cancelAction = UIAlertAction(
            title: "No",
            style: UIAlertActionStyle.cancel) { (action) in
                self.printReceipt()
        }
        
        let saveAction = UIAlertAction(
        title: "Yes", style: UIAlertActionStyle.default) { (action) in
            CommonUtils.setSavedPrinterMACAddress(value: CommonUtils.getPrinterMACAddress())
            self.printReceipt()
        }
        
        alertController.addAction(cancelAction);
        alertController.addAction(saveAction);
        
        self.present(alertController, animated: true, completion: nil);
    }
    
    func printReceipt()
    {
        let printStatus = PrinterViewController.connectAndPrintReceipt(address:CommonUtils.getPrinterMACAddress(),printerData: self.printerData);
        if(!(printStatus == "success"))
        {
            let skipPrinting = self.printerData["skipPrinting"] as? Bool ?? false;
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating();
                self.progressView?.removeFromSuperview()
            }
            let alertController = UIAlertController(title: "", message:
                PrinterViewController.getPrinterErrorMessage(status: printStatus), preferredStyle: UIAlertControllerStyle.alert);
            let okAction = UIAlertAction(
                title: "Try Again",
                style: UIAlertActionStyle.cancel) { (action) in
            }
            alertController.addAction(okAction);
            if(skipPrinting)
            {
            let skipAction = UIAlertAction(
                title: "Skip Printing",
                style: UIAlertActionStyle.destructive) { (action) in self.dismiss(animated: true, completion: nil)
                }
            alertController.addAction(skipAction);
            }
            self.present(alertController, animated: true, completion: nil);
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.activityIndicator?.stopAnimating();
                self.progressView?.removeFromSuperview()
            }
            self.dismiss(animated: true, completion: nil);
        }
    }
    
    class func getPrinterErrorMessage(status:String) -> String
    {
        if(status == "NoPaper")
        {
            return "The printer is out of paper. Please add paper to print or select another printer.";
        }
        else if(status == "LatchOpen")
        {
            return "The latch on the printer is open. Please close it to print.";
        }
        else if(status == "LowBattery")
        {
            return "The battery on the printer is low. Please charge the printer to continue use.";
        }
        else if(status == "Busy")
        {
            return "The printer is busy. Try again in a few seconds or select another printer.";
        }
        else if(status == "NoResponse")
        {
            return "We can't connect to the printer. You may be out of range. Please try again or select another printer.";
        }
        
        return "There was an issue with printing. Select another printer or try again.";
    }
    
    class func connectAndPrintReceipt(address:String,printerData:NSDictionary)  -> String
    {
        let callBackId = printerData["handle"] as? String ?? "";
        let receiptInfo = printerData["receipt"] as? String ?? "";
        var printStatus = "error";
        
        if(ZebraBluetooth.connectToDevice(address: address))
        {
            printStatus = ZebraBluetooth.printData(receiptMarkUp: receiptInfo);
            if( printStatus == "success")
            {
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + callBackId + "\", false, true )");
                ZebraBluetooth.disconnectFromDevice();
                return printStatus;
            }
        }
        
        ZebraBluetooth.disconnectFromDevice();
        LoggingRequest.logData(name: LoggingRequest.metrics_print_failed, value: "could not print receipt in the printer with status : "+printStatus, type: "STRING", indexable: true);
        //ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + callBackId + "\", false, false )");
        return printStatus;
    }
}
