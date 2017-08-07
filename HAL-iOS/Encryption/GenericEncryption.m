//
//  GenericEncryption.m
//  HAL-iOS
//
//  Created by Brian Dembinski on 8/1/17.
//  Copyright © 2017 macys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GenericEncryption.h"
#include <openssl/md5.h>
#include <openssl/sha.h>
#import <openssl/evp.h>
#include <openssl/rsa.h>

@implementation GenericEncryption

RSA * rsaContext = nil;
unsigned char *rsaPublicKey = nil;
NSString *rsaPublicModulusHex = nil;
NSString *rsaPublicExpHex = @"00010001";

const int RSA_KEY_BYTES = 512;
const int RSA_KEY_BITS = 2048;

+(short)rsaInit {
    rsaContext = RSA_new();
    
    rsaPublicKey = (unsigned char *)malloc(RSA_KEY_BYTES);
    
    memset( rsaPublicKey, 0, RSA_KEY_BYTES );
    
    BIGNUM *pubExponent = BN_new();
    BN_set_word(pubExponent, RSA_F4);   /* RSA_F4 = 65537 or 0x10001L */
    if ( pubExponent != NULL )
    {
        RSA_generate_key_ex( rsaContext, (int)RSA_KEY_BITS, pubExponent, NULL );
        BN_free( pubExponent );
    }
    
    if( rsaContext == nil )
        return (-1);
    
    //copy over to the public key
    BN_bn2bin( (const BIGNUM *)rsaContext->n, rsaPublicKey );
    
    //pull it out in hex
    NSMutableString *hex = [NSMutableString string];
    for( int i = 0; i < RSA_KEY_BYTES / 2; i++ )
        [hex appendFormat:@"%02X", rsaPublicKey[i]];
    
    //store that modulus, yeah
    rsaPublicModulusHex = [NSString stringWithString:hex];
    
    return 0;
}

+(NSString *)getRsaPublicExpHex
{
    return rsaPublicExpHex;
}

+(NSString *)getRsaPublicModulusHex
{
    return rsaPublicModulusHex;
}

+(NSData *)decrypt:( NSString * ) encryptedString
{
    int asciiLength = encryptedString.length;
    
    // uh oh no data
    if( asciiLength <= 0 )
        return nil;
    
    char tempFrom[asciiLength+1];
    memset( tempFrom, 0, asciiLength+1 );
    memcpy(tempFrom, encryptedString.cString, asciiLength);
    
    // length has to be divisible by two
    // since it took 1 ascii character (8 bits)
    // to represent 1 hexadecimal digit (4 bits)
    if( asciiLength % 2 != 0 )
        return nil;
    
    int length = asciiLength / 2;
    
    unsigned char tempTo[length];
    memset( tempTo, 0, length );
    
    // loop through each character and
    // subtract off the appropriate offset
    // to make it the binary number
    unsigned char high4 = 0;
    unsigned char low4 = 0;
    int binaryIndex = 0;
    for( int i = 0; i < asciiLength; )
    {
        // grab the next two characters
        high4 = tempFrom[i++];
        low4 = tempFrom[i++];
        
        // if it's 'A' - 'F' need to subtract 0x37
        // else subtract just 0x30 for both
        // the low and high digits
        if( high4 >= 'A' )
            high4 -= 0x07;
        high4 -= 0x30;
        
        if( low4 >= 'A' )
            low4 -= 0x07;
        low4 -= 0x30;
        
        // put the high in the higher 4 bits
        // and the low in the lower 4 bits
        tempTo[binaryIndex] = (high4 << 4) | low4;
        binaryIndex++;
    }
    
//    NSMutableString *hex = [NSMutableString string];
//    for( int i = 0; i < RSA_KEY_BYTES / 2; i++ )
//        [hex appendFormat:@"%02X", tempTo[i]];
//    NSLog(@"hex: %@", hex);
    
    unsigned char binaryValue[RSA_KEY_BYTES];
    memset( binaryValue, 0x00, RSA_KEY_BYTES );
    
    int rvRsaPrivateKeyDecrypt;
    unsigned char encryptedBytes[RSA_KEY_BYTES*2];
    unsigned char decryptedBytes[RSA_KEY_BYTES*2];
    
    memset( encryptedBytes, 0x00, RSA_KEY_BYTES*2 );
    memset( decryptedBytes, 0x00, RSA_KEY_BYTES*2 );
    memcpy( encryptedBytes, tempTo, RSA_KEY_BYTES );
    
//    NSMutableString *hex2 = [NSMutableString string];
//    for( int i = 0; i < RSA_KEY_BYTES / 2; i++ )
//        [hex2 appendFormat:@"%02X", encryptedBytes[i]];
//    NSLog(@"hex2: %@", hex2);
    
    rvRsaPrivateKeyDecrypt = RSA_private_decrypt( ( RSA_KEY_BYTES / 2 ),
                                                 ( unsigned char * )encryptedBytes,
                                                 ( unsigned char * )decryptedBytes,
                                                 rsaContext,
                                                 RSA_PKCS1_PADDING );
    if ( rvRsaPrivateKeyDecrypt != (-1) )
    {
        // WOO!
        return [NSData dataWithBytes:decryptedBytes length:( RSA_KEY_BYTES / 16 )];
    }
  
//    unsigned long rc = 1;
//    while( rc = ERR_get_error() )
//    {
//        NSLog(@"rc [%ld]", rc);
//    }

    return nil;
}

@end
