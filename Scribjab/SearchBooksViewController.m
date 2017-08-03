//
//  SearchBooksViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-09.
//
//

#import "SearchBooksViewController.h"
#import "NavigationManager.h"
#import "BookThumbnailButton.h"
#import "SearchInputViewController.h"
#import "CommonMessageBoxes.h"
#import "URLRequestUtilities.h"
#import "Globals.h"
#import "BookPreviewViewController.h"
#import "AppDelegate.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static int const BATCH_SIZE = 20;

@interface SearchBooksViewController () <SearchInputViewControllerDelegate, NSURLConnectionDelegate, DownloadManagerDelegate, BookPreviewViewControllerDelegate, UIScrollViewDelegate>
{
    DownloadManager * _downloadBookPreviewManager;
    BookThumbnailButton * _lastButtonClicked;               // used for download progress
    NSMutableDictionary * _downloadingBooksAndThumbnails;   // to keep track of which books are currently downloading in order to prevet dowble downloads of the same book.
    
    int _loginAction;   // what to do after login finishes
    
    NSURLConnection * _connection;
    NSMutableData * _httpData;
    
    NSMutableArray * _searchResults;
    BOOL _isDownloadingPreviews;
    
    NSString * NOTHING_FOUND_LABEL;
}
- (void) downloadNextBookPreviewBatch;
- (void) bookItemTouchUpInsideEventHandler:(BookThumbnailButton *)sender;
- (void) bookItemDownloadValueChanged:(BookThumbnailButton *)sender;

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation SearchBooksViewController

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
    self.searchResultScrollView.delegate = self;
    _downloadingBooksAndThumbnails = [[NSMutableDictionary alloc] initWithCapacity:5];
    NOTHING_FOUND_LABEL = NSLocalizedString(@"Nothing Found", @"This is to notify users that their search for books did not return any result.");
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Search Books Screen", [self class]];
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

// ======================================================================================================================================
- (IBAction)navigateToBrowseSection:(id)sender
{
    //[NavigationManager navigateToBrowseBooksAnimatedWithDuration:0.75F transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
    [self.navigationController popViewControllerAnimated:YES];
}

