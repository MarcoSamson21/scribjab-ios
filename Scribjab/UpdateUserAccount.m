//
//  ModifiedUserAccount.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-13.
//
//

#import "UpdateUserAccount.h"

@implementation UpdateUserAccount
@synthesize passwordNew;
@synthesize databaseID;
@synthesize email;
@synthesize avatar;
@synthesize currentPassword;
@synthesize backgroundColorCode;

// ======================================================================================================================================
// Get this object as JSON data
-(NSData*) jsonRepresentation;
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:6];
    [data setObject:self.databaseID forKey:@"id"];
    [data setObject:self.passwordNew forKey:@"password"];
    [data setObject:self.email forKey:@"email"];
    [data setObject:self.avatar forKey:@"avatar"];
    [data setObject:self.currentPassword forKey:@"currentPassword"];
    [data setObject:self.backgroundColorCode forKey:@"avatarBgColor"];

    //NSJSONWritingPrettyPrinted use this option for a nicely-formatted json
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:NULL];
}
@end
