//
//  PublishBookViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-22.
//
//

#import "PublishBookViewController.h"
#import "URLRequestUtilities.h"
#import "NSString+URLEncoding.h"
#import "NSURLConnectionWithID.h"
#import "Globals.h"
#import "CommonMessageBoxes.h"
#import "DocumentHandler.h"
#import "User.h"
#import "BookManager.h"
#import "UserGroupManager.h"
#import "Utilities.h"
#import "ZipArchive.h"
#import "UIColor+HexString.h"
#import "NavigationManager.h"
#import "ModalConstants.h"
#import "LoginRegistrationManager.h"
#import "CreateBookNavigationManager.h"
#import "PublishBookTermOfUseViewController.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface PublishBookViewController ()<NSURLConnectionDelegate>
{
    BOOL hasValidationError;
    BOOL hasAudio;
    BOOL hasUploadError;
    BOOL isDesc1Edited;
    BOOL isDesc2Edited;
    UIColor * errorTextBoxBackgroudColor;
    
    BookManager *bookManager;
    
    NSMutableArray * ageGroupListData;
    NSMutableArray * userGroupListData;
    NSMutableSet * audioZipFilePathSet;
    int selectedAgeGroupId;
    int selectedUserGroupId;
    float totalFileCount;
    int currentFileUploadCount;
    NSMutableData * httpResponseAgeGroupData;
    NSMutableData * httpResponseUserGroupData;
    NSMutableData * httpResponseBookData;
    NSMutableData * httpResponseBookPagesData;
    NSMutableData * httpResponsesUploadData;
    NSMutableData * httpResponseDownloadData;
    NSMutableData * httpResponseDeleteBookData;
    NSURLConnectionWithID *ageGroupConnection;
    NSURLConnectionWithID *userGroupConnection;
    NSURLConnectionWithID *bookConnection;
    NSURLConnectionWithID *bookPagesConnection;
    NSURLConnectionWithID *downloadConnection;
    NSURLConnectionWithID *deleteBookConnection;
    
    BOOL isDesc1AudioRecorded;
    BOOL isDesc2AudioRecorded;
    
    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audioTitle1AbsPath;
    NSString *audioTitle2AbsPath;
    NSString *audioDesc1AbsPath;
    NSString *audioDesc2AbsPath;
    NSString * requiredMessage;
    AVAudioPlayer *audioPlayer;
    NSURL *playURL;
}
- (void) bookHasSubmittedForApproval;
- (void) getAllAgeGroupsFromWS;
- (void) getAllUserGroupsFromWS;
- (void) setup;
- (void) enableAllControls;
- (void) moveMP3Files;
- (void) uploadFile:(NSString*)fileAbsPath bookId:(NSNumber *)bookId bookPageId:(NSNumber *)bookPageId bookType:(int)bookType isLast:(BOOL)isLast;
- (void) getAndUploadAudio:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName zipFileName:(NSString *)zipFileName bookItem:(id) bookItem bookPageId:(NSNumber *) bookPageId bookType:(int) bookType;
- (void) presentAudioRecordingPopover:(int)buttonPressed;
- (void) changeAudioButton;
- (NSString *) getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName;
- (void) enableButtonsForPlayDesc1:(bool) playDesc1 playDesc2:(bool) playDesc2 recordDesc1:(bool)recordDesc1 recordDesc2:(bool)recordDesc2;
- (void) changeToPlayMode:(UIButton *)button fileAbsPath:(NSString *)fileAbsPath;
- (void) resetPlayAudioButtons;
- (void) resetAudioButton:(UIButton *) button fileAbsURL:(NSString *)fileAbsURL;
- (void) changeToStopMode:(UIButton *)button;
@end

@implementation PublishBookViewController

@synthesize noGroupLabel = _noGroupLabel;
@synthesize titleLabel = _titleLabel;
@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize thumbImageView = _thumbImageView;
@synthesize ageGroupTableView = _ageGroupTableView;
@synthesize userGroupTableView = _userGroupTableView;
@synthesize searchTagTextField = _searchTagTextField;
@synthesize termsButton =_termsButton;
@synthesize publishButton = _publishButton;
@synthesize cancelButton = _cancelButton;
@synthesize uploadActivity = _uploadActivity;
@synthesize uploadProgress = _uploadProgress;
@synthesize uploadingLabel = _uploadingLabel;
@synthesize book = _book;
@synthesize delegate;

@synthesize primaryLanguageDescLabel = _primaryLanguageDescLabel;
@synthesize secondaryLanguageDescLabel = _secondaryLanguageDescLabel;

@synthesize description1TextField = _description1TextField;
@synthesize description2TextField = _description2TextField;
@synthesize description1AudioRecordButton = _description1AudioRecordButton;
@synthesize description2AudioRecordButton = _description2AudioRecordButton;

@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;

static int const DESC1_TEXT_VIEW = 3;
static int const DESC2_TEXT_VIEW = 4;
static int const DESC_MAX_LENGTH = 250;

static int const DESC1_AUDIO = 3;
static int const DESC2_AUDIO = 4;
static int const PLAY_MODE = 1;
static int const STOP_MODE = 0;

static CGFloat const CORNER_RADIUS = 9.0;

@synthesize playDesc1AudioButton = _playDesc1AudioButton;
@synthesize playDesc2AudioButton = _playDesc2AudioButton;


// ********** CONSTANTS **********
static int const SEARCHTAG_TEXT_FIELD = 1;
static int const PUSH_Y_FOR_SEARCHTAG = 200;
static int const PUSH_Y_FOR_DESC1 = 70;
static int const PUSH_Y_FOR_DESC2 = 150;

static CGFloat const TEXT_ANIMATION_DURATION = 0.25;
static int const SEARCHTAG_MAX_LENGTH = 100;

static int const AGEGROUP_TABLE_VIEW = 1;
static int const USERGROUP_TABLE_VIEW = 2;
static int const ALERT_PUBLISHED = 1;

static int const CONNECTION_AGEGROUP_GET_ALL = 1;
static int const CONNECTION_USERGROUP_GET_ALL = 2;
static int const CONNECTION_ADD_BOOK = 3;
static int const CONNECTION_UPLOAD_FILE = 4;
static int const CONNECTION_DOWNLOAD_FILE = 5;
static int const CONNECTION_LAST_UPLOAD_FILE = 6;
static int const CONNECTION_ADD_BOOK_PAGES = 7;
static int const CONNECTION_DELETE_BOOK = 8;
static int const NOT_SELECTED = -1;

-(IBAction) showTermsOfUseView:(id)sender
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
    PublishBookTermOfUseViewController * tou = [storyboard instantiateViewControllerWithIdentifier:@"Publish Book - Term of Use"];
    
    tou.modalPresentationStyle = UIModalPresentationPageSheet;
    tou.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:tou animated:YES completion:^{}];
}

-(IBAction) cancelButtonPressed:(id)sender
{
    [CreateBookNavigationManager navigateToBookViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:self.book];
}

// enable all controlls again.
-(void) enableAllControls
{
    self.description1TextField.enabled = YES;
    self.description2TextField.enabled = YES;
    self.description1AudioRecordButton.enabled = YES;
    self.description2AudioRecordButton.enabled = YES;
    self.playDesc1AudioButton.enabled = YES;
    self.playDesc2AudioButton.enabled = YES;
    self.termsButton.enabled = YES;
    self.userGroupTableView.scrollEnabled = YES;
    self.ageGroupTableView.scrollEnabled = YES;
    self.searchTagTextField.enabled = YES;
    self.publishButton.enabled = YES;
    self.cancelButton.enabled = YES;
    self.uploadingLabel.hidden = YES;
    self.uploadProgress.hidden = YES;
//    [self.uploadActivity stopAnimating];
//    [self.uploadActivity setHidden:YES];
}

