//
//  Locn.swift
//  HAL-iOS
//
//  Created by Brian Dembinski on 1/6/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

public class Locn {
    
    required public init()
    {
        getLocn();
    }
    
    public func getLocn()
    {
        if let path = Bundle.main.path(forResource: "LOCN", ofType: "json")
        {
            do
            {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped);
                let jsonObj = JSON(data: data);
                
                if( jsonObj != JSON.null )
                {
                    let divisionString = ( CommonUtils.getDivNum() == 72 ? "Bloomingdales" : "Macys" );
//                    let divisionString = /*"Bloomingdales"*/ "Macys";
                    let div = jsonObj["getLocationsResponse"][divisionString]["LocationsDetail"];
                    for store in div
                    {
                        if( store.1["locationStatusCode"] == "A" &&      // check for active listing
                            store.1["locationLegacyNbr"].intValue == CommonUtils.getStoreNum())
                        {
                            CommonUtils.setLocnNum(value: store.1["locationLocnNbr"].intValue)
                            print( "StoreNum: " + String( CommonUtils.getStoreNum() ) );                            
                            print( "LOCN: " + String( CommonUtils.getLocnNum() ) );
                            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: ( "LOCN: " + String( CommonUtils.getLocnNum() ) ), type: "STRING", indexable: true);
                        }
                    }
                }
                else
                {
                    LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to open LOCN JSON file.", type: "STRING", indexable: true);
                }
            }
            catch let error
            {
                LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "LOCN JSON file: " + error.localizedDescription, type: "STRING", indexable: true);
            }
        }
        else
        {
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Invalid LOCN JSON file.", type: "STRING", indexable: true);
        }
    }
}
