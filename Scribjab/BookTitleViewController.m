//
//  CreateBookTitleViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-09-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookTitleViewController.h"
#import "BookDescriptionViewController.h"

#import "Book.h"
#import "Language+Utils.h"
#import "BookManager.h"
#import "Utilities.h"
#import "CommonMessageBoxes.h"
#import "NavigationManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface BookTitleViewController ()
{
    BOOL isTitle1Edited;
//    BOOL isTitle2Edited;
    BOOL hasError;
    UIColor *errorTextBoxBackgroudColor;
    Book *currentBook;
    
    BOOL isTitle1AudioRecorded;
    BOOL isTitle2AudioRecorded;
    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audio1AbsPath;
    NSString *audio2AbsPath;
}
@end

@implementation BookTitleViewController

@synthesize primaryLanguageLabel = _primaryLanguageLabel;
@synthesize secondaryLanguageLabel = _secondaryLanguageLabel;
@synthesize title1TextView = _title1TextView;
@synthesize title2TextView = _title2TextView;
@synthesize title1AudioRecordButton = _title1AudioRecordButton;
@synthesize title2AudioRecordButton = _title2AudioRecordButton;

@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize nextButton = _nextButton;
@synthesize cancelButton = _cancelButton;

@synthesize wizardDataObject = _wizardDataObject;
@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;

static int const TITLE1_TEXT_VIEW = 1;
static int const TITLE2_TEXT_VIEW = 2;

static int const TITLE1_AUDIO = 3;
static int const TITLE2_AUDIO = 4;

static int const MAX_LENGTH=25;
//static int const PUSH_Y_COOD_BY=40;
static NSString * const ENTER_THE_BOOK_TITLE=@"Enter the book title.";