- (void) setup
{
//    [self.uploadActivity startAnimating];
    [self.uploadActivity setHidden:YES];
//    isDesc1Edited= FALSE;
//    isDesc2Edited = FALSE;
    requiredMessage = @"";
    self.primaryLanguageDescLabel.text = [self.book.primaryLanguage.nameEnglish stringByAppendingString:@":"];
    self.secondaryLanguageDescLabel.text = [self.book.secondaryLanguage.nameEnglish stringByAppendingString:@":"];
    self.searchTagTextField.text = self.book.tagSummary;
    self.noGroupLabel.hidden = YES;
    self.userGroupTableView.hidden = YES;
    self.userGroupTableView.scrollEnabled = NO;
    self.ageGroupTableView.scrollEnabled = NO;
    self.searchTagTextField.enabled = NO;
    self.searchTagTextField.tag = SEARCHTAG_TEXT_FIELD;
    self.searchTagTextField.delegate = self;
    self.description1TextField.delegate = self;
    self.description2TextField.delegate = self;
    self.description1TextField.tag = DESC1_TEXT_VIEW;
    self.description2TextField.tag = DESC2_TEXT_VIEW;
    self.description1TextField.layer.cornerRadius = CORNER_RADIUS;
    self.description1TextField.layer.masksToBounds = YES;
    self.description2TextField.layer.cornerRadius = CORNER_RADIUS;
    self.description2TextField.layer.masksToBounds = YES;
    
    audioZipFilePathSet = [[NSMutableSet alloc]init];

    //set the audio popover size.
    audioPopoverSize = CGSizeMake(400, 300);
    audioDesc1AbsPath = [self getAudioAbsPath:BOOK_DESC_1_AUDIO_FILENAME mp3FileName:BOOK_DESC_1_AUDIO_FILENAME_MP3];
    audioDesc2AbsPath = [self getAudioAbsPath:BOOK_DESC_2_AUDIO_FILENAME mp3FileName:BOOK_DESC_2_AUDIO_FILENAME_MP3];
    
    [self changeAudioButton];
    [self resetPlayAudioButtons];

    self.publishButton.enabled = NO;
    self.cancelButton.enabled = NO;
    [self getAllAgeGroupsFromWS];
    [self getAllUserGroupsFromWS];

    if(self.book != nil)
    {
        //initial text for description1.
        self.description1TextField.text = (self.book.description1 ==nil? NSLocalizedString(@"Enter the book description.", @"Description for book description."): self.book.description1);
        
        //initial text for description2.
        self.description2TextField.text = (self.book.description2 ==nil? NSLocalizedString(@"Enter the book description.", @"Description for book description."): self.book.description2);

        //set up the title1, title2 and thumbImageView.
        self.titleLabel.text = [[self.book.title1 stringByAppendingString:@" / "]
                                stringByAppendingString:self.book.title2];
        self.thumbImageView.image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:self.book fileName:BOOK_THUMBNAIL_FILENAME]];
        self.thumbImageView.backgroundColor = [UIColor colorWithHexString:self.book.backgroundColorCode];
        //set ageGroup data
        self.ageGroupTableView.dataSource = self;
        self.ageGroupTableView.delegate = self;
        self.ageGroupTableView.tag = AGEGROUP_TABLE_VIEW;

        //set userGroup data
        self.userGroupTableView.dataSource = self;
        self.userGroupTableView.delegate = self;
        self.userGroupTableView.tag = USERGROUP_TABLE_VIEW;
    }
    selectedUserGroupId = NOT_SELECTED;
    selectedAgeGroupId = NOT_SELECTED;
    self.errorMessageLabel.hidden = YES;
    
    totalFileCount = 1.0F;
    [self.uploadProgress setHidden:YES];
    [self.uploadingLabel setHidden:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    [self resetFieldsWhenUploadHasError]; //for testing only.
    [self setup];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Publish Book Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
}

- (void)viewDidUnload
{
    [self setNoGroupLabel:nil];
    [self setTitleLabel:nil];
    [self setThumbImageView:nil];
    [self setErrorMessageLabel:nil];
    [self setAgeGroupTableView:nil];
    [self setUserGroupTableView:nil];
    [self setSearchTagTextField:nil];
    [self setPublishButton:nil];
    [self setTermsButton:nil];
    [self setUploadingLabel:nil];
    [self setUploadProgress:nil];
    
    [self setCancelButton:nil];
    [self setUploadActivity:nil];
    [self setPrimaryLanguageDescLabel:nil];
    [self setSecondaryLanguageDescLabel:nil];
    [self setDescription1TextField:nil];
    [self setDescription2TextField:nil];
    
    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setDescription1AudioRecordButton:nil];
    [self setDescription2AudioRecordButton:nil];
    
    [self setPlayDesc1AudioButton:nil];
    [self setPlayDesc2AudioButton:nil];
    
    [super viewDidUnload];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:TRUE];
}

// ======================================================================================================================================
#pragma mark Text Field data source methods
// set the max. length of search tag.
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
{
    NSUInteger newLength = (textField.text.length - range.length) + text.length;
    
    if(textField.tag == SEARCHTAG_TEXT_FIELD)
    {
        if(newLength <= SEARCHTAG_MAX_LENGTH)
        {
            return YES;
        } else {
            NSUInteger emptySpace = SEARCHTAG_MAX_LENGTH - (textField.text.length - range.length);
            textField.text = [[[textField.text substringToIndex:range.location]
                               stringByAppendingString:[text substringToIndex:emptySpace]]
                              stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
            return NO;
        }
    }
    if(textField.tag == DESC1_TEXT_VIEW || textField.tag == DESC2_TEXT_VIEW)
    {
        if(newLength <= DESC_MAX_LENGTH)
        {
            return YES;
        } else {
            NSUInteger emptySpace = DESC_MAX_LENGTH - (textField.text.length - range.length);
            textField.text = [[[textField.text substringToIndex:range.location]
                              stringByAppendingString:[text substringToIndex:emptySpace]]
                             stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
            return NO;
        }
    }

    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //reset the text in textview.
    if(textField.tag == SEARCHTAG_TEXT_FIELD)
    {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_FOR_SEARCHTAG, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
    }
    //reset the text in textview.
    if(textField.tag == DESC1_TEXT_VIEW || textField.tag == DESC2_TEXT_VIEW)
    {
        
        if([textField.text isEqualToString:NSLocalizedString(@"Enter the book description.", @"Description for book description.")])
            textField.text = @"";
        
        int PUSH_Y = 0;
        if(textField.tag == DESC1_TEXT_VIEW)
        {
            PUSH_Y = PUSH_Y_FOR_DESC1;
        }
        if(textField.tag == DESC2_TEXT_VIEW)
        {
            PUSH_Y = PUSH_Y_FOR_DESC2;
        }
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
    }

}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField.tag == SEARCHTAG_TEXT_FIELD)
    {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_FOR_SEARCHTAG, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
    }
    
    if(textField.tag == DESC1_TEXT_VIEW)
    {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_FOR_DESC1, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
        [self saveBook];
    }
    
    if(textField.tag == DESC2_TEXT_VIEW)
    {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_FOR_DESC2, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
        [self saveBook];
    }
}

 
#pragma mark Table View data source methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView.tag == AGEGROUP_TABLE_VIEW)
        return [ageGroupListData count];
    if(tableView.tag == USERGROUP_TABLE_VIEW)
        return [userGroupListData count];
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static
    NSString *simpleTableIdentifier = @"SimpleTableIdentifier";
    if(tableView.tag == AGEGROUP_TABLE_VIEW)
        simpleTableIdentifier = @"AgeGroupTableIdentifier";
    
    if(tableView.tag == USERGROUP_TABLE_VIEW)
        simpleTableIdentifier = @"UserGroupTableIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if(tableView.tag == AGEGROUP_TABLE_VIEW)
    {
        NSDictionary *item = [ageGroupListData objectAtIndex:[indexPath row]];
        if(item != nil)
        {
            cell.textLabel.text = [item objectForKey:@"name"];
            NSString *dbId = [item objectForKey:@"id"];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
            cell.tag = dbId.intValue;
        }
    }
    if(tableView.tag == USERGROUP_TABLE_VIEW)
    {
        NSDictionary *item = [userGroupListData objectAtIndex:[indexPath row]];
//        UserGroups *group = [userGroupListData objectAtIndex:[indexPath row]];
        if(item != nil)
        {
            cell.textLabel.text = [item objectForKey:@"groupName"];
            NSString *dbId = [item objectForKey:@"groupId"];
            cell.tag = dbId.intValue;
//            cell.textLabel.text = group.name;
//            cell.tag = [group.remoteId intValue];
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //reset error message.
    self.errorMessageLabel.text = nil;
    hasValidationError = FALSE;
    
    if(tableView.tag == AGEGROUP_TABLE_VIEW)
    {
        selectedAgeGroupId = [self.ageGroupTableView cellForRowAtIndexPath:indexPath].tag;
    }
    else if(tableView.tag == USERGROUP_TABLE_VIEW)
    {
        selectedUserGroupId = [self.userGroupTableView cellForRowAtIndexPath:indexPath].tag;
        self.errorMessageLabel.hidden = YES;
    }
}

//getting all age groups from server
-(void) getAllAgeGroupsFromWS
{
    if (ageGroupConnection != nil)
        return;
    httpResponseAgeGroupData = [[NSMutableData alloc] initWithLength:10];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_AGEGROUP_GET_ALL]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [ageGroupConnection cancel];
    ageGroupConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_AGEGROUP_GET_ALL];
    
    return;
}

