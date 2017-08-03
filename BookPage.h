//
//  BookPage.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-04.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Book;

@interface BookPage : NSManagedObject

@property (nonatomic, retain) NSString * backgroundColorCode;
@property (nonatomic, retain) NSNumber * remoteId;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSString * text1;
@property (nonatomic, retain) NSString * text2;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) Book *book;
@property (nonatomic, retain) NSNumber *videoCount;
@property (nonatomic, retain) NSData * videoPathArray;
@property (nonatomic, retain) UIColor * calligraphyColor;
@property (nonatomic, retain) UIColor * penColor;
@property (nonatomic, retain) NSNumber * penWidth;
@property (nonatomic, retain) NSNumber * calligraphyWidth;
@property (nonatomic, retain) UIColor * savedPenColor;
@property (nonatomic, retain) UIColor * savedCalligraphyColor;

@end
