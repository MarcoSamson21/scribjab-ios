//
//  BrowseBooksViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//
#import "AppDelegate.h"
#import "Globals.h"
#import "BrowseBooksViewController.h"
#import "BookPreviewViewController.h"
#import "BookThumbnailButton.h"
#import "BookManager.h"
#import "SearchInputViewController.h"
#import "SearchBooksViewController.h"
#import "NSDate+Utils.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static const int SCROLL_CONTENT_HEIGHT = 1007.0F;

// **************************************************************************************************************************************
// Global storage for browse section
static NSArray * RECENTLY_ADDED_BOOKS                   =   nil;    // List of recently published books
static NSMutableArray * OTHER_BOOKS                     =   nil;    // List of all other books sorted by like count and shuffled
static NSDate * RECENT_BOOKS_LIST_LAST_REFRESH_DATE     =   nil;
static NSDate * NEXT_CLEANUP_DATE_BOOK_PREVIEWS         =   nil;    // once a day we should delete old previews to free up some space.
static NSDate * OTHER_BOOKS_LIST_LAST_REFRESH_DATE      =   nil;
static int OTHER_BOOKS_NEXT_INDEX                       =   0;
static int OTHER_BOOKS_BATCH_COUNT                      =   30;
static BOOL OTHER_BOOKS_ALL_LOADED                      =   NO;

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface BrowseBooksViewController () <DownloadManagerDelegate, BookPreviewViewControllerDelegate, SearchInputViewControllerDelegate, UIAlertViewDelegate, UIScrollViewDelegate>
{
    DownloadManager * _downloadRecentBookPreviewManager;
    DownloadManager * _downloadOtherBookPreviewManager;
    BookThumbnailButton * _lastButtonClicked;               // used for download progress
    NSMutableDictionary * _downloadingBooksAndThumbnails;   // to keep track of which books are currently downloading in order to prevet dowble downloads of the same book.
    
    int _loginAction;   // what to do after login finishes
}
- (void) initializeBookLists;
- (void) displayRecentAndDownloadedBooksInScrollViews;
- (void) displayOtherBooksInScrollView;
- (void) bookItemTouchUpInsideEventHandler:(BookThumbnailButton *)sender;
- (void) bookItemDownloadValueChanged:(BookThumbnailButton *)sender;
- (void) deleteBookFromDevice:(BookThumbnailButton *)sender;
- (void) cleanUpOldBookPreviews;
- (void) refreshBooksInScrollViews;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation BrowseBooksViewController

@synthesize recentlyPublishedScrollView;
@synthesize mostPopularScrollView;

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
    self.mostPopularScrollView.delegate = self;
    // Prepare parent scroll view
    self.parentScrollView.contentSize = CGSizeMake(self.parentScrollView.contentSize.width, SCROLL_CONTENT_HEIGHT);
    [self.parentScrollView setScrollEnabled:NO];
    [self.parentScrollView setContentOffset:CGPointMake(0.0F, self.downloadedBooksScrollView.frame.origin.y + self.downloadedBooksScrollView.frame.size.height)];
    _downloadingBooksAndThumbnails = [[NSMutableDictionary alloc] initWithCapacity:5];
    [super viewDidLoad];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Browse Books Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
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
    [self setRecentlyPublishedScrollView:nil];
    [self setMostPopularScrollView:nil];
    [self setParentScrollView:nil];
    [self setDownloadedBooksScrollView:nil];
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initializeBookLists];
}


// ======================================================================================================================================
// Determine with view is popped from the navigation stack
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

