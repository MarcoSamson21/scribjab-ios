//
//  NSURLConnection+AsyncRequestWithConnectionInstance.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (AsyncRequestWithConnectionInstance)
-(void)sendAsynchronousRequest:(NSURLRequest*)request queue:(NSOperationQueue*)queue completionHandler:(void(^)(NSURLResponse *response, NSData *data, NSError *error))handler;
@end
