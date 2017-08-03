//
//  Utilities.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Static utility functions
//

#import <Foundation/Foundation.h>

static NSString * const ENGLISH_LOCALE    = @"en";
static NSString * const FRENCH_LOCALE     = @"fr";

@interface Utilities : NSObject
+ (BOOL) isEmailValid: (NSString *) candidate;      // Validate Email string
+ (NSString*) sha1:(NSString*)input;                // Calculate sha1 string encoding
+ (NSString *) md5:(NSString *) input;              // Calculate md5 string encoding
+ (NSString*)base64forData:(NSData*)theData;        // NSData to Base64 string
+ (NSData *)base64DataFromString: (NSString *)string;   // String to Data
+ (NSString *) getAbsoluteFile:(NSString *)filePath; //get the absoluteFilePath, used in book and book page.

+ (NSString *)NSDateToJSONString:(NSDate *)date;
+ (BOOL)createZipFrom:(NSDictionary *)source targetURL:(NSString *)targetURL; //create zip file. can be multiple files.

+ (NSString*) localizedStringFromEnglish:(NSString *)english french:(NSString*)french;  // Determine what language the device is in and return corresponding input parameter.
+ (NSString*) locale;

+ (BOOL)excludeFromBackupItemAtPath:(NSString *)path;
+ (BOOL)excludeFromBackupItemAtURL:(NSURL *)URL;
@end
