//
//  LoginViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "Utilities.h"
#import "URLRequestUtilities.h"
#import "LoginRegistrationManager.h"
#import "NSURLConnectionWithID.h"
#import "CreateAccountNavigationViewController.h"
#import "AccountManagementViewController.h"

#import "DocumentHandler.h"
#import "User+Utils.h"
#import "UserAccount.h"
#import "NSString+URLEncoding.h"
#import "URLRequestUtilities.h"
#import "BookManager.h"
#import "CommentManager.h"
#import "UserGroupManager.h"
#import "UserManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface LoginViewController () <NSURLConnectionDelegate>
{
    NSURLConnection * loginConnection;
    NSMutableData * httpResponseData;
    NSMutableData * httpUserResponseData;
    NSURLConnectionWithID *userConnection;
    BOOL loginSuccessful;
    BOOL hasAuthError;
}
- (void)addLoggedInUser:(NSDictionary *)userData;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************


@implementation LoginViewController

@synthesize delegate = _delegate;
@synthesize userNameText = _userNameText;
@synthesize passwordText = _passwordText;
@synthesize errorLabel = _errorLabel;
@synthesize loginButton = _loginButton;
@synthesize showRegistrationButton = _showRegistrationButton;

// ********** CONSTANTS **********
static int const CONNECTION_USER_GET_BY_NAME = 1;

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
    loginSuccessful = NO;
    hasAuthError = NO;
    [self.errorLabel setHidden:YES];
    [self.activityIndicator setHidden:YES];
    
    if (self.showRegistrationButton == NO)
        [self.registerButton setHidden:YES];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Login Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
//    self.userNameText.text = @"Charles";
//    self.passwordText.text = @"test";
}

- (void)viewDidUnload
{
    [self setUserNameText:nil];
    [self setPasswordText:nil];
    [self setErrorLabel:nil];
    [self setLoginButton:nil];
    [self setRegisterButton:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (loginSuccessful)
    {
        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(loginFinishedWithSuccess)])
            [self.delegate loginFinishedWithSuccess];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
// user wants to register a new account: notify parent to open registration view
- (IBAction)showRegistrationForm:(id)sender 
{
    [loginConnection cancel];
    [self.activityIndicator setHidden:YES];

    // Get registration form controller
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"AccountManagement" bundle:nil];
    CreateAccountNavigationViewController * registration = [storyboard instantiateViewControllerWithIdentifier:@"Create Account NavigationController"];
    registration.modalPresentationStyle = UIModalPresentationFormSheet;
    registration.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  
    UIViewController * view = [self presentingViewController];
    id tempDelegate = self.delegate;
    
    [self dismissModalViewControllerAnimated:NO];
    [view presentViewController:registration animated:NO completion:^{}];
    
    // Notify the delegate
    
    if ([tempDelegate respondsToSelector:@selector(loginReplacedWithRegistrationForm)])
        [tempDelegate loginReplacedWithRegistrationForm];
}

// ======================================================================================================================================
// user wants to cancel
- (IBAction)cancel:(id)sender
{
    [loginConnection cancel];
    [self.activityIndicator setHidden:YES];
    
    id tempDelegate = self.delegate;
    
    [self dismissModalViewControllerAnimated:NO];
    
    // Notify the delegate
    if ([tempDelegate respondsToSelector:@selector(loginCancelled)])
        [tempDelegate loginCancelled];
}

// ======================================================================================================================================
// Send login request
- (IBAction)login:(id)sender 
{
    [self.errorLabel setHidden:YES];
    [self.loginButton setEnabled:NO];
    [self.activityIndicator setHidden:NO];
    
    httpResponseData = [[NSMutableData alloc] initWithLength:10];

    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_LOGIN]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    loginConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// ======================================================================================================================================
