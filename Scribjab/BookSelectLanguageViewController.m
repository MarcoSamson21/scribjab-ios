//
//  SelectLanguageViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-09-24.
//
//

#import "BookSelectLanguageViewController.h"

#import "BookManager.h"
#import "LanguageManager.h"
#import "Language+Utils.h"

#import "BookViewController.h"

#import "Utilities.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "NavigationManager.h"
#import "CreateBookNavigationManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

//@interface BookSelectLanguageViewController ()<NSURLConnectionDelegate>
@interface BookSelectLanguageViewController ()
{
    BOOL isPrimaryLanguageSelected;
    BOOL isSecondaryLanguageSelected;

    BOOL hasError;
    BOOL isFirstTime;
    BOOL didLoad;
    UIColor * errorTextBoxBackgroudColor;

//    UITableViewCell *selectedPrimaryLCell;
//    UITableViewCell *selectedSecLCell;
    UIPickerView *selectedPrimaryLCell;
    UIPickerView *selectedSecLCell;
    BookManager *bookManager;
    
    NSMutableArray * languageListData;
    NSMutableDictionary *objectsPassed;

//    NSMutableData * httpResponseData;
//    NSURLConnectionWithID *languageConnection;
    
    NSString* priSelectedLng;
    NSString* secSelectedLng;
}
//- (void) getAllLanguageFromWS;
//- (void) processLanguageResponseData;
- (void) setup;
@end

@implementation BookSelectLanguageViewController

@synthesize primaryLanguageLabel = _primaryLanguageLabel;
//@synthesize togglePrimaryLanguageDropDownButton = _togglePrimaryLanguageDropDownButton;
//@synthesize primaryLanguageListTableView = _primaryLanguageListTableView;
@synthesize primaryLanguagePickerView = _primaryLanguagePickerView;

@synthesize secondaryLanguageLabel = _secondaryLanguageLabel;
//@synthesize toggleSecondaryLanguageDropDownButton = _toggleSecondaryLanguageDropDownButton;
//@synthesize secondaryLanguageListTableView = _secondaryLanguageListTableView;
@synthesize secondaryLanguagePickerView = _secondaryLanguagePickerView;

@synthesize loadingActivity = _loadingActivity;
@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize nextButton = _nextButton;
@synthesize cancelButton = _cancelButton;
@synthesize loginUser = _loginUser;
@synthesize wizardDataObject = _wizardDataObject;
@synthesize isFromHome = _isFromHome;

// ********** CONSTANTS **********
static int const PRIMARY_TABLE_VIEW = 1;
static int const SECONDARY_TABLE_VIEW = 2;
//static int const CONNECTION_LANGUAGE_GET_ALL = 1;

// setter for wizardDataObject
-(void) wizardDataObject:(Book *)book
{
    _wizardDataObject = book;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(didLoad)
        didLoad = FALSE;
    else
        [self setup];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [CreateBookNavigationManager setHomeControllerForCreateBook:self];
    // check if this is the first time the user create book in the current ipad.
    [self setup];
    didLoad = TRUE;
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Select Book Languages Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void) setup
{
    if([self.loginUser.book count]==0)
        isFirstTime = TRUE;
    else
        isFirstTime = FALSE;
    
    //loading language.
    [self.loadingActivity setHidden:YES];
    
    if(objectsPassed == nil)
        objectsPassed = [[NSMutableDictionary alloc] init];
    
    self.wizardDataObject = objectsPassed;
    
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    self.errorMessageLabel.text = NULL;
    self.primaryLanguageLabel.backgroundColor = [UIColor clearColor];
    self.secondaryLanguageLabel.backgroundColor = [UIColor clearColor];
    self.cancelButton.enabled = YES;
    
    self.primaryLanguagePickerView.tag = PRIMARY_TABLE_VIEW;
    self.primaryLanguagePickerView.layer.borderWidth = 0;
//    self.primaryLanguagePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(364.0, 251.0, 137.0, 403.0)];
    selectedPrimaryLCell = nil;
    selectedSecLCell = nil;
    //set secondary language data
    self.secondaryLanguagePickerView.tag = SECONDARY_TABLE_VIEW;
    self.secondaryLanguagePickerView.layer.borderWidth = 0;
//    self.secondaryLanguagePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(668.0, 250.0, 53.0, 403.0)];
    
    languageListData = [[NSMutableArray alloc] initWithArray:[LanguageManager getAllLanguages]];
    
    // Sort by Name
    [languageListData sortUsingDescriptors:
        [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)], nil]
    ];
    
    
