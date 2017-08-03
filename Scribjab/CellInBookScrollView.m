//
//  CellInBookScrollView.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-09.
//
//

#import "CellInBookScrollView.h"
#import "Book.h"
#import "BookManager.h"
#import "MyLibraryViewController.h"
#import "BookViewController.h"
#import "Language+Utils.h"
#import "UIColor+HexString.h"
#import "ModalConstants.h"

@interface CellInBookScrollView()
{
    MyLibraryViewController *myLibraryViewController;
    Book *currentBook;
//    UILabel *rejectMessageLabel;
    UIProgressView * _downloadProgressBar;
    UIButton *readBookButton;
    UIButton *downloadBookButton;
    BOOL hasDeleteButton;
    UITapGestureRecognizer *pgr;
}
- (void) setupBookView;
- (void) deleteBook:(id)sender;
- (void) editBook:(id)sender;
- (void) readBook:(id)sender;
- (void) downloadBook:(id)sender;

@end

@implementation CellInBookScrollView
@synthesize isDownloading = _isDownloading;
static int const BOOK_IMAGE_VIEW_START_X = 5;
static int const BOOK_IMAGE_VIEW_START_Y = 5;
static int const WHITE_SPACE = 5;
static int const WHITE_SPACE_START_Y = 15;
static int const WHITE_SPACE_START_X = 0;
static int const LABEL_HEIGHT = 20;
static int const LANGUAGE_LABEL_HEIGHT = 25;

- (void) changeDownloadToReadButton
{
    readBookButton.hidden = NO;
    downloadBookButton.hidden = YES;
}

-(BOOL)isDownloading
{
    return _isDownloading;
}
- (void)setIsDownloading:(BOOL)isDownloading
{
    if (_isDownloading != isDownloading)
    {
        _isDownloading = isDownloading;
    }
    
    if (isDownloading)
    {
        [_downloadProgressBar setHidden:NO];
        [_downloadProgressBar setProgress:0.0F];
        downloadBookButton.hidden = YES;
        //can not tap on it.
        pgr.enabled = NO;
    }
    else
    {
        [_downloadProgressBar setHidden:YES];
        pgr.enabled = YES;
    }
}
    
-(void)downloadedTotalSize:(NSUInteger)size withManager:(id)manager
{
    self.isDownloading = YES;
    [_downloadProgressBar setProgress:(1.0F * size / currentBook.bookSizeKB.floatValue)];
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
            readBookButton.hidden = NO;
            downloadBookButton.hidden = YES;
            [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:myLibraryViewController
                                           selector:@selector(updateScrollView:)
                                           userInfo:currentBook
                                            repeats:NO];
            
        });
    });
}

- (Book *) getCurrentBook
{
    return currentBook;
}

- (void)awakeFromNib
{
    [self setupBookView]; // get initialized when we come out of a storyboard
}

-(id)initWithFame:(CGRect)frame book:(Book *)book myLibraryViewController:(MyLibraryViewController *)aMyLibraryViewController tagNum:(int)tagNum canDelete:(BOOL)canDelete{
    
    self = [super initWithFrame:frame];
    if (self) {
        myLibraryViewController = aMyLibraryViewController;
        currentBook = book;
        
        int wi =0;
        self.backgroundColor = [UIColor clearColor];
        
        int totalWidth = WHITE_SPACE + IMG_VIEW_FRAME_WIDTH + WHITE_SPACE + IMG_VIEW_RIGHT_SPACE;
        wi = tagNum * totalWidth;

        self.frame = CGRectMake(wi , 0 , totalWidth, self.bounds.size.height);
        self.tag = tagNum;
        hasDeleteButton = canDelete? TRUE:FALSE;
        [self setupBookView]; // get initialized if someone uses alloc/initWithFrame: to create us
    }
    
    return self;
}

