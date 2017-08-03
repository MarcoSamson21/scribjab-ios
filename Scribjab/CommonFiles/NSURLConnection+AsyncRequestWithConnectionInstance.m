//
//  NSURLConnection+AsyncRequestWithConnectionInstance.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURLConnection+AsyncRequestWithConnectionInstance.h"

@implementation NSURLConnection (AsyncRequestWithConnectionInstance)
-(void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))handler
{
    __block NSURLResponse *response = nil;
    __block NSError *error = nil;
    __block NSData *data = nil;
    
    // Wrap up synchronous request within a block operation
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        data = [NSURLConnection sendSynchronousRequest:request 
                                     returningResponse:&response 
                                                 error:&error];
    }];
    
    // Set completion block
    // EDIT: Set completion block, perform on main thread for safety
    blockOperation.completionBlock = ^{
        
        // Perform completion on main queue
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            handler(response, data, error);
        }];
    };
    
    // (or execute completion block on background thread)
    // blockOperation.completionBlock = ^{ handler(response, data, error); };
    
    // Execute operation
    [queue addOperation:blockOperation];
}

@end
