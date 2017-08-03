//
//  User+Utils.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-13.
//
//


#import "User+Utils.h"

@implementation User (Utils)

// set this objects fields with data from the specified UserAccount object
-(void) setDataFromModel:(UserAccount*) account
{
    self.email = account.email;
    self.userName = account.userName;
    self.userTypeId = account.userType;
    self.remoteId = account.databaseID;
    self.password = @"";
    self.backgroundColorCode = account.avatarBgColor;
}
@end
