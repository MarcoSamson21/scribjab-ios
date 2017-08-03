//
//  User+Utils.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-13.
//
//

#import "User.h"
#import "UserAccount.h"

@interface User (Utils)
-(void) setDataFromModel:(UserAccount*) account;
@end
