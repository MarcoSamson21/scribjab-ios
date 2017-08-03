//
//  UserManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-30.
//
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface UserManager : NSObject
+ (User *)getUserByRemoteId:(int) remoteId;
+ (User *)getUserByUserName:(NSString*) userName;
+ (void)addOrUpdateUsersWithoutAvatar:(NSArray *)userList;
+ (User *)addOrUpdateUserWithoutAvatar:(NSDictionary *)userData;
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) userIds;    // check which of these users already exist in core data and remove them from the list
+ (BOOL) deleteUsersIfOrphan:(NSArray*) users;    // delete user if it has no connections to other objects in core data and if not logge-in
+ (NSString*) getAvatarAbsolutePathForUser:(User*) user thumbnailSize:(BOOL) thumbnail;
+ (NSString *) getUserStorageAbsolutePath;
+ (void) deleteUser:(User*)user saveContext:(BOOL)saveContext;

@end
