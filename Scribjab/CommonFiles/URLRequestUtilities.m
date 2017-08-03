//
//  URLRequestUtilities.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-13.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "URLRequestUtilities.h"
#import "Globals.h"
#import "CommonMessageBoxes.h"

@implementation URLRequestUtilities


// ======================================================================================================================================
// shortcut method for setting commonly-used headers to the request that will communicate with the web server
+ (void) setCommonOptionsToURLRequest:(NSMutableURLRequest *) request
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setValue:REQUEST_HEADER_VALUE_IPAD_ID forHTTPHeaderField:REQUEST_HEADER_NAME_IPAD_ID];
    [request setValue:language forHTTPHeaderField:@"Accept-Language"];
}

// ======================================================================================================================================
// shortcut method for adding JSON data to request and setting required headers.
// Note: call to setCommonOptionsToURLRequest: method is not required, as this method make that call for you
+ (void) setJSONData:(NSData*) jsonData ToURLRequest:(NSMutableURLRequest *) request
{
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [jsonData length]] forHTTPHeaderField:@"Content-Length"];
}

// ======================================================================================================================================
// Return NSDictionary containing server responce data extracted from the specified httpResponce data, or show error message with using the specified parameters.
// Returns NSDictionary with data, or nil if the server returned no data or if there was an error extracting it. You can check if there was an error by
// 'isError' parameter
/*+ (NSDictionary*) getResponseFromData:(NSData*)httpResponseData orShowErrorMessageWithDelegate:(id)delegate andTitle:(NSString*)title indicateIfError:(BOOL*)isError
{
    if (isError != NULL)
        *isError = YES;

    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];

    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return nil;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorBody = @"UNKNOWN ERROR";
        
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            errorBody = [errArr componentsJoinedByString:@"\n"];
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:errorBody delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return nil;
    }
    
    if (isError != NULL)
        *isError = NO;
    
    return responseDictionary;
}*/

// Return NSDictionary containing server responce data extracted from the specified httpResponce data, or show error message with using the specified parameters.
// Authentication errors won't show.
+ (NSDictionary*) getResponseFromData:(NSData*)httpResponseData orShowErrorMessageWithDelegate:(id)delegate andTitle:(NSString*)title indicateIfError:(BOOL*)isError indicateIfAuthenticationError:(BOOL*)isAuthError
{
    if (isError != NULL)
        *isError = YES;
    if (isAuthError != NULL)
        *isAuthError = NO;
    
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];
    
    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return nil;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorBody = @"UNKNOWN ERROR";
        
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            errorBody = [errArr componentsJoinedByString:@"\n"];
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
        }
        
        // Authentication Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_AUTH_FAIL])
        {
            if (isAuthError != NULL)
                *isAuthError = YES;
            return nil;
        }
        
        // Show error message in the main thread, to avoid threading issues.
     //   dispatch_async(dispatch_get_main_queue(),
     //   ^{
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:errorBody delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
            [alert show];
            
       // });
        
        return nil;
    }
    
    if (isError != NULL)
        *isError = NO;
    
    return responseDictionary;
}
@end