//process ageGroup response data
-(void) processAgeGroupsResponseData
{
    // do something with the json that comes back 
    NSError * error = NULL;
    NSDictionary *  responseDictionary = [NSJSONSerialization JSONObjectWithData:httpResponseAgeGroupData options:kNilOptions error:&error];
    
    if (error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        [self enableAllControls];
        return;
    }
    
    ageGroupListData = [responseDictionary objectForKey:@"result"];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.book.ageGroupRemoteId intValue] inSection:0];
    [self.ageGroupTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.ageGroupTableView didSelectRowAtIndexPath:indexPath];

    [self.ageGroupTableView reloadData];
    [self enableAllControls];
}

-(void) getAllUserGroupsFromWS
{
    if (userGroupConnection != nil)
        return;
    httpResponseUserGroupData = [[NSMutableData alloc] initWithLength:10];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL_AUTH, URL_USERGROUP_MEMBERSHIP, [NSString stringWithFormat:@"%d",  self.book.author.remoteId.intValue]]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    
    [userGroupConnection cancel];
    userGroupConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_USERGROUP_GET_ALL];
    
    return;
}

//Force logout if auth error.
- (void) logoutIfAuthError
{
    [LoginRegistrationManager logout];
    [LoginRegistrationManager showLoginWithParent:self delegate:(id<LoginViewControllerDelegate>)self registrationButton:YES];
}

//common process response data.
//errorMessageTitle will be localized in the function.
-(id) processResponseData:(NSMutableData *) data withErrorMessageTitle:(NSString *)errorMessageTitle indicateIfError:(BOOL*)isError indicateIfAuthenticationError:(BOOL*)isAuthError
{
    if (isError != NULL)
        *isError = YES;
    if (isAuthError != NULL)
        *isAuthError = NO;
    
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    //status fail.
    if (responseDictionary == nil || error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        [self logoutIfAuthError];
        return nil;
    }
    else if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = errorMessageTitle;
        NSString * errorBody = NSLocalizedString(@"UNKNOWN ERROR", @"unknown error from server");
        
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            errorBody = [errArr componentsJoinedByString:@"\n"];
            if (isError != NULL)
                *isError = YES;
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
            if (isError != NULL)
                *isError = YES;
        }
        
        // Auth Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_AUTH_FAIL])
        {
            errorBody = [responseDictionary objectForKey:@"message"];
            if (isAuthError != NULL)
                *isAuthError = YES;
            //update user login status
            errorTitle = NSLocalizedString(@"Authorization Fail. Please sign in again.", @"Message whe authorization fail.");
            [self logoutIfAuthError];
            return nil;
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
        
        return nil;
    }
    
    //get result.
    *isError = NO;
    return [responseDictionary objectForKey:@"result"];
}


//process userGroup response data
-(void) processUserGroupsResponseData
{
    BOOL isAuthError = NO;
    BOOL isError = NO;
    
    id result = [self processResponseData:httpResponseUserGroupData withErrorMessageTitle:NSLocalizedString(@"An error occur when retrieving user group.", @"Error Message when fail to retrieve user group.") indicateIfError:&isError indicateIfAuthenticationError:&isAuthError];
    
    if(isAuthError)
        return;
    
    if(isError)
    {
        [self enableAllControls];
        return;
    }
    
    if (result != nil)
    {
        NSMutableArray * mArr = [result mutableCopy];
        if([mArr count] !=0)
        {
            //construct the table view.
            userGroupListData = [[NSMutableArray alloc]init];
            [userGroupListData addObjectsFromArray:mArr];
            //update db.
            NSMutableArray *groupArr = [[NSMutableArray alloc]init];
            
            for(NSDictionary * groupDetails in mArr)
            {
                NSDictionary *newDict = [[NSDictionary alloc]initWithObjectsAndKeys: [groupDetails objectForKey:@"groupId"],@"id",
                                         [groupDetails objectForKey:@"groupName"], @"name",
                                         nil];
                [groupArr addObject:newDict];
            }
            
            [UserGroupManager addOrUpdateUserGroups:groupArr];
            self.noGroupLabel.hidden = YES;
            self.userGroupTableView.hidden = NO;
        }
        else
        {
            self.noGroupLabel.hidden = NO;
            self.userGroupTableView.hidden = YES;
        }
    }
    else
    {
        self.noGroupLabel.hidden = NO;
        self.userGroupTableView.hidden = YES;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.book.userGroup.remoteId intValue] inSection:0];
    [self.userGroupTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.userGroupTableView didSelectRowAtIndexPath:indexPath];    
    [self.userGroupTableView reloadData];
}

-(void) publishBookErrorLoginRequired
{
    [LoginRegistrationManager showLoginWithParent:self delegate:(id<LoginViewControllerDelegate>)self registrationButton:NO];
}

