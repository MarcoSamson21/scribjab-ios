//
//  CommentManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-11.
//
//

#import <Foundation/Foundation.h>
#import "Comment.h"
#import "Book.h"
#import "User.h"

@interface CommentManager : NSObject
+ (Comment *) getCommentByRemoteId:(int) remoteId;
+ (Comment *) addOrUpdateCommentWithData:(NSDictionary *)commentData user:(User *)user book:(Book*)book;
+ (Comment *) addOrUpdateCommentWithData:(NSDictionary *)commentData user:(User *)user;
+ (void) likeCommentsInTheList:(NSArray*)commentRemoteIds byUser:(User*)user;
+ (void) flagCommentsInTheList:(NSArray*)commentRemoteIds byUser:(User*)user;
+ (void) deleteFlaggedCommentByRemoteId:(NSNumber*)remoteId flagCount:(NSNumber *) flagCount;
@end
