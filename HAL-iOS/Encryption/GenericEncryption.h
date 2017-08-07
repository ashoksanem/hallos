
#import <Foundation/Foundation.h>

@interface GenericEncryption : NSObject

+(short)rsaInit;
+(NSString *)getRsaPublicModulusHex;
+(NSString *)getRsaPublicExpHex;
+(NSData *)decrypt:( NSString * ) encryptedValue;

@end
