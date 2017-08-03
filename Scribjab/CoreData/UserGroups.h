//
//  UserGroups.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-18.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book;

@interface UserGroups : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSSet *books;
@end

@interface UserGroups (CoreDataGeneratedAccessors)

- (void)addBooksObject:(Book *)value;
- (void)removeBooksObject:(Book *)value;
- (void)addBooks:(NSSet *)values;
- (void)removeBooks:(NSSet *)values;

@end
