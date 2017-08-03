//
//  AccountManagementViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountManagementViewController.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "Utilities.h"
#import "Globals.h"
#import "LoginViewControllerDelegate.h"
#import "LoginRegistrationManager.h"
#import "UpdateUserAccount.h"
#import "Utilities.h"
#import "LoginRegistrationManager.h"
#import "DocumentHandler.h"
#import "NSURLConnectionWithID.h"
#import "UserAccount.h"
#import "UIColor+HexString.h"
#import "ModifyUserAvatarViewController.h"
#import "DrawingPadImageUpdatedDelegate.h"
#import "NavigationManager.h"

#import "BookManager.h"
#import "CommentManager.h"
#import "UserManager.h"
#import "UserGroupManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface AccountManagementViewController () <NSURLConnectionDelegate, LoginViewControllerDelegate, UIAlertViewDelegate, DrawingPadImageUpdatedDelegate, LoginRegistrationManagerDelegate>
{
    NSURLConnectionWithID * _connection;
    NSMutableData * _httpResponseData;
    User * _user;
    BOOL _emailChanged;
    BOOL _bgColorChanged;
    NSString * _avatar;
    UIImage * _image;
    
    UIColor * _defaultTextBackground;
    UIColor * _errorTextBoxBackgroudColor;
    
    int _lastAlertView;
    LoginRegistrationManager * _lrm;
}
-(void) initializeAccountForm;
-(void) processUpdateUserRequestResponse;
-(void) processGetUserDataRequestResponse;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void) saveAccountConfirmedWithPassword:(NSString*)password;
- (void) deleteAccountConfirmedWithPassword:(NSString*)password;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation AccountManagementViewController

static int const CONNECTION_USER_GET_DATA = 1;
static int const CONNECTION_USER_UPDATE = 2;

static int const ALERT_VIEW_MODIFY = 1;
static int const ALERT_VIEW_DELETE_CONFIRM = 2;
static int const ALERT_VIEW_DELETE = 3;

//// ===========================================================================================================================================
//// returns absolute path for avatar or avatar thumbnail file, based on user ID
//+(NSString*) getAvatarAbsolutePathForUser:(User*) user thumbnailSize:(BOOL) thumbnail
//{
//    NSString * objectId = [[user.objectID URIRepresentation] lastPathComponent];
//    
//    if (thumbnail)
//        return [Utilities getAbsoluteFile:[NSString stringWithFormat:@"users/%@/%@.png", objectId, @"thumb"]];
//    
//    return [Utilities getAbsoluteFile:[NSString stringWithFormat:@"users/%@/%@.png", objectId, @"avatar"]];
//}


// ===========================================================================================================================================
// ===========================================================================================================================================
// ===========================================================================================================================================
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
    [self initializeAccountForm];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Modify Account Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setUserNameLabel:nil];
    [self setConfirmPassword:nil];
    [self setPasswordNew:nil];
    [self setEmailNew:nil];
    [self setEmailConfirm:nil];
    [self setSaveButton:nil];
    [self setActivityIndicator:nil];
    [self setDrawImageButton:nil];
    [self setAvatarThumBGView:nil];
    [self setDeleteAccountButton:nil];
    [self setDeleteAccountActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// ===========================================================================================================================================
// Close the tour view and return to where this view was called from
- (IBAction)closeAccountManagement:(id)sender 
{
    [self dismissModalViewControllerAnimated:NO];
}

// ===========================================================================================================================================
// Prepares the form for the user to edit.
- (void)initializeAccountForm
{
    _defaultTextBackground = self.passwordNew.backgroundColor;
    _errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    
    _httpResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    _connection = nil;
    _emailChanged = NO;
    _avatar = nil;
    _user = [LoginRegistrationManager getLoginUser];
    [self.activityIndicator stopAnimating];
    [self.deleteAccountActivityIndicator stopAnimating];
    self.userNameLabel.text = _user.userName;
    self.emailNew.text = _user.email;
    [self.drawImageButton setTitle:@"" forState:UIControlStateNormal];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO]])
    {
        UIImage * image = [UIImage imageWithContentsOfFile:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO]];
       // [self.drawImageButton setBackgroundImage:image forState:UIControlStateNormal];
       // [self.drawImageButton setBackgroundColor:[UIColor colorWithHexString:_user.backgroundColorCode]];
        self.avatarThumBGView.image = image;
        self.avatarThumBGView.backgroundColor = [UIColor colorWithHexString:_user.backgroundColorCode];
    }
}

