//
//  CreateBookDescriptionViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-09-27.
//
//

#import "BookDescriptionViewController.h"
#import "BookDrawViewController.h"
#import "Book.h"
#import "BookManager.h"
#import "Language+Utils.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface BookDescriptionViewController ()
{
    BOOL isDescription1Edited;
    BOOL hasError;
    UIColor *errorTextBoxBackgroudColor;
    Book *currentBook;

    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audio1AbsPath;
    NSString *audio2AbsPath;
}
@end

@implementation BookDescriptionViewController

@synthesize primaryLanguageLabel = _primaryLanguageLabel;
@synthesize secondaryLanguageLabel = _secondaryLanguageLabel;
@synthesize description1TextView = _description1TextView;
@synthesize description2TextView = _description2TextView;
@synthesize description1AudioRecordButton = _description1AudioRecordButton;
@synthesize description2AudioRecordButton = _description2AudioRecordButton;

@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize nextButton = _nextButton;
@synthesize backButton = _backButton;

@synthesize wizardDataObject = _wizardDataObject;
@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;

static int const DESC1_TEXT_VIEW = 1;
static int const DESC2_TEXT_VIEW = 2;

static int const DESC1_AUDIO = 3;
static int const DESC2_AUDIO = 4;

static int const MAX_LENGTH=250;
//static int const PUSH_Y_COOD_BY=40;
static NSString * const ENTER_THE_BOOK_DESC=@"Enter the book description.";

- (IBAction)recordAudio1Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
    [self presentAudioRecordingPopover:DESC1_AUDIO];
}

- (IBAction)recordAudio2Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
/*    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
    [UIView commitAnimations];
*/
    [self presentAudioRecordingPopover:DESC2_AUDIO];
}

- (void) changeAudioButton
{
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audio1AbsPath])
    {
        //will change to image
        [self.description1AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal] ;
    }
    else
    {
        [self.description1AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal] ;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audio2AbsPath])
    {
        //will change to image
        [self.description2AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal] ;
    }
    else
    {
        [self.description2AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal] ;
    }

}

- (void) popoverDone:(id)sender
{
    [self.audioRecordingPopoverController dismissPopoverAnimated:YES];
 /*   AudioRecordingViewController *ar = (AudioRecordingViewController *)sender;
    if(ar.buttonNum == DESC2_AUDIO)
    {
        [UIView setAnimationDuration:0.25];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_COOD_BY_FOR_AUDIO, self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    }
    ar = nil;
  */
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
            self.audioRecordingViewController.fileAbsURL = audio1AbsPath;
            self.audioRecordingViewController.buttonNum = DESC1_AUDIO;
        }
        else
        {
            self.audioRecordingViewController.fileAbsURL = audio2AbsPath;
            self.audioRecordingViewController.buttonNum = DESC2_AUDIO;
        }
        
        self.audioRecordingPopoverController = [[UIPopoverController alloc]
                                                initWithContentViewController:self.audioRecordingViewController];
        self.audioRecordingViewController.parentPopoverController = self.audioRecordingPopoverController;
        
        self.audioRecordingPopoverController.delegate = (id)self;
        self.audioRecordingPopoverController.popoverContentSize = audioPopoverSize;
    }
    else{
        if(buttonPressed == DESC1_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = DESC1_AUDIO;
        }
        else
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = DESC2_AUDIO;

        }
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    int yCood = 0, xCood = 71;
    if(buttonPressed == DESC1_AUDIO)
    {
        yCood = 230;
    }
    else if(buttonPressed == DESC2_AUDIO)
    {
        yCood = 420;
    }
    
    [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(xCood, yCood, audioPopoverSize.width, audioPopoverSize.height) inView:self.view permittedArrowDirections:0 animated:YES];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)backButtonPressed:(id)sender
{
    [self saveBook];
    
    [[self navigationController] popViewControllerAnimated:YES] ;
}

