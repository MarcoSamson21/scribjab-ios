//
//  ReadBookPageViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-19.
//
//

#import "ReadPageViewController.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import <AVFoundation/AVFoundation.h>
#import "LoginRegistrationManager.h"
#import "FlagBookViewController.h"
#import "DocumentHandler.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "NSURLConnectionWithID.h"
#import "URLRequestUtilities.h"
#import "ReadBookCommentsViewController.h"
#import "Book.h"
#import "User.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static int const CONNECTION_LIKE_BOOK = 1;
static int const CONNECTION_UNLIKE_BOOK = 2;
static int const CONNECTION_GET_BOOK_WEB_URL = 3;

@interface ReadPageViewController () <AVAudioPlayerDelegate, LoginViewControllerDelegate, FlagBookViewControllerDelegate, NSURLConnectionDelegate>
{
    User * _loggedInUser;
    
    NSString * _text1AudioPath;
    NSString * _text2AudioPath;
    
    AVAudioPlayer * _audioPlayer;
    UIButton * _currentPlayButton;
    NSMutableArray * _readToMeFileList;
    BOOL _isReadingAudio;
    
    BOOL _menuHidden;
    
    NSURLConnectionWithID * _connectionLike;
    NSMutableData * _httpResponseDataLike;
    
    NSURLConnectionWithID * _connectionGetBookURL;
    NSMutableData * _httpResponseDataBookURL;
    
    UIPopoverController * _popCommentsController;
}
- (void) initializeViewController;
- (void) playAudioFile:(NSString *) filePath initiatedBy:(UIButton*)playButton;
- (void) stopPlayback;
- (void) processUserInformation;
- (void) processLikeURLResponce;
- (void) processGetBookURLResponce;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ReadPageViewController

@synthesize page = _page;
@synthesize isMenuHidden = _menuHidden;

// ======================================================================================================================================

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _menuHidden = YES;
    }
    return self;
}
-(id)init
{
    self = [super init];
    if (self)
    {
        _menuHidden = YES;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _menuHidden = YES;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self initializeViewController];
    
    // --- Send Google Analytics Data ----------
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Read Book (Regular Page) Screen", [self class]];
    [tracker set:kGAIScreenName value:screenName];
    
    // Book Title Dimension
    NSString * bookTitleDimentionValue = [NSString stringWithFormat:@"%@ | %@", _page.book.title1, _page.book.title2];
    [tracker set:[GAIFields customDimensionForIndex:1] value:bookTitleDimentionValue];
    
    // Book ID
    NSString * bookIdDimentionValue = _page.book.remoteId.stringValue;
    [tracker set:[GAIFields customDimensionForIndex:2] value:bookIdDimentionValue];
    
    // Page ID
    NSString *pageIdDimentionValue = _page.remoteId.stringValue;
    [tracker set:[GAIFields customDimensionForIndex:3] value:pageIdDimentionValue];
    
    // Send the screen view.
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    // Clear custom dimentions
    [tracker set:[GAIFields customDimensionForIndex:1] value:nil];
    [tracker set:[GAIFields customDimensionForIndex:2] value:nil];
    [tracker set:[GAIFields customDimensionForIndex:3] value:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)viewDidUnload
{
    [self setImage:nil];
    [self setText1:nil];
    [self setText2:nil];
    [self setPlayText1Button:nil];
    [self setPlayText2Button:nil];
    [self setMenuBarView:nil];
    [self setMenuExpendButton:nil];
    [self setReadToMeButton:nil];
    [self setLikeButton:nil];
    [self setCommentsButton:nil];
    [self setFlagButton:nil];
    [super viewDidUnload];
}

// ======================================================================================================================================
// Update user interface in case something has changed (e.g. flags were added or likes)
-(void)viewWillAppear:(BOOL)animated
{
    [self processUserInformation];
}
// ======================================================================================================================================
// Custom initialization
- (void) initializeViewController
{
    if (_page == nil)
        return;
    
    // create rounded corners
    self.text1.layer.cornerRadius = ROUNDED_CORNER_RADIUS;
    self.text1.layer.masksToBounds = YES;
    self.text2.layer.cornerRadius = ROUNDED_CORNER_RADIUS;
    self.text2.layer.masksToBounds = YES;

    // load page data
    self.text1.text = _page.text1;
    self.text2.text = _page.text2;

    // Add image
    UIImage * image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:_page fileName:BOOK_PAGE_IMAGE_FILENAME]];
    self.image.image = image;
    self.image.backgroundColor = [UIColor colorWithHexString:_page.backgroundColorCode];
    
    // Check if sound exists
    _text1AudioPath  = [BookManager getBookItemAbsPath:_page fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3];
    _text2AudioPath  = [BookManager getBookItemAbsPath:_page fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_text1AudioPath])
    {
        _text1AudioPath = nil;
        [self.playText1Button setHidden:YES];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_text2AudioPath])
    {
        _text2AudioPath = nil;
        [self.playText2Button setHidden:YES];
    }
    
    if (_text1AudioPath == nil && _text2AudioPath == nil)
    {
        //[self.readToMeButton setEnabled:NO];
        [self.readToMeButton setHidden:YES];
    }
    
    // hide menu bar
    if (_menuHidden)
    {
        self.menuBarView.frame = CGRectMake(self.menuBarView.frame.origin.x + self.menuBarView.frame.size.width, self.menuBarView.frame.origin.y, self.menuBarView.frame.size.width, self.menuBarView.frame.size.height);
        //self.menuExpendButton.frame = CGRectMake(self.menuExpendButton.frame.origin.x + self.menuBarView.frame.size.width, self.menuExpendButton.frame.origin.y, self.menuExpendButton.frame.size.width, self.menuExpendButton.frame.size.height);
        [self.menuBarView setHidden:YES];
        _menuHidden = YES;
        [self.menuExpendButton setSelected:NO];
    }
    else
    {
        [self.menuExpendButton setSelected:YES];
    }
    
    // process user data
    [self processUserInformation];
}

