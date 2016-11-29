//
//  ZPLConnector.h
//  HAL-iOS
//
//  Created by Pranitha on 11/22/16.
//  Copyright © 2016 macys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTDevices.h"

@interface ZPLConnector : NSObject
-(bool)printStuff:(NSString *)printData withSled:(DTDevices *)sled isCPCL:(bool)isCPCL;
@end
