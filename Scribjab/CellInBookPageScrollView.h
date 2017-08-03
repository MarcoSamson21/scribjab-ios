//
//  pageInCollectionView.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-03.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

static int const TITLE_PAGE_IMG_VIEW_FRAME_WIDTH=90;
static int const PAGE_IMG_VIEW_FRAME_WIDTH=158;
static int const IMG_VIEW_FRAME_HEIGHT = 100;
static int const IMG_VIEW_SPACE = 20;
static int const TITLE_PAGE_VIEW_TAG =0;
static int const FIRST_PAGE_VIEW_TAG =1;


@class BookViewController;
@interface CellInBookPageScrollView : UIView{
    BookViewController *bookViewController;
}

@property (nonatomic, assign) BookViewController *bookViewController;
@property int tagNumber;

- (void)handleTapGestureForImageView:(UITapGestureRecognizer *)sender;
- (id)getBookItem;
-(id)initWithFame:(CGRect)frame book:(id)book bookViewController:(BookViewController *)aBookViewController tag:(int)tagNum;

- (void) updateBookItem:(id)bookItem;
- (void) updatePageNumber;
- (void) highlightItself;
- (void) unHighlightIteself;
@end