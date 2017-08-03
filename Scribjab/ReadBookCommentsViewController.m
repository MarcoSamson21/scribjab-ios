//
//  ReadBookCommentsViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-03.
//
//

#import "ReadBookCommentsViewController.h"
#import "ReadBookCommentTableViewCell.h"
#import "LoginRegistrationManager.h"
#import "DownloadManager.h"
#import "NSURLConnectionWithID.h"
#import "CommonMessageBoxes.h"
#import "URLRequestUtilities.h"
#import "DocumentHandler.h"
#import "UserManager.h"
#import "CommentManager.h"
#import "Globals.h"
#import "Utilities.h"
#import "UIColor+HexString.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static int const CONNECTION_FLAG = 2;
static int const CONNECTION_DELETE = 3;
static int const CONNECTION_POST_COMMENT = 4;

static int const REFRESH_COMMENTS_FREQUENCY_IN_MINUTES = 10;


@interface ReadBookCommentsViewController () <UITableViewDataSource, UITableViewDelegate, NSURLConnectionDelegate, DownloadManagerDelegate, LoginViewControllerDelegate, UIAlertViewDelegate>
{
    NSArray * _commentDataSource;
    NSMutableDictionary * _rowHeights;
    User * _loginUser;
    NSTimer * _updateTimer;
    
    // Connection's data
    DownloadManager * _downloadManager;
    NSURLConnectionWithID * _connection;
    NSMutableData * _httpData;
    
    // Comment to delete or to flag
    Comment * _lastConnectionRelatedComment;
    
    // Tap gesture recognizer for when presented modally
    UITapGestureRecognizer * _tapRecognizer;
}
- (void) initializeViewController;
- (void) loadTableData;
- (void) updateTimerTick:(NSTimer *) timer;
- (void) startUpdateTimerWithInterval:(NSTimeInterval)seconds;
- (void) showConnectionInProgressMessageBox;

- (void) processAddCommentReturnData;
- (void) processDeleteCommentReturnData;
- (void) processFlagCommentReturnData;

-(void) handleDismissalTap:(id) sender;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ReadBookCommentsViewController

@synthesize book = _book;
@synthesize popoverController;
@synthesize loginDelegate;

// ======================================================================================================================================

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Book Comments Screen", [self class]];
    [tracker set:kGAIScreenName value:screenName];
    
    // Book Title Dimension
    NSString * bookTitleDimentionValue = [NSString stringWithFormat:@"%@ | %@", self.book.title1, self.book.title2];
    [tracker set:[GAIFields customDimensionForIndex:1] value:bookTitleDimentionValue];
    
    // Book ID
    NSString * bookIdDimentionValue = self.book.remoteId.stringValue;
    [tracker set:[GAIFields customDimensionForIndex:2] value:bookIdDimentionValue];
    
    // Send the screen view.
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    // Clear custom dimentions
    [tracker set:[GAIFields customDimensionForIndex:1] value:nil];
    [tracker set:[GAIFields customDimensionForIndex:2] value:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [self setActivityIndicator:nil];
    [self setCommentText:nil];
    [self setSubmitButton:nil];
    [self setPleaseLoginButton:nil];
    [super viewDidUnload];
}

-(void)viewWillDisappear:(BOOL)animated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_updateTimer != nil)
            [_updateTimer invalidate];
        
    });
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidAppear:(BOOL)animated
{
    // If presented modally initialize tap gesture recognizer, so that we can dismiss view when tapped outside the bounds
    if ([self.presentingViewController.modalViewController isEqual:self])
    {
        // dismiss preview on tap ouside the bounds
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissalTap:)];
        
        [_tapRecognizer setNumberOfTapsRequired:1];
        _tapRecognizer.cancelsTouchesInView = NO; // So the user can still interact with controls in the modal view
        [self.view.window addGestureRecognizer:_tapRecognizer];
    }
}
// ======================================================================================================================================
-(void)handleDismissalTap:(UITapGestureRecognizer *)sender
{
    if (_tapRecognizer == nil)
        return;
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint locationOfTap = [sender locationInView:nil];    // passing nil gives coordinates in window
        locationOfTap = [self.view convertPoint:locationOfTap fromView:self.view.window];
        
        if (![self.view pointInside:locationOfTap withEvent:nil])
        {
            [self.view.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:^{}];
        }
    }
}

