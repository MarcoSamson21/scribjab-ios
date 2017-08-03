//
//  MyLibarryViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-09.
//
//

#import "MyLibraryViewController.h"
#import "CellInBookScrollView.h"
#import "BookSelectLanguageViewController.h"
#import "BookPreviewViewController.h"
#import "BookViewController.h"

#import "BookManager.h"
#import "UserManager.h"
#import "UserGroupManager.h"
#import "LoginRegistrationManager.h"
#import "NavigationManager.h"
#import "DownloadManager.h"

#import "ModalConstants.h"
#import "URLRequestUtilities.h"
#import "NSString+URLEncoding.h"
#import "NSURLConnectionWithID.h"
#import "Globals.h"
#import "CommonMessageBoxes.h"
#import "AppDelegate.h"
#import "CreateBookNavigationManager.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static NSArray * MY_BOOKS           =   nil;    // List of my books
static NSArray * MY_FAVOURITE_BOOKS =   nil;    // List of favourite books
static NSArray * MY_GROUP_BOOKS     =   nil;    // List of group books
static NSDate  * RECENT_BOOKS_LIST_LAST_REFRESH_DATE  =   nil;
static int const REFRESH_FREQUENCY_IN_SECONDS   =   600;    // 10 minutes = 600 seconds

@interface MyLibraryViewController ()<DownloadManagerDelegate, BookPreviewViewControllerDelegate, LoginViewControllerDelegate>
{
    DownloadManager * _downloadManager;
    CellInBookScrollView * _lastCellClicked;
    NSMutableArray * userGroupListData;
    Book *bookToBeDeleted;
    
    int deleteButtonTag;
    int selectedUserGroupId;
    BOOL didLoad;
    BOOL hasGroupBooksFromServer;
    BOOL hasGroupsFromServer;
    NSMutableData * httpResponseDeleteBookData;
    NSMutableData * httpResponsePendingBookData;
    NSMutableData * httpResponseUserGroupData;

    NSURLConnectionWithID *deleteBookConnection;
    NSURLConnectionWithID *pendingBookConnection;    
    NSURLConnectionWithID *userGroupConnection;
}

- (void) setup;
- (void) initializeBookLists;
- (void) setupMyBooksScrollView;
- (void) setupMyFavouriteBooksScrollView;
- (void) setupMyGroupBooksScrollView;

- (void) handleTapGestureForCreateBookImageView:(UITapGestureRecognizer *)sender;
- (void) updateScrollView:(NSTimer *)timer;
- (void) editBook:(NSTimer *)timer;
- (void) readBook:(NSTimer *)timer;
- (void) downloadBook:(NSTimer *)timer;
- (void) deleteBook:(NSTimer *)timer;
- (void) toggleRejectedMessage:(NSTimer *)timer;
- (void) disableAllControls;
- (void) enableAllControls;
- (void) disableLibraryControls;
- (void) enableLibraryControls;

- (void) removeDeletedBook;
- (void) getMyUserGroupsFromWS;
- (void) sendDeleteBookRequestToServer;
- (void) sendUpdatesForPendingBookRequestToServer:(NSString *)idString;
- (void) processPendingBookResponseData;
- (void) processDeleteBookResponseData;
- (void) processUserGroupsResponseData;
- (void) logoutIfAuthError;

@end

@implementation MyLibraryViewController
@synthesize parentScrollView = _parentScrollView;
@synthesize myBooksScrollView = _myBooksScrollView;
@synthesize myFavouriteBooksScrollView = _myFavouriteBooksScrollView;
@synthesize myGroupBooksScrollView = _myGroupBooksScrollView;
@synthesize myBookLabel = _myBookLabel;
@synthesize myGroupLabel = _myGroupLabel;
@synthesize noBookFavouriteLabel = _noBookFavouriteLabel;
@synthesize noBookGroupLabel = _noBookGroupLabel;
@synthesize groupImageView = _groupImageView;
@synthesize deleteActivity = _deleteActivity;
@synthesize userGroupTableView = _userGroupTableView;
@synthesize readButton = _readButton;
@synthesize createButton = _createButton;

@synthesize logoutMenuButton = _logoutMenuButton;
@synthesize accountMenuButton = _accountMenuButton;
@synthesize loginUser = _loginUser;

// ********** CONSTANTS **********

static int const USERGROUP_TABLE_VIEW = 1;
static int const ALL_GROUP_TAGID = -1;
static int const DELETE_BOOK_ALERT_VIEW = 1;
static int const REJCET_MESSAGE_ALERT_VIEW = 2;
static int const YES_BUTTON_INDEX = 1;
static int const NO_BOOK_LABEL = 1;

