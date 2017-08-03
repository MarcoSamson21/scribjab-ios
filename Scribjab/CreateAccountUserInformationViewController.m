//
//  CreateAccountUserInformationViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateAccountUserInformationViewController.h"
#import "CreateAccountAvatarDrawingViewController.h"
#import "UserAccount.h"
#import "UserType.h"
#import "ModelConstants.h"
#import "Utilities.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "NSString+URLEncoding.h"
#import "NSURLConnectionWithID.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

// ********** CONSTANTS **********
int const CONNECTION_USERNAME_EXISTS = 1;
int const CONNECTION_ADD_USER = 2;

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface CreateAccountUserInformationViewController () <NSURLConnectionDelegate>
{
    UIColor * defaultTextBackground;
    UIColor * errorTextBoxBackgroudColor;
    BOOL userOK;
    BOOL passwordOK;
    BOOL emailOK;
    BOOL nameOk;
    BOOL locationOK;
    UserType * userType;
    
    NSMutableData * httpResponseData;
    NSURLConnectionWithID * userNameConnection;
    NSURLConnectionWithID * registrationConnection;
}
-(void) toggleSubmitButtonVisibility;
-(void) checkIfUserIsAvailableAsync:(NSString*) userName;
-(void) processUserNameAvailabilityResponceData;
-(void) sendUserRegistrationRequestToServer;
-(void) processUserRegistrationRequestResponse;
-(void) finishProcessingUserRegistrationRequest;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
@end






// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation CreateAccountUserInformationViewController

@synthesize userNameTextBox = _userNameTextBox;
@synthesize passwordTextBox = _passwordTextBox;
@synthesize confirmPasswordTextBox = _confirmPasswordTextBox;
@synthesize emailTextBox = _emailTextBox;
@synthesize confirmEmailTextBox = _confirmEmailTextBox;
@synthesize activityIndicator = _activityIndicator;
@synthesize submitButton = _submitButton;
@synthesize addUserSpinner = _addUserSpinner;

@synthesize delegate = _delegate;
@synthesize wizardDataObject = _wizardDataObject;

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
    
    if ([((UserAccount*)self.wizardDataObject).userType intValue] == ACCOUNT_TYPE_CHILD)
    {
        self.emailTextBox.placeholder = NSLocalizedString(@"Parent's Email", @"User registration email text box placeholder text");
    }
    
    defaultTextBackground = self.confirmPasswordTextBox.backgroundColor;
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    userOK = NO;
    passwordOK = NO;
    emailOK = NO;
    nameOk = NO;
    locationOK = NO;
    registrationConnection = nil;
    [self.submitButton setHidden:YES];
    [self.activityIndicator setHidden:YES];
    [self.addUserSpinner setHidden:YES];
    [self.errorMessageLabel setHidden:YES];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Create Account (User Information) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setUserNameTextBox:nil];
    [self setPasswordTextBox:nil];
    [self setConfirmPasswordTextBox:nil];
    [self setEmailTextBox:nil];
    [self setConfirmEmailTextBox:nil];
    [self setSubmitButton:nil];
    [self setActivityIndicator:nil];
    [self setAddUserSpinner:nil];
    [self setRealName:nil];
    [self setLocation:nil];
    [self setErrorMessageLabel:nil];
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
// Move view such that the keyboard doen't coverup any text boxes
- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
     ^{
         CGRect b = self.view.bounds;
         b.origin.y = 80.0f;
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

// ======================================================================================================================================
//
- (IBAction)userNameIsChanging:(id)sender 
{
    userOK = NO;
    self.userNameTextBox.backgroundColor = defaultTextBackground;
    [self toggleSubmitButtonVisibility];
}
// ======================================================================================================================================
// Check if the user already exists
- (IBAction)userNameChanged:(id)sender 
{
    self.userNameTextBox.text = [self.userNameTextBox.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
    UserAccount * user = (UserAccount*)self.wizardDataObject;
    
    if (![user.userName isEqualToString:self.userNameTextBox.text])
    {
        user.userName = self.userNameTextBox.text;
    }
    
    if ([user.userName isEqualToString:@""])
    {
        userOK = NO;
    }
    else
    {
        // Check if user name is available (on the server) 
        [self checkIfUserIsAvailableAsync:((UserAccount*)self.wizardDataObject).userName];
        [self.activityIndicator setHidden:NO];
    }
    
    [self toggleSubmitButtonVisibility];
}


// ======================================================================================================================================
// These might have to be moved to a separate class with authentication support 
-(void) checkIfUserIsAvailableAsync:(NSString*) userName
{
    // currently processing registration data? 
    // Halt all other server communications
    if (registrationConnection != nil)      
        return; 

    userName = [userName urlEncode];
    [self.activityIndicator setHidden:NO];
    httpResponseData = [[NSMutableData alloc] initWithLength:10];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL, URL_USER_IS_USERNAME_EXISTS, userName]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [userNameConnection cancel];
    userNameConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_USERNAME_EXISTS];
}

