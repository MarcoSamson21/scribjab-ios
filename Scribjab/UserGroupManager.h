//
//  UserGroupManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-29.
//
//

#import <Foundation/Foundation.h>
#import "UserGroups.h"

@interface UserGroupManager : NSObject
+ (UserGroups *)getUserGroupByRemoteId:(int) remoteId;
+ (NSArray *)getAllUserGroups;
+ (void)addOrUpdateUserGroups:(NSArray *)userGroupList;
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) userIds;    // check which of these groups already exist in core data and remove them from the list
+ (void) deleteAllUserGroups;
@end
