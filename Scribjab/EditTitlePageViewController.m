//
//  EditTitlePageViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-12-09.
//
//

#import <QuartzCore/QuartzCore.h>
#import "EditTitlePageViewController.h"
#import "Language+Utils.h"
#import "Book.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import "ModalConstants.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface EditTitlePageViewController ()
{
    BOOL isTitle1Edited;
    BOOL hasError;
    UIColor *errorTextBoxBackgroudColor;
    Book *currentBook;
    
    BOOL isTitle1AudioRecorded;
    BOOL isTitle2AudioRecorded;

    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audioTitle1AbsPath;
    NSString *audioTitle2AbsPath;
    
    AVAudioPlayer *audioPlayer;
    NSURL *playURL;
}
- (void)presentAudioRecordingPopover:(int)buttonPressed;
- (void)changeAudioButton;
- (void)saveBook;
- (void)setup;
- (NSString *)getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName;
- (void)enableButtonsForPlayTitle1:(bool) playTitle1 playTitle2:(bool)playTitle2 recordTitle1:(bool)recordTitle1 recordTitle2:(bool)recordTitle2;

- (void)changeToPlayMode:(UIButton *)button fileAbsPath:(NSString *)fileAbsPath;
- (void)resetPlayAudioButtons;
- (void)resetAudioButton:(UIButton *) button fileAbsURL:(NSString *)fileAbsURL;
- (void)changeToStopMode:(UIButton *)button;
@end

@implementation EditTitlePageViewController
@synthesize primaryLanguageLabel = _primaryLanguageLabel;
@synthesize secondaryLanguageLabel = _secondaryLanguageLabel;
@synthesize primaryLanguageDescLabel = _primaryLanguageDescLabel;
@synthesize secondaryLanguageDescLabel = _secondaryLanguageDescLabel;
@synthesize title1TextField = _title1TextField;
@synthesize title2TextField = _title2TextField;
@synthesize title1AudioRecordButton = _title1AudioRecordButton;
@synthesize title2AudioRecordButton = _title2AudioRecordButton;
@synthesize pageLabel = _pageLabel;

@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize drawButton = _drawButton;

@synthesize wizardDataObject = _wizardDataObject;
@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;

static int const TITLE1_TEXT_VIEW = 1;
static int const TITLE2_TEXT_VIEW = 2;
static int const TITLE_MAX_LENGTH = 50;

static int const TITLE1_AUDIO = 1;
static int const TITLE2_AUDIO = 2;
static int const PLAY_MODE = 1;
static int const STOP_MODE = 0;

static CGFloat const CORNER_RADIUS = 9.0;
static CGFloat const TEXT_ANIMATION_DURATION = 0.25;
 
@synthesize imageView = _imageView;
@synthesize playTitle1AudioButton = _playTitle1AudioButton;
@synthesize playTitle2AudioButton = _playTitle2AudioButton;


// ================================================================================================================================
// Reset controller as if it is reloaded. Turn off all audio playbacks.
- (void)reset
{
    if(audioPlayer != nil && [audioPlayer play])
    {
        [audioPlayer stop];
        audioPlayer = nil;
        playURL = nil;
    }
    
    [self resetPlayAudioButtons];
    [self enableButtonsForPlayTitle1:TRUE playTitle2:TRUE recordTitle1:TRUE recordTitle2:TRUE];
}

// ================================================================================================================================
// Record audio button click
- (IBAction)recordAudioTitle1Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:TITLE1_AUDIO];
}

- (IBAction)recordAudioTitle2Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:TITLE2_AUDIO];
}

// ================================================================================================================================
// draw button clicked
- (IBAction)drawButtonIsPressed:(id)sender
{
    [self.view endEditing:TRUE];
    
    //go back to bookview controller
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self.parentViewController
                                   selector:@selector(drawBookImage:)
                                   userInfo:currentBook
                                    repeats:NO];
}

// ================================================================================================================================
- (void)changeAudioButton
{
    [self resetPlayAudioButtons];
}

