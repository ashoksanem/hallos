//
//  PrinterViewController.swift
//  HAL-iOS
//
//  Created by Pranitha Kota on 7/17/17.
//  Copyright © 2017 macys. All rights reserved.
//

import UIKit

class PrinterViewController: UIViewController {
    @IBOutlet weak var macAddress: UILabel!
    @IBOutlet weak var printButton: UIButton!
    var printerData = NSDictionary()
    @IBAction func printButton(_ sender: UIButton) {
        //printResult = PrinterViewController.connectAndPrintReceipt(address: macAddress.text!, printerData: printerData);
        //dismiss(animated: true, completion: nil)
        displayPrinterAlert();
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if(CommonUtils.getPrinterMACAddress()=="")
        {
            macAddress.text = "MAC: _________________";
            printButton.isHidden=true;
        }
        else
        {
            printButton.isHidden=false;
            macAddress.text = "MAC: "+CommonUtils.getPrinterMACAddress();
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func updateMacAddress(barcode: String)
    {
        macAddress.text = barcode;
        CommonUtils.setPrinterMACAddress(value: barcode)
        CommonUtils.setSavedPrinterMACAddress(value: "")
        printButton.isHidden=false;
    }
    
    func displayPrinterAlert()
    {
        let alertController = UIAlertController(title: "", message:
            "Save this printer for later?", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(
            title: "No",
            style: UIAlertActionStyle.cancel) { (action) in
                PrinterViewController.connectAndPrintReceipt(address:CommonUtils.getPrinterMACAddress(),printerData: self.printerData)
                self.dismiss(animated: true, completion: nil)
        }
        
        let saveAction = UIAlertAction(
        title: "Yes", style: UIAlertActionStyle.default) { (action) in
            CommonUtils.setSavedPrinterMACAddress(value: CommonUtils.getPrinterMACAddress())
            PrinterViewController.connectAndPrintReceipt(address:CommonUtils.getPrinterMACAddress(),printerData: self.printerData)
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    class func connectAndPrintReceipt(address:String,printerData:NSDictionary)  -> Bool
    {
        let callBackId = printerData["handle"] as? String ?? ""
        let receiptInfo = printerData["receipt"] as? String ?? ""
        if(ZebraBluetooth.connectToDevice(address: address))
        {
            if( ZebraBluetooth.printData(receiptMarkUp: receiptInfo))
            {
                ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + callBackId + "\", false, true )");
                ZebraBluetooth.disconnectFromDevice()
                return true;
            }
        }
        ZebraBluetooth.disconnectFromDevice()
        LoggingRequest.logData(name: LoggingRequest.metrics_print_failed, value: "could not print receipt in the printer", type: "STRING", indexable: true);
        ViewController.webView?.evaluateJavaScript("window.onMessageReceive(\"" + callBackId + "\", false, false )");
        return false;
    }
}