//*******************************************************************************************************************//
// Publish Book
//*******************************************************************************************************************//
-(IBAction) publishButtonPressed:(id)sender
{
    [self validate];
    //check if both desc have entered.
    if(!isDesc1Edited || !isDesc2Edited)
    {
        return;
    }

    NSString *objectId = [[[self.book objectID] URIRepresentation] lastPathComponent];
    NSString *absPath = [Utilities getAbsoluteFile:[NSString stringWithFormat:@"%@%@%@", @"books/", objectId, @"/"]];
    if([[NSFileManager defaultManager] fileExistsAtPath:absPath])
    {
        NSError *error = nil;
        //create directory.
        NSArray *fileArr = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:absPath error:&error];
        NSArray *wavFiles = [fileArr filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF  ENDSWITH %@" , @".wav"]];
        if([wavFiles count] == 0)
            totalFileCount = 1.0F; //image zip + no. of wav files + download mp3 zip.
        else
            totalFileCount = 1.0F + [wavFiles count] + 1.0F; //image zip + no. of wav files + download mp3 zip.
    }
    
    self.description1TextField.enabled = NO;
    self.description2TextField.enabled = NO;
    self.description1AudioRecordButton.enabled = NO;
    self.description2AudioRecordButton.enabled = NO;
    self.playDesc1AudioButton.enabled = NO;
    self.playDesc2AudioButton.enabled = NO;
    self.userGroupTableView.scrollEnabled = NO;
    self.ageGroupTableView.scrollEnabled = NO;
    self.searchTagTextField.enabled = NO;
    self.publishButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.termsButton.enabled = NO;
    
    if(selectedAgeGroupId != NOT_SELECTED)
    {
        self.book.ageGroupRemoteId = [NSNumber numberWithInt:selectedAgeGroupId];
    }
    
    self.book.tagSummary = [self.searchTagTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(selectedUserGroupId != NOT_SELECTED)
    {
        self.book.userGroup = [UserGroupManager getUserGroupByRemoteId:selectedUserGroupId];
    }
    hasUploadError = FALSE;
    
    currentFileUploadCount = 0;
    [self.uploadingLabel setHidden:NO];
    [self.uploadProgress setHidden:NO];
    [self.uploadProgress setProgress:0.0f animated:YES];

    [self sendPublishRequestToServer];    // send request
    return;
 }

// ======================================================================================================================================
// ======================================================================================================================================
// Common functions used when upload to publish
// ======================================================================================================================================
// ======================================================================================================================================
-(id) processResponseData:(NSMutableData *) data
{
    NSArray *resultArray =nil;
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (responseDictionary == nil || error != NULL)
    {
        [CommonMessageBoxes showInvalidResponseFromServerMessageBoxWithDelegate:self];
        [self enableAllControls];
        return nil;
    }
    else if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // show error message
        NSString * errorTitle = NSLocalizedString(@"Cannot publish book", @"Error message for cannot publish book");
        NSString * errorBody = NSLocalizedString(@"UNKNOWN ERROR", @"unknown error from server");
        
        
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
        
        [self enableAllControls];
        return nil;
    }

    resultArray = [responseDictionary objectForKey:@"result"];
    return resultArray;
}

- (void)resetFieldsWhenUploadHasError
{
    //delete temp files.
    NSError *error = NULL;
    
    NSString * imageDirFileName = [NSString stringWithFormat:@"image_%d", [self.book.remoteId intValue]];
    NSString * tempImageAbsDirURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageDirFileName];
    NSString * imageZipFileName = [NSString stringWithFormat:@"%@%@", imageDirFileName, @".zip"];
    NSString * imageZipAbsURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageZipFileName];
    
    BOOL isDir;
    if([[NSFileManager defaultManager] fileExistsAtPath:tempImageAbsDirURL isDirectory:&isDir])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:tempImageAbsDirURL] error:&error];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:imageZipAbsURL isDirectory:NO])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:imageZipAbsURL] error:&error];
    }

    //delete all audio zip file.
    for(NSString * zipURL in audioZipFilePathSet)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:zipURL])
        {
            [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:zipURL] error:&error];
            if(error)
            {
#ifdef DEBUG
                NSLog(@"has error when removing");
#endif
            }
        }
    }
    
    [self sendDeleteBookRequestToServer];

    self.book.remoteId = [NSNumber numberWithInt:0];
        
    //reset fields in book page
    for(BookPage * bookPage in self.book.pages)
    {
        bookPage.remoteId = [NSNumber numberWithInt:0];
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContext];

    [self enableAllControls];
    NSString * errorTitle = NSLocalizedString(@"Cannot publish book", @"Error message for cannot publish book");
    NSString * errorBody = NSLocalizedString(@"UNKNOWN ERROR", @"unknown error from server");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
    [alert show];

}

// ======================================================================================================================================
// Submit delete book data
- (void) sendDeleteBookRequestToServer
{
    if (deleteBookConnection != nil)
        return;
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_DELETE_BOOK]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];
    
    NSData * json = [BookManager jsonBookRepresentation:self.book];
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    httpResponseDeleteBookData = [[NSMutableData alloc] initWithLength:10];
    [deleteBookConnection cancel];
    
    deleteBookConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_DELETE_BOOK];
}

- (void)getAndUploadAudio:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName zipFileName:(NSString *)zipFileName bookItem:(id) bookItem bookPageId:(NSNumber *) bookPageId bookType:(int) bookType
{
    NSString * wavAbsPath = [BookManager getBookItemAbsPath:bookItem fileName:wavFileName];
    BOOL hasWav = [[NSFileManager defaultManager] fileExistsAtPath:wavAbsPath] == TRUE? TRUE:FALSE;
    
    //if has a wav file, i.e. a new audio has been recorded. Therefore, need to upload it to the server and convert it to mp3 on the server.
    //if only mp3 file exists, that means the book has been rejected before and no new audio has been recorded.
    if(hasWav)
    {
        NSString *zipURL = [BookManager getBookItemAbsPath:bookItem fileName:zipFileName];
        [audioZipFilePathSet addObject:zipURL];
        NSDictionary *filesDict = [[NSDictionary alloc]initWithObjectsAndKeys:wavAbsPath,wavFileName , nil];
        NSError *error = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:zipURL])
        {
            //delete everything in the directory.
            [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:zipURL] error:&error];
        }

        BOOL success = [Utilities createZipFrom:filesDict targetURL:zipURL];
        if (success)
        {
            hasAudio = TRUE;
            [self uploadFile:zipURL bookId:self.book.remoteId bookPageId:bookPageId bookType:bookType isLast:FALSE];
        }
        else
        {
//            [self resetFieldsWhenUploadHasError];
            //print error. todo
            hasUploadError = TRUE;
        }
    }
}


-(void)uploadFile:(NSString*)fileAbsPath bookId:(NSNumber *)bookId bookPageId:(NSNumber *)bookPageId bookType:(int)bookType isLast:(BOOL)isLast
{
    NSData *data = [NSData dataWithContentsOfFile:fileAbsPath];
    NSURL *url;
    NSError *error = nil;
    if(isLast)
    {
        url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%d/%d/%d/1/", URL_SERVER_BASE_URL_AUTH, URL_BOOK_UPLOAD_FILE, bookId.intValue, bookPageId.intValue, bookType ]];
    }
    else
    {
        url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%d/%d/%d/0/", URL_SERVER_BASE_URL_AUTH, URL_BOOK_UPLOAD_FILE, bookId.intValue, bookPageId.intValue, bookType ]];
    }
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0f];
    
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postbody = [NSMutableData data];
    
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"filenames\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[fileAbsPath dataUsingEncoding:NSUTF8StringEncoding]];
    
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", fileAbsPath] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:[NSData dataWithData:data]];
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // setting the body of the post to the reqeust
    [request setHTTPBody:postbody];
    [postbody appendData:data];
    [postbody appendData:[[NSString stringWithFormat:@"rn--%@--rn",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postbody];
    
    [request setValue:REQUEST_HEADER_VALUE_IPAD_ID forHTTPHeaderField:REQUEST_HEADER_NAME_IPAD_ID];
    
    httpResponsesUploadData = [[NSMutableData alloc] initWithLength:10];
    
    // now lets make the connection to the web
    NSURLResponse * response = [[NSURLResponse alloc]init];
    
    //after each upload, it should return whether the upload is success, which is 1. 0=fail.
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(error)
    {
        NSLog(@"error when uploading file, file URL:%@, %@",[url path], [error localizedDescription]);
        hasUploadError = TRUE;
        return;
    }
    
    NSNumber * isSuccess= [self processResponseData:[returnData mutableCopy]];
    if(isSuccess.intValue == 1)
        hasUploadError = FALSE;
    else
    {
        hasUploadError = TRUE;
        return;
    }

    //delete zip file
    if(bookType == 1 || bookType == 2 || bookType == 3 || bookType ==4 || bookType == 5)
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:fileAbsPath])
        {
            //delete everything in the directory.
            [[NSFileManager defaultManager] removeItemAtURL:[NSURL URLWithString:fileAbsPath] error:&error];
        }
    }
    //send uploadprogressview from background
    [self performSelectorOnMainThread:@selector(updateProgressView) withObject:nil waitUntilDone:NO];
    
    //after uploaded images zip. At this point the book on the server has been submitted.
    if(isLast && isSuccess.intValue == 1)
    {
        [self performSelectorOnMainThread:@selector(uploadIsSuccess) withObject:nil waitUntilDone:YES];
    }
    
    if(isSuccess.intValue != 1)
        hasUploadError = TRUE;
}