// ===========================================================================================================================================
// Move view such that the keyboard doen't coverup any text boxes
- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
     ^{
         CGRect b = self.view.bounds;
         b.origin.y = 50.0f;
         self.view.bounds = b;
    } completion:^(BOOL finished){}];
}
// ===========================================================================================================================================
// Move view bck to its original position
-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
     ^{
         CGRect b = self.view.bounds;
         b.origin.y = 0.0f;
         self.view.bounds = b;
     } completion:^(BOOL finished){}];
}

// ===========================================================================================================================================
// Save data to the online database
- (IBAction)saveAccountInfo:(id)sender
{    
    if (_connection != nil)
    {   NSLog(@"connection is in progress, must wait..."); return;  }
    
    // If no changes are made, just close
    if (!_emailChanged && [self.passwordNew.text isEqualToString:@""] && _avatar == nil && !_bgColorChanged)
    {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }

    if (self.confirmPassword.backgroundColor == _errorTextBoxBackgroudColor)
    {
        UIAlertView * errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Message box title bar")
                                   message:NSLocalizedString(@"Passwords must match", @"New password doesn't match the confirmed password")
                                  delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles:nil];
        [errorView show];
        return;
    }
    
    if (self.emailConfirm.backgroundColor == _errorTextBoxBackgroudColor)
    {
        UIAlertView * errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Message box title bar")
                                                             message:NSLocalizedString(@"Emails must match", @"New email doesn't match the confirmed email")
                                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles:nil];
        [errorView show];
        return;
    }
    
    // -------------------------------------
    // Get user's current password for security
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Scribjab password:",@"'Please enter password' label")
                                                     message:_user.userName delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                           otherButtonTitles:NSLocalizedString(@"OK", @"OK button label"),  nil];
    alert.alertViewStyle =  UIAlertViewStyleSecureTextInput;
    _lastAlertView = ALERT_VIEW_MODIFY;
    [alert show];
    
    // REQUEST SENDING is done in the alert's delegate
}

// ===========================================================================================================================================
// After user entered account password successfully, send update request to the server
- (void)saveAccountConfirmedWithPassword:(NSString *)password
{
    // Continue saving the information
    UpdateUserAccount * ua = [[UpdateUserAccount alloc] init];
    ua.avatar = @"";
    ua.email = @"";
    ua.passwordNew = @"";
    ua.backgroundColorCode = _user.backgroundColorCode;
    
    if (_emailChanged)
        ua.email = self.emailNew.text;
    
    if ([self.confirmPassword.text length] > 0)
        ua.passwordNew = [Utilities sha1:(self.passwordNew.text)];
    
    ua.currentPassword = [Utilities sha1:password];
    ua.databaseID = _user.remoteId;
    
    // save image
    if (_avatar != nil)
        ua.avatar = _avatar;
    
    // --------------------------------------
    // Send the request
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_USER_UPDATE]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    NSData * json = [ua jsonRepresentation];
    
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    
    _httpResponseData = [[NSMutableData alloc] initWithLength:1024];
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:YES identification:CONNECTION_USER_UPDATE];
    [self.activityIndicator startAnimating];
}

// ===========================================================================================================================================
// Handle user password input and proceed with saving/deleting user account info.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Cancel clicked?
    if (buttonIndex == 0)
        return;
    
    UIAlertView * alert;
    
    switch (_lastAlertView)
    {
        case ALERT_VIEW_MODIFY:
            [self saveAccountConfirmedWithPassword:[alertView textFieldAtIndex:0].text];
            break;
        case ALERT_VIEW_DELETE_CONFIRM:
            // Get user's current password for security
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Scribjab password:",@"'Please enter password' label")
                                                             message:_user.userName delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                                   otherButtonTitles:NSLocalizedString(@"OK", @"OK button label"),  nil];
            alert.alertViewStyle =  UIAlertViewStyleSecureTextInput;
            _lastAlertView = ALERT_VIEW_DELETE;
            [alert show];
            break;
        case ALERT_VIEW_DELETE:
            [self deleteAccountConfirmedWithPassword:[alertView textFieldAtIndex:0].text];
            break;
        default:
            break;
    }
}

