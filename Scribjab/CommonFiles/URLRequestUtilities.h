//
//  URLRequestUtilities.h
//  Scribjab
//
//  A set of methods to work with URLRequest's headers, cookies and tokens
//
//  Created by Oleg Titov on 12-09-13.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const REMEMBER_ME_COOKIE_NAME = @"SPRING_SECURITY_REMEMBER_ME_COOKIE";

@interface URLRequestUtilities : NSObject

// shortcut method for setting commonly-used headers
+ (void) setCommonOptionsToURLRequest:(NSMutableURLRequest *) request;    

// shortcut method for adding JSON data to request and setting required headers
+ (void) setJSONData:(NSData*) jsonData ToURLRequest:(NSMutableURLRequest *) request;       

// Return NSDictionary containing server responce data extracted from the specified httpResponce data, or show error message with using the specified parameters.
//+ (NSDictionary*) getResponseFromData:(NSData*)httpResponseData orShowErrorMessageWithDelegate:(id)delegate andTitle:(NSString*)title indicateIfError:(BOOL*)isError;

// Return NSDictionary containing server responce data extracted from the specified httpResponce data, or show error message with using the specified parameters.
// Authentication errors won't show.
+ (NSDictionary*) getResponseFromData:(NSData*)httpResponseData orShowErrorMessageWithDelegate:(id)delegate andTitle:(NSString*)title indicateIfError:(BOOL*)isError indicateIfAuthenticationError:(BOOL*)isAuthError;
@end