// ======================================================================================================================================
// When Server data is fully received - determine if the user name is available
-(void) processUserNameAvailabilityResponceData
{
    [self.activityIndicator setHidden:YES];
    
    // do something with the json that comes back
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];

    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return;
    }
    
    BOOL exists = [[responseDictionary objectForKey:@"result"] boolValue];
    
    if (exists)
    {
        userOK = NO;
        self.userNameTextBox.backgroundColor = errorTextBoxBackgroudColor;
    }
    else 
    {
        userOK = YES;
        self.userNameTextBox.backgroundColor = defaultTextBackground;
    }
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// reset confirmation password
- (IBAction)passwordChanged:(id)sender 
{
    self.confirmPasswordTextBox.text = @"";
    self.confirmPasswordTextBox.backgroundColor = errorTextBoxBackgroudColor;
    passwordOK = NO;
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// Verify two passwords match
- (IBAction)confirmPasswordChanged:(id)sender
{
    if ([self.confirmPasswordTextBox.text isEqualToString:self.passwordTextBox.text])
    {
        passwordOK = YES;
        self.confirmPasswordTextBox.backgroundColor = defaultTextBackground;
    }
    else 
    {
        passwordOK = NO;
        self.confirmPasswordTextBox.backgroundColor = errorTextBoxBackgroudColor;
    }
    
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// Reset confirm email
- (IBAction)emailChanged:(id)sender 
{
    self.confirmEmailTextBox.text = @"";
    self.confirmEmailTextBox.backgroundColor = errorTextBoxBackgroudColor;
    emailOK = NO;
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// verify that two emails match
- (IBAction)confirmEmailChanged:(id)sender 
{
    if ([self.confirmEmailTextBox.text isEqualToString:self.emailTextBox.text])
    {
        self.confirmEmailTextBox.backgroundColor = defaultTextBackground;
        emailOK = [Utilities isEmailValid:self.confirmEmailTextBox.text];
    }
    else 
    {
        emailOK = NO;
        self.confirmEmailTextBox.backgroundColor = errorTextBoxBackgroudColor;
    }
    
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// if locally user input is valid - show submit button
-(void) toggleSubmitButtonVisibility
{
    BOOL wasHidden = [self.submitButton isHidden];
    self.submitButton.hidden = !(userOK && passwordOK && emailOK && nameOk && locationOK);
    self.errorMessageLabel.hidden = !self.submitButton.hidden;
    
    if (wasHidden != [self.submitButton isHidden] && wasHidden)
    {
        [self.view endEditing:YES];
    }
}

// ======================================================================================================================================
- (IBAction)submitNewUserButtonPress:(id)sender 
{
    [self.view endEditing:YES];
    self.userNameTextBox.enabled = NO;
    self.passwordTextBox.enabled = NO;
    self.emailTextBox.enabled = NO;
    self.confirmPasswordTextBox.enabled = NO;
    self.confirmEmailTextBox.enabled = NO;
    self.submitButton.hidden = YES;
    [self.addUserSpinner startAnimating];
    [self.addUserSpinner setHidden:NO];
    
    UserAccount * account = (UserAccount*)self.wizardDataObject;
    account.databaseID = [NSNumber numberWithInt:-1];
    account.userName = self.userNameTextBox.text;
    account.password = [Utilities sha1:self.passwordTextBox.text];
    account.email = self.emailTextBox.text;
    account.avatar = @"";
    account.isActivated = NO;
    account.isAdmin = NO;
    account.isDisabled = NO;
    account.accountNote = @"";
    account.name = [self.realName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    account.location = [self.location.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    // If queried for userType ID already - just use previous result 
    if (userType != nil)
    {
        account.userType = userType.databaseID;
        self.wizardDataObject = account;
        [self sendUserRegistrationRequestToServer];    // send request
        return;
    }
    
    // ---------------
    // OTHERWISE - Fetch for userTypeID
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USERTYPE_GET_TEACHER]];
    
    if ([((UserAccount*)self.wizardDataObject).userType intValue] == ACCOUNT_TYPE_CHILD)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USERTYPE_GET_CHILD]];
    }
    else if ([((UserAccount*)self.wizardDataObject).userType intValue] == ACCOUNT_TYPE_ADULT)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USERTYPE_GET_ADULT]];
    }
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if (error == NULL)
        {
            // process result             
            NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (error != NULL)
            {
                dispatch_async(dispatch_get_main_queue(), 
                ^{
                   [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
                   [self finishProcessingUserRegistrationRequest];
                });
                 
                return;
            }
             
            // Error?
            if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
            {
                dispatch_async(dispatch_get_main_queue(), 
                ^{
                    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
                    [self finishProcessingUserRegistrationRequest];
                });
                 
                return;
            }
            
            userType = [[UserType alloc] initWithDictionary:[responseDictionary objectForKey:@"result"]];
            account.userType = userType.databaseID;
            self.wizardDataObject = account;
            dispatch_async(dispatch_get_main_queue(), ^{ [self sendUserRegistrationRequestToServer]; });   // send the request on main thread
        }
        else 
        {
            dispatch_async(dispatch_get_main_queue(), 
            ^{
                [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
                [self finishProcessingUserRegistrationRequest];
            });
            
            return;
        }
     }];
}

