//
//  NSURLConnectionWithID.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnectionWithID : NSURLConnection
@property int identification;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately identification:(int)tag;
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate identification:(int)tag;
@end
