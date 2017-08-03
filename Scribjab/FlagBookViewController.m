//
//  FlagBookViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-02.
//
//

#import "FlagBookViewController.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "LoginRegistrationManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface FlagBookViewController () <NSURLConnectionDelegate>
{
    NSURLConnection * _connection;
    NSMutableData * _httpResponseData;
}
-(void) initialize;
-(void) processHttpData;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation FlagBookViewController

@synthesize book = _book;
@synthesize delegate;

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
    [self initialize];
    
    // --- Send Google Analytics Data ----------
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Flag Book Screen", [self class]];
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
    [self setCommentText:nil];
    [self setFlagButton:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
// ======================================================================================================================================
-(void)initialize
{
    [self.activityIndicator stopAnimating];
}

// ======================================================================================================================================
- (IBAction)flagClicked:(id)sender
{
    if (_connection != nil)
        return;
    
    NSString * flagText = [self.commentText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.commentText.text.length == 0)
    {
        NSString * errorTitle   = NSLocalizedString(@"Flagging Error", @"Error message box title.");
        NSString * errorBody    = NSLocalizedString(@"Please enter the reason for your flag", @"Ask user to describe why they are flagging a book.");
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    [self.activityIndicator startAnimating];
    _httpResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    
    // Start download connection
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH, URL_FLAG_BOOK, _book.remoteId]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
        
    [URLRequestUtilities setJSONData:[flagText dataUsingEncoding:NSUTF8StringEncoding] ToURLRequest:request];
    [request setHTTPMethod:@"POST"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}
// ======================================================================================================================================
- (IBAction)cancelClicked:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(bookFlaggingCancelled)])
        [delegate bookFlaggingCancelled];
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

// ======================================================================================================================================
// Process data received from the server
-(void) processHttpData
{
    NSString * errorTitle = NSLocalizedString(@"Book flagging failed", @"Error title: Cannot flag book");

    BOOL isAuthError = NO;
    BOOL isError = NO;
    
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    responseData = nil;
    // if login reuired - exit and display login prompt
    if (isAuthError)
    {
        [LoginRegistrationManager logout];
        [self dismissViewControllerAnimated:NO completion:^{
            if ([self.delegate respondsToSelector:@selector(bookFlaggingErrorLoginRequired)])
                [self.delegate bookFlaggingErrorLoginRequired];
        }];
    }
    
    if (isError)
    {
        return;
        _connection = nil;
    }
    
    // No errors - notify delegate of success
    if ([self.delegate respondsToSelector:@selector(bookFlagAdded)])
        [self.delegate bookFlagAdded];
    
    
    // ---- Google analytics ---
    // May return nil if a tracker has not already been initialized with a property ID.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book"    // Event category (required)
                                                          action:@"flag_book"  // Event action (required)
                                                           label:[NSString stringWithFormat:@"Book ID = %@", self.book.remoteId.stringValue]  // Event label
                                                           value:nil] build]];      // Event value
    // ---- END Google analytics ---
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_httpResponseData setLength:0];
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_httpResponseData appendData:data];
}

// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_httpResponseData setLength:0];
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    [self.activityIndicator stopAnimating];
    _connection = nil;
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self processHttpData];
    _connection = nil;
    [self.activityIndicator stopAnimating];
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}
@end