// ======================================================================================================================================
// Show or hide the menu
-(void)setMenuHidden:(BOOL)hidden
{
    if (_menuHidden == hidden)
        return;
    
    float multiplier = 1.0F;
    
    if (hidden)
    {
        [self.menuExpendButton setSelected:NO];
    }
    else
    {
        multiplier = -1.0F;
        [self.menuExpendButton setSelected:YES];
    }
    
    self.menuBarView.frame = CGRectMake(self.menuBarView.frame.origin.x + multiplier * self.menuBarView.frame.size.width, self.menuBarView.frame.origin.y, self.menuBarView.frame.size.width, self.menuBarView.frame.size.height);
    [self.menuBarView setHidden:hidden];
    
    _menuHidden = hidden;
}

// ======================================================================================================================================
- (IBAction)closeBook:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
// ======================================================================================================================================
- (IBAction)showOrHideMenuBar:(id)sender
{
    float multiplier = 1.0F;
    
    if (_menuHidden)
    {
        multiplier = -1.0F;
        [self.menuBarView setHidden:NO];
    }
    
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationCurveEaseInOut
                     animations:
     ^{
         // hide or show menu bar
         self.menuBarView.frame = CGRectMake(self.menuBarView.frame.origin.x + multiplier * self.menuBarView.frame.size.width, self.menuBarView.frame.origin.y, self.menuBarView.frame.size.width, self.menuBarView.frame.size.height);
         //self.menuExpendButton.frame = CGRectMake(self.menuExpendButton.frame.origin.x + multiplier * self.menuBarView.frame.size.width, self.menuExpendButton.frame.origin.y, self.menuExpendButton.frame.size.width, self.menuExpendButton.frame.size.height);
 
         if (_menuHidden)
             [self.menuExpendButton setSelected:YES];
         else
             [self.menuExpendButton setSelected:NO];

     } completion:^(BOOL finished)
     {
        // if (_menuHidden)
           //  self.menuExpendButton.titleLabel.text = @">";
        // else
         
         if (!_menuHidden)
         {
             [self.menuBarView setHidden:YES];
//             self.menuExpendButton.titleLabel.text = @"<";
         }
         
         _menuHidden = !_menuHidden;
     }];
}
// ======================================================================================================================================
- (IBAction)playText1:(id)sender
{
    if (_text1AudioPath == nil) return;
    if (_isReadingAudio) return;
    
    [self playAudioFile:_text1AudioPath initiatedBy:sender];
}
// ======================================================================================================================================
- (IBAction)playText2:(id)sender
{
    if (_text2AudioPath == nil) return;
    if (_isReadingAudio) return;
    
    [self playAudioFile:_text2AudioPath initiatedBy:sender];
}

