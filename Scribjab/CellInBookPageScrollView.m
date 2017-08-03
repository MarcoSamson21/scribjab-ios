//
//  pageInCollectionView.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-03.
//
//

#import "CellInBookPageScrollView.h"
#import "Book.h"
#import "BookPage.h"
#import "BookManager.h"
#import "UIColor+HexString.h"

@interface CellInBookPageScrollView ()
{
    BOOL isBook;
    id currentBookItem;
}
- (void) setup;
@end

@implementation CellInBookPageScrollView
@synthesize bookViewController = _bookViewController;
@synthesize tagNumber = _tagNumber;

static int const IMG_X_START = 10;
static int const IMG_Y_START = 10;
static int const LABEL_HEIGHT = 20;

- (void)awakeFromNib
{
    [self setup]; // get initialized when we come out of a storyboard
}

- (id)getBookItem
{    return currentBookItem;
}

-(id)initWithFame:(CGRect)frame book:(id)book bookViewController:(BookViewController *)aBookViewController tag:(int)tagNum{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        for(UIView *subview in [self subviews])
        {
            [subview removeFromSuperview];
        }
        
        self.bookViewController = aBookViewController;
        self.tagNumber = tagNum;
//        self.pageNum = pageNum;
        currentBookItem = book;
//        NSLog(@"%@", book==nil?@"true":@"false");
        if([currentBookItem isKindOfClass:[Book class]])
            isBook = TRUE;
        else
            isBook = FALSE;
        
        
        [self setup]; // get initialized if someone uses alloc/initWithFrame: to create us
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) updateBookItem:(id)bookItem
{
    currentBookItem = bookItem;
    for(UIView *subview in [self subviews])
    {
        if([subview isKindOfClass:[UIImageView class]])
        {
            if([currentBookItem isKindOfClass:[Book class]])
            {
                Book * book = (Book *)currentBookItem;
                ((UIImageView *)subview).image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:book fileName:BOOK_THUMBNAIL_FILENAME]];
                ((UIImageView *)subview).backgroundColor = [UIColor colorWithHexString:book.backgroundColorCode];
            }
            if([currentBookItem isKindOfClass:[BookPage class]])
            {
                BookPage * bookPage = (BookPage *)currentBookItem;
                ((UIImageView *)subview).image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:bookPage fileName:BOOK_PAGE_THUMBNAIL_FILENAME]];
                ((UIImageView *)subview).backgroundColor = [UIColor colorWithHexString:bookPage.backgroundColorCode];
            }
        }
    }
}

- (void) updatePageNumber
{
    for(UIView *subview in [self subviews])
    {
        if([subview isKindOfClass:[UILabel class]])
        {
            if([currentBookItem isKindOfClass:[BookPage class]])
            {
                ((UILabel *)subview).text = [NSString stringWithFormat:@"%d", self.tag];
                self.tagNumber = self.tag;
//                BookPage * bookPage = (BookPage *)currentBookItem;
//                ((UIImageView *)subview).image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:bookPage fileName:BOOK_PAGE_THUMBNAIL_FILENAME]];
//                ((UIImageView *)subview).backgroundColor = [UIColor colorWithHexString:bookPage.backgroundColorCode];
            }
        }
    }

}

- (void) highlightItself
{
    
    if([currentBookItem isKindOfClass:[Book class]])
    {
//            self.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"create_ptitle_bg.png"]];
//        self.backgroundColor = highlight? [UIColor paleYellowColor] : [UIColor whitecolor];
        self.backgroundColor = [UIColor colorWithRed:255/255.0f green:50/255.0f blue:36/255.0f alpha:0.5];
        
    }
    if([currentBookItem isKindOfClass:[BookPage class]])
    {
//        self.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"create_page_bg.png"]];
        self.backgroundColor = [UIColor colorWithRed:255/255.0f green:50/255.0f blue:36/255.0f alpha:0.5];
    }
    
    for(UIView *subview in [self subviews])
    {
        if([subview isKindOfClass:[UIImageView class]])
        {
            ((UIImageView *)subview).layer.borderColor = [UIColor grayColor].CGColor;
            ((UIImageView *)subview).layer.borderWidth = 1;
        }
    }
}

