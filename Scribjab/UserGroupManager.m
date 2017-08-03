//
//  UserGroupManager.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-29.
//
//

#import "UserGroupManager.h"
#import "DocumentHandler.h"

@implementation UserGroupManager

// ======================================================================================================================================
+ (UserGroups *)getUserGroupByRemoteId:(int) remoteId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %@", [NSNumber numberWithInt:remoteId]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"UserGroups" predicate:predicate sortDescriptors:nil];
  
    UserGroups *userGroup = nil;
    
    if (objects != nil && [objects count] > 0)
        userGroup = [objects objectAtIndex:0];
    
    return userGroup;
}

// ======================================================================================================================================
// Add groups that don't exists in core data yet, update groups that do exist.
+ (void)addOrUpdateUserGroups:(NSArray *)userGroupList;
{
    for(NSDictionary *item in userGroupList)
    {
        if(item != nil)
        {
            UserGroups * grObj = [UserGroupManager getUserGroupByRemoteId:[[item objectForKey:@"id"] intValue]];
            
            if (grObj == nil)
            {
                grObj = [NSEntityDescription insertNewObjectForEntityForName:@"UserGroups" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
                [grObj.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:grObj] error:NULL];
                grObj.remoteId = [item objectForKey:@"id"];
            }
            
            grObj.name = [item objectForKey:@"name"];
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// check which of these groups already exist in core data and remove them from the list
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) groupIds
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"remoteId IN {%@}", [groupIds componentsJoinedByString:@","]]];
    NSArray * groups = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"UserGroups" predicate:predicate sortDescriptors:nil];
    
    NSMutableArray * newList = [NSMutableArray arrayWithArray:groupIds];
    
    for (UserGroups * gr in groups)
    {
        [newList removeObject:gr.remoteId];
    }
    
    return newList;
}

// ======================================================================================================================================
// Delete all user groups from CoreData (used by logout)
+ (void) deleteAllUserGroups
{
    NSArray * groups = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"UserGroups" predicate:nil sortDescriptors:nil];
    
    for (UserGroups * gr in groups)
    {
        [gr.managedObjectContext deleteObject:gr];
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
+ (NSArray *)getAllUserGroups
{
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"UserGroups" predicate:nil sortDescriptors:nil];
    return objects;
}
@end