//    [self.primaryLanguagePickerView reloadAllComponents];
//    [self.secondaryLanguagePickerView reloadAllComponents];
    
    isPrimaryLanguageSelected = FALSE;
    isSecondaryLanguageSelected = FALSE;
    
    self.nextButton.hidden = YES;
    self.nextButton.enabled = NO;
}

- (void)viewDidUnload
{
    [self setPrimaryLanguageLabel:nil];
    [self setSecondaryLanguageLabel:nil];
    [self setSecondaryLanguagePickerView:nil];
    [self setPrimaryLanguagePickerView:nil];
    [self setNextButton:nil];
    [self setErrorMessageLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================

//cancel button is pressed.
- (IBAction) cancelCreateBook:(id)sender
{
//    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    [self dismissModalViewControllerAnimated:YES];
    
    if(self.isFromHome)
       [NavigationManager navigateToHomeAnimatedWithDuration:0.75F transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
    else
       [NavigationManager navigateToMyLibraryForUser:self.loginUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

- (IBAction)cancelCreateBookAndGoToLibrary:(id)sender
{
//    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    [self dismissModalViewControllerAnimated:YES];
    [NavigationManager navigateToMyLibraryForUser:self.loginUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
    
}


//primary language button is pressed.
//- (IBAction) togglePrimaryLanguageDropDown:(id)sender
//{
//    self.primaryLanguageListTableView.hidden = !self.primaryLanguageListTableView.isHidden;
//}
//
////secondary language button is pressed.
//- (IBAction) toggleSecondaryLanguageDropDown:(id)sender
//{
//    self.secondaryLanguageListTableView.hidden = !self.secondaryLanguageListTableView.isHidden;
//}

- (IBAction)nextButtonIsPress:(id)sender
{
    [self.view endEditing:YES];
    [objectsPassed setObject:self.loginUser forKey:@"user"];
    self.wizardDataObject = objectsPassed;
    
    [CreateBookNavigationManager navigateToBookViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:self.wizardDataObject];
}

//- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    [self.view endEditing:YES];
////    self.primaryLanguageListTableView.hidden = YES;
////    self.secondaryLanguageListTableView.hidden = YES;
//    [objectsPassed setObject:self.loginUser forKey:@"user"];
//
//    self.wizardDataObject = objectsPassed;
//    if ([segue.identifier isEqualToString:@"editBookIdentifier"])
//    {
//        ((BookViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
//    }
//}

// ======================================================================================================================================
#pragma mark Table View data source methods

//- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return [languageListData count];
//}

//- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    //static
//    NSString *simpleTableIdentifier = @"SimpleTableIdentifier";
//    
//    if(tableView.tag == PRIMARY_TABLE_VIEW)
//        simpleTableIdentifier = @"PrimaryTableIdentifier";
//
//    if(tableView.tag == SECONDARY_TABLE_VIEW)
//        simpleTableIdentifier = @"SecondaryTableIdentifier";
//
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
//    if(cell == nil)
//    {
//        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
//    }
//
//    Language *language = [languageListData objectAtIndex:[indexPath row]];
//    if(language != nil)
//    {
//        cell.textLabel.text = language.name;
//        cell.tag = language.remoteId.intValue;
//        cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:16];
//    }
//    return cell;
//}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//    //reset error message.
//    self.primaryLanguageLabel.backgroundColor = nil;
//    self.secondaryLanguageLabel.backgroundColor = nil;
//    self.errorMessageLabel.text = nil;
//    hasError = FALSE;
//    
//    if(tableView.tag == PRIMARY_TABLE_VIEW)
//    {
//        selectedPrimaryLCell = [self.primaryLanguageListTableView cellForRowAtIndexPath:indexPath];
////        self.primaryLanguageLabel.text = [[selectedPrimaryLCell textLabel] text];
////        self.primaryLanguageListTableView.hidden = YES;
//        
//        isPrimaryLanguageSelected = TRUE;
//        
//        Language *selectedLang = [LanguageManager getLanguageByRemoteId:selectedPrimaryLCell.tag];
//        [objectsPassed setObject:selectedLang forKey:@"primaryLanaguage"];
//    }
//    else if(tableView.tag == SECONDARY_TABLE_VIEW)
//    {
//        selectedSecLCell = [self.secondaryLanguageListTableView cellForRowAtIndexPath:indexPath];
////        self.secondaryLanguageLabel.text = [[selectedSecLCell textLabel] text];
////        self.secondaryLanguageListTableView.hidden = YES;
//        
//        Language *selectedLang = [LanguageManager getLanguageByRemoteId:selectedSecLCell.tag];
//        isSecondaryLanguageSelected = TRUE;
//        [objectsPassed setObject:selectedLang forKey:@"secondaryLanaguage"];
//    }
//
//    //check if the user has selected the same language. If yes, error message and hide the submit button.
//    if(selectedPrimaryLCell.tag == selectedSecLCell.tag)
//    {
//        if(tableView.tag == PRIMARY_TABLE_VIEW)
//        {
//            self.primaryLanguageLabel.backgroundColor = errorTextBoxBackgroudColor;
//        }
//        else if(tableView.tag == SECONDARY_TABLE_VIEW)
//        {   
//            self.secondaryLanguageLabel.backgroundColor = errorTextBoxBackgroudColor;
//        }
//        hasError = TRUE;
//        self.errorMessageLabel.text = NSLocalizedString(@"Please select a different language", @"check if user selected the same language.");
//    }
//    
//    if(!hasError && isPrimaryLanguageSelected && isSecondaryLanguageSelected)
//    {
//        self.nextButton.hidden = NO;
//        self.nextButton.enabled = YES;
//    }
//    else
//    {
//        self.nextButton.hidden = YES;
//        self.nextButton.enabled = NO;
//    }
//}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [languageListData count];
}

- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    Language *language = [languageListData objectAtIndex:row];
    return language.name;
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //reset error message.
    self.primaryLanguageLabel.backgroundColor = nil;
    self.secondaryLanguageLabel.backgroundColor = nil;
    self.errorMessageLabel.text = nil;
    hasError = FALSE;
    
    if(pickerView.tag == PRIMARY_TABLE_VIEW)
    {
//        selectedPrimaryLCell = [self.primaryLanguagePickerView cellForRowAtIndexPath:indexPath];
        //        self.primaryLanguageLabel.text = [[selectedPrimaryLCell textLabel] text];
        //        self.primaryLanguageListTableView.hidden = YES;
        
        isPrimaryLanguageSelected = TRUE;
    
        Language *selectedLang = languageListData[row];//[LanguageManager getLanguageByRemoteId:(int)row];
        priSelectedLng = selectedLang.name;
        [objectsPassed setObject:selectedLang forKey:@"primaryLanaguage"];
    }
    else if(pickerView.tag == SECONDARY_TABLE_VIEW)
    {
//        selectedSecLCell = [self.primaryLanguagePickerView cellForRowAtIndexPath:indexPath];
        //        self.secondaryLanguageLabel.text = [[selectedSecLCell textLabel] text];
        //        self.secondaryLanguageListTableView.hidden = YES;
        
        Language *selectedLang = languageListData[row];//[LanguageManager getLanguageByRemoteId:(int)row];
        isSecondaryLanguageSelected = TRUE;
        secSelectedLng = selectedLang.name;
        [objectsPassed setObject:selectedLang forKey:@"secondaryLanaguage"];
    }
    
//    check if the user has selected the same language. If yes, error message and hide the submit button.
    if(priSelectedLng == secSelectedLng)
    {
        if(pickerView.tag == PRIMARY_TABLE_VIEW)
        {
            self.primaryLanguageLabel.backgroundColor = errorTextBoxBackgroudColor;
        }
        else if(pickerView.tag == SECONDARY_TABLE_VIEW)
        {
            self.secondaryLanguageLabel.backgroundColor = errorTextBoxBackgroudColor;
        }
        hasError = TRUE;
        self.errorMessageLabel.text = NSLocalizedString(@"Please select a different language", @"check if user selected the same language.");
    }
    
    if(!hasError && isPrimaryLanguageSelected && isSecondaryLanguageSelected)
    {
        self.nextButton.hidden = NO;
        self.nextButton.enabled = YES;
    }
    else
    {
        self.nextButton.hidden = YES;
        self.nextButton.enabled = NO;
    }

}

// ======================================================================================================================================
//- (void) getAllLanguageFromWS
//{
//    if (languageConnection != nil)
//        return;
//    httpResponseData = [[NSMutableData alloc] initWithLength:10];
//    
//    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_LANGUAGE_GET_ALL]];
//    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
//    [URLRequestUtilities setCommonOptionsToURLRequest:request];
//    
//    [languageConnection cancel];
//    languageConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_LANGUAGE_GET_ALL];
//    
//    return;
//}
//
////process language response data
//-(void) processLanguageResponseData
//{
//    // do something with the json that comes back
//    NSError * error = NULL;
//    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseData options:kNilOptions error:&error];
//    if (error != NULL)
//    {
//        //try loading from core data
//        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
//        return;
//    }
//    
//    languageListData = [responseDictionary objectForKey:@"result"];
//    if (languageListData != nil)
//    {
//        [LanguageManager addOrUpdateLanguages:languageListData];
//        languageListData = [LanguageManager getAllLanguages];
//    }
//
//    [self.primaryLanguageListTableView reloadData];
//    [self.secondaryLanguageListTableView reloadData];
//    //enable buttons.
//    [self.loadingActivity stopAnimating];
//    [self.loadingActivity setHidden:YES];
////    self.togglePrimaryLanguageDropDownButton.enabled = YES;
////    self.toggleSecondaryLanguageDropDownButton.enabled = YES;
//    self.cancelButton.enabled = YES;
//}
//
//// ======================================================================================================================================
//#pragma-mark Connection Delegate Methods
//
//// THESE ARE TO HANDLE ASYNC REQUESTS
//
//// ======================================================================================================================================
//// Process server initial response
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    [httpResponseData setLength:0];
//}
//// ======================================================================================================================================
//// Process incoming data
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [httpResponseData appendData:data];
//}
//// ======================================================================================================================================
//// Process connection error
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//    languageConnection = nil;
//    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
//    
//    languageListData = [LanguageManager getAllLanguages];
//
//    [self.primaryLanguageListTableView reloadData];
//    [self.secondaryLanguageListTableView reloadData];
//    //enable buttons.
//    [self.loadingActivity stopAnimating];
//    [self.loadingActivity setHidden:YES];
////    self.togglePrimaryLanguageDropDownButton.enabled = YES;
////    self.toggleSecondaryLanguageDropDownButton.enabled = YES;
//    self.cancelButton.enabled = YES;
//
//}
//// ======================================================================================================================================
//// Do something with received data
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    switch (((NSURLConnectionWithID*)connection).identification)
//    {
//        case CONNECTION_LANGUAGE_GET_ALL:
//            [self processLanguageResponseData];
//            break;
//        default:
//            break;
//    }
//    
//    languageConnection = nil;
//}
//// ======================================================================================================================================
//// return cached respone
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
//{
//    return cachedResponse;
//}

@end