//this is on main thread.
- (void) uploadIsSuccess
{
    if(hasAudio)
        [self sendAudioDownloadRequestToServer];
    else
        [self bookHasSubmittedForApproval];
}

// ======================================================================================================================================
// 1. Submit book data - book
// ======================================================================================================================================
-(void) sendPublishRequestToServer
{
     if (bookConnection != nil)
        return;
        
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_ADD_BOOK_FOR_PUBLISH]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];

    NSData * json = [BookManager jsonBookRepresentation:self.book];
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    httpResponseBookData = [[NSMutableData alloc] initWithLength:10];
    
    [bookConnection cancel];
    
    bookConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_ADD_BOOK];
}

// ======================================================================================================================================
// Publish response from the server
// Add book - return bookId from the server.
// ======================================================================================================================================
-(void) processAddBookResponseData
{
    NSNumber *bookId = [self processResponseData:httpResponseBookData];
    if(bookId == nil)
    {
        NSLog(@"error in add book response.");
        return;
    }
    // ALL OK - save book
    self.book.remoteId = bookId;
     
    [[DocumentHandler sharedDocumentHandler] saveContext];
    
    //add bookpages.
     [self sendAddBookPagesRequestToServer];
}

// ======================================================================================================================================
// 2. Submit book data - all book pages
// ======================================================================================================================================
-(void) sendAddBookPagesRequestToServer
{
   if (bookPagesConnection != nil)
        return;
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL_AUTH, URL_ADD_BOOKPAGES_FOR_PUBLISH]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0f];

    NSData * json = [BookManager jsonBookPagesRepresentation:self.book.pages];
    [request setHTTPMethod:@"POST"];
    [URLRequestUtilities setJSONData:json ToURLRequest:request];
    
    httpResponseBookPagesData = [[NSMutableData alloc] initWithLength:10];
    
    [bookPagesConnection cancel];
    
    bookPagesConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_ADD_BOOK_PAGES];
}

// ======================================================================================================================================
// Publish response from the server
// Add book page - return dictionary of bookpages (key: sortOrder, value:bookPageId  from the server.
// ======================================================================================================================================
-(void) processAddBookPagesResponseData
{
   NSDictionary *resultArray = [self processResponseData:httpResponseBookPagesData];
    
    // check? || [resultArray count] != [self.book.pages count]
    if(resultArray == nil )
    {
        NSLog(@"error in add book page response.");
        //remove remoteId for book.
        [self resetFieldsWhenUploadHasError];
        return;
    }

    NSArray *keys = [resultArray allKeys];
    for(NSString *key in keys)
    {
        NSString *pageRemoteId = [resultArray objectForKey:key];
        
        for(BookPage *bp in self.book.pages)
        {
//            NSLog(@"page sortOrder: %d, %d, remote:%d , %d", [bp.sortOrder intValue], [key intValue], [bp.remoteId intValue], [pageRemoteId intValue]);
            if([bp.sortOrder intValue]== [key intValue])
            {
                bp.remoteId = [NSNumber numberWithInt:[pageRemoteId intValue]];
            }
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContext];
    
    //send to background thread.
    hasUploadError = FALSE;
    [self performSelectorInBackground:@selector(sendAudioUploadRequestToServer) withObject:nil];
}

-(void) updateProgressView
{
    currentFileUploadCount ++;
    self.uploadingLabel.hidden = NO;
    float length = currentFileUploadCount / totalFileCount ;

    [self.uploadProgress setProgress:length animated:YES];
}

// ======================================================================================================================================
// 3. Submit book data - upload audio.  Audio is in wav and zipped.  Each audio file will make 1 server request. reset fields when any one of
//      request fail.
// ======================================================================================================================================
-(void)sendAudioUploadRequestToServer
{
    hasAudio = FALSE;
    audioZipFilePathSet = [[NSMutableSet alloc]init];
#ifdef DEBUG
    NSLog(@"uploading audio, %d", hasUploadError);
#endif
    //book title 1 audio and zip and upload it.
    [self getAndUploadAudio:BOOK_TITLE_1_AUDIO_FILENAME mp3FileName:BOOK_TITLE_1_AUDIO_FILENAME_MP3 zipFileName:BOOK_TITLE_1_AUDIO_ZIP bookItem:self.book bookPageId:0 bookType:1];
    
    if(hasUploadError)
    {
        [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
        return;
    }
    
    //book title 2 audio
    [self getAndUploadAudio:BOOK_TITLE_2_AUDIO_FILENAME mp3FileName:BOOK_TITLE_2_AUDIO_FILENAME_MP3 zipFileName:BOOK_TITLE_2_AUDIO_ZIP bookItem:self.book bookPageId:0 bookType:2];
    
    if(hasUploadError)
    {
        [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
        return;
    }
    //book desc 1 audio
    [self getAndUploadAudio:BOOK_DESC_1_AUDIO_FILENAME mp3FileName:BOOK_DESC_1_AUDIO_FILENAME_MP3 zipFileName:BOOK_DESC_1_AUDIO_ZIP bookItem:self.book bookPageId:0 bookType:3];
    
    if(hasUploadError)
    {
        [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
        return;
    }
    //book desc 2 audio
    [self getAndUploadAudio:BOOK_DESC_2_AUDIO_FILENAME mp3FileName:BOOK_DESC_2_AUDIO_FILENAME_MP3 zipFileName:BOOK_DESC_2_AUDIO_ZIP bookItem:self.book bookPageId:0 bookType:4];
    
    if(hasUploadError)
    {
        [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
        return;
    }
    int i=1;
    for (BookPage * bp in self.book.pages)
    {
        [self getAndUploadAudio:BOOK_PAGE_TEXT_1_AUDIO_FILENAME mp3FileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3 zipFileName:BOOK_PAGE_TEXT_1_AUDIO_ZIP bookItem:bp bookPageId:bp.remoteId bookType:3];
        if(hasUploadError)
        {
            [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
            return;
        }
        [self getAndUploadAudio:BOOK_PAGE_TEXT_2_AUDIO_FILENAME mp3FileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3 zipFileName:BOOK_PAGE_TEXT_2_AUDIO_ZIP bookItem:bp bookPageId:bp.remoteId bookType:4];
        if(hasUploadError)
        {
            [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
            return;
        }
        i++;
    }
    
    [self sendImagesUploadRequestToServer];
}

// ======================================================================================================================================
// 4. Submit book data - upload all images.  It will zipped to image_{bookId}.zip and upload as 1 server request. reset fields when any one of
//      request fail.
// ======================================================================================================================================
- (void)sendImagesUploadRequestToServer
{
    //loop through the book's di rectory, copy it to tmp, rename it to match the server's file structure, zip it and send it in 1 request.
    NSMutableDictionary *filesDict = [[NSMutableDictionary alloc]init];
    NSError *error = NULL;

    //create a zip dir.
    NSString * imageDirFileName = [NSString stringWithFormat:@"image_%d", [self.book.remoteId intValue]];
    NSString * tempImageDirURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageDirFileName];
    NSString * imageZipFileName = [NSString stringWithFormat:@"%@%@", imageDirFileName, @".zip"];
    NSString * imageZipURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageZipFileName];

    BOOL isDir;
    //delete the directory and zip file if exists.
    if([[NSFileManager defaultManager] fileExistsAtPath:tempImageDirURL isDirectory:&isDir])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:tempImageDirURL] error:&error];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:imageZipURL isDirectory:NO])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:imageZipURL] error:&error];
    }

    //create directory
    [[NSFileManager defaultManager] createDirectoryAtPath:tempImageDirURL withIntermediateDirectories:YES attributes:nil error:&error];

    //copy book image and thumbnail to the zip dir
    NSString * tempImagePath = [tempImageDirURL stringByAppendingPathComponent:BOOK_IMAGE_FILENAME];
    NSString * tempThumbPath = [tempImageDirURL stringByAppendingPathComponent:BOOK_THUMBNAIL_FILENAME];
    NSString * permImagePath = [BookManager getBookItemAbsPath:self.book fileName:BOOK_IMAGE_FILENAME];
    NSString * permThumbPath = [BookManager getBookItemAbsPath:self.book fileName:BOOK_THUMBNAIL_FILENAME];
    
    // 1. Move preview images (cover page's image and thumbnail) to the temp directory
    [[NSFileManager defaultManager] copyItemAtPath:permImagePath toPath:tempImagePath error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:permThumbPath toPath:tempThumbPath error:&error];
    [filesDict setObject:tempImagePath forKey:BOOK_IMAGE_FILENAME];
    [filesDict setObject:tempThumbPath forKey:BOOK_THUMBNAIL_FILENAME];
    
    //2. Move all book pages images.
    for (BookPage * page in self.book.pages)
    {
        //rename and copy book page image and thumbnail to the zip dir
        NSString *imageName = [NSString stringWithFormat:@"%d%@", [page.remoteId intValue],BOOK_PAGE_IMAGE_FILENAME];
        NSString *thumbName = [NSString stringWithFormat:@"%d%@", [page.remoteId intValue],BOOK_PAGE_THUMBNAIL_FILENAME];

        NSString * tempPageImagePath = [tempImageDirURL stringByAppendingPathComponent:imageName];
        NSString * tempPageThumbPath = [tempImageDirURL stringByAppendingPathComponent:thumbName];
        NSString * permPageImagePath = [BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_IMAGE_FILENAME];
        NSString * permPageThumbPath = [BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_THUMBNAIL_FILENAME];

        [[NSFileManager defaultManager] copyItemAtPath:permPageImagePath toPath:tempPageImagePath error:&error];
        [[NSFileManager defaultManager] copyItemAtPath:permPageThumbPath toPath:tempPageThumbPath error:&error];
        [filesDict setObject:tempPageImagePath forKey:imageName];
        [filesDict setObject:tempPageThumbPath forKey:thumbName];
    }
    //zip it.
    BOOL success = [Utilities createZipFrom:filesDict targetURL:imageZipURL];
    if (success)
    {
        //upload file.
        [self uploadFile:imageZipURL bookId:self.book.remoteId bookPageId:0 bookType:5 isLast:YES];
        if(hasUploadError)
        {
            [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
            return;
        }

    }
    else
    {
#ifdef DEBUG
        NSLog(@"has error when creating image zip.");
#endif
        hasUploadError = TRUE;
        [self performSelectorOnMainThread:@selector(resetFieldsWhenUploadHasError) withObject:nil waitUntilDone:NO];
    }    
}

