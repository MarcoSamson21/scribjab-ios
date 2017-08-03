//
//  UserAccount.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface UserAccount : BaseModel
@property (nonatomic, strong) NSNumber* databaseID;
@property (nonatomic, strong) NSString* userName;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* avatar;
@property (nonatomic, strong) NSString* thumbnailAvatar;
@property (nonatomic, strong) NSString* accountNote;
@property (nonatomic, strong) NSNumber* userType;
@property (nonatomic, strong) NSString* avatarBgColor;
@property (nonatomic) BOOL isAdmin;
@property (nonatomic) BOOL isActivated;
@property (nonatomic) BOOL isDisabled;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * location;

@end