// ======================================================================================================================================
// Check if book lists should be refetched from the database.
// Refetch if needed and display book lists to the user.
-(void)initializeBookLists
{    
    // Initialize Download managers
    if (_downloadRecentBookPreviewManager == nil)
    {
        _downloadRecentBookPreviewManager = [[DownloadManager alloc] init];
        _downloadRecentBookPreviewManager.delegate = self;
    }
    
    if (_downloadOtherBookPreviewManager == nil)
    {
        _downloadOtherBookPreviewManager = [[DownloadManager alloc] init];
        _downloadOtherBookPreviewManager.delegate = self;
    }
    
    if (_downloadRecentBookPreviewManager.isDownloadingPreviews || _downloadOtherBookPreviewManager.isDownloadingPreviews)
        return;
    
    // Initialize LAST DATE to a time in the past
    if (RECENT_BOOKS_LIST_LAST_REFRESH_DATE == nil)
        RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    
    // Initialize LAST DATE to a time in the past
    if (OTHER_BOOKS_LIST_LAST_REFRESH_DATE == nil)
        OTHER_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    
    // -------------------- load recently published books
    
    // if it is not time to refresh yet, just show books from the static variable
    if ([RECENT_BOOKS_LIST_LAST_REFRESH_DATE compare:[NSDate date]] == NSOrderedDescending)       
    {
        [self displayRecentAndDownloadedBooksInScrollViews];
    }
    else    // Otherwise need to fetch new book sets from the server
    {
        [self.recentlyPublishedScrollView showActivityIndicator];
        [_downloadRecentBookPreviewManager downloadRecentlyPublishedBooks];
    }
    
    // -------------------- load other books
    
    // If it is a new date - reload the books from the website
    if ([NSDate daysBetweenDate:OTHER_BOOKS_LIST_LAST_REFRESH_DATE andDate:[NSDate date]] > 0)
    {
        OTHER_BOOKS_ALL_LOADED = NO;
        OTHER_BOOKS_NEXT_INDEX = 0;
        OTHER_BOOKS = nil;
        OTHER_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate date];
       
        // 1. show activity indicator
        [self.mostPopularScrollView showActivityIndicator];
        
        // 2. load books from the website
        [_downloadOtherBookPreviewManager downloadOtherBooksShuffledStartingAtIndex:OTHER_BOOKS_NEXT_INDEX maxNumberOfBooks:OTHER_BOOKS_BATCH_COUNT];
    }
    else
    {
        // display from cache
        [self displayOtherBooksInScrollView];
    }
}

// ======================================================================================================================================
// Attempt to download more books into the "more books" section when user scrolls to the end of the list
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat rightOffsetX = scrollView.contentSize.width - scrollView.bounds.size.width;
    
    if (scrollView.contentOffset.x >= rightOffsetX -30.0F)
    {
        if (OTHER_BOOKS_ALL_LOADED)
            return;
        
        if (_downloadOtherBookPreviewManager.isDownloadingPreviews)
            return;
        
        [self.mostPopularScrollView showLoadingMoreActivityIndicator];
        [_downloadOtherBookPreviewManager downloadOtherBooksShuffledStartingAtIndex:OTHER_BOOKS_NEXT_INDEX maxNumberOfBooks:OTHER_BOOKS_BATCH_COUNT];
    }
}

// ======================================================================================================================================
// Show books that were identified as most recent to the user.
// Books books must be fetched and stored in the local DB (core data).
- (void) displayRecentAndDownloadedBooksInScrollViews
{
    [self.recentlyPublishedScrollView removeAllSubviews];
    [self.downloadedBooksScrollView removeAllSubviews];
    
    // Show downloaded Books
    NSArray * downloadedBooks = [BookManager getDownloadedBooks];

    if (downloadedBooks != nil)
    {
        for (Book * book in downloadedBooks)
        {
            BookThumbnailButton * button = [[BookThumbnailButton alloc] initWithBook:book];
            button.canDelete = YES;
            [button addTarget:self action:@selector(bookItemTouchUpInsideEventHandler:) forControlEvents:UIControlEventTouchUpInside];  // Add touch event
            [self.downloadedBooksScrollView addSubview:button];
        }
    }
    
    if (RECENTLY_ADDED_BOOKS != nil)
    {
        for(Book * book in RECENTLY_ADDED_BOOKS)
        {
            BookThumbnailButton * button = [[BookThumbnailButton alloc] initWithBook:book];
            [button addTarget:self action:@selector(bookItemTouchUpInsideEventHandler:) forControlEvents:UIControlEventTouchUpInside];  // Add touch event
            [button addTarget:self action:@selector(bookItemDownloadValueChanged:) forControlEvents:UIControlEventValueChanged];
            [self.recentlyPublishedScrollView addSubview:button];
        }
    }
    
    // enable scrolling
    if ([downloadedBooks count] > 0 && !self.parentScrollView.isScrollEnabled)
    {
        [self.parentScrollView setScrollEnabled:YES];
        [self.parentScrollView setContentOffset:CGPointMake(0.0F, 0.0F) animated:NO];
    }

    // run cleanup, if it is time
    [self cleanUpOldBookPreviews];
    
    // run refresh, if it is time
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate refreshDataForDownloadedBooksAndLoginUser];
}

