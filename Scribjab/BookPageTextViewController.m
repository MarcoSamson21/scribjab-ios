//
//  BookPageTextViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-05.
//
//

#import "BookPageTextViewController.h"
#import "BookPageDrawViewController.h"
#import "BookPage.h"
#import "Language+Utils.h"
#import "BookManager.h"
//#import "Utilities.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface BookPageTextViewController ()
{
    BOOL isText1Edited;
    BOOL hasError;
    UIColor *errorTextBoxBackgroudColor;
    BookPage *currentBookPage;
    
    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audio1AbsPath;
    NSString *audio2AbsPath;
    
}
@end

@implementation BookPageTextViewController

@synthesize sortOrder = _sortOrder;
@synthesize primaryLanguageLabel = _primaryLanguageLabel;
@synthesize secondaryLanguageLabel = _secondaryLanguageLabel;
@synthesize text1TextView = _text1TextView;
@synthesize text2TextView = _text2TextView;
@synthesize text1AudioRecordButton = _text1AudioRecordButton;
@synthesize text2AudioRecordButton = _text2AudioRecordButton;

@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize nextButton = _nextButton;

@synthesize wizardDataObject = _wizardDataObject;
@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;

static int const TEXT1_TEXT_VIEW = 1;
static int const TEXT2_TEXT_VIEW = 2;

static int const TEXT1_AUDIO = 3;
static int const TEXT2_AUDIO = 4;

static int const MAX_LENGTH=250;
static int const PUSH_Y_COOD_BY=40;
static NSString * const ENTER_THE_BOOK_TEXT=@"Enter the book text.";

- (IBAction)recordAudio1Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
    [self presentAudioRecordingPopover:TEXT1_AUDIO];
}

- (IBAction)recordAudio2Pressed:(id)sender
{
    [[self view] endEditing:TRUE];
/*    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY_FOR_KEYBOARD, self.view.frame.size.width,self.view.frame.size.height);
    [UIView commitAnimations];
*/
    [self presentAudioRecordingPopover:TEXT2_AUDIO];
}

- (void) changeAudioButton
{
    if([[NSFileManager defaultManager] fileExistsAtPath:audio1AbsPath])
    {
        //will change to image
        [self.text1AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal] ;
    }
    else
    {
        [self.text1AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal] ;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audio2AbsPath])
    {
        //will change to image
        [self.text2AudioRecordButton setTitle:@"audio" forState:UIControlStateNormal] ;
    }
    else
    {
        [self.text2AudioRecordButton setTitle:@"no audio" forState:UIControlStateNormal] ;
    }
    
}

