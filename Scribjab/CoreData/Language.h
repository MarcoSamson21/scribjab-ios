//
//  Language.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-04.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book;

@interface Language : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSString * nameEnglish;
@property (nonatomic, retain) NSString * nameFrench;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSSet *primaryBook;
@property (nonatomic, retain) NSSet *secondaryBook;
@end

@interface Language (CoreDataGeneratedAccessors)

- (void)addPrimaryBookObject:(Book *)value;
- (void)removePrimaryBookObject:(Book *)value;
- (void)addPrimaryBook:(NSSet *)values;
- (void)removePrimaryBook:(NSSet *)values;

- (void)addSecondaryBookObject:(Book *)value;
- (void)removeSecondaryBookObject:(Book *)value;
- (void)addSecondaryBook:(NSSet *)values;
- (void)removeSecondaryBook:(NSSet *)values;

@end