// ======================================================================================================================================
- (void) initializeViewController
{
    [self.activityIndicator stopAnimating];
    _loginUser = [LoginRegistrationManager getLoginUser];
    
    if (_loginUser == nil)
    {
        [self.commentText setEditable:NO];
        [self.submitButton setHidden:YES];
    }
    else
    {
        [self.pleaseLoginButton setHidden:YES];
    }
    
    self.commentTitle1.text = [NSString stringWithFormat:@"%@ / %@", _book.title1, _book.title2];

    // Initialize data source
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self loadTableData];
    
    // start update timer
    [self startUpdateTimerWithInterval:2.0];
}

// ======================================================================================================================================
// Re/Initialize table's data source
-(void)loadTableData
{
    // Sort book's comments
    NSSortDescriptor * dateOrder =[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSArray * sortDescriptors = [NSArray arrayWithObject:dateOrder];
    _commentDataSource  = [[_book.comments allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    
    _rowHeights = [[NSMutableDictionary alloc] initWithCapacity:_commentDataSource.count];

    [self.tableView reloadData];
}

// ======================================================================================================================================
// Start comment update timer
- (void) startUpdateTimerWithInterval:(NSTimeInterval)seconds
{
    dispatch_async(dispatch_get_main_queue(),
    ^{
        if (_updateTimer != nil)
            [_updateTimer invalidate];
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(updateTimerTick:) userInfo:nil repeats:NO];
    });
}

// ======================================================================================================================================
// Update comments periodically, as long as this view is opened
- (void) updateTimerTick:(NSTimer *) timer
{
    // ----------------------------------------
    // reload data from server, if it has been long enough since last refresh
    NSDate * timeToRefresh = [_book.updateTimeStamp dateByAddingTimeInterval:60*REFRESH_COMMENTS_FREQUENCY_IN_MINUTES];
    
    // if it is not time to refresh yet
    if ([timeToRefresh compare:[NSDate date]] == NSOrderedDescending)
    {
        [self startUpdateTimerWithInterval:REFRESH_COMMENTS_FREQUENCY_IN_MINUTES*60];
        return;
    }
  
    // conection is in use, try again later
    if (_connection != nil)
    {
        [self startUpdateTimerWithInterval:5.0];
        return;
    }
    
    // --------------
    // Update comments and authors
    
    _connection = [[NSURLConnectionWithID alloc] init];     // don't need this, initializing just to prevent other network activities while refresh is in progress
    [self.activityIndicator startAnimating];

    if (_downloadManager == nil)
        _downloadManager = [[DownloadManager alloc] init];
    
    _downloadManager.delegate = self;
    [_downloadManager refreshCommentsForBook:_book loggedInUser:_loginUser];
}

// ======================================================================================================================================
- (IBAction)closePopup:(id)sender
{
    [self.view.window removeGestureRecognizer:_tapRecognizer];

    if (self.popoverController != nil)
    {
        [self.popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
}

// ======================================================================================================================================
// flag comment as inappropriate
- (IBAction)flagComment:(id)sender
{
    if (_loginUser == nil)
    {
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:NO];
        return;
    }
    
    if (_connection != nil)
    {
        [self showConnectionInProgressMessageBox];
        return;
    }
    
    // each table cell has its row index saved in the 'tag' property. Get it to get the corresponding comment from the data source.
    // THIS DOESN"T WORK IN iOS 7?? int rowIndex = [[((UIButton*)sender) superview] superview].tag;
    int rowIndex = ((UIButton*)sender).tag;
    
    if (rowIndex >= _commentDataSource.count)
        return;
    
    Comment * comment = [_commentDataSource objectAtIndex:rowIndex];
    
    if (comment == nil)
        return;
    
    _lastConnectionRelatedComment = comment;
    [self.activityIndicator startAnimating];
    
    _httpData = [[NSMutableData alloc] initWithCapacity:128];
    
    // Start  connection
    NSString * urlWithParam = [NSString stringWithFormat:URL_FLAG_COMMENT, comment.remoteId.intValue];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, urlWithParam]];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setJSONData:[@"" dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
    [request setHTTPMethod:@"POST"];
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_FLAG];
}
// ======================================================================================================================================
// delete comment from the server and from the book
- (IBAction)deleteComment:(id)sender
{
    if (_connection != nil)
    {
        [self showConnectionInProgressMessageBox];
        return;
    }
    
    // each table cell has its row index saved in the 'tag' property. Get it to get the corresponding comment from the data source.
    // THIS DOESN"T WORK IN iOS 7?? int rowIndex = [[((UIButton*)sender) superview] superview].tag;
    int rowIndex = ((UIButton*)sender).tag;

    if (rowIndex >= _commentDataSource.count)
        return;
    
    Comment * comment = [_commentDataSource objectAtIndex:rowIndex];
    
    if (comment == nil)
        return;
 
    _lastConnectionRelatedComment = comment;
    [self.activityIndicator startAnimating];
    
    
    NSString * title = NSLocalizedString(@"Delete Confirmation", @"Message box title: ask if user wants to delete a book comment from iPad");
    NSString * body = NSLocalizedString(@"Do you want to delete this comment?", @"Message box body: ask if user wants to delete a book comment");
    NSString * yes = NSLocalizedString(@"Yes", @"Message box button lable");
    NSString * no = NSLocalizedString(@"No", @"Message box button lable");
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:no otherButtonTitles:yes, nil];
    alert.tag = comment.remoteId.intValue;    // comment ID
    [alert show];
}