- (void) unHighlightIteself
{
    self.backgroundColor = [UIColor clearColor];

    for(UIView *subview in [self subviews])
    {
        if([subview isKindOfClass:[UIImageView class]])
        {
            ((UIImageView *)subview).layer.borderColor = [UIColor clearColor].CGColor;
            ((UIImageView *)subview).layer.borderWidth = 0;
        }
    }
}

- (void) setup{
    //set self properties.
    self.contentMode = UIViewContentModeRedraw; // if our bounds changes, redraw ourselves
    self.backgroundColor = [UIColor clearColor];
//    self.layer.borderColor = (__bridge CGColorRef)([UIColor blackColor]);
//    self.layer.borderWidth = 2;
    if(self.tagNumber == TITLE_PAGE_VIEW_TAG) //title page.
        self.frame = CGRectMake(0, 0, TITLE_PAGE_IMG_VIEW_FRAME_WIDTH+IMG_VIEW_SPACE, self.bounds.size.height);
     else
    {
        int wi = TITLE_PAGE_IMG_VIEW_FRAME_WIDTH+IMG_VIEW_SPACE + (self.tagNumber -1) * (PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE);
        self.frame = CGRectMake(wi, 0, PAGE_IMG_VIEW_FRAME_WIDTH+IMG_VIEW_SPACE, self.bounds.size.height);
    }

    NSString *thumbnailPath=nil;
    //NSLog(@"%d, %d, %d, %d", imgLabelX, imgLabelY, imgLabelframeWidth, imgLabelframeHeight );
    UILabel *title1Label = [[UILabel alloc] init];
    if(isBook)
        title1Label.frame= CGRectMake(IMG_X_START, IMG_Y_START+IMG_VIEW_FRAME_HEIGHT, TITLE_PAGE_IMG_VIEW_FRAME_WIDTH,LABEL_HEIGHT);
    else
        title1Label.frame= CGRectMake(IMG_X_START, IMG_Y_START+IMG_VIEW_FRAME_HEIGHT, PAGE_IMG_VIEW_FRAME_WIDTH,LABEL_HEIGHT);
    title1Label.backgroundColor = [UIColor clearColor];
    title1Label.textAlignment = UITextAlignmentCenter;
    title1Label.textColor = [UIColor whiteColor];

    //create 1 imageViews for the front page/page thumbnail.
    //for frontpage:
    if(isBook)
    {
        Book *book = (Book *)currentBookItem;
        thumbnailPath = [BookManager getBookItemAbsPath:book fileName:BOOK_THUMBNAIL_FILENAME];

        UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
        imgView.backgroundColor = [UIColor colorWithHexString:book.backgroundColorCode];
        imgView.frame = CGRectMake(IMG_X_START, IMG_Y_START, TITLE_PAGE_IMG_VIEW_FRAME_WIDTH, IMG_VIEW_FRAME_HEIGHT);
        imgView.userInteractionEnabled = YES;
        imgView.tag = self.tagNumber;
        imgView.layer.cornerRadius = 9.0;
        imgView.layer.masksToBounds = YES;
//        imgView.layer.borderColor = (__bridge CGColorRef)([UIColor blackColor]);
//        imgView.layer.borderWidth = 2;

//        imgView.layer.borderColor
        
        
        UITapGestureRecognizer *pgr = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleTapGestureForImageView:)];
        
        [imgView addGestureRecognizer:pgr];
        
        [self addSubview:imgView];

        UILabel *pageLabel = [[UILabel alloc] init];
        pageLabel.frame= CGRectMake(IMG_X_START+5, IMG_Y_START, 80,20);
        pageLabel.backgroundColor = [UIColor clearColor];
        pageLabel.textAlignment = UITextAlignmentLeft;
        pageLabel.textColor = [UIColor blackColor];
        pageLabel.shadowColor = [UIColor colorWithWhite:1 alpha:1];
        pageLabel.shadowOffset = CGSizeMake(1,1);
        //        pageLabel.layer.cornerRadius = 9.0;
        //        pageLabel.alpha = 0.7;
        //        pageLabel.layer.masksToBounds = YES;
        pageLabel.text = NSLocalizedString(@"Cover",@"Cover Page of a book");
        pageLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
        //        NSLog(@"page:%f, %d" , self.frame.origin.x,self.tagNumber);
        [self addSubview:pageLabel];

        
         //label
        if(book.title1)
        {
            title1Label.text = book.title1;
        }
    }
    else
    {
        BookPage *bookPage = (BookPage *)currentBookItem;
        thumbnailPath = [BookManager getBookItemAbsPath:bookPage fileName:BOOK_PAGE_THUMBNAIL_FILENAME];
        title1Label.text = @"";
        UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
        imgView.backgroundColor = [UIColor colorWithHexString:bookPage.backgroundColorCode];
        imgView.frame = CGRectMake(IMG_X_START, IMG_Y_START, PAGE_IMG_VIEW_FRAME_WIDTH, IMG_VIEW_FRAME_HEIGHT);
        
        imgView.userInteractionEnabled = YES;
        imgView.layer.cornerRadius = 9.0;
        imgView.layer.masksToBounds = YES;
        imgView.tag = self.tagNumber;

        UITapGestureRecognizer *pgr = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handleTapGestureForImageView:)];
        [imgView addGestureRecognizer:pgr];
        
        [self addSubview:imgView];

        //create delete page button.
        UIButton *deletePageButton = [[UIButton alloc]init];
        deletePageButton.frame = CGRectMake(self.frame.size.width - 35,0, 38,37);
        [deletePageButton setBackgroundImage:[UIImage imageNamed:@"library_close.png"] forState:UIControlStateNormal];
        
        deletePageButton.titleLabel.text = @"";
        [deletePageButton addTarget:self action:@selector(deletePage:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:deletePageButton];
        
        UILabel *pageLabel = [[UILabel alloc] init];
        pageLabel.frame= CGRectMake(IMG_X_START, IMG_Y_START, 20,20);
        pageLabel.backgroundColor = [UIColor clearColor];
        pageLabel.textAlignment = UITextAlignmentCenter;
        pageLabel.textColor = [UIColor blackColor];
        pageLabel.shadowColor = [UIColor colorWithWhite:1 alpha:1];
        pageLabel.shadowOffset = CGSizeMake(1,1);
        pageLabel.text = [NSString stringWithFormat:@"%d", self.tagNumber];
        pageLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
//        NSLog(@"page:%f, %d" , self.frame.origin.x,self.tagNumber);
        [self addSubview:pageLabel];

    }
    [self addSubview:title1Label];
    [title1Label setHidden:YES];//not show for now.
}

- (void)deletePage:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self.bookViewController
                                   selector:@selector(deletePage:)
                                   userInfo:currentBookItem
                                    repeats:NO];
}

- (void)handleTapGestureForImageView:(UITapGestureRecognizer *)gestureRecognizer
{
    UIImageView * tapView = (UIImageView *)gestureRecognizer.view;
    if(tapView.tag == -1)
    {
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self.bookViewController
                                       selector:@selector(goToCreatePage:)
                                       userInfo:[NSNumber numberWithInt:tapView.tag]
                                        repeats:NO];
        
    }
    else
    {
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self.bookViewController
                                       selector:@selector(displayPage:)
                                       userInfo:currentBookItem
                                        repeats:NO];
    }
}
@end
