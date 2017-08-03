//
//  CommentManager.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-11.
//
//

#import "CommentManager.h"
#import "DocumentHandler.h"
#import "BookManager.h"

@implementation CommentManager

#pragma-mark Static Methods

// ======================================================================================================================================
// this function will update changes to the core data or add a new comment, if one doesn't exist.
// Params: user - comment author, book - book for which comment is updated
+ (Comment *)addOrUpdateCommentWithData:(NSDictionary *)commentData user:(User *)user book:(Book*)book;
{
   
    if(commentData == nil || user == nil || book == nil)
        return nil;

    Comment * comm = [CommentManager getCommentByRemoteId:[[commentData objectForKey:@"id"] intValue]];
    
    if (comm == nil)
    {
        comm = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
        [comm.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:comm] error:NULL];

        comm.comment = [commentData objectForKey:@"comment"];
        
        NSNumber * interval = [commentData objectForKey:@"date"];
        comm.date           = [NSDate dateWithTimeIntervalSince1970:[interval doubleValue] / 1000L];    // date form java time stamp
        comm.remoteId       = [commentData objectForKey:@"id"];
        comm.author         = user;
        comm.book           = book;
    }
    
    comm.likeCount = [commentData objectForKey:@"likeCount"];
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    return comm;
}

// ======================================================================================================================================
// this function will update changes to the core data or add a new comment, if one doesn't exist.
// Params: user - comment author, commentData - server data for a comment
+ (Comment *)addOrUpdateCommentWithData:(NSDictionary *)commentData user:(User *)user;
{
    
    if(commentData == nil || user == nil)
        return nil;
    
    Comment * comm = [CommentManager getCommentByRemoteId:[[commentData objectForKey:@"id"] intValue]];
    Book * book = [BookManager getBookByRemoteId:[[commentData objectForKey:@"bookId"] intValue]];
    
    if (book == nil || !book.isDownloaded.boolValue)
        return nil;
    
    if (comm == nil)
    {
        comm = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
        [comm.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:comm] error:NULL];
        
        comm.comment = [commentData objectForKey:@"comment"];
        
        NSNumber * interval = [commentData objectForKey:@"date"];
        comm.date           = [NSDate dateWithTimeIntervalSince1970:[interval doubleValue] / 1000L];    // date form java time stamp
        comm.remoteId       = [commentData objectForKey:@"id"];
        comm.author         = user;
        comm.book           = book;
    }

    comm.likeCount = [commentData objectForKey:@"likeCount"];
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    return comm;
}

// ======================================================================================================================================
+ (Comment *)getCommentByRemoteId:(int) remoteId;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %@", [NSNumber numberWithInt:remoteId]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Comment" predicate:predicate sortDescriptors:nil];
    
    Comment * comm = nil;
    
    if (objects != nil && [objects count] > 0)
        comm = [objects objectAtIndex:0];
    
    return comm;
}

// ======================================================================================================================================
// save that specified user liked comments specified by the list id remote comment IDs
+ (void) likeCommentsInTheList:(NSArray*)commentRemoteIds byUser:(User*)user
{
    if (user == nil || !user.isLoggedIn.boolValue)
        return;
    
    for (NSNumber * remoteId in commentRemoteIds)
    {
        Comment * comment = [CommentManager getCommentByRemoteId:remoteId.intValue];
        if (comment != nil)
        {
            comment.likedBy = user;
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}
// ======================================================================================================================================
// flag comments specified by the remote ids in the list
+ (void) flagCommentsInTheList:(NSArray*)commentRemoteIds byUser:(User*)user
{
    if (user == nil || !user.isLoggedIn.boolValue)
        return;
    
    for (NSNumber * remoteId in commentRemoteIds)
    {
        Comment * comment = [CommentManager getCommentByRemoteId:remoteId.intValue];
        if (comment != nil)
        {
            comment.flaggedBy = user;
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Delete specified comment (if exists) form core data if flag count is greateer or equial the count threashold. 
+ (void) deleteFlaggedCommentByRemoteId:(NSNumber*)remoteId flagCount:(NSNumber *) flagCount
{
    int FLAG_COUNT_THRESHOLD = 3;
    
    if (flagCount.intValue < FLAG_COUNT_THRESHOLD)
        return;
    
    Comment * comment = [CommentManager getCommentByRemoteId:remoteId.intValue];
    
    if (comment != nil)
    {
        [[DocumentHandler sharedDocumentHandler] deleteAndWaitContextForNSManagedObject:comment];
    }
}


@end