// Get logged-in user's detailel information from the server to finish the login process.
// performs any necessary cleanups/initializations.
- (void) getUserByUserName:(NSString *)userName
{
    // Get user details from server.
    if (userConnection != nil)
        return;

    [self.activityIndicator setHidden:NO];
    [self.loginButton setEnabled:NO];
    
    httpUserResponseData = [[NSMutableData alloc] initWithLength:10];

    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@", URL_SERVER_BASE_URL_AUTH, URL_USER_GET_USER_AND_DATA_BY_NAME, userName, [BookManager getDownloadedBooksRemoteIds]]];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [userConnection cancel];
    userConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:YES identification:CONNECTION_USER_GET_BY_NAME];
                      
}

// ======================================================================================================================================
// process user response data
-(void) processUserResponseData
{
    NSString * errorTitle = NSLocalizedString(@"Server Error", @"Error on server (title)");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:httpUserResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:nil indicateIfAuthenticationError:NULL];

    NSDictionary * userData = [responseData objectForKey:@"result"];
    if (userData != nil)
    {
        [self addLoggedInUser:userData];
        loginSuccessful = YES;
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
}

// ======================================================================================================================================
// Add user to the core data table (if not there yet), set login status to logged-in
- (void)addLoggedInUser:(NSDictionary *)userData
{
    if (userData == nil)
        return;
    
    UserAccount *userAccount = [[UserAccount alloc]initWithDictionary:[userData objectForKey:@"user"]];

    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"userName = %@", userAccount.userName];
    NSArray * objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];
    
    User * userObj = nil;
    
    if(objects == nil)
        return;
    
    // Save or update user account information
    if(objects.count == 0) // user not exist in core data
    {
        userObj = (User*)[NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
        [userObj.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:userObj] error:nil];
    }
    else
    {
        userObj = [objects objectAtIndex:0];
    }
    
    [userObj setDataFromModel:userAccount];
    userObj.isLoggedIn = [NSNumber numberWithBool:YES];
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];

    
    // ------------ Save avatars ---------------

    NSData * avatar = [Utilities base64DataFromString:userAccount.avatar];
    
    if (avatar.length > 0)
    {
        NSString * path = [UserManager getAvatarAbsolutePathForUser:userObj thumbnailSize:NO];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        
        [avatar writeToFile:[UserManager getAvatarAbsolutePathForUser:userObj thumbnailSize:NO] atomically:NO];
        avatar = [Utilities base64DataFromString:userAccount.thumbnailAvatar];
        [avatar writeToFile:[UserManager getAvatarAbsolutePathForUser:userObj thumbnailSize:YES] atomically:NO];
        
        [Utilities excludeFromBackupItemAtPath:[path stringByDeletingLastPathComponent]];
    }

    // ------------ Save comments, groups, comments' likes and flags, books' likes and flags ---------------
    
    // 1. Save flagged book
    [BookManager flagBooksInTheList:[userData objectForKey:@"flaggedBooks"] byUser:userObj];
   
     // 2. Save liked book
    [BookManager likeBooksInTheList:[userData objectForKey:@"likedBooks"] byUser:userObj];
   
     // 3. Save flagged comments
    [CommentManager flagCommentsInTheList:[userData objectForKey:@"flaggedComments"] byUser:userObj];
   
     // 4. Save liked comments
    [CommentManager likeCommentsInTheList:[userData objectForKey:@"likedComments"] byUser:userObj];
  
    // 5. Save Groups
    [UserGroupManager addOrUpdateUserGroups:[userData objectForKey:@"groups"]];
    
    // 6. Link Books to Groups
    [BookManager linkBooksToGroups:[userData objectForKey:@"groupBooks"]];
}

