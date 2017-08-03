//
//  UserAccount.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserAccount.h"

@implementation UserAccount
@synthesize databaseID = _databaseID;
@synthesize userName = _userName;
@synthesize password = _password;
@synthesize email = _email;
@synthesize avatar = _avatar;
@synthesize thumbnailAvatar = _thumbnailAvatar;
@synthesize accountNote = _accountNote;
@synthesize userType = _userType;
@synthesize isAdmin = _isAdmin;
@synthesize isDisabled = _isDisabled;
@synthesize isActivated = _isActivated;
@synthesize avatarBgColor = _avatarBgColor;
@synthesize name = _name;
@synthesize location = _location;

// ======================================================================================================================================
-(id) initWithDictionary:(NSDictionary *)data
{
    self = [super init];
    
    if (self)
    {
        _databaseID = [data objectForKey:@"id"];
        _userType = [data objectForKey:@"userTypeId"];
        _userName = [data objectForKey:@"userName"];
        _password = [data objectForKey:@"password"];
        _email = [data objectForKey:@"email"];
        _avatar = [data objectForKey:@"avatar"];
        _thumbnailAvatar = [data objectForKey:@"thumbnailAvatar"];
        _accountNote = [data objectForKey:@"accountNote"];
        _isAdmin = [[data objectForKey:@"admin"] boolValue];
        _isActivated = [[data objectForKey:@"activated"] boolValue];
        _isDisabled = [[data objectForKey:@"disabled"] boolValue];
        _avatarBgColor = [data objectForKey:@"avatarBgColor"];
        _name = nil;
        _location = nil;
        if ([data objectForKey:@"name"] != nil)
            _name = [data objectForKey:@"name"];
        if ([data objectForKey:@"location"])
            _location = [data objectForKey:@"location"];
    }
    return self;
}

// ======================================================================================================================================
// Get this object as JSON data 
-(NSData*) jsonRepresentation;
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:10];
    [data setObject:_databaseID forKey:@"id"];
    [data setObject:_userType forKey:@"userTypeId"];
    [data setObject:_userName forKey:@"userName"];
    [data setObject:_password forKey:@"password"];
    [data setObject:_email forKey:@"email"];
    [data setObject:_avatar forKey:@"avatar"];
    [data setObject:[NSNumber numberWithBool:_isAdmin] forKey:@"admin"];
    [data setObject:[NSNumber numberWithBool:_isActivated] forKey:@"activated"];
    [data setObject:[NSNumber numberWithBool:_isDisabled] forKey:@"disabled"];
    [data setObject:_accountNote forKey:@"accountNote"];
    [data setObject:_avatarBgColor forKey:@"avatarBgColor"];
    [data setObject:_name forKey:@"name"];
    [data setObject:_location forKey:@"location"];
        
    
    //NSJSONWritingPrettyPrinted use this option for a nicely-formatted json
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:NULL];
}
@end