// ======================================================================================================================================
// Show all books in the 'other' section to the user.
// Books books must be fetched and stored in the local DB (core data).
- (void) displayOtherBooksInScrollView
{
    [self.mostPopularScrollView removeAllSubviews];
    
    if (OTHER_BOOKS != nil)
    {
        NSMutableArray * duplicates = [[NSMutableArray alloc] initWithCapacity:20];
        
        for(Book * book in OTHER_BOOKS)
        {
            if ([RECENTLY_ADDED_BOOKS containsObject:book])
            {
                [duplicates addObject:book];
                continue;
            }
            BookThumbnailButton * button = [[BookThumbnailButton alloc] initWithBook:book];
            [button addTarget:self action:@selector(bookItemTouchUpInsideEventHandler:) forControlEvents:UIControlEventTouchUpInside];  // Add touch event
            [button addTarget:self action:@selector(bookItemDownloadValueChanged:) forControlEvents:UIControlEventValueChanged];
            [self.mostPopularScrollView addSubview:button];
        }
        
        for (Book * book in duplicates)
        {
            [OTHER_BOOKS removeObject:book];
        }
    }
}

// ======================================================================================================================================
// Refresh all book buttons (visually) in scroll view for changes 
- (void) refreshBooksInScrollViews
{
    // find all other items with the same book and hide download icon.
    for (UIView * view in self.recentlyPublishedScrollView.subviews)
    {
        if ([view isKindOfClass:[BookThumbnailButton class]])
        {
            BookThumbnailButton * b = (BookThumbnailButton*)view;
            if (b.book.isDownloaded.boolValue)
                [b.downloadIcon setHidden:YES];
            else
                [b.downloadIcon setHidden:NO];
        }
    }
    // find all other items with the same book and hide download icon.
    for (UIView * view in self.mostPopularScrollView.subviews)
    {
        if ([view isKindOfClass:[BookThumbnailButton class]])
        {
            BookThumbnailButton * b = (BookThumbnailButton*)view;
            if (b.book.isDownloaded.boolValue)
                [b.downloadIcon setHidden:YES];
            else
                [b.downloadIcon setHidden:NO];
        }
    }
}
// ======================================================================================================================================
// Receive Most Popular and Recently added books from the DownloadManager
- (void)downloadCompletedSuccessfullyWithReturnedData:(NSDictionary *)responseData withManager:(id)manager
{
    if (manager == _downloadRecentBookPreviewManager)
    {
        [self.recentlyPublishedScrollView hideActivityIndicator];
         
        // populate panel
        RECENTLY_ADDED_BOOKS    = [responseData objectForKey:@"books"];
        
        [self displayRecentAndDownloadedBooksInScrollViews];
        
        // update time when last fetch happened
        RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [[NSDate date] dateByAddingTimeInterval:60*BROWSE_BOOK_REFRESH_FREQUENCY_IN_MINUTES];      // set the time of the next fetch request
    }
    
    if (manager == _downloadOtherBookPreviewManager)
    {
        [self.mostPopularScrollView hideActivityIndicator];
        
        // populate panel
        NSArray * books    = [responseData objectForKey:@"books"];
        
        if (OTHER_BOOKS == nil)
        {
            OTHER_BOOKS = [[NSMutableArray alloc] initWithArray:books];
        }
        else
        {
            [OTHER_BOOKS addObjectsFromArray:books];
        }
        
        OTHER_BOOKS_NEXT_INDEX += books.count;
        
        if (books.count < OTHER_BOOKS_BATCH_COUNT)
            OTHER_BOOKS_ALL_LOADED = YES;
        
        [self displayOtherBooksInScrollView];
    }
}