// ======================================================================================================================================
// This method enables automatic keyboard dismissal. needed for this to work: [self.view endEditing:YES];
-(BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

// ======================================================================================================================================
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
    if([connection isKindOfClass:[NSURLConnectionWithID class]])
    {
        if (((NSURLConnectionWithID*)connection).identification == CONNECTION_USER_GET_BY_NAME)
        {
            [httpUserResponseData setLength:0];
        }
    }
    else
    {
        [httpResponseData setLength:0];
    }
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    if([connection isKindOfClass:[NSURLConnectionWithID class]])
    {
        if (((NSURLConnectionWithID*)connection).identification == CONNECTION_USER_GET_BY_NAME)
        {
            [httpUserResponseData appendData:data];
        }
    }
    else
    {
        [httpResponseData appendData:data];
    }
}
// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    userConnection = nil;
    if(hasAuthError)
    {
        return;
    }
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    [self.activityIndicator setHidden:YES];
    [self.loginButton setEnabled:YES];
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    userConnection = nil;
    [self.activityIndicator setHidden:YES];
    [self.loginButton setEnabled:YES];
    
    if([connection isKindOfClass:[NSURLConnectionWithID class]])
    {
        if (((NSURLConnectionWithID*)connection).identification == CONNECTION_USER_GET_BY_NAME)
        {
            [self processUserResponseData];
        }
    }
    else
    {        
        // No response is good - success. Save session and return. We are done here.
        if ([httpResponseData length] == 0)
        {
            [self.loginButton setEnabled:YES];
            [self.errorLabel setHidden:YES];
        
            [LoginRegistrationManager login];
            [self getUserByUserName:self.userNameText.text];
            return;
        }
        else
        {
//            NSError * error = NULL;
          //  NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];
          //  NSLog(@"%@", [[NSString alloc] initWithData:httpResponseData encoding:NSUTF8StringEncoding]);
        }

    }
    
    // -------------
 /*
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];
    
    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = NSLocalizedString(@"Server Error", @"Error on server (title)");
        NSString * errorBody = @"UNKNOWN ERROR";
        
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_AUTH_FAIL])
        {
            return; 
        }
        
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            errorBody = [errArr componentsJoinedByString:@"\n"];
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];  
        
        return;
    }
  */
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return NO;
}
// ======================================================================================================================================
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}
// ======================================================================================================================================
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
}
// ======================================================================================================================================
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] ==0)
    {
        NSURLCredential * cred = [NSURLCredential
                                  credentialWithUser:self.userNameText.text
                                  password:[Utilities sha1:self.passwordText.text]
                                  persistence:NSURLCredentialPersistenceNone];
        
        [[challenge sender] useCredential:cred forAuthenticationChallenge:challenge];
    }
    else
    {
        NSURLResponse *response = [challenge failureResponse];
        NSHTTPURLResponse *hre = (NSHTTPURLResponse *)response;
        
        NSDictionary * headerFields = [hre allHeaderFields];
        NSString * failMessage = [headerFields valueForKey:REQUEST_RESPONSE_AUTH_FAIL];
        NSString * failCode = [headerFields valueForKey:REQUEST_RESPONSE_AUTH_FAIL_CODE];
        /**
         failCode:  1 = bad credentails
         2 = disabled user
         3 = inactivated user
         4 = username not found
         5 = others.
         **/
        
        // Deleted account? Delete it locally as well
        if ([failCode isEqualToString:AUTH_FAIL_CODE_ACCOUNT_NOT_FOUNT])
        {
            LoginRegistrationManager * lrm = [[LoginRegistrationManager alloc] init];
            [lrm deleteUserAccountPermanently:[UserManager getUserByUserName:self.userNameText.text] password:self.passwordText.text];
        }
        
        if(failMessage != nil && [failMessage length] >0)
            self.errorLabel.text = failMessage;
        else
            self.errorLabel.text = NSLocalizedString(@"Username or password is incorrect. Please try again.", @"Username or password is incorrect. Please try again.");

        hasAuthError = YES;
        [self.loginButton setEnabled:YES];
        [self.errorLabel setHidden:NO];
        [self.activityIndicator setHidden:YES];

        [[challenge sender] cancelAuthenticationChallenge:challenge];  //this will go to didfailwitherror.
    }
    
}
// ======================================================================================================================================
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}

@end