static int const CONNECTION_DELETE_BOOK = 1;
static int const CONNECTION_UPDATE_BOOK_FOR_PENDING_APPROVAL = 2;
static int const CONNECTION_GET_MY_USERGROUP = 3;

//Force logout if auth error.
- (void) logoutIfAuthError
{
    [LoginRegistrationManager logout];
    [LoginRegistrationManager showLoginWithParent:self delegate:(id<LoginViewControllerDelegate>)self registrationButton:YES];
}

// Check if book lists should be refetched from the database.
// Refetch if needed and display book lists to the user.
-(void)initializeBookLists
{
    // Initialize Download manager
    if (_downloadManager == nil)
    {
        _downloadManager = [[DownloadManager alloc] init];
        _downloadManager.delegate = self;
    }
    
    if (_downloadManager.isDownloadingPreviews)
        return;
    
    // Initialize LAST DATE to a time in the past
    if (RECENT_BOOKS_LIST_LAST_REFRESH_DATE == nil)
        RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    
    // Otherwise need to fetch new book sets from the server
    [_downloadManager downloadRecentlyMyBookAndFavouriteAndGroupBooks:self.loginUser];
}


//setup the "my book" scroll view.
- (void) setupMyBooksScrollView
{
    int i =0;
    
    NSString *bookLabel = NSLocalizedString(@"'s Books", @"MyLibrary book label");
    
    NSString *locale = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    if([locale isEqualToString:@"fr"])
        self.myBookLabel.text = [bookLabel stringByAppendingString:self.loginUser.userName];
    else
        self.myBookLabel.text = [self.loginUser.userName stringByAppendingString:bookLabel];
    
    
    self.myBooksScrollView.frame = CGRectMake(self.myBooksScrollView.frame.origin.x, 40, self.myBooksScrollView.frame.size.width,self.myBooksScrollView.frame.size.height);
    
    [self.myBooksScrollView removeAllSubviews];     //remove all views before setup.
    [BookManager sortUserBooks:self.loginUser];     //get all the books from core data.
    
    for( Book *book in self.loginUser.book)
    {
        CellInBookScrollView * bookCV = (CellInBookScrollView *)[[CellInBookScrollView alloc]initWithFame:self.myBooksScrollView.bounds book:book myLibraryViewController:(MyLibraryViewController *)self tagNum:i canDelete:TRUE];
        
//        bookCV.tag = i;
        [self.myBooksScrollView addSubview:bookCV];
        i++;
    }
    self.myBooksScrollView.backgroundColor = [UIColor clearColor];

}

//setup the "my favouriteBook" scroll view.
- (void) setupMyFavouriteBooksScrollView
{
    int i =0;
    [self.myFavouriteBooksScrollView removeAllSubviews];    //remove all views before setup.
    self.myFavouriteBooksScrollView.frame = CGRectMake(self.myFavouriteBooksScrollView.frame.origin.x, 366, self.myFavouriteBooksScrollView.frame.size.width,self.myFavouriteBooksScrollView.frame.size.height);

    for(Book *book in self.loginUser.likedBooks)
    {
        if([book.approvalStatus intValue]== BookApprovalStatusApproved)
        {
        CellInBookScrollView * bookCV = (CellInBookScrollView *)[[CellInBookScrollView alloc]initWithFame:self.myFavouriteBooksScrollView.bounds book:book myLibraryViewController:(MyLibraryViewController *)self tagNum:i canDelete:FALSE];
//        bookCV.tag = i;
        [self.myFavouriteBooksScrollView addSubview:bookCV];
        i++;
        }
    }
    
    self.noBookFavouriteLabel.hidden = i==0? NO:YES;
    self.myFavouriteBooksScrollView.backgroundColor = [UIColor clearColor];
}

//setup the "my favouriteBook" scroll view.
- (void) setupMyGroupBooksScrollView
{
    int i =0;
    if(self.myGroupLabel.hidden)
    {
        self.myGroupBooksScrollView.hidden = YES;
        self.groupImageView.hidden = YES;
        return;
    }
    self.myGroupBooksScrollView.hidden = NO;
    [self.myGroupBooksScrollView removeAllSubviews];    //remove all views before setup.
    for( Book *book in MY_GROUP_BOOKS)
    {
        if ([book.approvalStatus intValue] == BookApprovalStatusApproved  && [book.userGroup.remoteId intValue] !=0 && (selectedUserGroupId == ALL_GROUP_TAGID || [book.userGroup.remoteId intValue] == selectedUserGroupId))
        {
            CellInBookScrollView * bookCV = (CellInBookScrollView *)[[CellInBookScrollView alloc]initWithFame:self.myGroupBooksScrollView.bounds book:book myLibraryViewController:(MyLibraryViewController *)self tagNum:i canDelete:FALSE];
            [self.myGroupBooksScrollView addSubview:bookCV];
            i++;
        }
    }
    self.noBookGroupLabel.hidden = i==0? NO:YES;
    self.myGroupBooksScrollView.backgroundColor = [UIColor clearColor];
}

