//
//  ResetPasswordViewControllerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-14.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ResetPasswordViewController.h"
#import "Utilities.h"
#import "Globals.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface ResetPasswordViewController () <NSURLConnectionDelegate>
{
    NSURLConnection * passwordResetConnection;
    NSMutableData * responseData;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ResetPasswordViewController

@synthesize userNameEmailText;
@synthesize sendRequestButton;
@synthesize submitView;
@synthesize successView;

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
    [self.errorMessageLabel setHidden:YES];
    [self.spinner setHidden:YES];
    [self.successView setHidden:YES];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Reset User Password Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setUserNameEmailText:nil];
    [self setSendRequestButton:nil];
    [self setSubmitView:nil];
    [self setSuccessView:nil];
    [self setErrorMessageLabel:nil];
    [self setSpinner:nil];
    [self setSuccessMessage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
// ======================================================================================================================================
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
// Close dialog
- (IBAction)closeDialog:(id)sender 
{
    [self dismissModalViewControllerAnimated:YES];
}

// ======================================================================================================================================
// Send the request to the server
- (IBAction)sendRequest:(id)sender
{
    self.userNameEmailText.text = [self.userNameEmailText.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    
    if ([self.userNameEmailText.text length] == 0)
        return;
    
    // Send request
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USER_LOGIN_TROUBLE_RESET_REQUEST]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    // Create request data
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:1];
    [data setObject:self.userNameEmailText.text forKey:@"data"];
    NSData * json = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:NULL];
    
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
       
    responseData = [[NSMutableData alloc] initWithCapacity:30];
    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    connection = nil;
    [self.errorMessageLabel setHidden:YES];
    [self.spinner setHidden:NO];
    [self.sendRequestButton setEnabled:NO];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [responseData setLength:0];
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}
// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.errorMessageLabel setHidden:YES];
    [self.spinner setHidden:YES];
    [self.sendRequestButton setEnabled:YES];
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.spinner setHidden:YES];
    [self.sendRequestButton setEnabled:YES];
    
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        return;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = NSLocalizedString(@"Password Reset Failed", @"Error title: when user request to reset password fails");
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
        
        return;
    }
    
    // ALL OK
    NSNumber * result = [responseDictionary objectForKey:@"result"];

    if ([result intValue] > 0)
    {
        CGRect rect = self.submitView.bounds;
        [self.successView setFrame:CGRectMake(rect.origin.x, rect.origin.y, self.successView.bounds.size.width, self.successView.bounds.size.height)];
        [self.submitView setHidden:YES];
        [self.successView setHidden:NO];
        self.successMessage.text = [responseDictionary objectForKey:@"message"];
    }
    else
    {
        [self.errorMessageLabel setHidden:NO];
        self.errorMessageLabel.text = [responseDictionary objectForKey:@"message"];
    }
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}
@end
