//
//  MainViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "LoginRegistrationManager.h"
#import "DocumentHandler.h"
#import "LoginViewControllerDelegate.h"
#import "NavigationManager.h"
#import "BrowseBooksViewController.h"
#import "UserManager.h"
#import "NSURLConnectionWithID.h"
#import "Globals.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "LanguageManager.h"
#import "BookManager.h"
#import "UserManager.h"
#import "Utilities.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

static NSString * const INITIAL_DATA_LOADED_USER_DEFAULTS_KEY = @"Scribjab-Initialized-With-Server-On-First-Launch";
static NSString * const GOOGLE_ANALYTICS_CONCENT_FORM_SHOWN_KEY = @"Scribjab-GA-Concent-Received";
static NSDate *         LANGUAGES_LAST_REFRESH_DATE = nil;  //[NSDate distantPast];

//static NSString * const MY_LIBRARY_ICON = @"browse_menu_library.png";
//static NSString * const MY_LOGIN_ICON = @"library_menu_login.png";

static int const CONNECTION_LANGUAGE_GET_ALL = 1;
static int const CONNECTION_CHECK_LOGIN = 2;
static int const CONNECTION_LANGUAGE_REFRESH = 3;


@interface MainViewController () <LoginViewControllerDelegate, NSURLConnectionDelegate, DocumentHandlerDelegate, UIAlertViewDelegate>
{
    BOOL _loaded;
    // for initial load
    NSURLConnectionWithID * _connection;
    NSMutableData * _httpData;
    BOOL goToCreateBook;
}
-(void) loadInitialDataFromServer;                  // This method should execute only once, when application is first launched
-(void) checkLoginStatusOnServer;                   // make a authenticated request to the server and check if the server asks for credentials.
-(void) toggleLoginButtons:(BOOL)isLoggedIn;        // changes the state, background, and visibility of login/logout/my library buttons based on authentication status
-(void) hideOverlayAndInitializeGoogleAnalytics;    // Hides overlays after the initial data loading process finished (weather successfully or not)
-(void) sendDataToGoogleAnalytics;                  // Sends data to GA
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation MainViewController

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

  //  [self.overlayView setHidden:YES];
  //  [self.logoutButton setHidden:YES];
  
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.overlayView.frame = CGRectMake(0.0F, 0.0F, self.view.bounds.size.width, self.view.bounds.size.height );
    [self.overlayView setHidden:NO];
    [self.activityIndicator startAnimating];
    
    [NavigationManager setHomeViewController:self];
}

- (void)viewDidUnload
{
    [self setOverlayView:nil];
    [self setActivityIndicator:nil];
    [self setLoginButton:nil];
    [self setLogoutButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidAppear:(BOOL)animated
{
    if (_loaded)
    {
        if ([LoginRegistrationManager getLoginUser] != nil)
        {
            [self toggleLoginButtons:YES];
//            [self.loginButton setSelected:YES]; // my library
//            [self.logoutButton setHidden:NO];
        }
        else
        {
            [self toggleLoginButtons:NO];
//            [self.loginButton setSelected:NO]; 
//            [self.logoutButton setHidden:YES];
        }
    }
}

// ============================================================================================================================================================
// Hides overlays after the initial data loading process finished (weather successfully or not).
// Initializes and possibly sends data Google Analytics (if the user has concented)
-(void) hideOverlayAndInitializeGoogleAnalytics
{
    [self.overlayView setHidden:YES];
    [self.activityIndicator stopAnimating];
    
    // Show user concent form for Google Analytics?
    NSNumber * isConcented = [[NSUserDefaults standardUserDefaults] objectForKey:GOOGLE_ANALYTICS_CONCENT_FORM_SHOWN_KEY];
    
    // If already concented - then don't show the message box
    if (isConcented != nil && isConcented.boolValue)
    {
        [[GAI sharedInstance] setOptOut:NO];
        [self sendDataToGoogleAnalytics];
        return;
    }
    
    // Get user's concent to use google analytics
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Statistics",@"Google Analytics Concent Title")
                                                     message:NSLocalizedString(@"To improve this app, Scribjab would like to collect the following anonymous data about your usage through google analytics: \n- crash reports\n- books viewed\n- your location", @"Google Analytics Concent text")
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"No, I Don't Agree", @"Refuse to give concent")
                                           otherButtonTitles:NSLocalizedString(@"Yes, I Agree", @"Agree to give concent"),  nil];
    [alert show];
}

