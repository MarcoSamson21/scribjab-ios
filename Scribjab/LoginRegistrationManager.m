//
//  LoginRegistrationManager.m
//  Scribjab
//
//  Utility methods for simplifying showing of Login and Register forms
//
//  Created by Oleg Titov on 12-09-13.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginRegistrationManager.h"
#import "LoginViewController.h"
#import "Globals.h"
#import "Utilities.h"
#import "DocumentHandler.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "UserGroupManager.h"
#import "UserManager.h"
#import "BookManager.h"

@interface LoginRegistrationManager () <NSURLConnectionDelegate, UIAlertViewDelegate>
{
    NSMutableData * _httpData;
    NSURLConnection * _connection;
    User * _userToDelete;
}
-(void)deleteLocalAccount;
@end
    
@implementation LoginRegistrationManager

// ======================================================================================================================================
// Show login form with specified parent and specified delegate
+ (void) showLoginWithParent:(UIViewController* )parent delegate:(id<LoginViewControllerDelegate>)delegate registrationButton:(BOOL)showRegistration
{
    [LoginRegistrationManager logout];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"AccountManagement" bundle:nil];
    LoginViewController * login = [storyboard instantiateViewControllerWithIdentifier:@"Login View Controller"];
    
    login.delegate = delegate;
    login.showRegistrationButton = showRegistration;
    login.modalPresentationStyle = UIModalPresentationFormSheet;
    login.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

    [parent presentViewController:login animated:YES completion:^{}];
}

// ======================================================================================================================================
// Shows user registration dialog and attach it to the specified parent controller. 
+ (void) showAccountRegistrationFormWithParent:(UIViewController* )parent
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"AccountManagement" bundle:nil];
    UIViewController * registration = [storyboard instantiateViewControllerWithIdentifier:@"Create Account NavigationController"];
    
    registration.modalPresentationStyle = UIModalPresentationFormSheet;
    registration.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [parent presentViewController:registration animated:NO completion:^{}];
}

// ======================================================================================================================================
// Get login user from core data.
+ (User *) getLoginUser
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isLoggedIn = %@", [NSNumber numberWithBool:YES]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];

    if([objects count]==1)
    {
        return [objects objectAtIndex:0];
    }
    return nil;
}

// ======================================================================================================================================
// Logs a user in to the system and performs any necessary cleanups/initializations.
+ (void) login
{
//    [[NSUserDefaults standardUserDefaults] synchronize];    // Force the system to save cookies to file storage
    
    // TODO: initializations
 //   [[NSUserDefaults standardUserDefaults] synchronize];    // Force the system to save cookies to file storage
    
     

    
    
    
    // Commented out code saves cookies to the cookie storage manually.
    // But it seems that iOS does this automatically.
    // If needed, use this code, but you'll need to pass NSHTTPURLResponse object to this method.
    /*
     NSHTTPURLResponse * httpResp = (NSHTTPURLResponse *) response;

     NSArray * cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResp allHeaderFields] forURL:[[NSURL alloc] initWithString:URL_SERVER_BASE_URL ]];
     
     [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
     NSLog(@"Num of cookies: %d", [cookies count]);
     for (NSHTTPCookie * cookie in cookies)
     {
         NSLog(@"save cookie: %@, %@, %@, %@, %@", cookie.domain, cookie.expiresDate, cookie.name, cookie.path, cookie.value);
         [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
     }
     
     [[NSUserDefaults standardUserDefaults] synchronize];
 */
    // [[NSUserDefaults standardUserDefaults] synchronize];
    /*
    NSData *cookiesdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"MySavedCookies"];
    if([cookiesdata length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        NSHTTPCookie *cookie;
        
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
     
     */
}

// ======================================================================================================================================
// Logs out a user (if logged-in) from the system and performs any necessary cleanups.
+ (void) logout
{
    // Delete all cookies for this app's server URL
    NSArray * array = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[[NSURL alloc] initWithString:URL_SERVER_BASE_URL]];
    for (NSHTTPCookie * cookie in array) 
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //reset user isLoggedIn flag in User model.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isLoggedIn = %@", [NSNumber numberWithBool:YES]];
    NSArray *objects =[[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"User" predicate:predicate sortDescriptors:nil];

    for(User * user in objects)
    {
        user.isLoggedIn = [NSNumber numberWithBool:NO];
        [user removeFlaggedBooks:user.flaggedBooks];
        [user removeLikedBooks:user.likedBooks];
        [user removeFlaggedComments:user.flaggedComments];
        [user removeLikedComments:user.likedComments];
    }
    
    [UserGroupManager deleteAllUserGroups];
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}



