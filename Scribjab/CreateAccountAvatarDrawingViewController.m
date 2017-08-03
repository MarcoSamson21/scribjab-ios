//
//  CreateAccountAvatarDrawingViewControllerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateAccountAvatarDrawingViewController.h"
#import "CreateAccountConfirmationViewController.h"
#import "UserAccount.h"
#import "ModelConstants.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "Utilities.h"
#import "UIColor+HexString.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface CreateAccountAvatarDrawingViewController () <NSURLConnectionDelegate, DrawingPadViewControllerDelegate>
{
    NSMutableData * httpResponseData;
    NSURLConnection * accountConnection;
    
    UIButton * _currentToolButton;
    UIButton * _canvasSelectionButton;
}
@end



// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation CreateAccountAvatarDrawingViewController

@synthesize delegate = _delegate;
@synthesize submitButton = _submitButton;
@synthesize activityIndicator = _activityIndicator;
@synthesize wizardDataObject = _wizardDataObject;

@synthesize drawingAreaView;

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
    
    [self.activityIndicator setHidden:YES];
    self.canvasView = self.drawingAreaView;
    [self.canvasView usePenTool];
    _currentToolButton = self.penToolButton;
    [_currentToolButton setSelected:YES];
    self.drawingDelegate = self;
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Create Account (Draw Avatar) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setSubmitButton:nil];
    [self setActivityIndicator:nil];
    [self setPenToolButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
// send new avatar to the server
- (IBAction)submitButtonClicked:(id)sender 
{
    // currently processing update request?
    if (accountConnection != nil)      
        return; 
    
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self.submitButton setEnabled:NO];
    
    UserAccount * account = (UserAccount*)self.wizardDataObject;
    
    // SAVE IMAGE HERE
    UIImage * image = [self getImageInCanvas];
    account.avatarBgColor = [UIColor hexStringForColor:[self getImageBackgroundColor]];
    
    if ([self isCanvasBlank])
        image = nil;
    
    if (image == nil)
    {
        account.avatar = nil;
        self.wizardDataObject = account;
        [self performSegueWithIdentifier:@"Create Account - Proceed to Confirmation" sender:self];
        return;
    }
    
    account.avatar = [Utilities base64forData:UIImagePNGRepresentation(image)];
    self.wizardDataObject = account;
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_USER_UPDATE_AVATAR]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    NSData * json = [account jsonRepresentation];
    
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    httpResponseData = [[NSMutableData alloc] initWithLength:10];
    
    accountConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// ======================================================================================================================================
// Don't use user's drawing, and instead use default avatar.
// Basically, instruct the server to pick the default avatar for the user by not sending any image data.
- (IBAction)useDefaultAvatarButtonPressed:(id)sender
{
    // currently processing update request?
    if (accountConnection != nil)
        return;
    
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self.submitButton setEnabled:NO];
    
    UserAccount * account = (UserAccount*)self.wizardDataObject;
    account.avatar = nil;
    self.wizardDataObject = account;
    [self performSegueWithIdentifier:@"Create Account - Proceed to Confirmation" sender:self];
}

// ======================================================================================================================================
// Go on to the next screen
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Create Account - Proceed to Confirmation"])
    {
        ((CreateAccountConfirmationViewController*)segue.destinationViewController).delegate = self.delegate;
        ((CreateAccountConfirmationViewController*)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}




// ======================================================================================================================================
#pragma-mark Drawing Controls Methods


// ======================================================================================================================================
// Undo path
- (IBAction)penSelected:(id)sender
{
    [self selectPenAndShowPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)brushSelected:(id)sender
{
    [self selectBrushAndShowPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
   
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)undoPathDrawing:(id)sender 
{
    [self undoLastPath];
}

- (IBAction)calligraphySelected:(id)sender
{
    [self selectCalligraphyToolAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)canvasColorClicked:(id)sender
{
    [self openCanvasColorSelectionPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp animated:YES];
    _canvasSelectionButton = sender;
    [_canvasSelectionButton setSelected:YES];
}


- (IBAction)eraserSelected:(id)sender 
{
    [self selectEraserAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)clearAll:(id)sender
{
    [self clearAll];
}

// ======================================================================================================================================
// ======================================================================================================================================

#pragma-mark DrawingPadViewController Delegate

-(void)drawingControllerDidDismissToolPopover:(UIPopoverController *)popoverController
{
}

-(BOOL)drawingControllerShouldDismissToolPopover:(UIPopoverController *)popoverController
{
    [_canvasSelectionButton setSelected:NO];
    return YES;
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
    accountConnection = nil;
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
    [self.submitButton setEnabled:YES];
    
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
    
    
    
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];
    
    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        [self.submitButton setEnabled:YES];
        return;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = NSLocalizedString(@"Cannot Update Avatar", @"Error title: when new user tries to save new avatar and request returns an error");
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
        
        [self.submitButton setEnabled:YES];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(),
   ^{
        // go on to the next screen.
        [self performSegueWithIdentifier:@"Create Account - Proceed to Confirmation" sender:self];
    });
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}


@end