// ======================================================================================================================================
// Alert view Delegate method. User confirmed or cancelled comment deletion. Proceed accordingly.
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // delete book alert.
    if (buttonIndex == 1)       // Yes clicked
    {
        _httpData = [[NSMutableData alloc] initWithCapacity:128];

        // Start  connection
        NSString * urlWithParam = [NSString stringWithFormat:URL_DELETE_COMMENT, alertView.tag];
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, urlWithParam]];

        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];

        [URLRequestUtilities setJSONData:[@"" dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
        [request setHTTPMethod:@"DELETE"];
        _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_DELETE];
        
        
        // ---- Google analytics ---
        
        // May return nil if a tracker has not already been initialized with a property ID.
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book_comment"    // Event category (required)
                                                              action:@"delete_comment"  // Event action (required)
                                                               label:[NSString stringWithFormat:@"Book ID = %@", self.book.remoteId.stringValue]  // Event label
                                                               value:nil] build]];      // Event value
    }
}

// ======================================================================================================================================
- (IBAction)addComment:(id)sender
{
    [self.view endEditing:YES];
    
    if (_loginUser == nil)
    {
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
        return;
    }
    
    if (_connection != nil)
    {
        [self showConnectionInProgressMessageBox];
        return;
    }
    
    _httpData = [[NSMutableData alloc] initWithCapacity:1024];
    
    // Start download connection
    NSString * urlWithParam = [NSString stringWithFormat:URL_ADD_COMMENT, _book.remoteId.intValue];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, urlWithParam]];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setJSONData:[self.commentText.text dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
    [request setHTTPMethod:@"POST"];
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_POST_COMMENT];
    
    // ---- Google analytics ---
    
    // May return nil if a tracker has not already been initialized with a property ID.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book_comment"    // Event category (required)
                                                          action:@"add_comment"  // Event action (required)
                                                           label:[NSString stringWithFormat:@"Book ID = %@", self.book.remoteId.stringValue]  // Event label
                                                           value:nil] build]];      // Event value
}