- (void) popoverDone:(id)sender
{
    [self.audioRecordingPopoverController dismissPopoverAnimated:YES];
 /*   AudioRecordingViewController *ar = (AudioRecordingViewController *)sender;
    if(ar.buttonNum == TEXT2_AUDIO)
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
    
    if(self.audioRecordingPopoverController == nil)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
        
        self.audioRecordingViewController = [sb instantiateViewControllerWithIdentifier:@"audioRecordingIdentifier"];
        if(buttonPressed == TEXT1_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audio1AbsPath;
            self.audioRecordingViewController.buttonNum = TEXT1_AUDIO;
        }
        else
        {
            self.audioRecordingViewController.fileAbsURL = audio2AbsPath;
            self.audioRecordingViewController.buttonNum = TEXT2_AUDIO;
        }
        
        self.audioRecordingPopoverController = [[UIPopoverController alloc]
                                                initWithContentViewController:self.audioRecordingViewController];
        self.audioRecordingViewController.parentPopoverController = self.audioRecordingPopoverController;
        
        self.audioRecordingPopoverController.delegate = (id)self;
        self.audioRecordingPopoverController.popoverContentSize = audioPopoverSize;
    }
    else{
        if(buttonPressed == TEXT1_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TEXT1_AUDIO;
        }
        else
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audio2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TEXT1_AUDIO;

        }
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    int yCood = 0, xCood = 71;
    if(buttonPressed == TEXT1_AUDIO)
    {
        yCood = 230;
    }
    else if(buttonPressed == TEXT2_AUDIO)
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
    currentBookPage.text1 = [self.text1TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([self.text2TextView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT)])
        currentBookPage.text2 = nil;
    else
        currentBookPage.text2 = [self.text2TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

//    BOOL isTemp = [[currentBookPage objectID] isTemporaryID];

    [BookManager saveBookPage:currentBookPage];

    //move audio file.
 /*   if(isTemp) //this is a new book page.
    {
        NSLog(@"Moving audio files for %@", currentBookPage.text1);
        
        NSURL *oldAudio1Path = [NSURL fileURLWithPath:audio1AbsPath];
        NSURL *oldAudio2Path = [NSURL fileURLWithPath:audio2AbsPath];
        
        NSURL *newAudio1Path = [NSURL fileURLWithPath:[BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME]];
        NSURL *newAudio2Path = [NSURL fileURLWithPath:[BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME]];
                                
        NSError *error = NULL;
        [BookManager createDirIfNotExist:currentBookPage];

        NSLog(@"%@", audio1AbsPath);
        if([[NSFileManager defaultManager] fileExistsAtPath:audio1AbsPath])
            [[NSFileManager defaultManager] moveItemAtURL:oldAudio1Path toURL:newAudio1Path error:&error];
        if([[NSFileManager defaultManager] fileExistsAtPath:audio2AbsPath])
            [[NSFileManager defaultManager] moveItemAtURL:oldAudio2Path toURL:newAudio2Path error:&error];
    }
*/
    //move audio file to the right place.
    
    
    self.wizardDataObject = currentBookPage;
    if ([segue.identifier isEqualToString:@"Edit Book Page- Proceed to draw"])
    {
        ((BookPageDrawViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    NSLog(@"Create Text view");
    self.nextButton.hidden = TRUE;
    self.nextButton.enabled = FALSE;
     [self.navigationController setNavigationBarHidden:YES];
    //no page for the book and need to create one.
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        Book *currentBook = (Book *)self.wizardDataObject;
    
        if(currentBookPage == nil)
        {
            currentBookPage = [BookManager getNewBookPageInstance];
            currentBookPage.book = currentBook;
            currentBookPage.sortOrder = [NSNumber numberWithInt:[currentBook.pages count]];
        }
    }
 
    //book page already exists.
    if([self.wizardDataObject isKindOfClass:[BookPage class]])
        currentBookPage = self.wizardDataObject;
    
    self.primaryLanguageLabel.text = currentBookPage.book.primaryLanguage.name;
    self.secondaryLanguageLabel.text = currentBookPage.book.secondaryLanguage.name;
    

    self.text1TextView.delegate = self;
    self.text2TextView.delegate = self;
    self.text1TextView.tag = TEXT1_TEXT_VIEW;
    self.text2TextView.tag = TEXT2_TEXT_VIEW;
    
    if(currentBookPage.text1 == nil)
    {
        self.text1TextView.text = NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT);
    }
    else
    {
        self.text1TextView.text = currentBookPage.text1;
        self.nextButton.enabled = TRUE;
        self.nextButton.hidden = FALSE;
    }
    
    if(currentBookPage.text2 == nil)
    {
        self.text2TextView.text = NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT);
    }
    else
    {
        self.text2TextView.text = currentBookPage.text2;
    }
    
    //change book id.
    audioPopoverSize = CGSizeMake(670, 360);
    
    //get the path name of audio1 and audio2.
    [BookManager createDirIfNotExist:currentBookPage];
    audio1AbsPath = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME];
    audio2AbsPath = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME];
     
    [self changeAudioButton];
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Edit Page Text Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setPrimaryLanguageLabel:nil];
    [self setSecondaryLanguageLabel:nil];
    [self setText1TextView:nil];
    [self setText2TextView:nil];
    
    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setText1AudioRecordButton:nil];
    [self setText2AudioRecordButton:nil];
    
    [self setErrorMessageLabel:nil];
    [self setNextButton:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) viewWillDisappear:(BOOL)animated
{
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
    {
        if(currentBookPage.text1 != nil)
            currentBookPage.text1 = self.text1TextView.text;
        if(currentBookPage.text2 != nil)
            currentBookPage.text2 = self.text2TextView.text;

        [BookManager saveBookPage:currentBookPage];
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
    if([textView.text isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT)])
        textView.text = @"";
    
    if(textView.tag == TEXT2_TEXT_VIEW)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y-PUSH_Y_COOD_BY, self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.errorMessageLabel.text = NULL;
    hasError = FALSE;
    textView.backgroundColor = [UIColor whiteColor];
    
    [self validateDesc1];
   
    if(textView.tag == TEXT2_TEXT_VIEW)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.25];
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+PUSH_Y_COOD_BY, self.view.frame.size.width,self.view.frame.size.height);
        [UIView commitAnimations];
    }
    
    if(!hasError && isText1Edited)
    {
        self.nextButton.hidden = FALSE;
        self.nextButton.enabled = TRUE;
    }
    else
    {
        self.nextButton.hidden = TRUE;
        self.nextButton.enabled = FALSE;
    }
}

- (void)validateDesc1
{
    NSString *desc1 = [self.text1TextView text];
    desc1 = [desc1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([desc1 isEqualToString:NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT)] || [desc1 isEqualToString:@""]==TRUE)
    {
        self.text1TextView.backgroundColor = errorTextBoxBackgroudColor;
        self.errorMessageLabel.text = NSLocalizedString([[@"Text in " stringByAppendingString:self.primaryLanguageLabel.text] stringByAppendingString:@" is required."], @"Check if description is required.");
        self.text1TextView.text = NSLocalizedString(ENTER_THE_BOOK_TEXT, ENTER_THE_BOOK_TEXT);
        isText1Edited = FALSE;
        hasError = TRUE;
        currentBookPage.text1 = nil;
    }
    else
    {
        isText1Edited = TRUE;
        currentBookPage.text1 = desc1;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:TRUE];
}

@end