// ======================================================================================================================================
// ======================================================================================================================================
// ======================================================================================================================================

@synthesize delegate;

// Permanently delete user from the server and from iPad. This method will delete all of the data created by this user:
// books, comment, flags, groups, etc.
-(void)deleteUserAccountPermanently:(User *)user password:(NSString*)currentPassword
{
    if (user == nil)
    {
        if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
            [self.delegate userDeleteRequestFinishedWithSuccess:YES];
        return;
    }
    
    if (_connection != nil)
        return;
    
    // If user is logged in, but is trying to delete another user - this should not be allowed. 
    if ([LoginRegistrationManager getLoginUser] != nil && user != [LoginRegistrationManager getLoginUser])
    {
        if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
            [self.delegate userDeleteRequestFinishedWithSuccess:NO];
        return;
    }

     _userToDelete = user;
    if ([self.delegate respondsToSelector:@selector(userDeleteRequestStarted)])
        [self.delegate userDeleteRequestStarted];

    // If user is not logged in, then deletion is local only
    if ([LoginRegistrationManager getLoginUser] == nil)
    {
        [self deleteLocalAccount];
        return;
    }
    
    // --------------------------------------
    // Send the request
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_USER_DELETE_ACCOUNT]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    
    NSDictionary * postDict = [[NSDictionary alloc] initWithObjectsAndKeys:user.userName, @"userName", [Utilities sha1:currentPassword], @"password", nil];
    NSData * postData = [NSJSONSerialization dataWithJSONObject:postDict options:kNilOptions error:NULL];
    
    [request setHTTPMethod:@"DELETE"];
    [URLRequestUtilities setJSONData:postData ToURLRequest:request];
    
    _httpData = [[NSMutableData alloc] initWithLength:1024];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

// ======================================================================================================================================
// Delete account locally
-(void)deleteLocalAccount
{
    if (_userToDelete == nil)
    {
        if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
            [self.delegate userDeleteRequestFinishedWithSuccess:YES];
        return;
    }
    
    NSArray * booksToDelete = _userToDelete.book.array;
    
    for (Book * book in booksToDelete)
    {
        [BookManager deleteBook:book];
    }
    
    [UserManager deleteUser:_userToDelete saveContext:YES];
    
    if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
        [self.delegate userDeleteRequestFinishedWithSuccess:YES];
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
    _connection = nil;
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    
    if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
        [self.delegate userDeleteRequestFinishedWithSuccess:NO];
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _connection = nil;
    NSString * errorTitle = NSLocalizedString(@"Delete Account", @"Error title: Cannot delete a user account");
   
    BOOL isAuthError = NO;
    BOOL isError = NO;
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    responseData = nil;
    // if login required - display login prompt
    if (isAuthError || isError)
    {
        
        if ([self.delegate respondsToSelector:@selector(userDeleteRequestFinishedWithSuccess:)])
        {   //dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate userDeleteRequestFinishedWithSuccess:NO];
           // });
        }
        return;
    }
        
    // No errors - delete account locally
    [self deleteLocalAccount];
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
    return NO;
}
// ======================================================================================================================================
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
}
// ======================================================================================================================================
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLResponse *response = [challenge failureResponse];
    NSHTTPURLResponse *hre = (NSHTTPURLResponse *)response;
    
    NSDictionary * headerFields = [hre allHeaderFields];
    NSString * failMessage = [headerFields valueForKey:REQUEST_RESPONSE_AUTH_FAIL];
    
    NSString * title = NSLocalizedString(@"Authentication Error", @"Error message title. Error is shown for authentication problems in delete user account section.");
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:failMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
    [alert show];
    
    [[challenge sender] cancelAuthenticationChallenge:challenge];  //this will go to didfailwitherror.
}
// ======================================================================================================================================
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}
@end
