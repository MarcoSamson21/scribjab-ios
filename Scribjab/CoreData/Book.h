//
//  Book.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-21.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BookPage, BookSearchTag, BookTypes, Comment, Language, User, UserGroups;

@interface Book : NSManagedObject

@property (nonatomic, retain) NSNumber * ageGroupRemoteId;
@property (nonatomic, retain) NSNumber * approvalStatus;
@property (nonatomic, retain) NSString * backgroundColorCode;
@property (nonatomic, retain) NSNumber * bookSizeKB;
@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * description1;
@property (nonatomic, retain) NSString * description2;
@property (nonatomic, retain) NSNumber * isDownloaded;
@property (nonatomic, retain) NSNumber * isHidden;
@property (nonatomic, retain) NSNumber * isPublished;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSString * rejectionComment;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSString * tagSummary;
@property (nonatomic, retain) NSString * title1;
@property (nonatomic, retain) NSString * title2;
@property (nonatomic, retain) NSDate * updateTimeStamp;
@property (nonatomic, retain) NSDate * downloadDate;
@property (nonatomic, retain) User *author;
@property (nonatomic, retain) NSSet *bookTypes;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) User *flaggedBy;
@property (nonatomic, retain) User *likedBy;
@property (nonatomic, retain) NSOrderedSet *pages;
@property (nonatomic, retain) Language *primaryLanguage;
@property (nonatomic, retain) Language *secondaryLanguage;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) UserGroups *userGroup;

@property (nonatomic, retain) UIColor * calligraphyColor;
@property (nonatomic, retain) UIColor * penColor;
@property (nonatomic, retain) NSNumber * penWidth;
@property (nonatomic, retain) NSNumber * calligraphyWidth;
@property (nonatomic, retain) UIColor * savedPenColor;
@property (nonatomic, retain) UIColor * savedCalligraphyColor;
@end

@interface Book (CoreDataGeneratedAccessors)

- (void)addBookTypesObject:(BookTypes *)value;
- (void)removeBookTypesObject:(BookTypes *)value;
- (void)addBookTypes:(NSSet *)values;
- (void)removeBookTypes:(NSSet *)values;

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)insertObject:(BookPage *)value inPagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPagesAtIndex:(NSUInteger)idx;
- (void)insertPages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPagesAtIndex:(NSUInteger)idx withObject:(BookPage *)value;
- (void)replacePagesAtIndexes:(NSIndexSet *)indexes withPages:(NSArray *)values;
- (void)addPagesObject:(BookPage *)value;
- (void)removePagesObject:(BookPage *)value;
- (void)addPages:(NSOrderedSet *)values;
- (void)removePages:(NSOrderedSet *)values;
- (void)addTagsObject:(BookSearchTag *)value;
- (void)removeTagsObject:(BookSearchTag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
