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

    var window: UIWindow?
    var sled: DTDevices?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CommonUtils.setUpUserDefaults();
        
        //since the sumulator isn't in AW let's force some values
        if(CommonUtils.isSimulator())
        {
            setSimulatorValues();
        }
        
        if let app = application as? HALApplication
        {
            app.startTimer();
        }
        
        //app.startNetworkTimer()
        detectDevice();
        
        NotificationCenter.default.addObserver( self,
            selector: #selector(readMDMValues),
            name: UserDefaults.didChangeNotification,
            object: nil);
        
        NSSetUncaughtExceptionHandler { exception in
            DLog("error details : " + exception.reason!)
            LoggingRequest.logData(name: LoggingRequest.metrics_app_crash, value: exception.reason!, type: "STRING", indexable: true);
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
        
        Heap.setAppId("282132961"); //282132961 = development       1675328291 = production
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
        if(CommonUtils.isScanEnabled())
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                viewController.updateBarcodeData(barcode: barcode);
            }
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
            
            do {
                try sled?.setPassThroughSync(false);
                //disableScanner();
            }
            catch {
                
                DLog("Sled pass through error: " + String(describing:error));
            }
            if(CommonUtils.isScannerModeEnabledFromWeb())
            {
                enableScanner();
            }
            else
            {
                disableScanner();
            }
            disableMsr();
        }
        else {
            LoggingRequest.logData(name: LoggingRequest.metrics_lost_peripheral_connection, value: "sled", type: "STRING", indexable: true);
        }
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
                                                      AnyHashable("associateNumber"):CommonUtils.getCurrentAssociate(),
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
