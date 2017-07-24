//
//  AppDelegate.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/27/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import CoreData
import SystemConfiguration.CaptiveNetwork

//@UIApplicationMain
class AppDelegate: UIResponder, DTDeviceDelegate, UIApplicationDelegate {

    var window: UIWindow?;
    var sled: DTDevices?;
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CommonUtils.setUpUserDefaults();
        
        //since the sumulator isn't in AW let's force some values
        if( CommonUtils.isSimulator() ) {
            setSimulatorValues();
        }
        
        if let app = application as? HALApplication {
            app.startTimer();
        }
        
        //app.startNetworkTimer()
        detectDevice();
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(readMDMValues),
                                                name: UserDefaults.didChangeNotification,
                                                object: nil);
        
        NSSetUncaughtExceptionHandler { exception in
            DLog( "error details : " + exception.reason! );
            LoggingRequest.logData( name: LoggingRequest.metrics_app_crash, value: exception.reason!, type: "STRING", indexable: true );
        }
        
        let crashReporter = PLCrashReporter.shared();
        
        if( crashReporter?.hasPendingCrashReport() )! {
            DLog("Previous Error!");
            do {
                let crashData = try crashReporter?.loadPendingCrashReportDataAndReturnError();
                
                do {
                    let report = try PLCrashReport.init(data: crashData);
                    
                    let humanReadableReport: String = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS);
                    
                    //convert to NSData type
                    let crashReport = humanReadableReport.data(using: String.Encoding.utf8);
                   
                    //log the base64 encoded stack trace
                    LoggingRequest.logError(name: LoggingRequest.metrics_app_crash, value: (crashReport?.base64EncodedString())!, type: "STRING", indexable: false);
                }
                catch {
                    DLog("Could not parse crash report.");
                    LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not parse crash report.", type: "STRING", indexable: true);
                }
                
                crashReporter?.purgePendingCrashReport();
            }
            catch {
                DLog("Could not load crash report.");
                LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not load crash report.", type: "STRING", indexable: true);
                crashReporter?.purgePendingCrashReport();
            }
        }
        
        // Enable the Crash Reporter
        do {
            try crashReporter?.enableAndReturnError();
            DLog("Crash reporter enabled.");
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Crash reporter enabled.", type: "STRING", indexable: true);
        }
        catch
        {
            DLog("Could not enable crash reporter.");
            LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not enable crash reporter.", type: "STRING", indexable: true);
        }
        
        //_ = [][0];
        
        let iHateYouApple = SharedContainer.getIsp();
        iHateYouApple.substring(to: iHateYouApple.index(iHateYouApple.startIndex, offsetBy: 2)) == "fs" ?
            Heap.setAppId("282132961") :
            Heap.setAppId("1675328291");   //282132961 = development       1675328291 = production
        
        //Heap.enableVisualizer();  // let's keep this here for future research but don't want it turned on now. 
        
        return true;
    }
    
    func checkSSID() -> Bool
    {
        if( CommonUtils.isSimulator() )
        {
            return true;
        }

        let ssids = currentSSIDs();
        
        for ssid in ssids {
            if( ssid == "FDS030A" ) ||
              ( ssid == "FDS030B" ) ||
              ( ssid == "FDS030C" ) ||
              ( ssid == "MST030B" ) ||
              ( ssid == "MST030A" ) ||
              ( ssid == "MST030C" ) ||
              ( ssid == "FDS030AZ" ) ||
              ( ssid == "LAB030A" ) ||
              //( ssid == "FDS010" ) || // used for QE testing on a dev build only
              ( ssid == "MB030A" )
            {
                return true;
            }
        }
        
        if( ssids.count > 0 ) {
            LoggingRequest.logData(name: "IncorrectSSID", value: ssids[0], type: "STRING", indexable: true);
        }
        else {
            LoggingRequest.logData(name: "IncorrectSSID", value: "No SSID found", type: "STRING", indexable: true);
        }
        
        return false;
    }

    func currentSSIDs() -> [String] {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        return interfaceNames.flatMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        //CommonUtils.setIsSSOAuthenticated( value: false );
        //LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by applicationDidEnterBackground.", type: "STRING", indexable: true);
        
        if let app = application as? HALApplication
        {
            app.stopNetworkTimer();
            app.stopMetricTimer();
            app.stopBatteryTimer();
            app.stopJSTimer();
            app.stopChargingTimer();
        }
        self.setLineaCharging(val: false);
        
       /* if let viewController:ViewController = window!.rootViewController as? ViewController
        {
            viewController.loadWebView(url: CommonUtils.getLandingPage() );
        }*/
        
        LoggingRequest.logData(name: LoggingRequest.metrics_app_shutdown, value: "", type: "STRING", indexable: true);
        LoggingRequest.logStoredData();
        LogAnalyticsRequest.logStoredData();
        DataForwarder.forwardStoredData();
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if( !checkSSID() )
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                let jail = "The network settings on this device are not correct. Remove the device from the sales floor immediately and open a ticket.";
            
                // create the alert
                let alert = UIAlertController(title: "Network Error", message: jail, preferredStyle: UIAlertControllerStyle.alert)
            
                // add an action (button)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    switch action.style
                    {
                        case .default:
                            exit(0);
                        case .cancel:
                            exit(0);
                        case .destructive:
                            exit(0);
                    }
                }))
            
                // show the alert
                viewController.present(alert, animated: true, completion: nil)
            
                //exit(0);
            }
        }
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if( ( Date().timeIntervalSince( CommonUtils.getAutoLogoutStartTime() ) > TimeInterval( CommonUtils.getAutoLogoutTimeinterval() ) ) )
        {
            autoLogout();
        }
        else
        {
            if( !CommonUtils.isSSOAuthenticated() )
            {
                if let viewController:ViewController = window!.rootViewController as? ViewController
                {
                    viewController.loadWebView(url: CommonUtils.getLandingPage() );
                }
            }
            else if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                CommonUtils.setCurrentPage(value: (ViewController.webView?.url)!);
                let url = Bundle.main.url(forResource: "sso/index", withExtension:"html")
                viewController.loadWebView(url: url!)
            }
        }
        
        LoggingRequest.logData(name: LoggingRequest.metrics_app_startup, value: "", type: "STRING", indexable: true);
        LoggingRequest.logStoredData();
        LogAnalyticsRequest.logStoredData();
        DataForwarder.forwardStoredData()
        detectDevice();
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(readMDMValues),
                                                name: UserDefaults.didChangeNotification,
                                                object: nil);
        
        if let app = application as? HALApplication
        {
            app.startNetworkTimer();
            app.startMetricTimer();
            app.startBatteryTimer();
            app.startJSTimer();
            app.startChargingTimer();
        }
    }
    
    func setSimulatorValues()
    {
        CommonUtils.setLandingPage(value: URL(string: "http://mstore.devops.fds.com/")!);
        CommonUtils.setAutoLogoutTimeinterval(value: 3600);
        CommonUtils.setDivNum(value: 71);
        CommonUtils.setStoreNum(value: 572);
        SharedContainer.setIsp(value: "fs572asisp01");
        SharedContainer.setSsp(value: "fs008asssp01");
        SharedContainer.setCloud(value: "junk");
        CommonUtils.setLogRetryCount(value: 10);
        CommonUtils.setLogCountLimit(value: 5);
        CommonUtils.setLogRetryFrequency(value: 120);
        CommonUtils.setLogTimeLimit(value: 120);
        CommonUtils.setCertificatePinningEnabled(value: false);
        let esp = ESPRequest();
        esp.getZipCode();
    
        _ = Locn();
    
        CommonUtils.setCommonLogMetrics();
    }
    
    func readMDMValues()
    { //addLineZPL()
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil);
        let userDefaults = UserDefaults.standard;
        if let answersSaved = userDefaults.dictionary(forKey: CommonUtils.managedAppConfig)
        {
            if let val = answersSaved["landingPage"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    let url = URL(string: trimmed)!;
                    CommonUtils.setLandingPage(value: url);
                    
                    DLog("Setting landingPage to: " + trimmed);
                }
            }
            
            if let val = answersSaved["autoLogout"]
            {
                if(!((val as? Int)==nil))
                {
                    CommonUtils.setAutoLogoutTimeinterval(value: val as! Int);
                    let val = "Setting autoLogout to: " + String(describing:val);
                    
                    DLog( val );

                    //LoggingRequest.logData(name: LoggingRequest.metrics_info, value: val, type: "STRING", indexable: true);
                }
            }
            
            if let val = answersSaved["divNum"]
            {
                if(!((val as? Int)==nil))
                {
                    CommonUtils.setDivNum(value: val as! Int);
                    
                    DLog("Setting divNum to: " + String(describing:val));
                }
            }
            
            if let val = answersSaved["storeNum"]
            {
                if(!((val as? Int)==nil))
                {
                    CommonUtils.setStoreNum(value: val as! Int);
                    
                    DLog("Setting storeNum to: " + String(describing:val));
                }
            }
            
            if let val = answersSaved["isp"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setIsp(value: trimmed);
                    
                    DLog("Setting isp to: " + trimmed);
                }
            }
            
            if let val = answersSaved["ssp"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setSsp(value: trimmed);
                    
                    DLog("Setting ssp to: " + trimmed);
                }
            }
            
            if let val = answersSaved["cloud"]
            {
                if let _val = val as? String {
                    let trimmed = _val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                    SharedContainer.setCloud(value: trimmed);
                    
                    DLog("Setting cloud to: " + trimmed);
                }
            }
            
            if let val = answersSaved["LogRetryCount"]
            {
                if(!((val as? Int)==nil))
                {
                    CommonUtils.setLogRetryCount(value: val as! Int);
                }
            }
            
            if let val = answersSaved["LogStorageCountLimit"]
            {
                if(!((val as? Int)==nil))
                {
                    CommonUtils.setLogCountLimit(value: val as! Int);
                }
            }
            
            if let val = answersSaved["LogRetryFrequency"]
            {
                if(!((val as? Double)==nil))
                {
                    CommonUtils.setLogRetryFrequency(value: val as! Double);
                }
            }
            
            if let val = answersSaved["LogStorageTimeLimit"]
            {
                if(!((val as? Double)==nil))
                {
                    CommonUtils.setLogTimeLimit(value: val as! Double);
                }
            }
            
            if let val = answersSaved["CertificatePinning"]
            {
                if(!((val as? Bool)==nil))
                {
                    CommonUtils.setCertificatePinningEnabled(value: val as! Bool);
                }
            }
            
            // if we add anything else to change on the fly it might also need to be added to setSimultorValues()
            let esp = ESPRequest();
            esp.getZipCode();
            
            _ = Locn();
        }
        
        CommonUtils.setCommonLogMetrics();
    };
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext();
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "HAL_iOS");
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the 
                 
                 
                 
                 
                 
                 
                 device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)");
            }
        })
        return container;
    }()

    // MARK: - Core Data Saving support

    @available(iOS 10.0, *)
    func saveContext () {
        let context = persistentContainer.viewContext;
        if context.hasChanges {
            do {
                try context.save();
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError;
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)");
            }
        }
    }
    
    func getSled()-> Any?
    {
        if(isLineaConnected()) {
            return sled!;
        }
        else {
            return nil;
        }
    }
    
    func detectDevice()
    {
        sled = DTDevices.sharedDevice() as? DTDevices;
        
        DLog("sled SDK version: " + String(describing: sled?.sdkVersion));
        sled?.addDelegate(self);
        sled?.connect();
    }
    
    func isLineaConnected()->Bool
    {
        return ( sled?.connstate == 2 );
    }

    func isLineaCharging() -> Bool
    {
        if( isLineaConnected() )
        {
            var youSuckIP = ObjCBool(false)
            
            do {
                try sled?.getCharging(&youSuckIP);
            }
            catch {
                youSuckIP = false;
            }
            return youSuckIP.boolValue;
        }
        
        return false;
    }
    
    func setLineaCharging(val : Bool) -> Void
    {
        if( isLineaConnected() )
        {
            //        DLog( @"Charging switched to %s with rc of %s\n", chargeFlag ? "true":"false", [sled setCharging:chargeFlag error:nil] ? "true":"false" );
            do {
                try sled?.setCharging( val );
            }
            catch {
                
                DLog("Failed to charge");
            }
        }
    }
    
    func setLineaIdleTimeout() -> Void
    {
        if( isLineaConnected() )
        {
            //Set linea idle timeout of lightning port when app is running to 12 hours and disconnect timeout while app is in background to 12 hours.
            do{
                try sled?.setAutoOffWhenIdle(43200, whenDisconnected: 43200)
            }
            catch {
                
                DLog("Failed to change idle timeout")
            }
        }
    }
    
    func barcodeData(_ barcode: String!, type: Int32) {
        updateBarcodeData(barcode: barcode);
    }
    
    func barcodeData(_ barcode: String!, isotype: String!) {
        updateBarcodeData(barcode: barcode);
    }
    
    func barcodeNSData(_ barcode: Data!, type: Int32) {
        let strData = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue);
        updateBarcodeData(barcode: strData as! String);
    }
    
    func barcodeNSData(_ barcode: Data!, isotype: String!) {
        let strData = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue);
        updateBarcodeData(barcode: strData as! String);
    }
    
    func updateBarcodeData(barcode: String)
    {
        /*if(CommonUtils.isScanEnabled())
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                viewController.updateBarcodeData(barcode: barcode);
            }
        }*/
        
        if let printerViewController:PrinterViewController = window!.rootViewController?.presentedViewController as? PrinterViewController
        {
            printerViewController.updateMacAddress(barcode: barcode)
        }
        else if let viewController:ViewController = window!.rootViewController as? ViewController        {
            viewController.updateBarcodeData(barcode: barcode)
        }

    }
    
    func connectionState(_ state: Int32) {
        //let viewController:ViewController = window!.rootViewController as! ViewController;
        //viewController.connectionState(state)
        
        updateBattery();
        
        if(state==2)
        {
            //viewController.showAlert(title: (sled?.firmwareRevision)!,message:String(describing: sled?.sdkVersion))
            let val = "Sled firmware version: " + (sled?.firmwareRevision)!;
            let eMSRversion = "Sled eMSR firmware version: " + getSledEmsrFirmwareVersion();
            DLog(val);
            
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: val, type: "STRING", indexable: true);
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: eMSRversion, type: "STRING", indexable: true);

            LoggingRequest.logData(name: "Sled_Firmware_Version", value: (sled?.firmwareRevision)!, type: "STRING", indexable: true);
            LoggingRequest.logData(name: "eMSR_Version", value: getSledEmsrFirmwareVersion(), type: "STRING", indexable: true);
            
            do
            {
                try sled?.setPassThroughSync( false );
                //disableScanner();
            }
            catch
            {
                DLog("Sled pass through error: " + String(describing:error));
            }
            
            if( CommonUtils.isScannerModeEnabledFromWeb() )
            {
                enableScanner();
            }
            else
            {
                disableScanner();
            }
            
            //inject the default key into the MSR head
            let info = sled?.emsrGetDeviceInfo;
            
            if( info != nil )
            {
                if( sled?.emsrGetKeysInfo != nil )
                {
                    var retries = 4;
                    let newKeKData = [UInt8](getKek().utf8);
                    
                    //use version 1 for default key because we can't use version 0
                    let default_key_version = 1;
                    
                    repeat
                    {
                        if( loadKeyId(keyID: KEY_EH_AES256_LOADING, keyData: newKeKData, keyVersion: Int(getKekVersion()), kekData: newKeKData ) )
                        {
                            //We loaded the KEK, and there was much rejoicing

                            if( loadKeyId(keyID: KEY_EH_AES256_ENCRYPTION1, keyData: getDefaultAESKey(), keyVersion: default_key_version, kekData: newKeKData ) )
                            {
                                break;
                            }
                        }
                        
                        retries -= 1;
                        sleep(1);
                    }
                    while( retries > 0 );
                    
                    if( retries == 0 )
                    {
                        //we tried too many times, bail out
                        if let viewController:ViewController = window!.rootViewController as? ViewController
                        {
                            let message = "This device does not have the required security key. Please remove device from sales floor immediately and open a ticket.";
                        
                            // create the alert
                            let alert = UIAlertController(title: "No Security Key", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        
                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                                switch action.style
                                {
                                    case .default:
                                        exit(0);
                                    case .cancel:
                                        exit(0);
                                    case .destructive:
                                        exit(0);
                                }
                            }))
                        
                            // show the alert
                            viewController.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            
            disableMsr();
        }
        else {
            LoggingRequest.logData(name: LoggingRequest.metrics_lost_peripheral_connection, value: "sled", type: "STRING", indexable: true);
        }
    }
    
    //prepares and loads a key
    //NOTE!!!! There can't be a key with duplicate value, this is PCI requirement!
    func loadKeyId(keyID: Int32, keyData:[UInt8], keyVersion:Int, kekData:[UInt8]?) -> Bool
    {
        //format the key to load it, optionally encrypt with KEK
        let generatedKeyData = emsrGenerateKeyData(keyID: keyID, keyVersion: keyVersion, keyData: keyData, kekData: kekData);
        
        do {
            let lib: DTDevices = DTDevices.sharedDevice() as! DTDevices;
            
            //try to load the key in the slot
            try lib.emsrLoadKey(generatedKeyData.getNSData());
            return true;
        } catch let error as NSError {
            DLog("ERROR: Danger Will Robinson! [" + error.localizedDescription + "]");
        }
        return false;
    }
    
    /**
     Loads initial key in plain text or changes existing key. Keys in plain text can be loaded only once,
     on every subsequent key change, they needs to be encrypted with KEY_EH_AES256_LOADING.
     
     KEY_EH_AES256_LOADING can be used to change all the keys in the head except for the TMK, and KEY_AES256_LOADING
     can be loaded in plain text the first time too.
     */
    func emsrGenerateKeyData(keyID: Int32, keyVersion: Int, keyData: [UInt8], kekData: [UInt8]?) -> [UInt8] {
        var data: [UInt8] = [];
        
        data.append(0x2b);
        //key to encrypt with, either KEY_AES256_LOADING or 0xff to use plain text
        data.append((kekData != nil) ? UInt8(KEY_EH_AES256_LOADING) : 0xff);
        data.append(UInt8(keyID)); //key to set
        data.append(UInt8(keyVersion>>24)); //key version
        data.append(UInt8(keyVersion>>16)); //key version
        data.append(UInt8(keyVersion>>8)); //key version
        data.append(UInt8(keyVersion)); //key version
        
        let keyStart = data.count;
        
        var hashed: [UInt8] = [];
        hashed.append(contentsOf: data);
        hashed.append(contentsOf: keyData); //key data
        let hash = SHA256(data: NSData(bytes: hashed, length: hashed.count));
        
        hashed.append(contentsOf: hash.getBytes());
        
        //encrypt the data if using the encryption key
        if kekData != nil {
            let toEncrypt = Array( hashed[keyStart..<hashed.count] );
            let encrypted = AESEncryptWithKey(data: toEncrypt.getNSData() as NSData, key: kekData!.getNSData() as NSData);
            
            //store the encryptd data back into the packet
            data.append(contentsOf: encrypted!.getBytes());
        } else {
            //should never get here
        }
        return data;
    }
    
    func getKek() -> String
    {
        //a4387054:imas b415570$ openssl enc -aes-256-ecb -k InfinitePeripherals -P -md sha1 -nosalt
        //key=4475C493C0AE0B2A112B40535DFE0A61A3FEB9BFB999404DCD8D650932D3F799
        return "4475C493C0AE0B2A112B40535DFE0A61";
    }
    
    func getKekVersion() -> Int32
    {
        return 1;
    }
    
    func getDefaultAESKey() -> [UInt8]
    {
        var array : [UInt8] = [UInt8](repeating: 0x00, count: 32 );
        array[0] = 0xFC;
        array[1] = 0xF3;
        array[2] = 0x80;
        array[3] = 0xD1;
        array[4] = 0xAC;
        array[5] = 0xC2;
        array[6] = 0x72;
        array[7] = 0xEB;
        array[8] = 0x40;
        array[9] = 0x53;
        array[10] = 0x40;
        array[11] = 0x48;
        array[12] = 0x40;
        array[13] = 0xC1;
        array[14] = 0xFC;
        array[15] = 0x6E;
        array[16] = 0x40;
        array[17] = 0xD6;
        array[18] = 0x64;
        array[19] = 0xC2;
        array[20] = 0x6E;
        array[21] = 0xC1;
        array[22] = 0xE2;
        array[23] = 0xCD;
        array[24] = 0x6D;
        array[25] = 0x52;
        array[26] = 0xC8;
        array[27] = 0x66;
        array[28] = 0xA0;
        array[29] = 0x48;
        array[30] = 0x50;
        array[31] = 0xB0;
        
        return array;
    }
    
    func SHA256(data: NSData) -> NSData
    {
        let hash = UnsafeMutablePointer<UInt8>.allocate( capacity: Int( CC_SHA256_DIGEST_LENGTH ) );
        
        CC_SHA256( data.bytes,UInt32( data.length ),hash );
        
        let r = NSData( bytes: hash, length: Int( CC_SHA256_DIGEST_LENGTH ) );
        free( hash );
        
        return r;
    }
    
    func AESOperation(data: NSData, operation:CCOperation, key:NSData) -> NSData?
    {
        var keySize=kCCKeySizeAES256;
        if( key.length <= 16 )
        {
            keySize = kCCKeySizeAES128;
        }
        
        //See the doc: For block ciphers, the output size will always be less than or
        //equal to the input size plus the size of one block.
        //That's why we need to add the size of one block here
        let bufferSize = data.length + kCCBlockSizeAES128;
        
        //        let hash = UnsafeMutablePointer<UInt8>.alloc(Int(CC_SHA256_DIGEST_LENGTH))
        let buffer = malloc(bufferSize);
        var numBytes:size_t = 0;
        let cryptStatus = CCCrypt(operation, CCAlgorithm(kCCAlgorithmAES128), 0, key.bytes, keySize, nil, data.bytes, data.length, buffer, bufferSize, &numBytes);
        
        var d: NSData? = nil;
        if( cryptStatus == CCCryptorStatus(kCCSuccess) )
        {
            //the returned NSData takes ownership of the buffer and will free it on deallocation
            d=NSData(bytes: buffer, length: numBytes);
        }
        
        free(buffer); //free the buffer;
        return d;
    }
    
    func AESEncryptWithKey(data: NSData, key:NSData) -> NSData?
    {
        return AESOperation(data: data, operation:CCAlgorithm(kCCEncrypt), key:key);
    }
    
    func AESDecryptWithKey(data: NSData, key:NSData) -> NSData?
    {
        return AESOperation(data: data, operation:CCAlgorithm(kCCDecrypt), key:key);
    }

    
    func enableScanner()
    {
        CommonUtils.setScannerModeFromWeb(value: true);
       do{
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.ENABLED.rawValue)
            CommonUtils.setScanEnabled(value: true);
        }
        catch {
            
            DLog("Enable scanner error: " + String(describing:error));
        }
    }
    
    func disableScanner()
    {
        CommonUtils.setScannerModeFromWeb(value: false);
        do{
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.DISABLED.rawValue)
            CommonUtils.setScanEnabled(value: false);
   
        }
        catch {
            
            DLog("Disable scanner error: " + String(describing:error));
        }
    }
    
    func getSledBatteryLevel() -> Int32
    {
        if( isLineaConnected() )
        {
            do{
                let battery = try (sled?.getBatteryInfo().capacity)! as Int32
                return battery
            }
            catch {
                
                DLog("Get sled battery level error: " + String(describing:error));
                
            }
        }
        return 0;
    }
    func getSledEmsrFirmwareVersion() -> String
    {
        if( isLineaConnected() )
        {
            do{
                let firmwareVersion = try (sled?.emsrGetDeviceInfo().firmwareVersionString)! as String;
                return firmwareVersion;
            }
            catch {
                
                DLog("Get sled eMSR firmware version error: " + String(describing:error));
                
            }
        }
        return "";
    }
    
    func getDeviceBatteryLevel() -> Float
    {
        UIDevice.current.isBatteryMonitoringEnabled = true;
        
        DLog("Sled battery: " + String(describing:UIDevice.current.batteryLevel));
        return UIDevice.current.batteryLevel;
    }
    
    func updateBattery() {
        if let viewController:ViewController = window!.rootViewController as? ViewController
        {
            viewController.updateBattery();
        }
    }
    
    func autoLogout() {
        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout due to inactivity.", type: "STRING", indexable: true);
        Heap.track("AssociateLogout", withProperties:[AnyHashable("reason"):"inactivity",
                                                      AnyHashable("associateNumber"):CommonUtils.getCurrentAssociateNum(),
                                                      AnyHashable("duration"):CommonUtils.getSSODuration(),
                                                      AnyHashable("divNum"):CommonUtils.getDivNum(),
                                                      AnyHashable("storeNum"):CommonUtils.getStoreNum()]);
        
        CommonUtils.setIsSSOAuthenticated( value: false );
        
        if let viewController:ViewController = window!.rootViewController as? ViewController
        {
            viewController.loadWebView(url: CommonUtils.getLandingPage() );
        }
    }
    
    func enableMsr()
    {
        do{
            try sled?.msEnable();
            try sled?.msSetCardDataMode(0);
            CommonUtils.setEnableMsr(value: true);
            let val = "Timestamp : " + CommonUtils.getDateformatter().string(from: Date());
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_startup, value: val , type: "STRING", indexable: true);
        }
        catch {
            CommonUtils.setEnableMsr(value: false);
            let val = "Error in activating MSR at timestamp : " + CommonUtils.getDateformatter().string(from: Date()) + " with error : "+String(describing:error);
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_connectionError, value: val , type: "STRING", indexable: true);
            DLog("Enable MSR error : " + String(describing:error));
        }
    }
    
    func disableMsr()
    {
        do{
            try sled?.msDisable();
            CommonUtils.setEnableMsr(value: false);
            let val = "Timestamp : " + CommonUtils.getDateformatter().string(from: Date());
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_shutdown, value: val , type: "STRING", indexable: true);
        }
        catch {
            let val = "Error in deactivating MSR at timestamp : " + CommonUtils.getDateformatter().string(from: Date()) + " with error : "+String(describing:error);
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_connectionError, value: val , type: "STRING", indexable: true);
            DLog("Disable MSR error: " + String(describing:error));
        }
    }
    
    func updateMsrData(msrData: String)
    {
        if(CommonUtils.isMsrEnabled())
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                viewController.updateMsrData(msrData: msrData);
            }
        }
    }
    
    func magneticCardRawData(_ tracks: Data!) {
        let cardData = tracks ?? Data.init();
        let msrData = [
            "tracks": cardData.base64EncodedString(),
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
    }
    
    func magneticCardData(_ track1: String!, track2: String!, track3: String!) {
        let msrData = [
            "track1": track1 ?? "",
            "track2": track2 ?? "",
            "track3": track3 ?? ""
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
        
    }
    func magneticCardEncryptedRawData(_ encryption: Int32, data: Data!) {
        let cardData = data ?? Data.init();
        let msrData = [
            "data": cardData.base64EncodedString(),
            "encryption": encryption
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
    }
    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!) {
        let cardData = data ?? Data.init();
        let msrData = [
            "data": cardData.base64EncodedString(),
            "encryption": encryption,
            "tracks":tracks
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
    }
    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!, track1masked: String!, track2masked: String!, track3: String!) {
        let cardData = data ?? Data.init();
        let msrData = [
            "data": cardData.base64EncodedString(),
            "encryption": encryption,
            "tracks":tracks,
            "track1masked":track1masked ?? "",
            "track2masked":track2masked ?? "",
            "track3":track3 ?? ""
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
    }
    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!, track1masked: String!, track2masked: String!, track3: String!, source: Int32) {
        let cardData = data ?? Data.init();
       
//        let decrypted = AESDecryptWithKey(data: data as NSData, key: getDefaultAESKey().getNSData() as NSData );
//        let decryptedBytes = decrypted?.getBytes();
        
        do {
            let keyInfo = try sled?.emsrGetKeysInfo();
            if( keyInfo != nil ) {
                if( keyInfo?.getKeyVersion(KEY_EH_AES256_ENCRYPTION1 ) == 1 ) {
                    // Version 1 is the default key. Whoops!
                    LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "MSR swipe using default key.", type: "STRING", indexable: true);
                }
            }
            else {
                LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to get MSR keyInfo.", type: "STRING", indexable: true);
            }
        }
        catch {
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to get MSR key version.", type: "STRING", indexable: true);
        }
        
        let msrData = [
            "data": cardData.base64EncodedString(),
            "encryption": encryption,
            "tracks":tracks,
            "track1masked":track1masked ?? "",
            "track2masked":track2masked ?? "",
            "track3":track3 ?? "",
            "source":source
            ] as [String : Any]
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        updateMsrData(msrData: String(data: msrJsonData, encoding: String.Encoding.utf8)!);
    }
}