// ======================================================================================================================================
// Close and Go to main view
- (IBAction)navigateToHomeView:(id)sender;
{
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75F transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
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
// Initiate the search
- (void) searchForBooksWithGroupId:(NSNumber*)groupId firstLanguageId:(NSNumber*)firstLanguageId secondLanguageId:(NSNumber*)secondLanguageId keywords:(NSString *) keywords
{
    if (_connection != nil)
        return;
    
    [self.searchLabel setHidden:YES];
    [self.noResultsLabel setHidden:YES];
    
    _httpData = [[NSMutableData alloc] initWithCapacity:1024];
    [self.searchResultScrollView removeAllSubviews];
    [self.searchResultScrollView showActivityIndicator];

    NSNumber * zero = [NSNumber numberWithInt:0];
    
    if (groupId == nil)
        groupId = zero;
    
    if (firstLanguageId == nil)
        firstLanguageId = zero;
    
    if (secondLanguageId == nil)
        secondLanguageId = zero;
    
    keywords = [keywords stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (keywords.length == 0)
        keywords = @"~~~";              // code for "empty string".
    
    NSDictionary * body = [[NSDictionary alloc] initWithObjectsAndKeys:groupId, @"ageGroupId", firstLanguageId, @"firstLanguageId", secondLanguageId, @"secondLanguageId", keywords, @"keywords", nil];
    
    // Download search results - book IDs
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_SEARCH_BOOKS]];

    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    [request setHTTPMethod:@"POST"];
    
    [URLRequestUtilities setJSONData:[NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:NULL] ToURLRequest:request];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// ======================================================================================================================================
// Download book previews from the private list variable
-(void)downloadNextBookPreviewBatch
{
    if (_isDownloadingPreviews)
        return;
    if (_searchResults.count == 0)
    {
        [self.searchResultScrollView hideActivityIndicator];
        return;
    }
    
    _isDownloadingPreviews = YES;
    [self.searchResultScrollView showActivityIndicator];
    
    // -----
    // Download BATCH_SIZE book previews
    
    if (_downloadBookPreviewManager == nil)
    {
        _downloadBookPreviewManager = [[DownloadManager alloc] init];
    }
    
    // 1. Complile a set of IDs to process
    int i = 1;    
    NSMutableSet * bookIDs = [[NSMutableSet alloc] initWithCapacity:BATCH_SIZE];
    NSMutableSet * userIDs = [[NSMutableSet alloc] initWithCapacity:BATCH_SIZE];
    NSMutableSet * langIDs = [[NSMutableSet alloc] initWithCapacity:BATCH_SIZE];
    
    for (NSDictionary * dict in _searchResults)
    {
        if (i > BATCH_SIZE)
            break;

        [bookIDs addObject:[dict objectForKey:@"bookId"]];
        [userIDs addObject:[dict objectForKey:@"userId"]];
        [langIDs addObject:[dict objectForKey:@"firstLanguageId"]];
        [langIDs addObject:[dict objectForKey:@"secondLanguageId"]];
        
        i++;
    }
    
    _downloadBookPreviewManager.delegate = self;
    [_downloadBookPreviewManager downloadPreviewsForBookWithIDs:bookIDs authorIDs:userIDs languageIDs:langIDs];
}

// ======================================================================================================================================
// If book item is touched - open up either a preview or a downloaded book
-(void)bookItemTouchUpInsideEventHandler:(id)sender
{
    BookThumbnailButton * button = (BookThumbnailButton*)sender;
    
    // if this book is already downloading - show message
    if ([_downloadingBooksAndThumbnails objectForKey:button.book.objectID] != nil)
    {
        NSString * title = NSLocalizedString(@"Download in progress", @"Message box title. Notiy user that this book is currently being downloaded");
        NSString * body = NSLocalizedString(@"This book is being downloaded, please wait for download to complete.", @"Message box body. Notiy user that this book is currently being downloaded");
        NSString * OK = NSLocalizedString(@"OK", @"OK");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:body delegate:nil cancelButtonTitle:OK otherButtonTitles: nil];
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

-(void)bookItemDownloadValueChanged:(BookThumbnailButton *)sender
{
    // remember that this book is now downloading, or remove from the 'remember' list
    if (sender.isDownloading)
        [_downloadingBooksAndThumbnails setObject:sender forKey:sender.book.objectID];
    else
        [_downloadingBooksAndThumbnails removeObjectForKey:sender.book.objectID];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark DownloadManagerDelegate methods

-(void) downloadCompletedSuccessfullyWithReturnedData:(id)responseData withManager:(id)manager
{
    NSArray * books = responseData;
    
    // Insert Books to the scroll view
    for (Book * book in books)
    {
        BookThumbnailButton * button = [[BookThumbnailButton alloc] initWithBook:book];
        [button addTarget:self action:@selector(bookItemTouchUpInsideEventHandler:) forControlEvents:UIControlEventTouchUpInside];  // Add touch event
        [button addTarget:self action:@selector(bookItemDownloadValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.searchResultScrollView addSubview:button];
    }
    
    [_searchResults removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MIN(books.count, _searchResults.count))]];
    [self.searchResultScrollView hideActivityIndicator];
    _isDownloadingPreviews = NO;
}
-(void) downloadFailed:(id)manager
{
    [self.searchResultScrollView hideActivityIndicator];
    _isDownloadingPreviews = NO;
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark SearchInputViewControllerDelegate methods

-(void)searchCriteriaSelectedAgeGroupId:(NSNumber*)ageGroupId firstLanguage:(NSNumber*)firstLanguageId secondLanguage:(NSNumber*)secontLanguageId keywords:(NSString *)keywords searchSummary:(NSString *)searchSummary
{
    [self searchForBooksWithGroupId:ageGroupId firstLanguageId:firstLanguageId secondLanguageId:secontLanguageId keywords:keywords];
    self.searchLabel.text = searchSummary;
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

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
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    _connection = nil;
    [_httpData setLength:0];
    [self.searchResultScrollView hideActivityIndicator];
}

// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString * errorTitle = NSLocalizedString(@"Search Failed", @"Error title: Cannot perform search.");
    
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:nil];
    
    if (isError)
    {
        [self.searchResultScrollView hideActivityIndicator];
        _connection = nil;
        return;
    }
    
    // All OK - save array of results in a local variable and fetch the first 20 items
    _searchResults = [[NSMutableArray alloc] initWithArray:[responseData objectForKey:@"result"]];
    
    if (_searchResults.count == 0)
    {
        [self.searchResultScrollView hideActivityIndicator];
        [self.noResultsLabel setHidden:NO];
    }

    // download previews from the list
    [self downloadNextBookPreviewBatch];
    [self.searchLabel setHidden:NO];
    
    _connection = nil;
    _httpData = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
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
#pragma-mark UIScrollViewDelegate methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float bottomEdge = scrollView.contentOffset.y + scrollView.bounds.size.height;
    if (bottomEdge >= scrollView.contentSize.height - 50)
    {
        [self downloadNextBookPreviewBatch];
    }
    
}
- (void)viewDidUnload {
    [self setSearchLabel:nil];
    [self setNoResultsLabel:nil];
    [super viewDidUnload];
}
@end
