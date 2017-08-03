//
//  SearchInputViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-07.
//
//

#import "SearchInputViewController.h"
#import "SearchBookItemSelectionTableViewController.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "URLRequestUtilities.h"
#import "AgeGroup.h"
#import "LanguageManager.h"
#import "Language+Utils.h"
#import "Utilities.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************
@interface SearchItemAny : NSObject @end @implementation SearchItemAny @end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

static NSMutableArray * AGE_GROUPS = nil;

static int const SEGUE_AGE_GROUP = 1;
static int const SEGUE_FIRST_LANGUAGE = 2;
static int const SEGUE_SECOND_LANGUAGE = 3;

@interface SearchInputViewController () <NSURLConnectionDelegate, SearchBookItemSelectionTableViewControllerDelegate>
{
    NSURLConnection * _connection;
    NSMutableData * _httpData;
    SearchBookItemSelectionTableViewController * _selectionView;
    UIPopoverController * _pop;
    NSArray * _languageDataSource;
    
    NSNumber * _ageGroupSelection;
    NSNumber * _firstLanguaeSelection;
    NSNumber * _secondLanguageSelection;
}

- (void) loadAgeGroups;
- (void) initButton:(UIButton *) button;
+ (SearchItemAny*) anyItem;         // returns "any/don't care/anything/all" item selection

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation SearchInputViewController

@synthesize delegate;
@synthesize parentPopover;

// ======================================================================================================================================
// ======================================================================================================================================
// put any object in a dictionary and specify which name to display in the selection table view
+ (NSDictionary*) wrapObjectInDictionary:(id)object withDisplayName:(NSString*)name
{
    NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:object, @"object", name, @"name", nil];
    return dict;
}

// ==============================================================================
// returns "any/don't care/anything/all" item selection
+(SearchItemAny *)anyItem
{
    return [[SearchItemAny alloc] init];
}



// ======================================================================================================================================
// ======================================================================================================================================


// ===============================================================================
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
    
    [self initButton:self.ageGroupButton];
    [self initButton:self.firstLanguageButton];
    [self initButton:self.secondLanguageButton];
    
    [self loadAgeGroups];
}