//tap gesture for create a book.
- (void) handleTapGestureForCreateBookImageView:(UITapGestureRecognizer *)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(createBook)
                                   userInfo:nil
                                    repeats:NO];
}

//action from the cellInBookScrollView, If the book hasn't submit for approval, it will go to edit book page.
- (void) editBook:(NSTimer *)timer
{
    [NavigationManager navigateToCreateBookForUser:self.loginUser animatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut isFromHome:NO];
    [CreateBookNavigationManager navigateToBookViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:(Book *)[timer userInfo]];
}

//action from the cellInBookScrollView.
- (void) updateScrollView:(NSTimer *)timer
{
    Book * currentBook = (id)[timer userInfo];

    //update subview if exists in my book scroll view.
    [self.myBooksScrollView updateBookStatusInScrollViewWithRemoteId:currentBook.remoteId];
    
    //update subview if exists in favourite book scroll view.
        [self.myFavouriteBooksScrollView updateBookStatusInScrollViewWithRemoteId:currentBook.remoteId];
    
    //update subview if exists in group book scroll view.
    [self.myGroupBooksScrollView updateBookStatusInScrollViewWithRemoteId:currentBook.remoteId];
}

//action from the cellInBookScrollView.
- (void) toggleRejectedMessage:(NSTimer *)timer
{
    Book * currentBook = (id)[timer userInfo];
    
    NSString *message = NSLocalizedString(@"Message for ", @"Alert box title for reject message");
    NSString *message2 = NSLocalizedString(@" was rejected", @"Alert box title for reject message, part 2");
    message = [message stringByAppendingFormat:@"%@%@", currentBook.title1, message2];

    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:message
                                                    message: currentBook.rejectionComment
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label")
                                          otherButtonTitles:nil];
    alert.tag = REJCET_MESSAGE_ALERT_VIEW;
    [alert show];
}

//action from the cellInBookScrollView.  
- (void) readBook:(NSTimer *)timer
{
    Book * currentBook = (id)[timer userInfo];
    if(currentBook.isDownloaded)
        [NavigationManager openReadBookViewController:currentBook parentViewController:self];
}

//action from the cellInBookScrollView.  
- (void) downloadBook:(NSTimer *)timer
{
    CellInBookScrollView * cell  = (CellInBookScrollView *)[timer userInfo];
    Book * currentBook = [cell getCurrentBook];
    _lastCellClicked = cell;
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"BrowseBooks" bundle:nil];
    BookPreviewViewController * preview = [storyboard instantiateViewControllerWithIdentifier:@"Book Preview View Controller"];
    preview.book = currentBook;
    preview.delegate = self;
    
    preview.modalPresentationStyle = UIModalPresentationPageSheet;
    preview.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:preview animated:YES completion:^{}];

//    [self presentModalViewController:preview animated:YES];
}

//action from the cellInBookScrollView
//Delete a book. Will pop up a message to confirm.
- (void) deleteBook:(NSTimer *)timer
{ 
    NSDictionary *info = (id)[timer userInfo];
    deleteButtonTag = ((NSNumber *)[info objectForKey:@"tag"]).intValue;
    bookToBeDeleted = [info objectForKey:@"book"];
    NSString *message;
    if([bookToBeDeleted.approvalStatus intValue] > BookApprovalStatusSaved && bookToBeDeleted.author == self.loginUser)
    {
        message = NSLocalizedString(@"Are you sure you want to permanently delete this book? It will be removed from ScribJab and no longer exist.", @"Ask to confirm delete book on ipad and server");
    }
    else
        message = NSLocalizedString(@"Are you sure you want to delete this book from ipad?", @"Ask to confirm delete book on ipad");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Book", @"Alert box title for delete book")                                                                          message:message
                                            delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    alert.tag = DELETE_BOOK_ALERT_VIEW;
    [alert show];
}

