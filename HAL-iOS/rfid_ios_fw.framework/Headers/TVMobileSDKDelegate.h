//
// Copyright (c) 2016 Johnson Controls. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVEnums.h"
#import "TVLogger.h"

@class ReaderStatus;


@protocol TVMobileSDKDelegate <NSObject>
@optional

//region General
- (void)tvReaderDidTriggerStart;

- (void)tvReaderDidTriggerStop;

- (void)tvReaderDidChangeStatus:(ReaderStatus *)readerStatus;
//endregion

//region Barcode
- (void)tvReaderDidScanBarcode:(NSString *)barcode;
//endregion

//region Communication
- (void)tvUserDidAuthenticate:(TVCommResult)result token:(NSString *)token;
//endregion

//region Inventory
- (void)tvInventoryDidOpenSession:(TVInventoryResult)result
                           inZone:(NSString *)zoneId
                    withSessionId:(NSString *)sessionId
               withIsSessionOwner:(BOOL)isSessionOwner;

- (void)tvInventoryDidCommitSession:(TVInventoryResult)result;

- (void)tvInventoryDidCloseSession:(TVInventoryResult)result;

- (void)tvInventoryDidReadTag:(NSString *)epc;

- (void)tvInventoryDidChangeLocalTagCount:(NSUInteger)localTagCount;

- (void)tvInventoryDidChangeTotalTagCount:(NSUInteger)totalTagCount;

- (void)tvInventoryDidChangeUserCount:(NSUInteger)userCount;
//endregion

//region Locate
- (void)tvLocateDidTag:(NSString *)upc changeProximity:(NSUInteger)proximityPercentage;
//endregion

@end