// ======================================================================================================================================
// Respond to network failure
-(void)downloadFailed:(id)manager
{ 
    if (manager == _downloadRecentBookPreviewManager)
    {
        [self.recentlyPublishedScrollView hideActivityIndicator];
        RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    }
    
    if (manager == _downloadOtherBookPreviewManager)
    {
        [self.mostPopularScrollView hideActivityIndicator];
        OTHER_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    }
}

// ======================================================================================================================================
-(void)bookItemTouchUpInsideEventHandler:(id)sender
{
    BookThumbnailButton * button = (BookThumbnailButton*)sender;
    
    // If delete event requested
    if (button.lastEvent == BookThumbnailButtonEventDelete)
    {
        [self deleteBookFromDevice:button];
        return;
    }
    
    // if this book is already downloading - show message
    if ([_downloadingBooksAndThumbnails objectForKey:button.book.objectID] != nil)
    {
        NSString * title = NSLocalizedString(@"Download in progress", @"Message box title. Notiy user that this book is currently being downloaded");
        NSString * body = NSLocalizedString(@"This book is being downloaded, please wait for download to complete.", @"Message box body. Notiy user that this book is currently being downloaded");
        NSString * ok = NSLocalizedString(@"OK", @"OK");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:ok otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    if (button.book.isDownloaded.boolValue)
    {
        [NavigationManager openReadBookViewController:button.book parentViewController:self];
        return;
    }
    
    _lastButtonClicked = button;
    
    BookPreviewViewController * preview = [self.storyboard instantiateViewControllerWithIdentifier:@"Book Preview View Controller"];
    preview.book = button.book;
    preview.delegate = self;

    preview.modalPresentationStyle = UIModalPresentationPageSheet;
    preview.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:preview animated:YES completion:^{}];
}

// ======================================================================================================================================
// Handle event when download finished.
- (void) bookItemDownloadValueChanged:(BookThumbnailButton *)sender
{
    // remember that this book is now downloading, or remove from the 'remember' list
    if (sender.isDownloading)
        [_downloadingBooksAndThumbnails setObject:sender forKey:sender.book.objectID];
    else
        [_downloadingBooksAndThumbnails removeObjectForKey:sender.book.objectID];
    
    // Create a new entry for this book in the "Downloaded Books" scroll view panel
    if (sender.book.isDownloaded.boolValue)
    {
        BookThumbnailButton * button = [[BookThumbnailButton alloc] initWithBook:sender.book];
        button.canDelete = YES;
        [button addTarget:self action:@selector(bookItemTouchUpInsideEventHandler:) forControlEvents:UIControlEventTouchUpInside];  // Add touch event
        [self.downloadedBooksScrollView prependSubview:button atIndex:0];
        
        // enable scrolling
        if (!self.parentScrollView.isScrollEnabled)
        {
            [self.parentScrollView setScrollEnabled:YES];
            [self.parentScrollView setContentOffset:CGPointMake(0.0F, 0.0F) animated:YES];
        }
    }
    
    [self refreshBooksInScrollViews];
    
    
    // ---- Google analytics ---
    
    if (sender.book.isDownloaded)
    {
        // May return nil if a tracker has not already been initialized with a property ID.
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book"    // Event category (required)
                                                              action:@"downloaded"  // Event action (required)
                                                               label:[NSString stringWithFormat:@"Book ID = %@", sender.book.remoteId.stringValue]  // Event label
                                                               value:nil] build]];      // Event value
    }
}

// ======================================================================================================================================
// Delete downloaded book form the device (remove all audio files and pages' images), but keep enough information for preview.
-(void)deleteBookFromDevice:(BookThumbnailButton *)sender
{
    NSString * title = NSLocalizedString(@"Delete Confirmation", @"Message box title: ask if user wants to delete book from iPad");
    NSString * body = NSLocalizedString(@"Do you want to delete this book from your iPad?", @"Message box body: ask if user wants to delete book from iPad");
    NSString * yes = NSLocalizedString(@"Yes", @"Message box button lable");
    NSString * no = NSLocalizedString(@"No", @"Message box button lable");
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:no otherButtonTitles:yes, nil];
    _lastButtonClicked = sender;
    alert.tag = -18;    // any number 
    [alert show];
}