// ======================================================================================================================================
// Auto read all text
-(void)readToMe:(id)sender
{
    // If reading - stop
    if (_isReadingAudio)
    {
        _isReadingAudio = NO;
        [self stopPlayback];
        [_readToMeFileList removeAllObjects];
        [self.readToMeButton setSelected:NO];
        return;
    }
    
    // start auto reading
    if (_readToMeFileList == nil)
        _readToMeFileList = [[NSMutableArray alloc] initWithCapacity:4];
    
    if (_text1AudioPath != nil)
        [_readToMeFileList addObject:_text1AudioPath];
    if (_text2AudioPath != nil)
        [_readToMeFileList addObject:_text2AudioPath];
    
    if (_readToMeFileList.count == 0)
        return;
    
    [self stopPlayback];
    [self.readToMeButton setSelected:YES];
    _isReadingAudio = YES;
    [self playAudioFile:[_readToMeFileList objectAtIndex:0] initiatedBy:nil];
    [_readToMeFileList removeObjectAtIndex:0];
}

// ======================================================================================================================================
- (IBAction)likeBook:(id)sender
{
    if (_loggedInUser == nil)
    {
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
        return;
    }
    
    _httpResponseDataLike = [[NSMutableData alloc] initWithCapacity:64];
    
    // Start download connection
    NSURL * url = nil;
    int connID = 0;
    
    if ([_loggedInUser.likedBooks containsObject:_page.book])
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH, URL_UNLIKE_BOOK, _page.book.remoteId]];
        connID = CONNECTION_UNLIKE_BOOK;
        [self.likeButton setSelected:NO];
    }
    else
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH, URL_LIKE_BOOK, _page.book.remoteId]];
        connID = CONNECTION_LIKE_BOOK;
        [self.likeButton setSelected:YES];
    }
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setJSONData:[@"" dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
    [request setHTTPMethod:@"POST"];
    _connectionLike = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:connID];

}
// ======================================================================================================================================
- (IBAction)viewComments:(id)sender
{
    ReadBookCommentsViewController * commentsView = [self.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Comments View Controller"];
    commentsView.book = _page.book;
    commentsView.loginDelegate = self;
    
    _popCommentsController = [[UIPopoverController alloc] initWithContentViewController:commentsView];
    commentsView.popoverController = _popCommentsController;
    [_popCommentsController presentPopoverFromRect:self.commentsButton.bounds inView:self.commentsButton permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
}

// ======================================================================================================================================
- (IBAction)flagBook:(id)sender
{
    if (_loggedInUser == nil)
    {
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
        return;
    }
    
    FlagBookViewController * flagView = [self.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Flag Book View Controller"];
    flagView.book = _page.book;
    flagView.delegate = self;
    flagView.modalPresentationStyle = UIModalPresentationFormSheet;
    flagView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:flagView animated:YES completion:^{}];
}

// ======================================================================================================================================
- (IBAction)facebookShare:(id)sender
{
    if (_connectionGetBookURL != nil)
        return;
    
    // Get Book's web URL and then present Facebook share dialog
    _httpResponseDataBookURL = [[NSMutableData alloc] initWithCapacity:512];
    
    // Start download connection
    
    NSString * urlStr = [NSString stringWithFormat:URL_BOOK_GET_WEB_URL, _page.book.remoteId];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, urlStr]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0F];
    
    [URLRequestUtilities setJSONData:[@"" dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
    [request setHTTPMethod:@"GET"];
    
    _connectionGetBookURL = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_GET_BOOK_WEB_URL];
}

// ======================================================================================================================================
- (void) playAudioFile:(NSString *) filePath initiatedBy:(UIButton*)playButton
{
    if (_currentPlayButton != nil && _currentPlayButton == playButton)
    {
        [self stopPlayback];
        return;
    }
    
    [self stopPlayback];
    
    NSError * error;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:&error];
    
    if (error)
    {
        NSLog(@"error");
        return;
    }
    
    if (_audioPlayer == nil)
    {
        NSLog(@"failed to initialize audio player");
        return;
    }
    
    if (playButton != nil)
    {
        _currentPlayButton = playButton;
        [_currentPlayButton setSelected:YES];
    }
    _audioPlayer.delegate = self;
    [_audioPlayer play];
}