//===========================
// #pragma alert view delegate
//Action after delete message box appear.  Book can be deleted anytime.  If it hasn't submitted for approval, it will only deleted from ipad. If it's already submitted, it will deleted both from ipad and server.
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //delete book alert.
    if (alertView.tag == DELETE_BOOK_ALERT_VIEW && buttonIndex == YES_BUTTON_INDEX)
    {
        [self disableAllControls];

        //remove the book from web server if not in saved status.
        if([bookToBeDeleted.approvalStatus intValue] > BookApprovalStatusSaved && bookToBeDeleted.author == self.loginUser)
        {
            [self sendDeleteBookRequestToServer];
        }
        else
        {
            [self removeDeletedBook];
        }
        
        [self enableAllControls];
    }
}

// remove book from ipad.
- (void) removeDeletedBook
{
    NSString * bookID = bookToBeDeleted.remoteId.stringValue;       // For GA
    
    if(bookToBeDeleted.author == self.loginUser)
    {
        [self.myBooksScrollView removeSubviewWithBook:bookToBeDeleted];
    }
    
    if([bookToBeDeleted.approvalStatus intValue] == BookApprovalStatusApproved)
    {
        [self.myFavouriteBooksScrollView removeSubviewWithBook:bookToBeDeleted];
        [self.myGroupBooksScrollView removeSubviewWithBook:bookToBeDeleted];
    }
    
    [BookManager deleteBook:bookToBeDeleted];
    
    bookToBeDeleted = nil;
    
    
    
    // ---- Google analytics ---
    
    // May return nil if a tracker has not already been initialized with a property ID.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book"    // Event category (required)
                                                          action:@"deleted"  // Event action (required)
                                                           label:[NSString stringWithFormat:@"Book ID = %@", bookID]  // Event label
                                                           value:nil] build]];      // Event value

}

