//
//  UserManager.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-30.
//
//

#import "UserManager.h"
#import "DocumentHandler.h"
#import "Utilities.h"

@implementation UserManager

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
// STATIC METHODS
#pragma-mark Static Methods

// ======================================================================================================================================
// this function will update changes to the core data or add a new user, if one doesn't exist.
// No avatar images are added.
+ (void)addOrUpdateUsersWithoutAvatar:(NSArray *)userList;
{
    for(NSDictionary *item in userList)
    {
        if(item == nil)
            continue;

        User * user = [UserManager getUserByRemoteId:[[item objectForKey:@"id"] intValue]];
        
        if (user == nil)
        {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
            [user.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:user] error:NULL];
            user.isLoggedIn = [NSNumber numberWithBool:NO];
        }
       
        user.backgroundColorCode = [item objectForKey:@"avatarBgColor"];
        user.email = [item objectForKey:@"email"];
        user.password = @"";
        user.remoteId = [item objectForKey:@"id"];
        user.userName = [item objectForKey:@"userName"];
        user.userTypeId = [item objectForKey:@"userTypeId"];
        
        // Get thumbnail image
        NSData * thumb = [Utilities base64DataFromString:[item objectForKey:@"thumbnailAvatar"]];
        if (thumb.length > 0)
        {
            NSString * path = [UserManager getAvatarAbsolutePathForUser:user thumbnailSize:YES];
            [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            [thumb writeToFile:path atomically:NO];
        }
    }

    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Update changes to the core data or add a new user, if one doesn't exist.
// No avatar images are added.
+ (User *)addOrUpdateUserWithoutAvatar:(NSDictionary *)userData
{
    if (userData == nil)
        return nil;
    
    User * user = [UserManager getUserByRemoteId:[[userData objectForKey:@"id"] intValue]];
    
    if (user == nil)
    {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
        [user.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:user] error:NULL];
        user.isLoggedIn = [NSNumber numberWithBool:NO];
    }
    
    user.backgroundColorCode = [userData objectForKey:@"avatarBgColor"];
    user.email = [userData objectForKey:@"email"];
    user.password = @"";
    user.remoteId = [userData objectForKey:@"id"];
    user.userName = [userData objectForKey:@"userName"];
    user.userTypeId = [userData objectForKey:@"userTypeId"];
    
    // Get thumbnail image
    NSData * thumb = [Utilities base64DataFromString:[userData objectForKey:@"thumbnailAvatar"]];
    if (thumb.length > 0)
    {
        NSString * path = [UserManager getAvatarAbsolutePathForUser:user thumbnailSize:YES];
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        [thumb writeToFile:path atomically:NO];
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    return user;
}

// ======================================================================================================================================
+ (User *)getUserByRemoteId:(int) remoteId
{
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:[@"remoteId = " stringByAppendingString:[NSString stringWithFormat:@"%d", remoteId]]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %@", [NSNumber numberWithInt:remoteId]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];
    
    User * user = nil;
    
    if (objects != nil && [objects count] > 0)
        user = [objects objectAtIndex:0];

    return user;
}

// ======================================================================================================================================
+ (User *)getUserByUserName:(NSString*) userName
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userName = %@", userName];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];
    
    User * user = nil;
    
    if (objects != nil && [objects count] > 0)
        user = [objects objectAtIndex:0];
    
    return user;
}

// ======================================================================================================================================
// Find out which of the specified users already exist in core data and return only IDs of the missing records
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) userIds
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"remoteId IN {%@}", [userIds componentsJoinedByString:@","]]];
    NSArray * users = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];
    
    NSMutableArray * newList = [NSMutableArray arrayWithArray:userIds];
    
    for (User * user in users)
    {
        [newList removeObject:user.remoteId];
    }
    return newList;
}

// ======================================================================================================================================
// delete user if it has no connections to other objects in core data and if not logge-in
+ (BOOL) deleteUsersIfOrphan:(NSArray *) users
{
    BOOL retVal = NO;
    
    for (id item in users)
    {
        if (![item isKindOfClass:[User class]])
            continue;

        User * user = (User *) item;
        
        // delete user?
        if (!user.isLoggedIn.boolValue && [user.book count] == 0 && [user.comment count] == 0)
        {
            [UserManager deleteUser:user saveContext:NO];
            retVal = YES;
        }
    }
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    return retVal;
}

// ===========================================================================================================================================
// returns absolute path for avatar or avatar thumbnail file, based on user ID
+(NSString*) getAvatarAbsolutePathForUser:(User*) user thumbnailSize:(BOOL) thumbnail
{
    NSString * objectId = [[user.objectID URIRepresentation] lastPathComponent];
    
    if (thumbnail)
    {
        return [NSString stringWithFormat:@"%@%@/%@.png", [self getUserStorageAbsolutePath], objectId, @"thumb"];
    }
    
    return [NSString stringWithFormat:@"%@%@/%@.png", [self getUserStorageAbsolutePath], objectId, @"avatar"];
}

// ======================================================================================================================================
// Get the directory path of where users' images will be saved
// i.e., return /<DocumentDirectory>/users/
+ (NSString *) getUserStorageAbsolutePath
{
    return [Utilities getAbsoluteFile:@"users/"];
}

// ===========================================================================================================================================
// delete the specified user from CoreDate and all of the user's files (like avatars).
// If saveContext is set to NO, caller has to save context manually.
// NOTE: user files will be deleted regardless of saveContext parameter value.
+ (void) deleteUser:(User*)user saveContext:(BOOL)saveContext
{
    if (user == nil)
        return;
    
    // Delete user's file directory
    NSString * path = [UserManager getAvatarAbsolutePathForUser:user thumbnailSize:NO];
    NSURL *dirURL = [NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil])
    {
        // delete everything in the directory.
        [[NSFileManager defaultManager] removeItemAtURL:dirURL error:nil];
    }
    
    // delete user
    [user.managedObjectContext deleteObject:user];
    
    // commit changes
    if (saveContext)
        [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}
@end
