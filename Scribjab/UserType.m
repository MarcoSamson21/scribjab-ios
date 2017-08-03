//
//  UserType.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserType.h"

@implementation UserType
@synthesize databaseID = _databaseID;
@synthesize name = _name;

// ======================================================================================================================================
-(id) initWithDictionary:(NSDictionary *)data
{
    self = [super init];
    
    if (self)
    {
        _databaseID = [data objectForKey:@"id"];
        _name = [data objectForKey:@"name"];
    }
    return self;
}

// ======================================================================================================================================
// Get this object as JSON data 
-(NSData*) jsonRepresentation;
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:2];
    [data setObject:_databaseID forKey:@"id"];
    [data setObject:_name forKey:@"name"];
        
    //NSJSONWritingPrettyPrinted use this option for a nicely-formatted json
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:NULL];
}

@end