//logout and go to main screen.
- (IBAction) logoutButtonIsPressed:(id)sender
{
    [LoginRegistrationManager logout];
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

//go to main screen.
- (IBAction) logoIsPressed:(id)sender
{
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

//go to account management screen.
- (IBAction) accountButtonIsPressed:(id)sender
{
    UIStoryboard * tourStoryboard = [UIStoryboard storyboardWithName:@"AccountManagement" bundle:[NSBundle mainBundle]];
    UIViewController * initialView = [tourStoryboard instantiateInitialViewController];

    initialView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:initialView animated:YES completion:^{}];

//    [self presentModalViewController:initialView animated:YES];
}

//go to create book page.
- (IBAction) createButtonIsPressed:(id)sender
{
    [NavigationManager navigateToCreateBookForUser:self.loginUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut isFromHome:NO];
}

//go to read book page.
- (IBAction) readButtonIsPressed:(id)sender
{
    [NavigationManager navigateToBrowseBooksAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

//disable control on library only.
- (void) disableLibraryControls
{
    self.myBooksScrollView.scrollEnabled = NO;
    self.myFavouriteBooksScrollView.scrollEnabled = NO;
    self.myGroupBooksScrollView.scrollEnabled = NO;
    self.userGroupTableView.scrollEnabled = NO;
    self.createButton.enabled = NO;
}

//enable control on library only.
- (void) enableLibraryControls
{
    self.myBooksScrollView.scrollEnabled = YES;
    self.myFavouriteBooksScrollView.scrollEnabled = YES;
    self.myGroupBooksScrollView.scrollEnabled = YES;
    self.userGroupTableView.scrollEnabled = YES;
    self.createButton.enabled = YES;
    [self.userGroupTableView reloadData];
}

// disable all controls.
- (void) disableAllControls
{
    [self.myBooksScrollView showActivityIndicator];
    [self.myFavouriteBooksScrollView showActivityIndicator];
    [self.myGroupBooksScrollView showActivityIndicator];
    [self.deleteActivity startAnimating];
    [self.deleteActivity setHidden:NO];
    self.myBooksScrollView.scrollEnabled = NO;
    self.myFavouriteBooksScrollView.scrollEnabled = NO;
    self.myGroupBooksScrollView.scrollEnabled = NO;
    self.parentScrollView.scrollEnabled = NO;
    self.userGroupTableView.scrollEnabled = NO;
    self.logoutMenuButton.enabled = NO;
    self.accountMenuButton.enabled = NO;
    self.createButton.enabled = NO;
    self.readButton.enabled = NO;
}

// enable all controls again.
- (void) enableAllControls
{
    self.myBooksScrollView.scrollEnabled = YES;
    self.myFavouriteBooksScrollView.scrollEnabled = YES;
    self.myGroupBooksScrollView.scrollEnabled = YES;
    self.userGroupTableView.scrollEnabled = YES;
    self.logoutMenuButton.enabled = YES;
    self.accountMenuButton.enabled = YES;
    self.createButton.enabled = YES;
    self.readButton.enabled = YES;
    [self.myBooksScrollView hideActivityIndicator];
    [self.myFavouriteBooksScrollView hideActivityIndicator];
    [self.myGroupBooksScrollView hideActivityIndicator];
    [self.deleteActivity stopAnimating];
    [self.deleteActivity setHidden:YES];
    
    if(!hasGroupsFromServer)
    {
        NSDictionary * all = [[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:-1] , @"groupId", @"All", @"groupName", nil];
        userGroupListData = [[NSMutableArray alloc]init];
        [userGroupListData addObject:all];
        
        //get from core data.
        for(Book *bk in self.loginUser.book)
        {
            if(bk.userGroup != nil)
            {
                UserGroups *ug = [UserGroupManager getUserGroupByRemoteId:[bk.userGroup.remoteId intValue]];
                NSDictionary * userGroup = [[NSDictionary alloc]initWithObjectsAndKeys:ug.remoteId , @"groupId", ug.name, @"groupName", nil];
                [userGroupListData addObject:userGroup];
            }
        }
        self.parentScrollView.scrollEnabled = YES;
    }
    else
        self.parentScrollView.scrollEnabled = YES;
    
    if(!hasGroupBooksFromServer)
    {
        NSMutableSet * bookInUserGroups = [[NSMutableSet alloc]init];
        //get from core data.
        for(Book *bk in self.loginUser.book)
        {
            [bookInUserGroups unionSet:bk.userGroup.books];
        }
        MY_GROUP_BOOKS = [bookInUserGroups allObjects];
    }
    
    [self.userGroupTableView reloadData];

}

- (void) setupAllScrollView
{
    self.myBooksScrollView.tag = 1;
    self.myFavouriteBooksScrollView.tag = 2;
    self.myGroupBooksScrollView.tag = 3;
    
    [self setupMyBooksScrollView];
    [self setupMyFavouriteBooksScrollView];
    [self setupMyGroupBooksScrollView];
}

- (void)setup
{
    hasGroupBooksFromServer = FALSE;
    hasGroupsFromServer = FALSE;
    self.noBookFavouriteLabel.hidden = YES;
    self.noBookGroupLabel.hidden = YES;
    [self getMyUserGroupsFromWS];
    self.parentScrollView.scrollEnabled = YES;
    self.parentScrollView.backgroundColor = [UIColor clearColor];
	// Do any additional setup after loading the view.
    [self.deleteActivity stopAnimating];
    [self.deleteActivity setHidden:YES];

    //set userGroup data
    self.userGroupTableView.dataSource = self;
    self.userGroupTableView.delegate = self;
    self.userGroupTableView.tag = USERGROUP_TABLE_VIEW;
    self.userGroupTableView.backgroundColor = [UIColor clearColor];
    selectedUserGroupId = ALL_GROUP_TAGID;
}

//============================
- (void) viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    didLoad = TRUE;
    
    
    // --- Send Google Analytics Data ----------

    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"My Library Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void) viewDidUnload
{
    [self setParentScrollView:nil];
    [self setMyBooksScrollView:nil];
    [self setMyFavouriteBooksScrollView:nil];
    [self setMyGroupBooksScrollView:nil];
    [self setMyBookLabel:nil];
    [self setMyGroupLabel:nil];
    [self setGroupImageView:nil];
    [self setNoBookFavouriteLabel:nil];
    [self setNoBookGroupLabel:nil];

    [self setDeleteActivity:nil];
    [self setUserGroupTableView:nil];
    [self setCreateButton:nil];
    [self setReadButton:nil];

    [self setLogoutMenuButton:nil];
    [self setAccountMenuButton:nil];
    
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!self.loginUser.isLoggedIn)
    {
        [self logoutIfAuthError];
    }
//    if(!didLoad)
    [self setup];
//    else
//        didLoad = FALSE;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    //reset user info.
     //set userGroup data
    self.myBookLabel.text = @"";
    [self.myBooksScrollView removeAllSubviews];
    [self.myFavouriteBooksScrollView removeAllSubviews];
    [self.myGroupBooksScrollView removeAllSubviews];
    self.myGroupLabel.hidden = YES;
    self.userGroupTableView.hidden = YES;
    self.myGroupBooksScrollView.hidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
#pragma mark Table View data source methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag == USERGROUP_TABLE_VIEW)
    {
        return [userGroupListData count];
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static
    NSString *simpleTableIdentifier = @"SimpleTableIdentifier";
    
    if(tableView.tag == USERGROUP_TABLE_VIEW)
        simpleTableIdentifier = @"UserGroupTableIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if(tableView.tag == USERGROUP_TABLE_VIEW)
    {
        NSDictionary *item = [userGroupListData objectAtIndex:[indexPath row]];
        if(item != nil && [item count]!=0)
        {
            cell.textLabel.text = [item objectForKey:@"groupName"];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
            NSString *dbId = [item objectForKey:@"groupId"];
            cell.tag = dbId.intValue;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag == USERGROUP_TABLE_VIEW)
    {
        selectedUserGroupId = [self.userGroupTableView cellForRowAtIndexPath:indexPath].tag;
        [self setupMyGroupBooksScrollView];
    }
}

//getting all user groups from server
- (void) getMyUserGroupsFromWS
{
    [self disableAllControls];
    if (userGroupConnection != nil)
        return;
    httpResponseUserGroupData = [[NSMutableData alloc] initWithLength:10];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH, URL_USERGROUP_MEMBERSHIP, [NSString stringWithFormat:@"%d",  self.loginUser.remoteId.intValue]]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [userGroupConnection cancel];
    userGroupConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_GET_MY_USERGROUP];
    
    return;
}

//common process response data.
//errorMessageTitle will be localized in the function.
-(id) processResponseData:(NSMutableData *) data withErrorMessageTitle:(NSString *)errorMessageTitle indicateIfError:(BOOL*)isError indicateIfAuthenticationError:(BOOL*)isAuthError
{
    if (isError != NULL)
        *isError = YES;
    if (isAuthError != NULL)
        *isAuthError = NO;

    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    //status fail.
    if (responseDictionary == nil || error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        [self enableAllControls];
        [self setupAllScrollView];
        return nil;
    }
    else if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = errorMessageTitle;
        NSString * errorBody = NSLocalizedString(@"UNKNOWN ERROR", @"unknown error from server");
        
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            errorBody = [errArr componentsJoinedByString:@"\n"];
            if (isError != NULL)
                *isError = YES;
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
            if (isError != NULL)
                *isError = YES;
        }
        
        // Auth Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_AUTH_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
            if (isAuthError != NULL)
                *isAuthError = YES;
            //update user login status
            errorTitle = NSLocalizedString(@"Authorization Fail. Please sign in again.", @"Message whe authorization fail.");
            [self logoutIfAuthError];
            return nil;
        }

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
        
        return nil;
    }
    
    //get result.
    *isError = NO;
    return [responseDictionary objectForKey:@"result"];
}

