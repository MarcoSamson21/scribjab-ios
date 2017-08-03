//
//  ModifiedUserAccount.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-13.
//
//

#import "BaseModel.h"

@interface UpdateUserAccount : BaseModel
@property (nonatomic, strong) NSNumber* databaseID;
@property (nonatomic, strong) NSString* passwordNew;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* avatar;
@property (nonatomic, strong) NSString* currentPassword;
@property (nonatomic, strong) NSString* backgroundColorCode;
@end
