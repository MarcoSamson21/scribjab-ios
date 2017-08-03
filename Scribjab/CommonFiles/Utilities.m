//
//  Utilities.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Utilities.h"
#import <CommonCrypto/CommonDigest.h>
#import "Globals.h"
#import "ZipArchive.h"

@implementation Utilities

// ======================================================================================================================================
// Validate email string and return YES is email appears to be properly formatted, NO otherwise. 
+ (BOOL) isEmailValid: (NSString *) candidate 
{
    //NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSString *emailRegex = @"^[a-zA-Z0-9_!~&\\+=\\-]+([\\.]{1}[a-zA-Z0-9_!~&\\+=\\-]+)*[@]{1}([a-zA-Z0-9]{2,}([\\.\\-]{0,1}[a-zA-Z0-9]{2,})*)+[\\.]{1}[a-zA-Z0-9]{2,}$";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:candidate];
}

// ======================================================================================================================================
// Compute Sha1 encoding for a string
+(NSString*) sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
    
}
// ======================================================================================================================================
// Compute md5 encoding for a string
+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}

// ======================================================================================================================================
// Convert NSData to Base64 String
+ (NSString*)base64forData:(NSData*)theData
{
    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

// ======================================================================================================================================
// Convert Base64 string to NSData
+ (NSData *)base64DataFromString: (NSString *)string
{
    unsigned long ixtext, lentext;
    unsigned char ch, inbuf[4], outbuf[3];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;
    
    if (string == nil)
        return [NSData data];

    ixtext = 0;
    tempcstring = (const unsigned char *)[string UTF8String];
    lentext = [string length];
    theData = [NSMutableData dataWithCapacity: lentext];
    ixinbuf = 0;
    
    while (true)
    {
        if (ixtext >= lentext)
            break;
        
        ch = tempcstring [ixtext++];
        flignore = false;
        
        if ((ch >= 'A') && (ch <= 'Z'))
            ch = ch - 'A';
        else if ((ch >= 'a') && (ch <= 'z'))
            ch = ch - 'a' + 26;
        else if ((ch >= '0') && (ch <= '9'))
            ch = ch - '0' + 52;
        else if (ch == '+')
            ch = 62;
        else if (ch == '=')
            flendtext = true;
        else if (ch == '/')
            ch = 63;
        else
            flignore = true;
        
        if (!flignore)
        {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;
            
            if (flendtext)
            {
                if (ixinbuf == 0)
                    break;
                
                if ((ixinbuf == 1) || (ixinbuf == 2))
                    ctcharsinbuf = 1;
                else
                    ctcharsinbuf = 2;

                ixinbuf = 3;
                flbreak = true;
            }
            
            inbuf [ixinbuf++] = ch;
            
            if (ixinbuf == 4)
            {
                ixinbuf = 0;
                
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                
                for (i = 0; i < ctcharsinbuf; i++)
                {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak)
                break;
        }
    }
    
    return theData;
}

// ======================================================================================================================================
// get absolute path based on document directory.
+(NSString *) getAbsoluteFile:(NSString *)filePath
{
    return [[[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingString:@"/"] stringByAppendingString:filePath];
}

// ======================================================================================================================================
+ (NSString *)NSDateToJSONString:(NSDate *)date
{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"yyyy-MM-dd"];
//    NSLog(@"%@, DateTime is %@", date, [fmt stringFromDate:date]);
    return [fmt stringFromDate:date];
}
// ======================================================================================================================================
+ (BOOL)createZipFrom:(NSDictionary *)source targetURL:(NSString *)targetURL 
{
    ZipArchive *zipArchive = [[ZipArchive alloc] init];
    BOOL ret = [zipArchive CreateZipFile2:targetURL];
    
    if(ret)
    {
        NSArray *keys = [source allKeys];
        for(NSString * fileName in keys)
        {
            NSString * sourceURL= [source objectForKey:fileName];
            ret = [zipArchive addFileToZip:sourceURL newname:fileName];
            if(!ret)
            {
                break;
            }
        }
        ret = [zipArchive CloseZipFile2];
    }
    return ret;
}

// ======================================================================================================================================
// Determine what language the device is in and return corresponding input parameter.
+ (NSString*) localizedStringFromEnglish:(NSString *)english french:(NSString*)french
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([language isEqualToString:FRENCH_LOCALE])
        return french;
    return english;
}

// ======================================================================================================================================
// Return either 'en' or 'fr' based on device's current language. default is 'en'
+(NSString *)locale
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([language isEqualToString:FRENCH_LOCALE])
        return FRENCH_LOCALE;
    return ENGLISH_LOCALE;
}

// ======================================================================================================================================
// Add path to "do not backup" list
+ (BOOL)excludeFromBackupItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
    
#ifdef DEBUG
    if(!success)
    {
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
#endif
    
    return success;
}

// ======================================================================================================================================
// Add path to "do not backup" list
+ (BOOL)excludeFromBackupItemAtPath:(NSString *)path
{
    NSURL * url = [NSURL fileURLWithPath:path];
    return [self excludeFromBackupItemAtURL:url];
}

@end