// ===========================================================================================================================================
// Handle user password input and proceed with saving/deleting user account info.

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Cancel clicked?
    if (buttonIndex == 0)
    {
        [[GAI sharedInstance] setOptOut:YES];
        return;
    }
    
    // Agree clicked
    
    [[GAI sharedInstance] setOptOut:NO];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:GOOGLE_ANALYTICS_CONCENT_FORM_SHOWN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self sendDataToGoogleAnalytics];
}

// ===========================================================================================================================================
// Sends data to GA
-(void) sendDataToGoogleAnalytics
{
    [[GAI sharedInstance] setDryRun:GOOGLE_ANALYTICS_DRY_RUN];
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Home Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

// ============================================================================================================================================================
// Open ProductTour storyboard
- (IBAction)takeTourButtonTouched:(id)sender 
{
    [NavigationManager navigateToAbout];
    [NavigationManager navigateToAboutAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];

//    NSURL * url = [NSURL URLWithString:@"http://www.scribjab.com/"];
//    [FBDialogs presentShareDialogWithLink:url
//                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                      if (error)
//                                      {
//                                          NSLog(@"error: %@", error.description);
//                                      }
//                                      else
//                                      {
//                                          NSLog(@"success");
//                                      }
//                                          
//    }];

    
//    [FBDialogs presentShareDialogWithLink:url
//                                     name:@"The name of the book"
//                                  caption:@"Caption of the share"
//                              description:@"The description <a href=\"http://www.sfu.ca\">SFU</a>, http://www.sfu.ca"
//                                  picture:[NSURL URLWithString:@"http://scribjab.com/static/images/tour_chr.png"]
//                              clientState:nil
//                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
//                                      if (error)
//                                      {
//                                          NSLog(@"error: %@", error.description);
//                                      }
//                                      else
//                                      {
//                                          NSLog(@"success");
//                                      }
//                                  }];
}

// ============================================================================================================================================================
// Open Create Book storyboard. Has to login
- (IBAction)showCreateBook:(id)sender
{
    //check if login, if yes, go to create book.
    User * currentUser = [LoginRegistrationManager getLoginUser];
    
    if(currentUser != nil)
    {
        //if login, just go to create book.
     //  [NavigationManager navigateToCreateBookForUser:currentUser animated:YES modalTransitionStyle:UIModalTransitionStyleCrossDissolve];

//        [NavigationManager navigateToMyLibraryForUser:currentUser animatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
        [NavigationManager navigateToCreateBookForUser:currentUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut isFromHome:YES];
    }
    else
    {
        goToCreateBook = YES;
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
    }
}


// ============================================================================================================================================================
// Open MyLibrary storyboard. Has to login
- (IBAction)showMyLibrary:(id)sender
{
    //check if login, if yes, go to library.
    User * currentUser = [LoginRegistrationManager getLoginUser];
    
    if(currentUser != nil)
    {
        //if login, just go to mylibrary.
        [NavigationManager navigateToMyLibraryForUser:currentUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
    }
    else
    {
        goToCreateBook = NO;
        [LoginRegistrationManager showLoginWithParent:self delegate:self registrationButton:YES];
    }
}

// ============================================================================================================================================================
// Open My Library storyboard when login is successful
- (void)loginFinishedWithSuccess
{
    if(goToCreateBook)
    {
        User * currentUser = [LoginRegistrationManager getLoginUser];
        [NavigationManager navigateToMyLibraryForUser:currentUser animatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
        [NavigationManager navigateToCreateBookForUser:currentUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut isFromHome:YES];

    }
    else
        [NavigationManager navigateToMyLibraryForUser:[LoginRegistrationManager getLoginUser] animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

// ============================================================================================================================================================
// Open Book Browser storyboard
- (IBAction)showBookNavigationAndSearch:(id)sender 
{
    [NavigationManager navigateToBrowseBooksAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
}

// ============================================================================================================================================================
- (IBAction)logout:(id)sender
{
    [LoginRegistrationManager logout];
//    [self.loginButton setSelected:NO];
//    [self.logoutButton setHidden:YES];
    
    [self toggleLoginButtons:NO];
}

// ============================================================================================================================================================
// changes the state, background, and visibility of login/logout/my library buttons based on authentication status
-(void) toggleLoginButtons:(BOOL)isLoggedIn
{
    if (isLoggedIn)
    {
        [self.loginButton setSelected:YES]; // my library icon
        [self.loginButton setBackgroundImage:[UIImage imageNamed:@"browse_menu_library.png"] forState:UIControlStateHighlighted];
        [self.logoutButton setHidden:NO];
    }
    else
    {
        [self.loginButton setSelected:NO];  // Login icon
        [self.loginButton setBackgroundImage:[UIImage imageNamed:@"library_menu_login.png"] forState:UIControlStateHighlighted];
        [self.logoutButton setHidden:YES];
    }
}

// ============================================================================================================================================================
// ============================================================================================================================================================
// ============================================================================================================================================================

#pragma-mark DocumentHandlerDelegate Methods

-(void)documentLoadedAndIsReady:(BOOL)ready
{
    User * loginUser = [LoginRegistrationManager getLoginUser];
    
    if (loginUser != nil)
    {
        [self toggleLoginButtons:YES];
//        [self.loginButton setSelected:YES]; // my library
//        [self.logoutButton setHidden:NO];
    }
    else
    {
        [self toggleLoginButtons:NO];
//        [self.loginButton setSelected:NO];
//        [self.logoutButton setHidden:YES];
    }
    _loaded = YES;
    
    NSNumber * isInitialized = [[NSUserDefaults standardUserDefaults] objectForKey:INITIAL_DATA_LOADED_USER_DEFAULTS_KEY];
    
    // If already initialized - just start using the app
    if (isInitialized != nil && isInitialized.boolValue)
    {
        if (loginUser == nil)
        {
            [self hideOverlayAndInitializeGoogleAnalytics];
        }
        else
        {
            [self checkLoginStatusOnServer];
        }
    }
    else
    {
        [self loadInitialDataFromServer];
    }
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Initial Application Data Retrieval

// ======================================================================================================================================
// make a authenticated request to the server and check if the server asks for credentials.
// This will tell if the user is logged in or not. 
-(void) checkLoginStatusOnServer
{
    if (_connection != nil)
        return;
    
    _httpData = [[NSMutableData alloc] initWithLength:1024];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_CHECK_LOGIN]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_CHECK_LOGIN];
}

// ======================================================================================================================================
// This method will download all necesssary languages and update them in core data if necessary.
- (void) refreshLanguages
{
    if (!_loaded)
        return;

    // Initialize LAST DATE to a time in the past
    if (LANGUAGES_LAST_REFRESH_DATE == nil)
        LANGUAGES_LAST_REFRESH_DATE = [NSDate distantPast];
    
    // if it is not time to refresh yet
    if ([LANGUAGES_LAST_REFRESH_DATE compare:[NSDate date]] == NSOrderedDescending)
        return;
    
    NSNumber * isInitialized = [[NSUserDefaults standardUserDefaults] objectForKey:INITIAL_DATA_LOADED_USER_DEFAULTS_KEY];
    
    // if first time execution - don't run this method.
    if (isInitialized == nil || !isInitialized.boolValue)
        return;
    
    if (_connection != nil)
        return;

    _httpData = [[NSMutableData alloc] initWithLength:1024];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_LANGUAGE_GET_ALL]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_LANGUAGE_REFRESH];
}

// Process responce data - update languages in core data
- (void) processLanguageRefreshResponseData
{
    // do something with the json that comes back
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:_httpData options:kNilOptions error:&error];
    if (error != NULL)
    {   return;     }
    
    NSArray * langData = [responseDictionary objectForKey:@"result"];
    if (langData != nil)
    {
        [LanguageManager addOrUpdateLanguages:langData];
    }
    
    LANGUAGES_LAST_REFRESH_DATE = [[NSDate date] dateByAddingTimeInterval:60*LANGUAGE_REFRESH_FREQUENCY_IN_MINUTES];      // set the time of the next language refresh
}

// ======================================================================================================================================
// This method should execute only once, when application is first launched.
// This method will download all necesssary initial information, like Languages.
-(void) loadInitialDataFromServer
{
    // Initialize LAST DATE to a time in the past
    if (LANGUAGES_LAST_REFRESH_DATE == nil)
        LANGUAGES_LAST_REFRESH_DATE = [NSDate distantPast];
    
    if (_connection != nil)
        return;
    
    _httpData = [[NSMutableData alloc] initWithLength:1024];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_LANGUAGE_GET_ALL]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_LANGUAGE_GET_ALL];
    
    // -------
    // Create book and user storage directories and exclude them from iCloud backup
    NSString * bookPath = [BookManager getBookStorageAbsPath];
    NSString * userPath = [UserManager getUserStorageAbsolutePath];
    NSURL * pathUrl = nil;
    NSError * error = nil;
    BOOL success;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:bookPath])
    {
        pathUrl = [NSURL fileURLWithPath:bookPath];

        success = [[NSFileManager defaultManager] createDirectoryAtURL:pathUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if(!success)
        {
            #ifdef DEBUG
            NSLog(@"book path error %@", error);
            #endif
        }
        else
        {
            [Utilities excludeFromBackupItemAtURL:pathUrl];
        }
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:userPath])
    {
        pathUrl = [NSURL fileURLWithPath:userPath];
        
        success = [[NSFileManager defaultManager] createDirectoryAtURL:pathUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if(!success)
        {
            #ifdef DEBUG
            NSLog(@"usr path error %@", error);
            #endif
        }
        else
        {
            [Utilities excludeFromBackupItemAtURL:pathUrl];
        }
    }
}