// ===========================================================================================================================================
// Got response from the server without the errors process it and finish.
-(void) processUpdateUserRequestResponse
{
    _connection = nil;
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:_httpResponseData options:kNilOptions error:&error];

    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:nil];
        return;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = NSLocalizedString(@"Modify Account", @"Account Modification error message box title");
        NSString * errorBody = @"UNKNOWN ERROR";
        
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
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
        
        return;
    }

    // -----------------------------------------------------------------
    // ALL OK - get updated user data and save to local storage
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@", URL_SERVER_BASE_URL_AUTH, URL_USER_GET_USER_AND_DATA_BY_NAME, _user.userName, [BookManager getDownloadedBooksRemoteIds]]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    _httpResponseData = [[NSMutableData alloc] initWithLength:1024];
    _connection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:YES identification:CONNECTION_USER_GET_DATA];
    [self.activityIndicator startAnimating];
}

// ===========================================================================================================================================
- (void)processGetUserDataRequestResponse
{
    _connection = nil;
    [self.activityIndicator stopAnimating];
    
    NSString * errorTitle = NSLocalizedString(@"Modify Account", @"Account Modification error message box title");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
  
    // ----------------------------------------
    // ALL OK
    NSDictionary * userData = [responseData objectForKey:@"result"];
    if (userData == nil)
        return;
    
    
    // Save to Core Data
    UserAccount *ua = [[UserAccount alloc]initWithDictionary:[userData objectForKey:@"user"]];
    _user.email = ua.email;
    _user.backgroundColorCode = ua.avatarBgColor;
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];

    // Save Avatars
    NSData * avatar = [Utilities base64DataFromString:ua.avatar];
    
    if (avatar.length > 0)
    {
        NSString * path = [UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO];
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
       
        [avatar writeToFile:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO] atomically:NO];
        avatar = [Utilities base64DataFromString:ua.thumbnailAvatar];
        [avatar writeToFile:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:YES] atomically:NO];
    }
    
    // ------------ Save comments, groups, comments' likes and flags, books' likes and flags ---------------
    
    // 1. Save flagged book
    [BookManager flagBooksInTheList:[userData objectForKey:@"flaggedBooks"] byUser:_user];
    
    // 2. Save liked book
    [BookManager likeBooksInTheList:[userData objectForKey:@"likedBooks"] byUser:_user];
    
    // 3. Save flagged comments
    [CommentManager flagCommentsInTheList:[userData objectForKey:@"flaggedComments"] byUser:_user];
    
    // 4. Save liked comments
    [CommentManager likeCommentsInTheList:[userData objectForKey:@"likedComments"] byUser:_user];
    
    // 5. Save Groups
    [UserGroupManager addOrUpdateUserGroups:[userData objectForKey:@"groups"]];
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    // NSLog(@"likedComments: %@\n flaggedComments %@\n likedBooks %@\n flaggedBooks %@\n groups%@",[userData objectForKey:@"likedComments"], [userData objectForKey:@"flaggedComments"], [userData objectForKey:@"likedBooks"], [userData objectForKey:@"flaggedBooks"], [userData objectForKey:@"groups"]);
    
    [self dismissModalViewControllerAnimated:YES];
}


// ===========================================================================================================================================
- (IBAction)passwordConfirmChanged:(id)sender
{
    if (![self.confirmPassword.text isEqualToString:self.passwordNew.text])
        self.confirmPassword.backgroundColor = _errorTextBoxBackgroudColor;
    else
        self.confirmPassword.backgroundColor = _defaultTextBackground;
}

// ===========================================================================================================================================
- (IBAction)emailConfirmChanged:(id)sender
{
    if (![self.emailConfirm.text isEqualToString:self.emailNew.text])
        self.emailConfirm.backgroundColor = _errorTextBoxBackgroudColor;
    else
        self.emailConfirm.backgroundColor = _defaultTextBackground;
}

// ===========================================================================================================================================
- (IBAction)openAvatarDrawingPad:(id)sender
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"AccountManagement" bundle:nil];
    ModifyUserAvatarViewController * drawController = [storyboard instantiateViewControllerWithIdentifier:@"Modify Avatar Drawing Controller"];
    
    drawController.delegate = self;
    drawController.modalPresentationStyle = UIModalPresentationFormSheet;
    drawController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:drawController animated:YES completion:^{}];