// ======================================================================================================================================
- (IBAction)openLoginView:(id)sender
{
    [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
}

// ======================================================================================================================================
// show message
- (void) showConnectionInProgressMessageBox
{
    NSString * title = NSLocalizedString(@"Application is Busy", @"Ask user to wait while the application is downloading data");
    NSString * body = NSLocalizedString(@"Scribjab is currently interacting with the server, please try again in a few moments.", @"Ask user to wait while the application is downloading data");
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles:nil];
    [alert show];
}

// ======================================================================================================================================
// ADD COMMENT
- (void) processAddCommentReturnData
{
    NSString * errorTitle = NSLocalizedString(@"Cannot add a comment", @"Error title: Cannot add a comment to the book");
    
    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    // if login required - display login prompt
    if (isAuthError)
    {
        [LoginRegistrationManager logout];
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:NO];
        [self.activityIndicator stopAnimating];
        _connection = nil;
        return;
    }
    
    if (isError)
    {
        [self.activityIndicator stopAnimating];
        _connection = nil;
        return;
    }

    // No errors - save data
    self.commentText.text = @"";
    NSDictionary * dictionary = [responseData objectForKey:@"result"];
    [CommentManager addOrUpdateCommentWithData:dictionary user:_loginUser];
    
    [self.activityIndicator stopAnimating];
    _connection = nil;
    
    [self loadTableData];
}
// ======================================================================================================================================
// DELETE COMMENT
- (void) processDeleteCommentReturnData
{
    NSString * errorTitle = NSLocalizedString(@"Cannot delete a comment", @"Error title: Cannot delete a comment from the book");
    
    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    responseData = nil;
    // if login required - display login prompt
    if (isAuthError)
    {
        [LoginRegistrationManager logout];
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:NO];
        [self.activityIndicator stopAnimating];
        _lastConnectionRelatedComment = nil;
        _connection = nil;
        return;
    }
    
    if (isError)
    {
        [self.activityIndicator stopAnimating];
        _lastConnectionRelatedComment = nil;
        _connection = nil;
        return;
    }
    
    // No errors - delete comment from core data
    [[DocumentHandler sharedDocumentHandler] deleteAndWaitContextForNSManagedObject:_lastConnectionRelatedComment];
    
    [self.activityIndicator stopAnimating];
    _lastConnectionRelatedComment = nil;
    _connection = nil;
    
    [self loadTableData];
}
// ======================================================================================================================================
- (void) processFlagCommentReturnData
{
    NSString * errorTitle = NSLocalizedString(@"Cannot flag a comment", @"Error title: Cannot flag a comment for the book");

    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    // if login required - display login prompt
    if (isAuthError)
    {
        [LoginRegistrationManager logout];
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:NO];
        [self.activityIndicator stopAnimating];
        _lastConnectionRelatedComment = nil;
        _connection = nil;
        return;
    }
    
    if (isError)
    {
        [self.activityIndicator stopAnimating];
        _lastConnectionRelatedComment = nil;
        _connection = nil;
        return;
    }
    
    [self.activityIndicator stopAnimating];
    
    // No errors - flag or delete the comment in the core data
    BOOL deleteComment = [[responseData objectForKey:@"result"] boolValue];
    
    
    if (deleteComment)
    {
        [[DocumentHandler sharedDocumentHandler] deleteAndWaitContextForNSManagedObject:_lastConnectionRelatedComment];
    }
    else
    {
        _lastConnectionRelatedComment.flaggedBy = _loginUser;
        _lastConnectionRelatedComment.flaggedByMe = [NSNumber numberWithBool:YES];
        [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    }
    
    _lastConnectionRelatedComment = nil;
    _connection = nil;
    [self loadTableData];
}








// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark Table View data source methods

// ======================================================================================================================================
// Number of rows
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_commentDataSource == nil)
        return 0;
    return _commentDataSource.count;
}

// ======================================================================================================================================
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