-(void) saveBook
{
    [self.view endEditing:YES];
    currentBook.description1 = [self.description1TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([self.description2TextView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC)])
        currentBook.description2 = nil;
    else
        currentBook.description2 = [self.description2TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [BookManager saveBook:currentBook];
    
    self.wizardDataObject = currentBook;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self saveBook];
    if ([segue.identifier isEqualToString:@"Edit Book - Proceed to draw"])
    {
        ((BookDrawViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.nextButton.hidden = TRUE;
    self.nextButton.enabled = FALSE;
    
    currentBook = self.wizardDataObject;
    self.primaryLanguageLabel.text = currentBook.primaryLanguage.name;
    self.secondaryLanguageLabel.text = currentBook.secondaryLanguage.name;

    self.description1TextView.delegate = self;
    self.description2TextView.delegate = self;
    self.description1TextView.tag = DESC1_TEXT_VIEW;
    self.description2TextView.tag = DESC2_TEXT_VIEW;
    
    if(currentBook.description1 == nil)
    {
        self.description1TextView.text = NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC);
    }
    else
    {
        self.description1TextView.text = currentBook.description1;
        self.nextButton.enabled = TRUE;
        self.nextButton.hidden = FALSE;
    }
    
    if(currentBook.description2 == nil)
    {
        self.description2TextView.text = NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC);
    }
    else
    {
        self.description2TextView.text = currentBook.description2;
    }

    //change book id.
    audioPopoverSize = CGSizeMake(400, 300);
    
    audio1AbsPath = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_DESC_1_AUDIO_FILENAME];
    audio2AbsPath = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_DESC_2_AUDIO_FILENAME];
    
    [self changeAudioButton];
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Book Edit Description Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setPrimaryLanguageLabel:nil];
    [self setSecondaryLanguageLabel:nil];
    [self setDescription1TextView:nil];
    [self setDescription2TextView:nil];
    
    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setDescription1AudioRecordButton:nil];
    [self setDescription2AudioRecordButton:nil];
    
    [self setErrorMessageLabel:nil];
    [self setNextButton:nil];
    [self setBackButton:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillDisappear:(BOOL)animated
{
    //back button.
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
    {
        if(currentBook.description1 != nil)
            currentBook.description1 = self.description1TextView.text;
        if(currentBook.description2 != nil)
        currentBook.description2 = self.description2TextView.text;
        [BookManager saveBook:currentBook];
    }
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
#pragma mark Text View data source methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= MAX_LENGTH)
    {
        return YES;
    } else {
        NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
        textView.text = [[[textView.text substringToIndex:range.location]
                          stringByAppendingString:[text substringToIndex:emptySpace]]
                         stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
        return NO;
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    //reset the text in textview.
    if([textView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC)])
        textView.text = @"";
    
    if(textView.tag == DESC2_TEXT_VIEW)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.errorMessageLabel.text = NULL;
    hasError = FALSE;
    textView.backgroundColor = [UIColor whiteColor];
    
    [self validateDesc1];

    if(textView.tag == DESC2_TEXT_VIEW)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    }
    
    if(!hasError && isDescription1Edited)
    {
        self.nextButton.hidden = FALSE;
        self.nextButton.enabled = TRUE;
    }
    else {
        self.nextButton.hidden = TRUE;
        self.nextButton.enabled = FALSE;
    }
}

- (void)validateDesc1
{
    NSString *desc1 = [self.description1TextView text];
    desc1 = [desc1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([desc1 isEqualToString:NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC)] || [desc1 isEqualToString:@""]==TRUE)
    {
        self.description1TextView.backgroundColor = errorTextBoxBackgroudColor;
        self.errorMessageLabel.text = NSLocalizedString([[@"Description in " stringByAppendingString:self.primaryLanguageLabel.text] stringByAppendingString:@" is required."], @"Check if description is required.");
        self.description1TextView.text = NSLocalizedString(ENTER_THE_BOOK_DESC, ENTER_THE_BOOK_DESC);
        isDescription1Edited = FALSE;
        hasError = TRUE;
        currentBook.description1 = nil;
    }
    else
    {
        isDescription1Edited = TRUE;
        currentBook.description1 = desc1;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:TRUE];
}

@end