//===========================
// #pragma alert view delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    Book * book = nil;
    
    // delete book alert.
    if (alertView.tag == -18 && buttonIndex == 1)       // Yes clicked
    {
        [BookManager deleteDownloadedBookButKeepPreview:_lastButtonClicked.book];
        book = _lastButtonClicked.book;
        [_lastButtonClicked removeFromSuperview];
        _lastButtonClicked = nil;
        
        if ([self.downloadedBooksScrollView.subviews count] == 0)
        {
            [self.parentScrollView setScrollEnabled:NO];
            [self.parentScrollView setContentOffset:CGPointMake(0.0F, /*self.downloadedBooksScrollView.frame.origin.y + */self.downloadedBooksScrollView.frame.size.height) animated:YES];
        }
        
        [self refreshBooksInScrollViews];
    }
    
    
    // ---- Google analytics ---
    
    if (book != nil)
    {
        // May return nil if a tracker has not already been initialized with a property ID.
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book"    // Event category (required)
                                                              action:@"deleted"  // Event action (required)
                                                               label:[NSString stringWithFormat:@"Book ID = %@", book.remoteId.stringValue]  // Event label
                                                               value:nil] build]];      // Event value
    }
}

// ======================================================================================================================================
// close the view
- (IBAction)navigateToHomeView:(id)sender
{
    [_downloadRecentBookPreviewManager cancelPreviewDownload];
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75F transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
}

// ======================================================================================================================================
// restart scroll view's sctivity indicators when view shown after transition.
-(void)transitionAnimationFinished
{
    [self.recentlyPublishedScrollView reinitializeAfterViewAnimation];
    [self.mostPopularScrollView reinitializeAfterViewAnimation];
}

// ======================================================================================================================================
// Delete old book previews
- (void) cleanUpOldBookPreviews
{
    if (NEXT_CLEANUP_DATE_BOOK_PREVIEWS == nil)
    {
        NEXT_CLEANUP_DATE_BOOK_PREVIEWS = [NSDate distantPast];
    }
    
    // if it is not time to refresh yet, just show books from the static variable
    if ([NEXT_CLEANUP_DATE_BOOK_PREVIEWS compare:[NSDate date]] == NSOrderedAscending)
    {
        NEXT_CLEANUP_DATE_BOOK_PREVIEWS = [[NSDate date] dateByAddingTimeInterval:60*60*24*1];      // set time to tomorrow        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [BookManager deleteBookPreviewsLastViewdBefore:[[NSDate date] dateByAddingTimeInterval:-60*60*24*BOOK_PREVIEW_LAST_ACCESS_AGE_FOR_CLEANUP_IN_DAYS]];
        });
    }
}

// ======================================================================================================================================
// Give search view controller pointer to popover controller, so that it can dismiss itself. 
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Search Input View Segue"])
    {
        ((SearchInputViewController *)segue.destinationViewController).parentPopover = [((UIStoryboardPopoverSegue*)segue) popoverController];
        ((SearchInputViewController *)segue.destinationViewController).delegate = self;
    }
}
// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark BookPreviewViewControllerDelegate methods

-(void)downloadRequestedForBook:(Book *)book
{
    _lastButtonClicked.isDownloading = YES;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.bookDownloadManager downloadBook:book delegate:_lastButtonClicked];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark SearchInputViewControllerDelegate methods

-(void)searchCriteriaSelectedAgeGroupId:(NSNumber*)ageGroupId firstLanguage:(NSNumber*)firstLanguageId secondLanguage:(NSNumber*)secontLanguageId keywords:(NSString *)keywords searchSummary:(NSString *)searchSummary
{
    SearchBooksViewController * vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Search Books View Controller"];
    [self.navigationController pushViewController:vc animated:YES];
    [vc searchForBooksWithGroupId:ageGroupId firstLanguageId:firstLanguageId secondLanguageId:secontLanguageId keywords:keywords];
    vc.searchLabel.text = searchSummary;
}

@end