//cancel button is pressed.
- (IBAction)cancelEditBook:(id)sender
{
    //delete any recorded audio if it is creating book.
    if(currentBook.description1 == nil ||  [[currentBook.description1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE)
    {
        [BookManager deleteBook:currentBook];
    }
    
    //go back to library.
      [NavigationManager navigateToMyLibraryForUser:currentBook.author animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

- (IBAction)recordAudio1Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
    [self presentAudioRecordingPopover:TITLE1_AUDIO];
}

- (IBAction)recordAudio2Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
//    [UIView setAnimationDuration:0.25];
//    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY_FOR_AUDIO, self.view.frame.size.width,self.view.frame.size.height);
//    [UIView commitAnimations];

    [self presentAudioRecordingPopover:TITLE2_AUDIO];
}

- (void) changeAudioButton
{
    //toggle enable of audio buttons to indicate whether the audio are recorded.
    if([[NSFileManager defaultManager] fileExistsAtPath:audio1AbsPath])
    {
        //will change to image
        [self.title1AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal];
    }
    else
    {
        [self.title1AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal];
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audio2AbsPath])
    {
        //will change to image
        [self.title2AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal];
    }
    else
    {
        [self.title2AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal];
    }
}

- (void) popoverDone:(id)sender
{
//    NSLog(@"%@", NSStringFromClass([sender class]));
    [self.audioRecordingPopoverController dismissPopoverAnimated:YES];
 /*   AudioRecordingViewController *ar = (AudioRecordingViewController *)sender;
    if(ar.buttonNum == TITLE2_AUDIO)
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
        
        if(buttonPressed == TITLE1_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audio1AbsPath;
            self.audioRecordingViewController.buttonNum = TITLE1_AUDIO;
        }
        else
        {
            self.audioRecordingViewController.fileAbsURL = audio2AbsPath;
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
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TITLE1_AUDIO;
        }
        else
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TITLE2_AUDIO;
        }
        
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    int yCood = 0, xCood = 71;
    if(buttonPressed == TITLE1_AUDIO)
    {
        yCood = 230;
    }
    else if(buttonPressed == TITLE2_AUDIO)
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


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.view endEditing:YES];
    currentBook.title1  = [self.title1TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if([self.title2TextView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TITLE, ENTER_THE_BOOK_TITLE)])
        currentBook.title2 = nil;
    else
        currentBook.title2 = [self.title2TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [BookManager saveBook:currentBook];
    
    self.wizardDataObject = currentBook;
    if ([segue.identifier isEqualToString:@"Edit Book - Proceed to book description"])
    {
        ((BookDescriptionViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.nextButton.hidden = TRUE;
    
    //editing an existing book.
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        currentBook = (Book *)self.wizardDataObject;
    }
    
    //creating a new book.
    if(currentBook == nil)
    {
        User *loginUser = (User *)[(NSDictionary *)self.wizardDataObject objectForKey:@"user"];
        currentBook = [BookManager getNewBookInstance:loginUser];

        //creating a new book and from select language view.
        if([self.wizardDataObject isKindOfClass:[NSDictionary class]])
        {
            currentBook.primaryLanguage = (Language *)[(NSDictionary *)self.wizardDataObject objectForKey:@"primaryLanaguage"];
            currentBook.secondaryLanguage = (Language *)[(NSDictionary *)self.wizardDataObject objectForKey:@"secondaryLanaguage"];
        }
    }
    self.primaryLanguageLabel.text = currentBook.primaryLanguage.name;
    self.secondaryLanguageLabel.text = currentBook.secondaryLanguage.name;
    
    self.title1TextView.delegate = self;
    self.title2TextView.delegate = self; 
    self.title1TextView.tag = TITLE1_TEXT_VIEW;
    self.title2TextView.tag = TITLE2_TEXT_VIEW;
    self.title1TextView.layer.cornerRadius = 9.0;
    self.title1TextView.layer.masksToBounds = YES;
    self.title2TextView.layer.cornerRadius = 9.0;
    self.title2TextView.layer.masksToBounds = YES;
    
    //initial text for title1.
    if(currentBook.title1 == nil)
    {
        self.title1TextView.text = NSLocalizedString(ENTER_THE_BOOK_TITLE, ENTER_THE_BOOK_TITLE);
    }
    else
    {
        self.title1TextView.text = currentBook.title1;
        self.nextButton.enabled = TRUE;
        self.nextButton.hidden = FALSE;
    }

    //initial text for title2.
    if(currentBook.title2 == nil)
    {
        self.title2TextView.text = NSLocalizedString(ENTER_THE_BOOK_TITLE, ENTER_THE_BOOK_TITLE);
    }
    else
    {
        self.title2TextView.text = currentBook.title2;
    }
    
    //set the audio popover size.
    audioPopoverSize = CGSizeMake(400, 300);

    //get the path name of audio1 and audio2.
    [BookManager createDirIfNotExist:currentBook]; //the id here is permanent.
        audio1AbsPath = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_1_AUDIO_FILENAME];
        audio2AbsPath = [BookManager getBookItemAbsPath:currentBook fileName:BOOK_TITLE_2_AUDIO_FILENAME];

    [self changeAudioButton];
    
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Edit Title Page Text Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setPrimaryLanguageLabel:nil];
    [self setSecondaryLanguageLabel:nil];
    [self setTitle1TextView:nil];
    [self setTitle2TextView:nil];

    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setTitle1AudioRecordButton:nil];
    [self setTitle2AudioRecordButton:nil];

    [self setErrorMessageLabel:nil];
    [self setNextButton:nil];
    [self setCancelButton:nil];

    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
#pragma mark Text View data source methods

// set the max. length of title can be edited.
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
    if([textView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TITLE, ENTER_THE_BOOK_TITLE)])
        textView.text = @"";
    if(textView.tag == TITLE2_TEXT_VIEW)
    {
        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
        
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.errorMessageLabel.text = NULL;
    textView.backgroundColor = [UIColor whiteColor];
    hasError = FALSE;
    
    [self validateTitle1];

    if(textView.tag == TITLE2_TEXT_VIEW)
    {
        [UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
    }
    
    if(!hasError && isTitle1Edited)
    {
        self.nextButton.hidden = FALSE;
        self.nextButton.enabled = TRUE;
    }
    else {
        self.nextButton.hidden = TRUE;
        self.nextButton.enabled = FALSE;
    }
}

- (void)validateTitle1
{
    NSString *title1 = [self.title1TextView text];
    title1 = [title1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if([title1 isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TITLE, ENTER_THE_BOOK_TITLE)] || [title1 isEqualToString:@""]==TRUE)
    {
        isTitle1Edited = FALSE;
        hasError = TRUE;
        self.title1TextView.backgroundColor = errorTextBoxBackgroudColor;
        self.errorMessageLabel.text = NSLocalizedString([[@"Title in " stringByAppendingString:self.primaryLanguageLabel.text] stringByAppendingString:@" is required."], @"Check if title is required.");
    }
    else
    {
        isTitle1Edited = TRUE;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:TRUE];
}
@end