//process userGroup response data
- (void) processUserGroupsResponseData
{
    BOOL isAuthError = NO;
    BOOL isError = NO;
    
    id result = [self processResponseData:httpResponseUserGroupData withErrorMessageTitle:NSLocalizedString(@"An error occur when retrieving user group.", @"Error Message when fail to retrieve user group.") indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    if(isAuthError)
        return;
    
    if(isError)
    {
        self.myGroupLabel.hidden = YES;
        [self enableAllControls];
        [self setupAllScrollView];
        return;
    }

    BOOL hasGroup = FALSE;
    if (result != nil)
    {
        NSMutableArray * mArr = [result mutableCopy];
        if([mArr count] !=0)
        {
            //construct the table view.
            NSDictionary * all = [[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:-1] , @"groupId", @"All", @"groupName", nil];
            userGroupListData = [[NSMutableArray alloc]init];
            [userGroupListData addObject:all];
            [userGroupListData addObjectsFromArray:mArr];
            hasGroupsFromServer = TRUE;
            //update db.
            NSMutableArray *groupArr = [[NSMutableArray alloc]init];
            NSDictionary * newDict;
            for(NSDictionary * groupDetails in mArr)
            {
                newDict = [[NSDictionary alloc]initWithObjectsAndKeys: [groupDetails objectForKey:@"groupId"],@"id",
                                                                               [groupDetails objectForKey:@"groupName"], @"name",
                                                                                nil];
                [groupArr addObject:newDict];
//                newDict = nil;
            }
        
            [UserGroupManager addOrUpdateUserGroups:groupArr];
            hasGroup = TRUE;
        }
    }
    if(hasGroup)
    {
        self.userGroupTableView.hidden = NO;
        self.userGroupTableView.delaysContentTouches = NO;
        self.myGroupLabel.hidden = NO;
        self.groupImageView.hidden = NO;
        self.parentScrollView.scrollEnabled = YES;
        self.parentScrollView.contentSize = CGSizeMake(self.parentScrollView.contentSize.width, 1007.0F);
        self.parentScrollView.frame = CGRectMake(self.parentScrollView.frame.origin.x, self.parentScrollView.frame.origin.y, self.parentScrollView.frame.size.width, 717);
    }
    else
    {
        self.userGroupTableView.hidden = YES;
        self.myGroupLabel.hidden = YES;
        self.groupImageView.hidden = YES;
        self.parentScrollView.scrollEnabled = YES;
        self.parentScrollView.contentSize = CGSizeMake(self.parentScrollView.contentSize.width, 780.0F);
        self.parentScrollView.frame = CGRectMake(self.parentScrollView.frame.origin.x, self.parentScrollView.frame.origin.y, self.parentScrollView.frame.size.width, 680);
    }
    //check if it needs to get pending book.
    NSString * idString = @"";
    for(Book * book in self.loginUser.book)
    {
        int idxI =1;
        if ([book.approvalStatus intValue] == BookApprovalStatusPending)
        {
            idString = (idxI == [self.loginUser.book count] ? [idString stringByAppendingFormat:@"%d", [book.remoteId intValue]]: [idString stringByAppendingFormat:@"%d,", [book.remoteId intValue]]);
            idxI ++ ;
        }
    }

    if(idString !=nil && ![idString isEqualToString:@""])
    {
        [self sendUpdatesForPendingBookRequestToServer:idString];
    }
    else
    {
        [self initializeBookLists];
    }
}

- (void) sendUpdatesForPendingBookRequestToServer:(NSString *)idString
{
    if(pendingBookConnection != nil)
        return;
        
    // First download IDs of books that need to be downloaded.
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH,URL_GET_MY_BOOK_STATUS_FOR_PENDING_APPROVAL, idString]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    httpResponsePendingBookData = [[NSMutableData alloc] initWithLength:10];
    [pendingBookConnection cancel];
    pendingBookConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_UPDATE_BOOK_FOR_PENDING_APPROVAL];
    return;
}

