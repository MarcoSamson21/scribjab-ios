//
//  BookSearchTag.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-04.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book;

@interface BookSearchTag : NSManagedObject

@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) Book *book;

@end