// Setup button colors and borders
- (void) initButton:(UIButton *) button
{
    if (button == nil)
        return;
    
    button.layer.borderColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2F alpha:0.2F].CGColor;
    button.layer.borderWidth = 1.0f;
    [button.layer setMasksToBounds:YES];
    button.layer.cornerRadius = 8.0f;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setAgeGroupButton:nil];
    [self setFirstLanguageButton:nil];
    [self setSecondLanguageButton:nil];
    [self setTagsTextInput:nil];
    [self setSubmitButton:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
-(void)viewWillAppear:(BOOL)animated
{
}

// ===============================================================================
- (IBAction)submitSearch:(id)sender
{
    NSMutableString * searchSummary = [[NSMutableString alloc] initWithCapacity:30];
    
    NSString * keywords = [self.tagsTextInput.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (keywords != nil)
        [searchSummary appendString:keywords];
    
    if (_ageGroupSelection != nil)
        [searchSummary appendFormat:@" - %@", [self.ageGroupButton titleForState:UIControlStateNormal]];
    
    if (_firstLanguaeSelection != nil)
        [searchSummary appendFormat:@" - %@", [self.firstLanguageButton titleForState:UIControlStateNormal]];
    
    if (_secondLanguageSelection != nil)
        [searchSummary appendFormat:@" - %@", [self.secondLanguageButton titleForState:UIControlStateNormal]];
    
  //  searchSummary = [searchSummary stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]];
    
    [self.delegate searchCriteriaSelectedAgeGroupId:_ageGroupSelection firstLanguage:_firstLanguaeSelection secondLanguage:_secondLanguageSelection keywords:self.tagsTextInput.text searchSummary:[searchSummary stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]]];
    [parentPopover dismissPopoverAnimated:YES];
}

// ===============================================================================
// Load age groups from the server and store them in a static variable
-(void)loadAgeGroups
{
    if (AGE_GROUPS != nil)
        return;
    
    if (_connection != nil)
        return;
    
    if (_httpData == nil)
        _httpData = [[NSMutableData alloc] initWithCapacity:1024];
    
    // books/users/languages/groups
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_AGEGROUP_GET_ALL]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [self.activityIndicator startAnimating];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

// ===============================================================================
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    _selectionView = segue.destinationViewController;
    _selectionView.delegate = self;
    _selectionView.parentPopover = [((UIStoryboardPopoverSegue*)segue) popoverController];
    
    if ([segue.identifier isEqualToString:@"Search Selection Age Group Item Choice"])
    {
        _selectionView.tag = SEGUE_AGE_GROUP;
        _selectionView.dataSource = AGE_GROUPS;
        
        if (AGE_GROUPS == nil)
            [self loadAgeGroups];
        
        return;
    }
    
    // ----------------- Show language selections ----------------- 
    
    // Show language selections
    if ([segue.identifier isEqualToString:@"Search Selection First Language Item Choice"])
    {
        _selectionView.tag = SEGUE_FIRST_LANGUAGE;
    }
    else
    {
        _selectionView.tag = SEGUE_SECOND_LANGUAGE;
    }
    
    if (_languageDataSource != nil)
    {
        _selectionView.dataSource = _languageDataSource;
        return;
    }
    
    // Compile language data source
    NSSortDescriptor * sortDesc = [[NSSortDescriptor alloc] initWithKey:[Utilities localizedStringFromEnglish:@"nameEnglish" french:@"nameFrench"] ascending:YES];
    NSArray * languages = [[LanguageManager getAllLanguages] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    NSMutableArray * dataSource = [[NSMutableArray alloc] initWithCapacity:languages.count + 1];
    
    // create and insert "Any" selection option
    [dataSource addObject:[SearchInputViewController wrapObjectInDictionary:[[SearchItemAny alloc] init] withDisplayName:[Utilities localizedStringFromEnglish:@"Any language" french:@"Toute langue"]]];
    for (Language * lang in languages)
    {
        [dataSource addObject:[SearchInputViewController wrapObjectInDictionary:lang withDisplayName:lang.name]];
    }
    
    _selectionView.dataSource = dataSource;
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-marl SearchBookItemSelectionTableViewControllerDelegate methods

// ======================================================================================================================================
// Item selection is made, place in in the correct container. 
- (void)searchItemSelected:(id)item
{
    [_selectionView.parentPopover dismissPopoverAnimated:YES];
    
    // which selection was made?
    
    // Age Group?
    if (_selectionView.tag == SEGUE_AGE_GROUP)
    {
        id object = [item objectForKey:@"object"];
        if ([object isKindOfClass:[SearchItemAny class]])
        {
            [self.ageGroupButton setTitle:@"" forState:UIControlStateNormal];
            _ageGroupSelection = nil;
        }
        else
        {
            [self.ageGroupButton setTitle:[item objectForKey:@"name"] forState:UIControlStateNormal];
            _ageGroupSelection = ((AgeGroup*)object).remoteId;
        }
    }
    
    // First Language?
    if (_selectionView.tag == SEGUE_FIRST_LANGUAGE)
    {
        id object = [item objectForKey:@"object"];
        if ([object isKindOfClass:[SearchItemAny class]])
        {
            [self.firstLanguageButton setTitle:@"" forState:UIControlStateNormal];
            _firstLanguaeSelection = nil;
        }
        else
        {
            [self.firstLanguageButton setTitle:[item objectForKey:@"name"] forState:UIControlStateNormal];
            _firstLanguaeSelection = ((Language*)object).remoteId;
        }
    }
    
    // Second Language?
    if (_selectionView.tag == SEGUE_SECOND_LANGUAGE)
    {
        id object = [item objectForKey:@"object"];
        if ([object isKindOfClass:[SearchItemAny class]])
        {
            [self.secondLanguageButton setTitle:@"" forState:UIControlStateNormal];
            _secondLanguageSelection = nil;
        }
        else
        {
            [self.secondLanguageButton setTitle:[item objectForKey:@"name"] forState:UIControlStateNormal];
            _secondLanguageSelection = ((Language*)object).remoteId;
        }
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
    _httpData = nil;
    [self.activityIndicator stopAnimating];
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString * errorTitle = NSLocalizedString(@"Cannot retrieve a list of age groups", @"Error title: Search books section, failed to get a list of age groups from the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    
    if (responseData == nil)
    {
        [self.activityIndicator stopAnimating];
        _connection = nil;
        return;
    }
    
    responseData = [responseData objectForKey:@"result"];
    
    AGE_GROUPS = [[NSMutableArray alloc] initWithCapacity:responseData.count+1];

    //[AGE_GROUPS addObject:[SearchInputViewController wrapObjectInDictionary:[[SearchItemAny alloc] init] withDisplayName:groupAny.name]];   // "Any group" selection
    [AGE_GROUPS addObject:[SearchInputViewController wrapObjectInDictionary:[[SearchItemAny alloc] init] withDisplayName:[Utilities localizedStringFromEnglish:@"Any age group" french:@"Tout groupe d'âge"]]];
    for (NSDictionary * dictionary in responseData)
    {
        AgeGroup * ageGr = [[AgeGroup alloc] initWithDictionary:dictionary];
        [AGE_GROUPS addObject:[SearchInputViewController wrapObjectInDictionary:ageGr withDisplayName:ageGr.name]];
    }

    _connection = nil;
    [self.activityIndicator stopAnimating];
    
    // If user is waiting for age groups to appear in the popup view - update the values right away.
    if (_selectionView != nil && _selectionView.tag == SEGUE_AGE_GROUP)
        _selectionView.dataSource = AGE_GROUPS;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

@end



