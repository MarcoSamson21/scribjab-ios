//
//  NSURLConnectionWithID.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURLConnectionWithID.h"

@implementation NSURLConnectionWithID
@synthesize identification;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately identification:(int)tag
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
     
    if (self) 
    {
        self.identification = tag;
    }
    	 
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate identification:(int)tag
{
    self = [super initWithRequest:request delegate:delegate];
    if (self) 
    {
        self.identification = tag;
    }
    
    return self;
}
@end
