//
//  BaseModel.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseModel.h"

@implementation BaseModel

// ======================================================================================================================================
-(id) initWithDictionary:(NSDictionary *)data
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

// ======================================================================================================================================
-(NSData*) jsonRepresentation;
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end