- (void) bookHasSubmittedForApproval
{
#ifdef DEBUG
    NSLog(@"book has submitted");
#endif
    //delete temp files.
    NSError *error = NULL;
    
    NSString * imageDirFileName = [NSString stringWithFormat:@"image_%d", [self.book.remoteId intValue]];
    NSString * tempImageAbsDirURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageDirFileName];
    NSString * imageZipFileName = [NSString stringWithFormat:@"%@%@", imageDirFileName, @".zip"];
    NSString * imageZipAbsURL = [NSTemporaryDirectory() stringByAppendingPathComponent: imageZipFileName];
    
    BOOL isDir;
    if([[NSFileManager defaultManager] fileExistsAtPath:tempImageAbsDirURL isDirectory:&isDir])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:tempImageAbsDirURL] error:&error];
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:imageZipAbsURL isDirectory:NO])
    {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:imageZipAbsURL] error:&error];
    }

    self.book.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusPending];
    self.book.rejectionComment = @""; //for book that is rejected before.
    self.book.isHidden = FALSE;
    [BookManager saveBook:self.book];

    NSString * body = NSLocalizedString(@"Book has been submitted for approval.", @"Book has been submitted for approval.");
     
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:body delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @"OK button label"), nil];
    alert.tag = ALERT_PUBLISHED;
    [alert show];
}

-(void)sendAudioDownloadRequestToServer
{
   if (downloadConnection != nil)
        return;
    
    //download book audios
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%d", URL_SERVER_BASE_URL, URL_BOOK_DOWNLOAD_AUDIO_FILES, [self.book.remoteId intValue]]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0f];
    [request setHTTPMethod:@"GET"];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    httpResponseDownloadData = [[NSMutableData alloc] initWithLength:10];
    
    [downloadConnection cancel];
    
    downloadConnection = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self startImmediately:true identification:CONNECTION_DOWNLOAD_FILE];
}

-(void)processDownloadResponseData
{
    NSString *bookZipDir = [BookManager getBookItemAbsPath:self.book fileName:nil];
    NSString *unzipFolder = [bookZipDir stringByAppendingString:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:unzipFolder
                              withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *zipFilePath = [bookZipDir stringByAppendingString:@"audio.zip"];
    
    //write zip file in temp directory.
    [httpResponseDownloadData writeToFile:zipFilePath atomically:NO];
    
    BOOL isZipEmpty = FALSE;
    if ([[NSFileManager defaultManager]  fileExistsAtPath:zipFilePath]) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:zipFilePath error:nil];
            unsigned long long size = [attributes fileSize];
            if (attributes && size == 0) {
                // file exists, but is empty.
                isZipEmpty = TRUE;
            }
        }
        
    if(!isZipEmpty)
    {
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        [zipArchive UnzipOpenFile:zipFilePath];
        //unzip file to the book folder in temp directory.
        BOOL ret =     [zipArchive UnzipFileTo:unzipFolder overWrite:YES];
        if( NO==ret )
        {
#ifdef DEBUG
            NSLog(@"error");
#endif
            // error handler here
        }
        [zipArchive UnzipCloseFile];
        zipArchive = nil;

        [self moveMP3Files];
    }

    [self updateProgressView];

    // go back to my library.
    [self bookHasSubmittedForApproval];
}

// ===========================================================================================================================================
// Handle user password input and proceed with saving user account info.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == ALERT_PUBLISHED && buttonIndex == 0)
    {
        [NavigationManager navigateToMyLibraryForUser:self.book.author animatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut];
        
        // ---- Google analytics ---
        
        // May return nil if a tracker has not already been initialized with a property ID.
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"book"    // Event category (required)
                                                              action:@"published"  // Event action (required)
                                                               label:[NSString stringWithFormat:@"Book ID = %@", self.book.remoteId.stringValue]  // Event label
                                                               value:nil] build]];      // Event value
    
    }
}