//create a book view.
- (void) setupBookView{
    pgr = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handleTapGestureForImageView:)];

    //remove previous view if exists.
    for(UIView *subview in [self subviews])
    {
        [subview removeFromSuperview];
    }
    
    self.contentMode = UIViewContentModeRedraw; // if our bounds changes, redraw ourselves
    self.backgroundColor = [UIColor clearColor];
    //add a white color background view.
    UIView *whiteBGView = [[UIView alloc]initWithFrame:CGRectMake(WHITE_SPACE_START_X, WHITE_SPACE_START_Y, WHITE_SPACE + IMG_VIEW_FRAME_WIDTH + WHITE_SPACE, WHITE_SPACE + IMG_VIEW_FRAME_HEIGHT + LABEL_HEIGHT + LABEL_HEIGHT )];
    whiteBGView.backgroundColor = [UIColor whiteColor];
    whiteBGView.layer.cornerRadius = 9.0;
    whiteBGView.layer.masksToBounds = YES;

    [self addSubview:whiteBGView];
    
    //create 1 imageViews for the book thumbnail.
    //add image view.
    UIImage *thumb = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:currentBook fileName:BOOK_THUMBNAIL_FILENAME]];
    UIImageView *imgView = [[UIImageView alloc]initWithImage:thumb];
    imgView.backgroundColor = [UIColor colorWithHexString:currentBook.backgroundColorCode];
    imgView.frame = CGRectMake(BOOK_IMAGE_VIEW_START_X , BOOK_IMAGE_VIEW_START_Y, IMG_VIEW_FRAME_WIDTH, IMG_VIEW_FRAME_HEIGHT);
    imgView.tag = self.tag;
    imgView.layer.cornerRadius = 9.0;
    imgView.layer.masksToBounds = YES;
    
    imgView.userInteractionEnabled = YES;    
    
    [whiteBGView addSubview:imgView];

    //add edit book button.
    switch (currentBook.approvalStatus.intValue) {
        case BookApprovalStatusSaved:
        {
            //add edit book button.
            UIButton *editBookButton = [[UIButton alloc]init];
            UIImage *editBookImage = [UIImage imageNamed:@"library_edit.png"];
            
           // editBookButton.frame = CGRectMake(whiteBGView.frame.origin.x + 5, whiteBGView.frame.origin.y + 20,   whiteBGView.frame.size.width -10 ,whiteBGView.frame.size.height- 63 );
            editBookButton.frame = CGRectMake(whiteBGView.center.x - editBookImage.size.width/2, IMG_VIEW_FRAME_HEIGHT - editBookImage.size.height, editBookImage.size.width,editBookImage.size.height);
            [editBookButton setImage:editBookImage forState:UIControlStateNormal];
            [editBookButton addTarget:self action:@selector(editBook:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:editBookButton];
        }
            break;
        case BookApprovalStatusPending:
        {
            //add waiting for approval label.
            UILabel * waitingLabel = [[UILabel alloc]init];
            waitingLabel.frame= imgView.frame;
            waitingLabel.backgroundColor = [UIColor whiteColor];
            waitingLabel.alpha = 0.6;
            waitingLabel.layer.cornerRadius = 9.0;
            waitingLabel.layer.masksToBounds = YES;
            
            waitingLabel.textAlignment = UITextAlignmentCenter;
            waitingLabel.textColor = [UIColor blackColor];
            waitingLabel.text = NSLocalizedString(@"Pending for approval", @"Label for book in library.");
            [whiteBGView addSubview:waitingLabel];
            }
            break;
        case BookApprovalStatusApproved:
        {
//            UITapGestureRecognizer *pgr = [[UITapGestureRecognizer alloc]
//                                           initWithTarget:self action:@selector(handleTapGestureForImageView:)];
            [imgView addGestureRecognizer:pgr];
            UILabel *appLabel = [[UILabel alloc] init];
            appLabel.frame = imgView.frame;

            //create download button
            downloadBookButton = [[UIButton alloc]init];
            UIImage *downloadBookImage = [UIImage imageNamed:@"browse_page_download.png"];
            
            downloadBookButton.frame = CGRectMake(whiteBGView.center.x - downloadBookImage.size.width/2, IMG_VIEW_FRAME_HEIGHT - downloadBookImage.size.height, downloadBookImage.size.width,downloadBookImage.size.height);
            [downloadBookButton setBackgroundImage:downloadBookImage forState:UIControlStateNormal];
            [downloadBookButton addTarget:self action:@selector(downloadBook:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:downloadBookButton];

            //create read button.
            readBookButton = [[UIButton alloc]init];
            readBookButton.frame = imgView.frame;
            [readBookButton addTarget:self action:@selector(readBook:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:readBookButton];

            if(!currentBook.isDownloaded.boolValue)
            {
                downloadBookButton.hidden = NO;
                readBookButton.hidden = YES;
            }
            else
            {
                downloadBookButton.hidden = YES;
                readBookButton.hidden = NO;
            }

        }
            break;
        case BookApprovalStatusRejected:
        {
            //add reject button and show/hide the message when toggled.
            UIButton *rejectMessageButton = [[UIButton alloc]init];
            UIImage *rejectMessageImage = [UIImage imageNamed:@"reject.png"];
            
            rejectMessageButton.frame = CGRectMake(2 , 17, rejectMessageImage.size.width,rejectMessageImage.size.height);
            [rejectMessageButton setBackgroundImage:rejectMessageImage forState:UIControlStateNormal];
//            rejectMessageButton.layer.cornerRadius = 9.0;
//            rejectMessageButton.layer.masksToBounds = YES;

            [rejectMessageButton addTarget:self action:@selector(toggleRejectedMessage:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:rejectMessageButton];
            
            //add reject message label.
//            rejectMessageLabel = [[UILabel alloc] init];
//            rejectMessageLabel.frame= imgView.frame;
//            rejectMessageLabel.backgroundColor = [UIColor whiteColor];
//            rejectMessageLabel.alpha = 0.4;
//            rejectMessageLabel.layer.cornerRadius = 9.0;
//            rejectMessageLabel.layer.masksToBounds = YES;
//            
//            rejectMessageLabel.textAlignment = UITextAlignmentCenter;
//            rejectMessageLabel.textColor = [UIColor blackColor];
//            rejectMessageLabel.text = currentBook.rejectionComment;
//            rejectMessageLabel.hidden = YES;
//            [whiteBGView addSubview:rejectMessageLabel];
            UIButton *editBookButton = [[UIButton alloc]init];
            UIImage *editBookImage = [UIImage imageNamed:@"library_edit.png"];
            
            editBookButton.frame = CGRectMake(whiteBGView.center.x - editBookImage.size.width/2, IMG_VIEW_FRAME_HEIGHT - editBookImage.size.height, editBookImage.size.width,editBookImage.size.height);
            [editBookButton setBackgroundImage:editBookImage forState:UIControlStateNormal];
            [editBookButton addTarget:self action:@selector(editBook:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:editBookButton];

        }
            break;
        default:
            break;
    }
 
    //add delete book button if it's in myScroll view
    if(hasDeleteButton)
    {
        UIButton *deleteBookButton = [[UIButton alloc]init];
        UIImage *deleteBookImage = [UIImage imageNamed:@"library_close.png"];
        deleteBookButton.frame = CGRectMake(whiteBGView.frame.size.width - deleteBookImage.size.width/2, 0 , deleteBookImage.size.width, deleteBookImage.size.height);
        [deleteBookButton setBackgroundImage:deleteBookImage forState:UIControlStateNormal];
        [deleteBookButton addTarget:self action:@selector(deleteBook:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:deleteBookButton];
    }
    
    //add book title label.
    if(currentBook.title1)
    {
        UILabel *title1Label = [[UILabel alloc] init];
        title1Label.frame= CGRectMake(BOOK_IMAGE_VIEW_START_X , IMG_VIEW_FRAME_HEIGHT + WHITE_SPACE, IMG_VIEW_FRAME_WIDTH,LABEL_HEIGHT);
        title1Label.backgroundColor = [UIColor clearColor];
        title1Label.textAlignment = UITextAlignmentCenter;
        title1Label.textColor = [UIColor blackColor];
        title1Label.text = currentBook.title1;
        title1Label.font = [UIFont systemFontOfSize:14.0f];

        [whiteBGView addSubview:title1Label];
    }
    if(currentBook.title2)
    {
        UILabel *title2Label = [[UILabel alloc] init];
        title2Label.frame= CGRectMake(BOOK_IMAGE_VIEW_START_X , IMG_VIEW_FRAME_HEIGHT + LABEL_HEIGHT, IMG_VIEW_FRAME_WIDTH,LABEL_HEIGHT);
        title2Label.backgroundColor = [UIColor clearColor];
        title2Label.textAlignment = UITextAlignmentCenter;
        title2Label.textColor = [UIColor blackColor];
        title2Label.text = currentBook.title2;
        title2Label.font = [UIFont systemFontOfSize:14.0f];
        [whiteBGView addSubview:title2Label];
    }
    
    //add language label.
    UILabel *langLabel = [[UILabel alloc] init];
    langLabel.frame= CGRectMake(0 , whiteBGView.frame.size.height+ WHITE_SPACE + WHITE_SPACE+WHITE_SPACE, whiteBGView.frame.size.width ,LANGUAGE_LABEL_HEIGHT);
    langLabel.backgroundColor = [UIColor clearColor];
    langLabel.textAlignment = UITextAlignmentCenter;
    langLabel.textColor = [UIColor whiteColor];
    langLabel.font = [UIFont italicSystemFontOfSize:14.0f];
    langLabel.text = [currentBook.primaryLanguage.name stringByAppendingFormat:@" %@ %@", @"/", currentBook.secondaryLanguage.name];
    [self addSubview:langLabel];
    
    // Add progress bar
    _downloadProgressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _downloadProgressBar.frame = CGRectMake(BOOK_IMAGE_VIEW_START_X * 2.0F, IMG_VIEW_FRAME_HEIGHT - 2.0F * WHITE_SPACE, IMG_VIEW_FRAME_WIDTH - BOOK_IMAGE_VIEW_START_X * 2.0F, LABEL_HEIGHT);
    [self addSubview:_downloadProgressBar];
    [_downloadProgressBar setHidden:YES];
}




//===============================================================
//pass the action back to viewcontroller to display message.
- (void)toggleRejectedMessage: (id)sender
{
//    rejectMessageLabel.hidden=!rejectMessageLabel.isHidden;
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(toggleRejectedMessage:)
                                   userInfo:currentBook
                                    repeats:NO];
}

//===============================================================
//pass the action back to viewcontroller to edit book.
- (void)editBook:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(editBook:)
                                   userInfo:currentBook
                                    repeats:NO];
}
//===============================================================
//pass the action back to viewcontroller to read book.
- (void)readBook:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(readBook:)
                                   userInfo:currentBook
                                    repeats:NO];
}
//===============================================================
//pass the action back to viewcontroller to download book.
- (void)downloadBook:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(downloadBook:)
                                   userInfo:self
                                    repeats:NO];
}
//===============================================================
//pass the action back to viewcontroller to delete book.
- (void)deleteBook:(id)sender
{
//    UIButton *button = (UIButton *)sender;
    NSDictionary *info =  [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:self.tag], @"tag",
                                    currentBook, @"book",
                                    nil];

    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(deleteBook:)
                                   userInfo:info
                                    repeats:NO];
}


//========
//gesture for the view:
- (void)handleTapGestureForImageView:(UITapGestureRecognizer *)sender
{
    //    if book is downloaded, go to read book, otherwise, download book.
    currentBook.isDownloaded == [NSNumber numberWithInt:1]?
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(readBook:)
                                   userInfo:currentBook
                                        repeats:NO]:
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:myLibraryViewController
                                   selector:@selector(downloadBook:)
                                   userInfo:self
                                    repeats:NO];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupBookView]; // get initialized if someone uses alloc/initWithFrame: to create us
    }
    return self;
}
@end