// ======================================================================================================================================
//process language response data
-(void) processLanguageResponseData
{
    // do something with the json that comes back
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:_httpData options:kNilOptions error:&error];
    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return;
    }
    
    NSArray * langData = [responseDictionary objectForKey:@"result"];
    if (langData != nil)
    {
        [LanguageManager addOrUpdateLanguages:langData];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:INITIAL_DATA_LOADED_USER_DEFAULTS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    LANGUAGES_LAST_REFRESH_DATE = [[NSDate date] dateByAddingTimeInterval:60*LANGUAGE_REFRESH_FREQUENCY_IN_MINUTES];      // set the time of the next language refresh
}

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
    if (((NSURLConnectionWithID*)connection).identification != CONNECTION_LANGUAGE_REFRESH)
        [self hideOverlayAndInitializeGoogleAnalytics];
    
    _connection = nil;
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_LANGUAGE_GET_ALL:
            [self processLanguageResponseData];
            break;
        case CONNECTION_LANGUAGE_REFRESH:
            [self processLanguageRefreshResponseData];
        default:
            break;
    }
    
    if (((NSURLConnectionWithID*)connection).identification != CONNECTION_LANGUAGE_REFRESH)
        [self hideOverlayAndInitializeGoogleAnalytics];
    
    _connection = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

// ======================================================================================================================================
// If authentication challenge is received, then user is not logged in
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [_connection cancel];
    _connection = nil;

    [self toggleLoginButtons:NO];
//    [self.loginButton setSelected:NO];
//    [self.logoutButton setHidden:YES];
    
    [LoginRegistrationManager logout];
    
    if (((NSURLConnectionWithID*)connection).identification != CONNECTION_LANGUAGE_REFRESH)
        [self hideOverlayAndInitializeGoogleAnalytics];
}

@end
