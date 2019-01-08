//
// Copyright (c) 2016 Johnson Controls. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TVEnums : NSObject

typedef NS_ENUM(NSUInteger, TVReaderMode) {
    TVReaderModeLocate,
    TVReaderModeWrite,
    TVReaderModeInventory,
    TVReaderModeNone
};

typedef NS_ENUM(NSUInteger, TVReaderSession) {
    TVReaderSession0,
    TVReaderSession1,
    TVReaderSession2,
    TVReaderSession3
};

typedef NS_ENUM(NSUInteger, TVReaderVolume) {
    TVReaderVolumeMute,
    TVReaderVolumeLow,
    TVReaderVolumeMedium,
    TVReaderVolumeHigh
};

typedef NS_ENUM(NSUInteger, TVGeneralResult) {
    TVGeneralSuccess,
    TVGeneralFailure
};

typedef NS_ENUM(NSInteger, TVCommResult) {
    TVCommSuccess,
    TVCommFailure,
    TVCommNotInitialized
};

typedef NS_ENUM(NSUInteger, TVInventoryResult) {
    TVInventorySuccess,
    TVInventoryFailure,
    TVInventoryCommNotInitialized,
    TVInventoryNoOpenSession
};

typedef NS_ENUM(NSUInteger, TVLocateResult) {
    TVLocateSuccess,
    TVLocateNoTagLockedOn,
    TVLocateNoTagsToLocate,
    TVLocateNoOpenSession
};

typedef NS_ENUM(NSUInteger, TVWriteResult) {
    TVWriteSuccess,
    TVWriteFailure,
    TVWriteTagNotFound,
    TVWriteInvalidTagLength,
    TVWriteNoOpenSession
};

typedef NS_ENUM(NSUInteger, TVProductLibraryType) {
    TVProductLibraryUnknown,
    TVProductLibraryEANUCC,
    TVProductLibraryVUESER,
    TVProductLibraryVUESERAUTH
};

typedef NS_ENUM(NSUInteger, TVSupportedReader) {
    Zebra,
    Bluebird
};

@end