//move mp3 back to the book.
- (void) moveMP3Files
{
//    NSLog(@"moveMP3Files");
   NSString *bookFolder = [BookManager getBookItemAbsPath:self.book fileName:nil];
    NSString *unzipFolder = [bookFolder stringByAppendingString:@"temp/"];
    NSError * error = nil;
    //copy all title page's mp3
    [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:BOOK_TITLE_1_AUDIO_FILENAME_MP3]  toPath:[bookFolder stringByAppendingString:BOOK_TITLE_1_AUDIO_FILENAME_MP3] error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:BOOK_TITLE_2_AUDIO_FILENAME_MP3]  toPath:[bookFolder stringByAppendingString:BOOK_TITLE_2_AUDIO_FILENAME_MP3] error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:BOOK_DESC_1_AUDIO_FILENAME_MP3]  toPath:[bookFolder stringByAppendingString:BOOK_DESC_1_AUDIO_FILENAME_MP3] error:&error];
    [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:BOOK_DESC_2_AUDIO_FILENAME_MP3]  toPath:[bookFolder stringByAppendingString:BOOK_DESC_2_AUDIO_FILENAME_MP3] error:&error];

    //remove all title page's wav and zip.
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_TITLE_1_AUDIO_FILENAME] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_TITLE_2_AUDIO_FILENAME] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_DESC_1_AUDIO_FILENAME] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_DESC_2_AUDIO_FILENAME] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_TITLE_1_AUDIO_ZIP] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_TITLE_2_AUDIO_ZIP] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_DESC_1_AUDIO_ZIP] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[bookFolder stringByAppendingString:BOOK_DESC_2_AUDIO_ZIP] error:&error];
  
    //copy all page's mp3
    for(BookPage * bp in self.book.pages)
    {
        NSString *bookPageFolder = [BookManager getBookItemAbsPath:bp fileName:nil];
        NSString *unzipFolder = [bookFolder stringByAppendingString:@"temp/pages/"];
        [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:[[NSString stringWithFormat:@"%d", [bp.remoteId intValue]] stringByAppendingString: BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3]]  toPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3] error:&error];
        [[NSFileManager defaultManager] copyItemAtPath:[unzipFolder stringByAppendingString:[[NSString stringWithFormat:@"%d", [bp.remoteId intValue]] stringByAppendingString: BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3]]  toPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3] error:&error];
        
        //remove wav and zip for pages.
       [[NSFileManager defaultManager] removeItemAtPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_1_AUDIO_FILENAME] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_1_AUDIO_ZIP] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_2_AUDIO_FILENAME] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:[bookPageFolder stringByAppendingString:BOOK_PAGE_TEXT_2_AUDIO_ZIP] error:&error];
    }
    
    //remove audio.zip, temp folder.
    NSString *zipFilePath = [bookFolder stringByAppendingString:@"audio.zip"];
    [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:unzipFolder error:&error];
    
    if(error != nil)
    {
#ifdef DEBUG
        NSLog(@"has error, %@", [error localizedDescription]);
#endif
        //error occur
    }
    return;
}

// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
   switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_AGEGROUP_GET_ALL:
            [httpResponseAgeGroupData setLength:0];
            break;
        case CONNECTION_USERGROUP_GET_ALL:
            [httpResponseUserGroupData setLength:0];
            break;
        case CONNECTION_ADD_BOOK:
            [httpResponseBookData setLength:0];
            break;
        case CONNECTION_ADD_BOOK_PAGES:
            [httpResponseBookPagesData setLength:0];
            break;
        case CONNECTION_UPLOAD_FILE:
        case CONNECTION_LAST_UPLOAD_FILE:
            [httpResponsesUploadData setLength:0];
            break;
        case CONNECTION_DOWNLOAD_FILE:
            [httpResponseDownloadData setLength:0];
            break;
        case CONNECTION_DELETE_BOOK:
            [httpResponseDeleteBookData setLength:0];
            break;
        default:
            break;
    }
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
   switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_AGEGROUP_GET_ALL:
            [httpResponseAgeGroupData appendData:data];
            break;
        case CONNECTION_USERGROUP_GET_ALL:
            [httpResponseUserGroupData appendData:data];
            break;
        case CONNECTION_ADD_BOOK:
            [httpResponseBookData appendData:data];
            break;
        case CONNECTION_ADD_BOOK_PAGES:
            [httpResponseBookPagesData appendData:data];
            break;
        case CONNECTION_UPLOAD_FILE:
        case CONNECTION_LAST_UPLOAD_FILE:
            [httpResponsesUploadData appendData:data];
            break;
        case CONNECTION_DOWNLOAD_FILE:
            [httpResponseDownloadData appendData:data];
            break;
        case CONNECTION_DELETE_BOOK:
            [httpResponseDeleteBookData appendData:data];
            break;

        default:
            break;
    }
}
// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    ageGroupConnection = nil;
    userGroupConnection = nil;
    bookConnection = nil;
    bookPagesConnection = nil;
    downloadConnection = nil;
    deleteBookConnection = nil;
    
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    [self enableAllControls];
}

// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_AGEGROUP_GET_ALL:
            [self processAgeGroupsResponseData];
            break;
        case CONNECTION_USERGROUP_GET_ALL:
            [self processUserGroupsResponseData];
            break;
        case CONNECTION_ADD_BOOK:
            [self processAddBookResponseData];
            break;
        case CONNECTION_ADD_BOOK_PAGES:
            [self processAddBookPagesResponseData];
            break;
        case CONNECTION_DOWNLOAD_FILE:
            [self processDownloadResponseData];
            break;
        case CONNECTION_DELETE_BOOK:
            break;
        default:
            break;
    }
    
    ageGroupConnection = nil;
    userGroupConnection = nil;
    downloadConnection = nil;
    bookConnection = nil;
    bookPagesConnection = nil;
    deleteBookConnection = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}



//====================descriptions of book
- (IBAction)recordAudioDesc1Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:DESC1_AUDIO];
}

- (IBAction)recordAudioDesc2Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:DESC2_AUDIO];
}

- (void)changeAudioButton
{
    [self resetPlayAudioButtons];
}

