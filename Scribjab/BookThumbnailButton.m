//
//  BookThumbnailButton.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import "BookThumbnailButton.h"
#import <QuartzCore/QuartzCore.h>
#import "BookManager.h"
#import "Language+Utils.h"
#import "UIColor+HexString.h"

#define BOOK_IMAGE_VIEW_START_X 5
#define BOOK_IMAGE_VIEW_START_Y 5
#define WHITE_SPACE 5
#define WHITE_SPACE_START_Y 3
#define WHITE_SPACE_START_X 0
#define LABEL_HEIGHT 20
#define LANGUAGE_LABEL_HEIGHT 25

#define IMG_VIEW_FRAME_WIDTH 180
#define IMG_VIEW_FRAME_HEIGHT 200
#define IMG_VIEW_RIGHT_SPACE 0

@interface BookThumbnailButton ()
{
    UIProgressView * _downloadProgressBar;
    UIButton * _deleteBookButton;
    UIImageView * _downloadImageView;
}
-(void) initializeButton;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation BookThumbnailButton

@synthesize lastEvent = _lastEvent;
@synthesize book = _book;
@synthesize isDownloading = _isDownloading;
@synthesize canDelete = _canDelete;
@synthesize downloadIcon = _downloadImageView;

-(BOOL)isDownloading
{
    return _isDownloading;
}
- (void)setIsDownloading:(BOOL)isDownloading
{
    if (_isDownloading != isDownloading)
    {
        _isDownloading = isDownloading;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    if (isDownloading)
    {
        [_downloadProgressBar setHidden:NO];
        [_downloadProgressBar setProgress:0.0F];
    }
    else
        [_downloadProgressBar setHidden:YES];
}
// ======================================================================================================================================
-(void)setCanDelete:(BOOL)canDelete
{
    _canDelete = canDelete;
    [_deleteBookButton setHidden:!_canDelete];
}
-(BOOL)canDelete
{
    return _canDelete;
}

// ======================================================================================================================================
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// ======================================================================================================================================
-(id)initWithBook:(Book *)book
{
    self = [super init];
    
    if (self)
    {
        _book = book;
        self.backgroundColor = [UIColor clearColor];
        
        int totalWidth = WHITE_SPACE + IMG_VIEW_FRAME_WIDTH + WHITE_SPACE + IMG_VIEW_RIGHT_SPACE;
        int totalHeight = WHITE_SPACE + IMG_VIEW_FRAME_HEIGHT + LABEL_HEIGHT + LABEL_HEIGHT;
        self.frame = CGRectMake(0.0F, 0.0F, totalWidth, totalHeight);
        
        [self initializeButton];
    }
    return self;
}

// ======================================================================================================================================
-(void) initializeButton
{
    _lastEvent = BookThumbnailButtonEventNone;
    self.contentMode = UIViewContentModeRedraw; // if our bounds changes, redraw ourselves
    self.backgroundColor = [UIColor clearColor];
    
    //add a white color background view.
    UIView * whiteBGView = [[UIView alloc] initWithFrame:CGRectMake(WHITE_SPACE_START_X, WHITE_SPACE_START_Y, WHITE_SPACE + IMG_VIEW_FRAME_WIDTH + WHITE_SPACE, WHITE_SPACE + IMG_VIEW_FRAME_HEIGHT + LABEL_HEIGHT + LABEL_HEIGHT )];
    whiteBGView.backgroundColor = [UIColor whiteColor];
  
    whiteBGView.layer.cornerRadius = 9.0;
    whiteBGView.layer.masksToBounds = YES;
    
    [self addSubview:whiteBGView];
    
    // create 1 imageViews for the book thumbnail.
    //    Book *book = (Book *)currentBook;
    // add image view.
    UIImage * thumb = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:_book fileName:BOOK_THUMBNAIL_FILENAME]];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:thumb];
    
    imgView.frame = CGRectMake(BOOK_IMAGE_VIEW_START_X , BOOK_IMAGE_VIEW_START_Y, IMG_VIEW_FRAME_WIDTH, IMG_VIEW_FRAME_HEIGHT);
    imgView.tag = self.tag;
    imgView.layer.cornerRadius = 9.0;
    imgView.layer.masksToBounds = YES;
    imgView.backgroundColor = [UIColor colorWithHexString:_book.backgroundColorCode];

    [whiteBGView addSubview:imgView];
    
    // Create download image 
    UIImage * downloadImage = [UIImage imageNamed:@"browse_page_download.png"];
    _downloadImageView = [[UIImageView alloc] initWithImage:downloadImage];
    CGPoint downloadCenter = imgView.center;
    downloadCenter.y = imgView.bounds.size.height - _downloadImageView.bounds.size.height / 2.0f;
    [_downloadImageView setCenter:downloadCenter];
    [whiteBGView addSubview:_downloadImageView];
    
    if (self.book.isDownloaded.boolValue)
        [_downloadImageView setHidden:YES];
    
    
    //add delete book button, but keep it hidden until requested otherwise
    _deleteBookButton = [[UIButton alloc]init];
    UIImage *deleteBookImage = [UIImage imageNamed:@"library_close.png"];
    _deleteBookButton.frame = CGRectMake(whiteBGView.frame.size.width - deleteBookImage.size.width/2-2.0f, -12.0F , deleteBookImage.size.width, deleteBookImage.size.height);
    [_deleteBookButton setBackgroundImage:deleteBookImage forState:UIControlStateNormal];
    [_deleteBookButton addTarget:self action:@selector(deleteBook:) forControlEvents:UIControlEventTouchUpInside];
    [_deleteBookButton setHidden:YES];
    [self addSubview:_deleteBookButton];
    
    
    //add book title label.
    if(_book.title1)
    {
        UILabel *title1Label = [[UILabel alloc] init];
        title1Label.frame= CGRectMake(BOOK_IMAGE_VIEW_START_X , IMG_VIEW_FRAME_HEIGHT + WHITE_SPACE, IMG_VIEW_FRAME_WIDTH, LABEL_HEIGHT);
        title1Label.backgroundColor = [UIColor clearColor];
        title1Label.textAlignment = UITextAlignmentCenter;
        title1Label.textColor = [UIColor blackColor];
        title1Label.text = _book.title1;
        title1Label.font = [UIFont systemFontOfSize:14.0f];
        
        [whiteBGView addSubview:title1Label];
    }
    if(_book.title2)
    {
        UILabel *title2Label = [[UILabel alloc] init];
        title2Label.frame= CGRectMake(BOOK_IMAGE_VIEW_START_X , IMG_VIEW_FRAME_HEIGHT + LABEL_HEIGHT, IMG_VIEW_FRAME_WIDTH,LABEL_HEIGHT);
        title2Label.backgroundColor = [UIColor clearColor];
        title2Label.textAlignment = UITextAlignmentCenter;
        title2Label.textColor = [UIColor blackColor];
        title2Label.text = _book.title2;
        title2Label.font = [UIFont systemFontOfSize:14.0f];
        [whiteBGView addSubview:title2Label];
    }
    
    //add language label.
    UILabel *langLabel = [[UILabel alloc] init];
    langLabel.frame= CGRectMake(0 , whiteBGView.frame.size.height, whiteBGView.frame.size.width ,LANGUAGE_LABEL_HEIGHT);
    langLabel.backgroundColor = [UIColor clearColor];
    langLabel.textAlignment = UITextAlignmentCenter;
    langLabel.textColor = [UIColor whiteColor];
    langLabel.font = [UIFont italicSystemFontOfSize:14.0f];
    langLabel.text = [_book.primaryLanguage.name stringByAppendingFormat:@" / %@", _book.secondaryLanguage.name];
    [self addSubview:langLabel];
    
    
    // Add progress bar
    _downloadProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _downloadProgressBar.frame = CGRectMake(BOOK_IMAGE_VIEW_START_X * 2.0F, IMG_VIEW_FRAME_HEIGHT - 2.0F * WHITE_SPACE, IMG_VIEW_FRAME_WIDTH - BOOK_IMAGE_VIEW_START_X * 2.0F, LABEL_HEIGHT);
    [self addSubview:_downloadProgressBar];
    [_downloadProgressBar setHidden:YES];
    
}

// ======================================================================================================================================
// Trigger the touch event.
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    _lastEvent = BookThumbnailButtonEventOpen;
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

-(void) deleteBook:(id)sender
{
    _lastEvent = BookThumbnailButtonEventDelete;
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

-(void)downloadedTotalSize:(NSUInteger)size withManager:(id)manager
{
    self.isDownloading = YES;
    [_downloadProgressBar setProgress:(1.0F * size / self.book.bookSizeKB.floatValue)];
}

-(void)downloadFailed:(id)manager
{
    self.isDownloading = NO;
}

-(void)downloadCompletedSuccessfullyWithReturnedData:(NSDictionary *)responseData withManager:(id)manager
{
    [_downloadProgressBar setProgress:1.0F];
    
    dispatch_queue_t dQ = dispatch_queue_create(NULL, NULL);
    dispatch_async(dQ, ^{
        sleep(1);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isDownloading = NO;
            [_downloadImageView setHidden:YES];
        });
    });
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