// ======================================================================================================================================
- (void) stopPlayback;
{
    if (_audioPlayer != nil)
    {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    
    if (_currentPlayButton != nil)
    {
        [_currentPlayButton setSelected:NO];
        _currentPlayButton = nil;
    }
}

// ======================================================================================================================================
- (void) processUserInformation
{
    _loggedInUser = [LoginRegistrationManager getLoginUser];
    if (_loggedInUser == nil)
        return;
    
    if ([_loggedInUser.flaggedBooks containsObject:_page.book])
        [self.flagButton setEnabled:NO];
    if ([_loggedInUser.likedBooks containsObject:_page.book])
        [self.likeButton setSelected:YES];
    else
        [self.likeButton setSelected:NO];
}

// ======================================================================================================================================
// Stops all sound playback.
-(void)stopAllSoundPlayback
{
    [self stopPlayback];
    if (_isReadingAudio && _readToMeFileList.count > 0)
    {
        _isReadingAudio = NO;
        [_readToMeFileList removeAllObjects];
        [self.readToMeButton setSelected:NO];
    }
}

// ======================================================================================================================================
// Process Like/Unlike http responce
- (void) processLikeURLResponce
{
    NSString * errorTitle = NSLocalizedString(@"Failed to like this book", @"Error title: Cannot add book to faviorites");
    
    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpResponseDataLike orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    // if login required - display login prompt
    if (isAuthError)
    {
        [LoginRegistrationManager logout];
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
        _connectionLike = nil;
        return;
    }
    
    if (isError)
    {
        _connectionLike = nil;
        return;
    }
    
    // No errors - save data
    int count = [[responseData objectForKey:@"result"] intValue];
    Book * book = _page.book;
    
    if (_connectionLike.identification == CONNECTION_LIKE_BOOK)
    {
        book.likedBy = _loggedInUser;
        book.likeCount = [NSNumber numberWithInt:[book.likeCount intValue] + count];
    }
    else
    {
        [_loggedInUser removeLikedBooksObject:book];
        book.likeCount = [NSNumber numberWithInt:[book.likeCount intValue] - count];
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    _connectionLike = nil;
}


// ======================================================================================================================================
// Process Get Book URL http responce
- (void) processGetBookURLResponce
{
    NSString * errorTitle = NSLocalizedString(@"Sharing Failed", @"Error title: Cannot share a book due to a network error");
    
    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpResponseDataBookURL orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    if (isError)
    {
        _connectionGetBookURL = nil;
        return;
    }
    
    // No errors - save data
    NSString * bookURL = [responseData objectForKey:@"result"];
    
    _connectionGetBookURL = nil;
    
    NSURL * url = [NSURL URLWithString:bookURL];
    
    if (url == nil)
    {
#ifdef DEBUG
        NSLog(@"Returned Book URL is not valid.");
#endif
        return;
    }
    
    
    // --------- POST to FaceBook: If FaceBook App is installed - use it, otherwise fallback to the web feed dialong
    
//    FBSDKShareLinkContent *content = [FBSDKShareLinkContent new];
//    content.contentURL = url;
//    FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
//    params.link = url;
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = url;
    //
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.fromViewController = self;
    dialog.shareContent = content;
    [dialog show];
    //TODO: Facebook update
    // FACEBOOK APP?
//    if ([FBDialogs canPresentShareDialogWithParams:params])
//    {
//        // Open FaceBook sharing dialog
//        
//        [FBDialogs presentShareDialogWithLink:url
//                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                          if (error)
//                                          {
//#ifdef DEBUG
//                                              NSLog(@"facebook error: %@", error.description);
//#endif
//                                          }
//                                          else
//                                          {
//                                              // ---- Google analytics ---
//                                              
//                                              // May return nil if a tracker has not already been initialized with a property ID.
//                                              id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//                                              
//                                              [tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:@"FaceBook"          // Social network (required)
//                                                                                                    action:@"Share"            // Social action (required)
//                                                                                                    target:bookURL] build]];        // Social target
//#ifdef DEBUG
//                                              NSLog(@"Facebook success");
//#endif
//                                          }
//                                      }];
//        
//    }
//    else    // FaceBook WEB
//    {
//        // Open FaceBook sharing dialog
//        
//        NSMutableDictionary * feedParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:bookURL, @"link", nil];
//        
//        
//        // === Log out from facebook ===
//        NSHTTPCookie *cookie;
//        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//        for (cookie in [storage cookies])
//        {
//            NSString* domainName = [cookie domain];
//            NSRange domainRange = [domainName rangeOfString:@"facebook"];
//            if(domainRange.length > 0)
//            {
//                [storage deleteCookie:cookie];
//            }
//        }
//        // === END OF: Log out from facebook ===
//        
//        [FBWebDialogs presentFeedDialogModallyWithSession:nil parameters:feedParams
//                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error)
//         {
//             if (error)
//             {
//#ifdef DEBUG
//                 // An error occurred, we need to handle the error
//                 // See: https://developers.facebook.com/docs/ios/errors
//                 NSLog([NSString stringWithFormat:@"Error publishing story: %@", error.description]);
//#endif
//             }
//             else
//             {
//                 // ---- Google analytics ---
//                 
//                 // May return nil if a tracker has not already been initialized with a property ID.
//                 id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//                 
//                 [tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:@"FaceBook"          // Social network (required)
//                                                                       action:@"Share"            // Social action (required)
//                                                                       target:bookURL] build]];        // Social target
//             }
//         }];
//    }
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark AVAudioPlayer Delegate Implementation

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlayback];
    
    if (_isReadingAudio && _readToMeFileList.count > 0)
    {
        [self playAudioFile:[_readToMeFileList objectAtIndex:0] initiatedBy:nil];
        [_readToMeFileList removeObjectAtIndex:0];
        return;
    }
    
    _isReadingAudio = NO;
    [self.readToMeButton setSelected:NO];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark LoginViewControllerDelegate Implementation

// Login view finished the login process and the user was logged in successfully.
-(void) loginFinishedWithSuccess
{
    [self processUserInformation];
}

// Login view's cancel button was clicked. Login was unsuccessful
-(void) loginCancelled
{
    
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark FlagBookViewControllerDelegate Implementation

-(void) bookFlagAdded
{
    _page.book.flaggedBy = _loggedInUser;
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    [self.flagButton setEnabled:NO];
}

-(void) bookFlaggingCancelled
{
    /* nothing to do here */
}

-(void) bookFlaggingErrorLoginRequired
{
    _loggedInUser = nil;
    [self.likeButton setSelected:YES];
    [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
}


// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Like Book - Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == _connectionLike)
        [_httpResponseDataLike setLength:0];
    else
        [_httpResponseDataBookURL setLength:0];
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == _connectionLike)
        [_httpResponseDataLike appendData:data];
    else
        [_httpResponseDataBookURL appendData:data];
}

// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == _connectionLike)
    {
        [_httpResponseDataLike setLength:0];
        [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
        
        if (_connectionLike.identification == CONNECTION_LIKE_BOOK)
            [self.likeButton setSelected:NO];
        else
            [self.likeButton setSelected:YES];
        
        _connectionLike = nil;
        return;
    }
    
    if (connection == _connectionGetBookURL)
    {
        [_httpResponseDataBookURL setLength:0];
        [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
        _connectionGetBookURL = nil;
    }
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (connection == _connectionLike)
        [self processLikeURLResponce];
    else if (connection == _connectionGetBookURL)
        [self processGetBookURLResponce];
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}
@end
