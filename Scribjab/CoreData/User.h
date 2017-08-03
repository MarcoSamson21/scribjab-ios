//
//  User.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-11.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book, Comment;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * backgroundColorCode;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * isLoggedIn;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSNumber * userTypeId;
@property (nonatomic, retain) NSOrderedSet *book;
@property (nonatomic, retain) NSSet *comment;
@property (nonatomic, retain) NSSet *flaggedBooks;
@property (nonatomic, retain) NSSet *flaggedComments;
@property (nonatomic, retain) NSSet *likedBooks;
@property (nonatomic, retain) NSSet *likedComments;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addBookObject:(Book *)value;
- (void)removeBookObject:(Book *)value;
- (void)addBook:(NSOrderedSet *)values;
- (void)removeBook:(NSOrderedSet *)values;

- (void)addCommentObject:(Comment *)value;
- (void)removeCommentObject:(Comment *)value;
- (void)addComment:(NSSet *)values;
- (void)removeComment:(NSSet *)values;

- (void)addFlaggedBooksObject:(Book *)value;
- (void)removeFlaggedBooksObject:(Book *)value;
- (void)addFlaggedBooks:(NSSet *)values;
- (void)removeFlaggedBooks:(NSSet *)values;

- (void)addFlaggedCommentsObject:(Comment *)value;
- (void)removeFlaggedCommentsObject:(Comment *)value;
- (void)addFlaggedComments:(NSSet *)values;
- (void)removeFlaggedComments:(NSSet *)values;

- (void)addLikedBooksObject:(Book *)value;
- (void)removeLikedBooksObject:(Book *)value;
- (void)addLikedBooks:(NSSet *)values;
- (void)removeLikedBooks:(NSSet *)values;

- (void)addLikedCommentsObject:(Comment *)value;
- (void)removeLikedCommentsObject:(Comment *)value;
- (void)addLikedComments:(NSSet *)values;
- (void)removeLikedComments:(NSSet *)values;

@end
