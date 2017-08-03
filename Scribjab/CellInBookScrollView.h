//
//  CellInBookScrollView.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-09.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Book.h"
#import "DownloadManager.h"

static int const IMG_VIEW_FRAME_WIDTH = 180;
static int const IMG_VIEW_FRAME_HEIGHT = 200;
static int const IMG_VIEW_RIGHT_SPACE = 20;

@class MyLibraryViewController;
@interface CellInBookScrollView : UIView <DownloadManagerDelegate>
@property BOOL isDownloading;

- (void) handleTapGestureForImageView:(UITapGestureRecognizer *)sender;
- (id) initWithFame:(CGRect)frame book:(id)book myLibraryViewController:(MyLibraryViewController *)aMyLibraryViewController tagNum:(int)tagNum canDelete:(BOOL)canDelete;
- (Book *) getCurrentBook;
- (void) changeDownloadToReadButton;
@end