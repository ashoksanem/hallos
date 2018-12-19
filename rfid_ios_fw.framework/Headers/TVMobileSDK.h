//
//  TruVueMobileSDK.h
//  TruVueMobileSDK
//
//  Copyright © 2016 Johnson Controls. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVEnums.h"

@class ReaderStatus;
@class ReaderConfig;
@protocol TVMobileSDKDelegate;

@interface TVMobileSDK : NSObject

@property(nonatomic, strong) NSObject <TVMobileSDKDelegate> *delegate;

+ (NSString *)getSdkVersion;

//region Configuration
#pragma mark Configuration

- (TVGeneralResult)initReaderWithReaderType:(TVSupportedReader)readerType
                             readerDelegate:(id <TVMobileSDKDelegate>)delegate;

- (TVGeneralResult)setReaderPower:(int)readerPower;

- (TVGeneralResult)setReaderSession:(TVReaderSession)readerSession;

- (TVGeneralResult)setReaderVolume:(TVReaderVolume)readerVolume;

- (TVGeneralResult)enableBarcodeScanner:(BOOL)enable;

- (TVGeneralResult)configureWithReaderConfig:(ReaderConfig *)readerConfig;

- (TVGeneralResult)configureWithReaderOptions:(NSDictionary *)readerOptions;

- (ReaderStatus *)getReaderStatus;
//endregion

//region Barcode
#pragma mark Barcode

- (TVGeneralResult)startScanningBarcode;

- (TVGeneralResult)stopScanningBarcode;
//endregion

//region Communication
#pragma mark Communication

- (TVCommResult)initCommServicesWithHost:(NSString *)hostname
                                  onPort:(NSInteger)port;

- (TVCommResult)loginWithUsername:(NSString *)username
                    usingPassword:(NSString *)password;
//endregion

//region Inventory
#pragma mark Inventory

- (TVInventoryResult)openInventorySessionUsingToken:(NSString *)token
                                             atSite:(NSString *)siteId
                                      withTableName:(NSString *)tableName;

- (TVInventoryResult)startInventory;

- (TVInventoryResult)stopInventory;

- (TVInventoryResult)clearTags;

- (TVInventoryResult)commitInventorySession;

- (TVInventoryResult)closeInventorySession;
//endregion

//region Locate Tag
#pragma mark Locate Tag

- (TVLocateResult)openLocateSessionWithUPCs:(NSMutableArray *)upcs
                        usingProductLibrary:(TVProductLibraryType)productLibrary
                                 withHeader:(NSString *)header;

- (TVLocateResult)startLocating;

- (TVLocateResult)stopLocating;

- (TVLocateResult)locateNextTag;

- (TVLocateResult)closeLocateSession;
//endregion

//region Write Tag
#pragma mark Write Tag

- (TVWriteResult)openWriteSessionUsingTimeout:(unsigned int)timeout
                                  withRetries:(unsigned int)retries;

- (TVWriteResult)writeTag:(NSString *)tag
                 withData:(NSString *)data;

- (TVWriteResult)closeWriteSession;
//endregion

@end
