//
//  UserType.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface UserType : BaseModel

@property (nonatomic, strong) NSNumber* databaseID;
@property (nonatomic, strong) NSString* name;

@end
