//
//  Comment.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-11.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book, User;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * flaggedByMe;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * likedByMe;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) User *author;
@property (nonatomic, retain) Book *book;
@property (nonatomic, retain) User *flaggedBy;
@property (nonatomic, retain) User *likedBy;

@end