- (void)popoverDone:(id)sender
{
    [self.audioRecordingPopoverController dismissPopoverAnimated:YES];
    
    //if wav file exists and has data, remove mp3 if exists
    AudioRecordingViewController *ar = (AudioRecordingViewController *)sender;
    if(![ar.fileAbsURL isEqualToString:ar.wavAbsURL])
    {
        if ([[NSFileManager defaultManager]  fileExistsAtPath:ar.wavAbsURL]) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:ar.wavAbsURL error:nil];
            if(attributes)
            {
                unsigned long long size = [attributes fileSize];
                if (size != 0) {
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:ar.fileAbsURL error:&error];
                    switch (ar.buttonNum) {
                        case DESC1_AUDIO:
                            audioDesc1AbsPath = ar.wavAbsURL;
                            break;
                        case DESC2_AUDIO:
                            audioDesc2AbsPath = ar.wavAbsURL;
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }
    [self saveBook];
    [self changeAudioButton];
}

- (void)presentAudioRecordingPopover:(int)buttonPressed
{
    //first time to instantiate popover.
    if(self.audioRecordingPopoverController == nil)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
        self.audioRecordingViewController = [sb instantiateViewControllerWithIdentifier:@"audioRecordingIdentifier"];
        
        if(buttonPressed == DESC1_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioDesc1AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:self.book fileName:BOOK_DESC_1_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = DESC1_AUDIO;
        }
        if(buttonPressed == DESC2_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioDesc2AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:self.book fileName:BOOK_DESC_2_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = DESC2_AUDIO;
        }
        
        
        self.audioRecordingPopoverController = [[UIPopoverController alloc]
                                                initWithContentViewController:self.audioRecordingViewController];
        self.audioRecordingViewController.parentPopoverController = self.audioRecordingPopoverController;
        
        self.audioRecordingPopoverController.delegate = (id)self;
        self.audioRecordingPopoverController.popoverContentSize = audioPopoverSize;
    }
    else     //popover already instantiated.
    {
        if(buttonPressed == DESC1_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioDesc1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:self.book fileName:BOOK_DESC_1_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = DESC1_AUDIO;
        }
        if(buttonPressed == DESC2_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioDesc2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:self.book fileName:BOOK_DESC_2_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = DESC2_AUDIO;
            
        }
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    if(buttonPressed == DESC1_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(self.description1TextField.frame.size.width/4, 0, audioPopoverSize.width, audioPopoverSize.height) inView:self.description1TextField permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
    else if(buttonPressed == DESC2_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(self.description2TextField.frame.size.width/4, 0, audioPopoverSize.width, audioPopoverSize.height) inView:self.description2TextField permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
}

- (NSString *)getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName
{
    NSString * wavAbsPath = [BookManager getBookItemAbsPath:self.book fileName:wavFileName];
    if([self.book.approvalStatus intValue]== BookApprovalStatusRejected)
    {
        NSString * mp3AbsPath = [BookManager getBookItemAbsPath:self.book fileName:mp3FileName];
        return ([[NSFileManager defaultManager] fileExistsAtPath:mp3AbsPath] == TRUE?  mp3AbsPath : wavAbsPath);
    }
    
    return wavAbsPath;
}


- (void)validate
{
    self.errorMessageLabel.text=@"";
    self.errorMessageLabel.hidden = YES;
    NSString *desc1 = self.description1TextField.text;
    desc1 = [desc1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([desc1 isEqualToString:NSLocalizedString(@"Enter the book description.", @"Description for book description.")] || [desc1 isEqualToString:@""]==TRUE)
    {
        isDesc1Edited = FALSE;
        hasValidationError = TRUE;

        NSString * messageText = NSLocalizedString(@"Description in ", @"Validation text for book description when publishing a book.");
        NSString * messageText2 = NSLocalizedString(@" is required. ", @"Part 2 of create book validation text.");
        self.errorMessageLabel.text = [[messageText stringByAppendingString:self.book.primaryLanguage.nameEnglish]  stringByAppendingString:messageText2];
        self.errorMessageLabel.hidden = NO;
        return;
    }
    else
    {
        isDesc1Edited = TRUE;
    }

    NSString *desc2 = self.description2TextField.text;
    desc2 = [desc2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([desc2 isEqualToString:NSLocalizedString(@"Enter the book description.", @"Description for book description.")] || [desc2 isEqualToString:@""]==TRUE)
    {
        isDesc2Edited = FALSE;
        hasValidationError = TRUE;
        NSString * messageText = NSLocalizedString(@"Description in ", @"Validation text for book description when publishing a book.");
        NSString * messageText2 = NSLocalizedString(@" is required. ", @"Part 2 of create book validation text.");
        self.errorMessageLabel.text = [[messageText stringByAppendingString:self.book.secondaryLanguage.nameEnglish]  stringByAppendingString:messageText2];
        self.errorMessageLabel.hidden = NO;
    }
    else
    {
        isDesc2Edited = TRUE;
    }
    
}

//save book.
- (void)saveBook
{
    [self.view endEditing:YES];
    
    //get desc1
    self.book.description1 = [self.description1TextField.text isEqualToString:NSLocalizedString(@"Enter the book description.", @"Description for book description.")] == TRUE ? nil: [self.description1TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //get desc2
    self.book.description2 = [self.description2TextField.text isEqualToString:NSLocalizedString(@"Enter the book description.", @"Description for book description.")] == TRUE ? nil: [self.description2TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [BookManager saveBook:self.book];
}
//=========================
// audio setup.
- (void)changeToStopMode:(UIButton *)button
{
    //play -> stop
    [button setTag:STOP_MODE];
    [button setBackgroundImage:[UIImage imageNamed:@"create_speaker.png"] forState:UIControlStateNormal];
    
    if([audioPlayer play])
    {
        [audioPlayer stop];
        audioPlayer = nil;
        playURL = nil;
    }
}

- (void)changeToPlayMode:(UIButton *)button fileAbsPath:(NSString *)fileAbsPath
{
    //stop -> play
    NSError *error;
    playURL = [NSURL fileURLWithPath:fileAbsPath];
    audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:playURL error:&error];
    
    audioPlayer.delegate = (id)self;
    
    if (error)
    {
#ifdef DEBUG
        NSLog(@"Error: %@",[error localizedDescription]);
#endif
        //            self.messageLabel.text = NSLocalizedString(@"error when start the player.", @"error when start the player.");
    }
    else
    {
        [audioPlayer play];
        [button setTag:PLAY_MODE];
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_pause.png"] forState:UIControlStateNormal];
        //        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_activehover.png"] forState:UIControlStateHighlighted];
    }
}

-(IBAction) togglePlayStopDesc1AudioButton:(id)sender
{
    //stop -> play
    if(self.playDesc1AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playDesc1AudioButton fileAbsPath:audioDesc1AbsPath];
        [self enableButtonsForPlayDesc1:TRUE playDesc2:FALSE recordDesc1:FALSE recordDesc2:FALSE];
    }
    else
    {
        [self changeToStopMode:self.playDesc1AudioButton];
        [self enableButtonsForPlayDesc1:TRUE playDesc2:TRUE recordDesc1:TRUE recordDesc2:TRUE];
    }
}

-(IBAction) togglePlayStopDesc2AudioButton:(id)sender
{
    //stop -> play
    if(self.playDesc2AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playDesc2AudioButton fileAbsPath:audioDesc2AbsPath];
        [self enableButtonsForPlayDesc1:FALSE playDesc2:TRUE recordDesc1:FALSE recordDesc2:FALSE];
    }
    else
    {
        [self changeToStopMode:self.playDesc2AudioButton];
        [self enableButtonsForPlayDesc1:TRUE playDesc2:TRUE recordDesc1:TRUE recordDesc2:TRUE];
    }
}

- (void) enableButtonsForPlayDesc1:(bool) playDesc1 playDesc2:(bool) playDesc2 recordDesc1:(bool)recordDesc1 recordDesc2:(bool)recordDesc2
{
    self.playDesc1AudioButton.enabled = playDesc1;
    self.playDesc2AudioButton.enabled = playDesc2;
    self.description1AudioRecordButton.enabled = recordDesc1;
    self.description2AudioRecordButton.enabled = recordDesc2;
}

- (void)resetPlayAudioButtons
{
    [self resetAudioButton:self.playDesc1AudioButton fileAbsURL:audioDesc1AbsPath];
    [self resetAudioButton:self.playDesc2AudioButton fileAbsURL:audioDesc2AbsPath];
}

- (void)resetAudioButton:(UIButton *) button fileAbsURL:(NSString *)fileAbsURL
{
    if([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL fileURLWithPath:fileAbsURL] path]])
    {
        button.enabled = YES;
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker.png"] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_hover.png"] forState:UIControlStateHighlighted];
        button.tag = STOP_MODE;
    }
    else
    {
        button.enabled = NO;
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_off.png"] forState:UIControlStateNormal];
    }
}

// delegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if([audioPlayer play])
    {
        [audioPlayer stop];
        audioPlayer = nil;
        playURL = nil;
    }
    
    [self resetPlayAudioButtons];
    [self enableButtonsForPlayDesc1:TRUE playDesc2:TRUE recordDesc1:TRUE recordDesc2:TRUE];
    audioPlayer = nil;
    playURL = nil;
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
#ifdef DEBUG
    NSLog(@"decode error in publish book view controller");
#endif
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player{}

-(void)dealloc
{
    audioPlayer=nil;
    playURL = nil;
}

@end