//    [self presentModalViewController:drawController animated:YES];
    
    if (_image == nil && [[NSFileManager defaultManager] fileExistsAtPath:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO]])
    {
        _image = [UIImage imageWithContentsOfFile:[UserManager getAvatarAbsolutePathForUser:_user thumbnailSize:NO]];
    }
        
    
 //   if ([[NSFileManager defaultManager] fileExistsAtPath:[AccountManagementViewController getAvatarAbsolutePathForUser:_user thumbnailSize:NO]])
  //  {
 //       UIImage * image = [UIImage imageWithContentsOfFile:[AccountManagementViewController getAvatarAbsolutePathForUser:_user thumbnailSize:NO]];
    drawController.avatar = _image;
    drawController.avatarBgColor = [UIColor colorWithHexString:_user.backgroundColorCode];
  //  }
}

// ===========================================================================================================================================
// Permanently delete account
- (IBAction)deleteAccount:(id)sender
{
    // -------------------------------------
    // Get user's current password for security
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Permanently Delete Your Account?",@"User account deletion confirmation message box title")
                                            message:NSLocalizedString(@"Are you sure you want to PERMANENTLY delete your user account and all of your books from the Scribjab server? Once your account and books are deleted you won't be able to recover them!",@"User account deletion confirmation message box") delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                           otherButtonTitles:NSLocalizedString(@"Yes, Delete", @"OK button label"),  nil];

    _lastAlertView = ALERT_VIEW_DELETE_CONFIRM;
    [alert show];
    
    // REQUEST SENDING is done in the alert's delegate    
}

// ===========================================================================================================================================
// Send delete request to the server and delete all local information related to this user.
-(void)deleteAccountConfirmedWithPassword:(NSString *)password
{
    _lrm = [[LoginRegistrationManager alloc] init];
    _lrm.delegate = self;
    [_lrm deleteUserAccountPermanently:_user password:password];
}

// ===========================================================================================================================================
// Image changed delegate method
- (void)imageUpdatedWithImage:(UIImage *)image andBackgroundColor:(UIColor *)color
{
    if (image != nil)
    {
        _image = image;
        _avatar = [Utilities base64forData:UIImagePNGRepresentation(image)];
        self.avatarThumBGView.image = image;
    }
    _user.backgroundColorCode = [UIColor hexStringForColor:color];
    _bgColorChanged = YES;
    self.avatarThumBGView.backgroundColor = color;
}

// ===========================================================================================================================================
- (IBAction)passwordChanged:(id)sender
{
    self.confirmPassword.text = @"";
    if (![self.passwordNew.text isEqualToString:@""])
        self.confirmPassword.backgroundColor = _errorTextBoxBackgroudColor;
    else
        self.confirmPassword.backgroundColor = _defaultTextBackground;
}

// ===========================================================================================================================================
- (IBAction)emailChanged:(id)sender
{
    self.emailNew.text = [self.emailNew.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    self.emailConfirm.text = @"";
    if (![self.emailNew.text isEqualToString:_user.email])
    {
        self.emailConfirm.backgroundColor = _errorTextBoxBackgroudColor;
        _emailChanged = YES;
    }
    else
    {
        self.emailConfirm.backgroundColor = _defaultTextBackground;
        _emailChanged = NO;
    }
}

// ===========================================================================================================================================
// Hide keyboard on view touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark LoginRegistrationManagerDelegate methods

-(void)userDeleteRequestStarted
{
    [self.deleteAccountActivityIndicator startAnimating];
    [self.deleteAccountButton setEnabled:NO];
}

-(void)userDeleteRequestFinishedWithSuccess:(BOOL)success
{
    [self.deleteAccountActivityIndicator stopAnimating];
    [self.deleteAccountButton setEnabled:YES];
    
    if (success)
    {
        [self dismissViewControllerAnimated:NO completion:
        ^{
            [NavigationManager navigateToHome];
        }];
    }
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
    [self.activityIndicator stopAnimating];
    _connection = nil;
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:nil];   // show error message
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    [self.activityIndicator stopAnimating];
    
    if ([connection isKindOfClass:[NSURLConnectionWithID class]])
    {
        if (((NSURLConnectionWithID*)connection).identification == CONNECTION_USER_UPDATE)
            [self processUpdateUserRequestResponse];
        else // CONNECTION_USER_GET_DATA
            [self processGetUserDataRequestResponse];
    }
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // If there is an authentication challenge, then cancel everything and require user to login
    UIViewController * parent = self.presentingViewController.presentingViewController;
    [parent dismissModalViewControllerAnimated:NO];
    [LoginRegistrationManager showLoginWithParent:parent delegate:(id<LoginViewControllerDelegate>)parent registrationButton:YES];
    
    [_connection cancel];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}


@end