- (void) processPendingBookResponseData
{
    BOOL isAuthError = NO;
    BOOL isError = NO;
     
    id result = [self processResponseData:httpResponsePendingBookData withErrorMessageTitle:NSLocalizedString(@"An error occur when retrieving updates for pending book.", @"Error Message when fail to retrieve pending book updates.")  indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    if(isAuthError)
        return;
    
    if(isError)
    {
        [self enableAllControls];
        [self setupAllScrollView];
        return;
    }

    if(result !=nil)
    {
        NSDictionary *pendingBooksData = (NSDictionary *)result;
        if ([pendingBooksData count]!=0)
        {
            [BookManager updateBookPendingStatus:pendingBooksData];
        }
    }
    [self initializeBookLists];
}
// ======================================================================================================================================
// Submit delete book data
- (void) sendDeleteBookRequestToServer
{
    if (deleteBookConnection != nil)
        return;
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_DELETE_BOOK]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    
    NSData * json = [BookManager jsonBookRepresentation:bookToBeDeleted];
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    httpResponseDeleteBookData = [[NSMutableData alloc] initWithLength:10];
    [deleteBookConnection cancel];
    
    deleteBookConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_DELETE_BOOK];
}

// ======================================================================================================================================
// process delete book response from the server
- (void) processDeleteBookResponseData
{
    BOOL isAuthError = NO;
    BOOL isError = NO;
    
    id result = [self processResponseData:httpResponseDeleteBookData withErrorMessageTitle:NSLocalizedString(@"Cannot delete book.", @"Error Message when fail to delete book on the server.") indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    if(isAuthError)
        return;
    
    if(result !=nil && (NSNumber *)result  == [NSNumber numberWithInt:0])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Book does not exists", @"Book does not exists.") message:NSLocalizedString(@"Book does not exists", @"Book does not exists.") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
    }
    
    [self removeDeletedBook];
    [self enableAllControls];
}

// ======================================================================================================================================
// Process server initial response
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_GET_MY_USERGROUP:
            [httpResponseUserGroupData setLength:0];
            break;
        case CONNECTION_DELETE_BOOK:
            [httpResponseDeleteBookData setLength:0];
            break;
        case CONNECTION_UPDATE_BOOK_FOR_PENDING_APPROVAL:
            [httpResponsePendingBookData setLength:0];
            break;
        default:
            break;
    }
}
// ======================================================================================================================================
// Process incoming data
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_GET_MY_USERGROUP:
            [httpResponseUserGroupData appendData:data];
            break;
        case CONNECTION_DELETE_BOOK:
            [httpResponseDeleteBookData appendData:data];
            break;
        case CONNECTION_UPDATE_BOOK_FOR_PENDING_APPROVAL:
            [httpResponsePendingBookData appendData:data];
            break;
        default:
            break;
    }
}
// ======================================================================================================================================
// Process connection error
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    deleteBookConnection = nil;
    pendingBookConnection = nil;
    userGroupConnection = nil;
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    
    [self enableAllControls];
    [self setupAllScrollView];
}