// ======================================================================================================================================
// Submit user registration data
- (IBAction)cancelRegistration:(id)sender 
{
    [self.delegate viewControllerInNavigation:self finishedNavigationAndRequestsModalDismissal:YES];
}

// ======================================================================================================================================
- (IBAction)realNameChanged:(id)sender
{
    if ([[self.realName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
    {
        nameOk = NO;
        self.realName.backgroundColor = errorTextBoxBackgroudColor;
        return;
    }
    
    nameOk = YES;
    self.realName.backgroundColor = defaultTextBackground;
    
    [self toggleSubmitButtonVisibility];
}
// ======================================================================================================================================
- (IBAction)locationChanged:(id)sender
{
    if ([[self.location.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
    {
        locationOK = NO;
        self.location.backgroundColor = errorTextBoxBackgroudColor;
        return;
    }
    
    locationOK = YES;
    self.location.backgroundColor = defaultTextBackground;
    
    [self toggleSubmitButtonVisibility];
}

// ======================================================================================================================================
// Submit user registration data
-(void) sendUserRegistrationRequestToServer
{
    // currently processing registration data? 
    // Halt all other server communications
    if (registrationConnection != nil)      
        return; 
    
    UserAccount * account = (UserAccount*)self.wizardDataObject;
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USER_ADD]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    NSData * json = [account jsonRepresentation];
    
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
     
    httpResponseData = [[NSMutableData alloc] initWithLength:1024];
    
    [userNameConnection cancel];
    
    registrationConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_ADD_USER];
}

// ======================================================================================================================================
// Read registration response from the server 
-(void) processUserRegistrationRequestResponse
{
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
        NSString * errorTitle = NSLocalizedString(@"Cannot create account", @"Error title: when add user request returns a validation error (e.g. user or email already in use)");
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
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];  
        
        [self finishProcessingUserRegistrationRequest];
        return;
    }

    
    // ALL OK - save user account ID
    UserAccount * account = (UserAccount*)self.wizardDataObject;
    
    account.databaseID = [responseDictionary objectForKey:@"result"];
    self.wizardDataObject = account;
    
    // go on to the next screen.

    [self performSegueWithIdentifier:@"Create Account - Proceed to User Avatar Drawing Section" sender:self];
}

// ======================================================================================================================================
// re-enable all controlls again. 
-(void) finishProcessingUserRegistrationRequest
{
    self.userNameTextBox.enabled = YES;
    self.passwordTextBox.enabled = YES;
    self.emailTextBox.enabled = YES;
    self.confirmPasswordTextBox.enabled = YES;
    self.confirmEmailTextBox.enabled = YES;
    self.submitButton.hidden = NO;
    [self.addUserSpinner stopAnimating];
    [self.addUserSpinner setHidden:YES];
}

// ======================================================================================================================================
// Go on to the next screen
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.view endEditing:YES];
    if ([segue.identifier isEqualToString:@"Create Account - Proceed to User Avatar Drawing Section"])
    {
        ((CreateAccountAvatarDrawingViewController*)segue.destinationViewController).delegate = self.delegate;
        ((CreateAccountAvatarDrawingViewController*)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}

// ===========================================================================================================================================
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
    [httpResponseData setLength:0];
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    [httpResponseData appendData:data];
}
// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    registrationConnection = nil;
    
    [self.activityIndicator setHidden:YES];
    
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    
    if (((NSURLConnectionWithID*)connection).identification == CONNECTION_ADD_USER)
    {
        [self finishProcessingUserRegistrationRequest];
    }
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    switch (((NSURLConnectionWithID*)connection).identification) 
    {
        case CONNECTION_USERNAME_EXISTS:
            [self processUserNameAvailabilityResponceData];
            break;
        case CONNECTION_ADD_USER:
            [self processUserRegistrationRequestResponse];
            break;
        default:
            break;
    }
    
    registrationConnection = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

@end
