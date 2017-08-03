//
//  BookThumbnailButton.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"
#import "DownloadManager.h"

// Custom even identifier
typedef NS_ENUM(NSInteger, BookThumbnailButtonEvent)
{
    BookThumbnailButtonEventNone=0,
    BookThumbnailButtonEventOpen=1,
    BookThumbnailButtonEventDelete=2
};


// class interface definition
@interface BookThumbnailButton : UIControl <DownloadManagerDelegate>

@property BOOL isDownloading;
@property BOOL canDelete;
@property (nonatomic, readonly) UIImageView * downloadIcon;
@property (nonatomic, readonly) Book* book;
@property (readonly) BookThumbnailButtonEvent lastEvent;
-(id) initWithBook:(Book*)book;

@end