// ======================================================================================================================================
// Do something with received data
- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_GET_MY_USERGROUP:
            [self processUserGroupsResponseData];
            break;
        case CONNECTION_DELETE_BOOK:
            [self processDeleteBookResponseData];
            break;
        case CONNECTION_UPDATE_BOOK_FOR_PENDING_APPROVAL:
            [self processPendingBookResponseData];
            break;
        default:
            break;
    }
    deleteBookConnection = nil;
    pendingBookConnection = nil;
    userGroupConnection = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

// ======================================================================================================================================
// Receive my library books from the DownloadManager
- (void)downloadCompletedSuccessfullyWithReturnedData:(NSDictionary *)responseData withManager:(id)manager
{
    MY_BOOKS            = [responseData objectForKey:@"myBook"];
    MY_FAVOURITE_BOOKS  = [responseData objectForKey:@"myFavourite"];
    NSArray *groupBookArr = [responseData objectForKey:@"allBooksInGroups"];
    
    if(groupBookArr != nil)
    {
    //update existing book's group.
    for(NSDictionary * groupBookDic in groupBookArr)
    {
        if(groupBookDic != nil)
        {
            for(NSString * key in [groupBookDic allKeys])
            {
                UserGroups *ug = [UserGroupManager getUserGroupByRemoteId:[key intValue]];
                if(ug != nil)
                {
                    Book *cbook = [BookManager getBookByRemoteId:[[groupBookDic objectForKey:key] intValue]];
                    if(cbook != nil)
                    {
                        cbook.userGroup = ug;
                        [BookManager saveBook:cbook];
                    }
                }
            }
        }
        }
    }
    for(Book *book in MY_FAVOURITE_BOOKS)
    {
        book.likedBy = self.loginUser;
        [BookManager saveBook:book];
    }
    
    if([responseData objectForKey:@"myGroup"] == nil || [[responseData objectForKey:@"myGroup"] count]==0)
    {
        hasGroupBooksFromServer = FALSE;
    }
    else
    {
        hasGroupBooksFromServer = TRUE;
        MY_GROUP_BOOKS      = [responseData objectForKey:@"myGroup"];
    }
    
    [self enableAllControls];
    [self setupAllScrollView];
    // update time when last fetch happened
    RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [[NSDate date] dateByAddingTimeInterval:REFRESH_FREQUENCY_IN_SECONDS];      // set the time of the next fetch request
}

// ======================================================================================================================================
// Respond to network failure
-(void)downloadFailed:(id)manager
{
    RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    [self enableAllControls];
    [self setupAllScrollView];
}


// ======================================================================================================================================
-(void)bookItemTouchUpInsideEventHandler:(id)sender
{
    CellInBookScrollView * cell = (CellInBookScrollView*)sender;
    Book * bookInCell = [cell getCurrentBook];
    if (bookInCell.isDownloaded == [NSNumber numberWithBool:TRUE])   // if this book is already downoading, then don't allow to preview it anymore.
        return;
    
    BookPreviewViewController * preview = [self.storyboard instantiateViewControllerWithIdentifier:@"Book Preview View Controller"];
    preview.book = bookInCell;
    preview.delegate = self;
    
    preview.modalPresentationStyle = UIModalPresentationPageSheet;
    preview.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:preview animated:YES completion:^{}];

//    [self presentModalViewController:preview animated:YES];
}

// ======================================================================================================================================
// close the view
- (IBAction)closeView:(id)sender
{
    [_downloadManager cancelPreviewDownload];
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
}

// ======================================================================================================================================
// restart scroll view's sctivity indicators when view shown after transition.
-(void)transitionAnimationFinished
{
    [self.myBooksScrollView reinitializeAfterViewAnimation];
    [self.myFavouriteBooksScrollView reinitializeAfterViewAnimation];
    [self.myGroupBooksScrollView reinitializeAfterViewAnimation];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark BookPreviewViewControllerDelegate methods

-(void)downloadRequestedForBook:(Book *)book
{
    _lastCellClicked.isDownloading = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.bookDownloadManager downloadBook:book delegate:_lastCellClicked];
}

#pragma mark LoginViewControllerDelegate Implementation

// Login view finished the login process and the user was logged in successfully.
-(void) loginFinishedWithSuccess
{
    self.loginUser = [LoginRegistrationManager getLoginUser];
    didLoad = TRUE;
    [self setup];
}

// Login view's cancel button was clicked. Login was unsuccessful
-(void) loginCancelled
{
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}
@end