// ======================================================================================================================================
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReadBookCommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Read Book Comment Cell"];
	Comment * comment = [_commentDataSource objectAtIndex:indexPath.row];
    
    NSLocale *locale = [[NSLocale alloc ] initWithLocaleIdentifier:[Utilities locale]];
    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    [dateFormat setTimeStyle:NSDateFormatterNoStyle];
    [dateFormat setLocale:locale];
    
    cell.fromLabel.text = [NSString stringWithFormat:@"%@ - %@", comment.author.userName, [dateFormat stringFromDate:comment.date]];
	cell.commentText.text = comment.comment;
    cell.avatar.image = [UIImage imageWithContentsOfFile:[UserManager getAvatarAbsolutePathForUser:comment.author thumbnailSize:YES]];
    [cell.avatar setBackgroundColor:[UIColor colorWithHexString:comment.author.backgroundColorCode]];
    cell.tag = indexPath.row;
    
    cell.flagCommentButton.tag = indexPath.row;
    cell.deleteCommentButton.tag = indexPath.row;
    
    [cell.deleteCommentButton setHidden:YES];
    [cell.flagCommentButton setEnabled:YES];
    
    // Enable or disable buttons
    if (_loginUser != nil)
    {
        if (comment.author == _loginUser || _book.author == _loginUser)
            [cell.deleteCommentButton setHidden:NO];
        
        if (comment.flaggedBy == _loginUser)
            [cell.flagCommentButton setEnabled:NO];
    }
    
    return cell;
}

// ======================================================================================================================================
// return height for a row
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int const CHARS_PER_LINE = 80.0F;      // characters per line
    int const LINE_HEIGHT = 25.0F;         // height of a line
    int const MAX_TEXT_HEIGHT = 300;    // max height of comment text area
    int const MARGINS = 40;
    
    Comment * comment = [_commentDataSource objectAtIndex:indexPath.row];

    int height = MARGINS + ceilf(comment.comment.length * 1.0F / CHARS_PER_LINE) * LINE_HEIGHT;
    height = MIN(MAX_TEXT_HEIGHT, height);
    return MAX(height, self.tableView.rowHeight);
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark Like Book - Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_httpData setLength:0];
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_httpData appendData:data];
}

// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_httpData setLength:0];
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    [self.activityIndicator stopAnimating];
    _connection = nil;
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSURLConnectionWithID * conn = (NSURLConnectionWithID*) connection;
    
    switch (conn.identification)
    {
        case CONNECTION_POST_COMMENT:
            [self processAddCommentReturnData];
            break;
        case CONNECTION_DELETE:
            [self processDeleteCommentReturnData];
            break;
        case CONNECTION_FLAG:
            [self processFlagCommentReturnData];
            break;
        default:
            _connection = nil;
            [self.activityIndicator stopAnimating];
            break;
    }
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark DownloadManager delegate methods

-(void)downloadCancelled:(id)manager
{
    [self.activityIndicator stopAnimating];
    [self startUpdateTimerWithInterval:REFRESH_COMMENTS_FREQUENCY_IN_MINUTES * 60];
    _connection = nil;
}

-(void)downloadCompletedSuccessfullyWithReturnedData:(NSDictionary *)responseData withManager:(id)manager
{
    // reload data
    [self loadTableData];
    _book.updateTimeStamp = [NSDate date];
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    [self.activityIndicator stopAnimating];
    [self startUpdateTimerWithInterval:REFRESH_COMMENTS_FREQUENCY_IN_MINUTES * 60];
    _connection = nil;
}

-(void)downloadFailed:(id)manager
{
    [self.activityIndicator stopAnimating];
    [self startUpdateTimerWithInterval:REFRESH_COMMENTS_FREQUENCY_IN_MINUTES * 60];
    _connection = nil;
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark LoginViewControllerDelegate Implementation

// Login view finished the login process and the user was logged in successfully.
-(void) loginFinishedWithSuccess
{
    _loginUser = [LoginRegistrationManager getLoginUser];
    
    [self.commentText setEditable:YES];
    [self.submitButton setHidden:NO];
    [self.pleaseLoginButton setHidden:YES];
    
    
    [self loadTableData];
    
    [self.loginDelegate loginFinishedWithSuccess];
}

// Login view's cancel button was clicked. Login was unsuccessful
-(void) loginCancelled
{
    
}

@end