// ================================================================================================================================
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
                     case TITLE1_AUDIO:
                         audioTitle1AbsPath = ar.wavAbsURL;
                         break;
                     case TITLE2_AUDIO:
                         audioTitle2AbsPath = ar.wavAbsURL;
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

// ================================================================================================================================
- (void)presentAudioRecordingPopover:(int)buttonPressed
{
    //first time to instantiate popover.
    if(self.audioRecordingPopoverController == nil)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
        self.audioRecordingViewController = [sb instantiateViewControllerWithIdentifier:@"audioRecordingIdentifier"];
        
        if(buttonPressed == TITLE1_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioTitle1AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_1_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = TITLE1_AUDIO;
        }
        if(buttonPressed == TITLE2_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioTitle2AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_2_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = TITLE2_AUDIO;
        }
        
        self.audioRecordingPopoverController = [[UIPopoverController alloc]
                                                initWithContentViewController:self.audioRecordingViewController];
        self.audioRecordingViewController.parentPopoverController = self.audioRecordingPopoverController;
        
        self.audioRecordingPopoverController.delegate = (id)self;
        self.audioRecordingPopoverController.popoverContentSize = audioPopoverSize;
    }
    else     //popover already instantiated.
    {
        if(buttonPressed == TITLE1_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioTitle1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_1_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TITLE1_AUDIO;
        }
        if(buttonPressed == TITLE2_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioTitle2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_2_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TITLE2_AUDIO;
        }
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    self.audioRecordingPopoverController.contentViewController.preferredContentSize = CGSizeMake(400, 300);
    
    if(buttonPressed == TITLE1_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(-110, -128, audioPopoverSize.width, audioPopoverSize.height) inView:self.title1TextField permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
    else if(buttonPressed == TITLE2_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(-110, -140, audioPopoverSize.width, audioPopoverSize.height) inView:self.title2TextField permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
}

// ================================================================================================================================
//save book.
- (void)saveBook
{
    [self.view endEditing:YES];
    
    //get title1
    currentBook.title1  = [self.title1TextField.text isEqualToString:NSLocalizedString(@"Enter the book title.", @"Description for book title.")] == TRUE ? nil: [self.title1TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //get title2
    currentBook.title2 = [self.title2TextField.text isEqualToString:NSLocalizedString(@"Enter the book title.", @"Description for book title.")] == TRUE ? nil: [self.title2TextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [BookManager saveBook:currentBook];
    self.wizardDataObject = currentBook;
}

// ================================================================================================================================
//setup view.
- (void)setup
{
	// Do any additional setup after loading the view.
    self.primaryLanguageLabel.text = currentBook.primaryLanguage.name;
    self.secondaryLanguageLabel.text = currentBook.secondaryLanguage.name;
    self.primaryLanguageDescLabel.text = currentBook.primaryLanguage.name;
    self.secondaryLanguageDescLabel.text = currentBook.secondaryLanguage.name;
    self.title1TextField.delegate = self;
    self.title2TextField.delegate = self;
    self.title1TextField.tag = TITLE1_TEXT_VIEW;
    self.title2TextField.tag = TITLE2_TEXT_VIEW;
    self.title1TextField.layer.cornerRadius = CORNER_RADIUS;
    self.title1TextField.layer.masksToBounds = YES;
    self.title2TextField.layer.cornerRadius = CORNER_RADIUS;
    self.title2TextField.layer.masksToBounds = YES;
    
    self.title1TextField.backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    self.title2TextField.backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    UIView *paddingView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    UIView *paddingView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.title1TextField.leftView = paddingView1;
    self.title1TextField.leftViewMode = UITextFieldViewModeAlways;
    self.title2TextField.leftView = paddingView2;
    self.title2TextField.leftViewMode = UITextFieldViewModeAlways;
    
    //initial text for title1.
    self.title1TextField.text = (currentBook.title1 ==nil? NSLocalizedString(@"Enter the book title.", @"Description for book title."): currentBook.title1);
    
    //initial text for title2.
    self.title2TextField.text = (currentBook.title2 ==nil? NSLocalizedString(@"Enter the book title.", @"Description for book title."): currentBook.title2);
    
    //set the audio popover size.
    audioPopoverSize = CGSizeMake(400, 300);
    
    [BookManager createDirIfNotExist:currentBook]; //the id here is permanent.
    //get the path name of title1 and title2, desc1 and desc2.
    
    audioTitle1AbsPath = [self getAudioAbsPath:BOOK_TITLE_1_AUDIO_FILENAME mp3FileName:BOOK_TITLE_1_AUDIO_FILENAME_MP3];
    audioTitle2AbsPath = [self getAudioAbsPath:BOOK_TITLE_2_AUDIO_FILENAME mp3FileName:BOOK_TITLE_2_AUDIO_FILENAME_MP3];
    
    [self changeAudioButton];
    [self resetPlayAudioButtons];
    
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    self.imageView.image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:currentBook fileName:BOOK_IMAGE_FILENAME]];
    self.imageView.backgroundColor = [UIColor colorWithHexString:currentBook.backgroundColorCode];
    self.imageView.frame = CGRectMake(324, 0, 578,642);
    self.view.backgroundColor = self.imageView.backgroundColor;
}

// ================================================================================================================================
- (NSString *)getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName
{
    NSString * wavAbsPath = [BookManager getBookItemAbsPath:currentBook fileName:wavFileName];
    if([currentBook.approvalStatus intValue]== BookApprovalStatusRejected)
    {
        NSString * mp3AbsPath = [BookManager getBookItemAbsPath:currentBook fileName:mp3FileName];
        return ([[NSFileManager defaultManager] fileExistsAtPath:mp3AbsPath] == TRUE?  mp3AbsPath : wavAbsPath);
    }
    
    return wavAbsPath;
}
// =====================================================================================================================================
#pragma mark Text View data source methods
// set the max. length of title.
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text
{
    NSUInteger newLength = (textField.text.length - range.length) + text.length;
    
    if(textField.tag == TITLE1_TEXT_VIEW || textField.tag == TITLE2_TEXT_VIEW)
    {
        if(newLength <= TITLE_MAX_LENGTH)
        {
            return YES;
        } else {
            NSUInteger emptySpace = TITLE_MAX_LENGTH - (textField.text.length - range.length);
            textField.text = [[[textField.text substringToIndex:range.location]
                              stringByAppendingString:[text substringToIndex:emptySpace]]
                             stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
            return NO;
        }
    }
    return NO;
}
// ================================================================================================================================
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.drawButton.enabled = NO;
    self.drawButton.hidden = YES;
    //reset the text in textview.
    if(textField.tag == TITLE1_TEXT_VIEW || textField.tag == TITLE2_TEXT_VIEW)
    {
        if([textField.text isEqualToString:NSLocalizedString(@"Enter the book title.", @"Description for book title.")])
            textField.text = @"";
        if(textField.tag == TITLE1_TEXT_VIEW)
        {
            self.errorMessageLabel.text = NULL;
            self.errorMessageLabel.hidden = YES;
            hasError = FALSE;
        }
        
    }    
}
// ================================================================================================================================
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self saveBook];
    self.drawButton.enabled = YES;
    self.drawButton.hidden = NO;
}
// ================================================================================================================================
- (void)validate
{
    NSString *title1 = [self.title1TextField text];
    title1 = [title1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([title1 isEqualToString:NSLocalizedString(@"Enter the book title.", @"Description for book title.")] || [title1 isEqualToString:@""]==TRUE)
    {
        isTitle1Edited = FALSE;
        hasError = TRUE;
        self.title1TextField.backgroundColor = errorTextBoxBackgroudColor;
        NSString * messageText = NSLocalizedString(@"Title in ", @"Validation text for book title when create/publish a book.");
        NSString * messageText2 = NSLocalizedString(@" is required. ", @"Part 2 of create book validation text.");
        self.errorMessageLabel.text = [[messageText stringByAppendingString:self.primaryLanguageLabel.text]  stringByAppendingString:messageText2];
        self.errorMessageLabel.hidden = NO;
    }
    else
    {
        isTitle1Edited = TRUE;
    }
}
// ================================================================================================================================
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:TRUE];
    self.drawButton.enabled = YES;
    self.drawButton.hidden = NO;
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
// ================================================================================================================================
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
    }
    else
    {
        [audioPlayer play];
        [button setTag:PLAY_MODE];
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_pause.png"] forState:UIControlStateNormal];
    }
}
// ================================================================================================================================
-(IBAction) togglePlayStopTitle1AudioButton:(id)sender
{
    //stop -> play
    if(self.playTitle1AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playTitle1AudioButton fileAbsPath:audioTitle1AbsPath];
        [self enableButtonsForPlayTitle1:TRUE playTitle2:FALSE recordTitle1:FALSE recordTitle2:FALSE];
    }
    else
    {
        [self changeToStopMode:self.playTitle1AudioButton];
        [self enableButtonsForPlayTitle1:TRUE playTitle2:TRUE recordTitle1:TRUE recordTitle2:TRUE];
    }
}
// ================================================================================================================================
-(IBAction) togglePlayStopTitle2AudioButton:(id)sender
{
    //stop -> play
    if(self.playTitle2AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playTitle2AudioButton fileAbsPath:audioTitle2AbsPath];
        [self enableButtonsForPlayTitle1:FALSE playTitle2:TRUE recordTitle1:FALSE recordTitle2:FALSE];
    }
    else 
    {
        [self changeToStopMode:self.playTitle2AudioButton];
        [self enableButtonsForPlayTitle1:TRUE playTitle2:TRUE recordTitle1:TRUE recordTitle2:TRUE];
    }
}
// ================================================================================================================================
- (void) enableButtonsForPlayTitle1:(bool) playTitle1 playTitle2:(bool)playTitle2 recordTitle1:(bool)recordTitle1 recordTitle2:(bool)recordTitle2
{
    self.playTitle1AudioButton.enabled = playTitle1;
    self.playTitle2AudioButton.enabled = playTitle2;
    self.title1AudioRecordButton.enabled = recordTitle1;
    self.title2AudioRecordButton.enabled = recordTitle2;
}
// ================================================================================================================================
- (void)resetPlayAudioButtons
{
    [self resetAudioButton:self.playTitle1AudioButton fileAbsURL:audioTitle1AbsPath];
    [self resetAudioButton:self.playTitle2AudioButton fileAbsURL:audioTitle2AbsPath];
}
// ================================================================================================================================
- (void)resetAudioButton:(UIButton *) button fileAbsURL:(NSString *)fileAbsURL
{
    if (button == nil)
        return;
    
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
// ================================================================================================================================
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
    [self enableButtonsForPlayTitle1:TRUE playTitle2:TRUE recordTitle1:TRUE recordTitle2:TRUE];
    audioPlayer = nil;
    playURL = nil;
}
// ================================================================================================================================
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
#ifdef DEBUG
    NSLog(@"decode error");
#endif
}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{}

-(void)dealloc
{
    audioPlayer=nil;
    playURL = nil;
}
// ================================================================================================================================
// view controller
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
    currentBook = (Book *)self.wizardDataObject;
    [self setup];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"My Library Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setPrimaryLanguageLabel:nil];
    [self setSecondaryLanguageLabel:nil];
    [self setTitle1TextField:nil];
    [self setTitle2TextField:nil];
    [self setImageView:nil];
    [self setDrawButton:nil];
    
    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setTitle1AudioRecordButton:nil];
    [self setTitle2AudioRecordButton:nil];
    
    [self setPlayTitle1AudioButton:nil];
    [self setPlayTitle2AudioButton:nil];
    
    [self setErrorMessageLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
