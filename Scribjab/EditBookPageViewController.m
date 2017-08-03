//
//  EditBookPageViewController
//  Scribjab
//
//  Created by Gladys Tang on 12-12-09.
//
//

#import "EditBookPageViewController.h"
#import "Language+Utils.h"
#import "Book.h"
#import "BookPage.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import "ModalConstants.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

#import <MediaPlayer/MediaPlayer.h>

@interface EditBookPageViewController ()
{
    BOOL isTitle1Edited;
    BOOL hasError;
    UIColor *errorTextBoxBackgroudColor;
    BookPage *currentBookPage;
    
    BOOL isText1AudioRecorded;
    BOOL isText2AudioRecorded;
    
    
    AudioRecordingViewController *_audioRecordingViewController;
    UIPopoverController *_audioRecordingPopover;
    CGSize audioPopoverSize;
    NSString *audioText1AbsPath;
    NSString *audioText2AbsPath;
    
    AVAudioPlayer *audioPlayer;
    NSURL *playURL;
    
    NSMutableArray* videoThumbnails;
    NSMutableArray* videoPaths;
    
    UITextView *currentText;
    
    
}
- (void)presentAudioRecordingPopover:(int)buttonPressed;
- (void)changeAudioButton;
- (void)saveBookPage;
- (NSString *)getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName;
- (void)enableButtonsForPlayText1:(bool) playText1 playText2:(bool) playText2 recordText1:(bool)recordText1 recordText2:(bool)recordText2;
- (void)changeToPlayMode:(UIButton *)button fileAbsPath:(NSString *)fileAbsPath;
- (void)resetPlayAudioButtons;
- (void)resetAudioButton:(UIButton *) button fileAbsURL:(NSString *)fileAbsURL;
- (void)changeToStopMode:(UIButton *)button;
@end

@implementation EditBookPageViewController
@synthesize primaryLanguageTextLabel = _primaryLanguageTextLabel;
@synthesize secondaryLanguageTextLabel = _secondaryLanguageTextLabel;
@synthesize pageLabel = _pageLabel;
@synthesize text1TextView = _text1TextView;
@synthesize text2TextView = _text2TextView;
@synthesize text1AudioRecordButton = _text1AudioRecordButton;
@synthesize text2AudioRecordButton = _text2AudioRecordButton;

@synthesize errorMessageLabel = _errorMessageLabel;
@synthesize drawButton = _drawButton;

@synthesize sortOrder = _sortOrder;
@synthesize wizardDataObject = _wizardDataObject;
@synthesize audioRecordingViewController = _audioRecordingViewController;
@synthesize audioRecordingPopoverController = _audioRecordingPopoverController;


@synthesize imageView = _imageView;
@synthesize playText1AudioButton = _playText1AudioButton;
@synthesize playText2AudioButton = _playText2AudioButton;

static int const TEXT1_TEXT_VIEW = 3;
static int const TEXT2_TEXT_VIEW = 4;
static int const TITLE_MAX_LENGTH = 50;
static int const TEXT_MAX_LENGTH = 250;
static int const PUSH_Y_FOR_TEXT1 = 210;
static int const PUSH_Y_FOR_TEXT2 = 290;
//static NSString * const ENTER_THE_BOOK_TEXT=@"Enter the book text.";

static int const TEXT1_AUDIO = 3;
static int const TEXT2_AUDIO = 4;
static int const PLAY_MODE = 1;
static int const STOP_MODE = 0;

static CGFloat const CORNER_RADIUS = 9.0;
static CGFloat const TEXT_ANIMATION_DURATION = 0.25;

- (IBAction)recordAudioText1Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:TEXT1_AUDIO];
}

- (IBAction)recordAudioText2Pressed:(id)sender
{
    [self.view endEditing:TRUE];
    [self presentAudioRecordingPopover:TEXT2_AUDIO];
}

- (IBAction)drawButtonIsPressed:(id)sender
{
    [self.view endEditing:TRUE];
    
    //go back to bookview controller
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self.parentViewController
                                   selector:@selector(drawBookImage:)
                                   userInfo:currentBookPage
                                    repeats:NO];
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
                        case TEXT1_AUDIO:
                            audioText1AbsPath = ar.wavAbsURL;
                            break;
                        case TEXT2_AUDIO:
                            audioText2AbsPath = ar.wavAbsURL;
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    }
 
    [self saveBookPage];
    [self changeAudioButton];
}

- (void)presentAudioRecordingPopover:(int)buttonPressed
{
    //first time to instantiate popover.
    if(self.audioRecordingPopoverController == nil)
    {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
        self.audioRecordingViewController = [sb instantiateViewControllerWithIdentifier:@"audioRecordingIdentifier"];
        
        if(buttonPressed == TEXT1_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioText1AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = TEXT1_AUDIO;
        }
        if(buttonPressed == TEXT2_AUDIO)
        {
            self.audioRecordingViewController.fileAbsURL = audioText2AbsPath;
            self.audioRecordingViewController.wavAbsURL = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME];
            self.audioRecordingViewController.buttonNum = TEXT2_AUDIO;
        }
        
        
        self.audioRecordingPopoverController = [[UIPopoverController alloc]
                                                initWithContentViewController:self.audioRecordingViewController];
        self.audioRecordingViewController.parentPopoverController = self.audioRecordingPopoverController;
        
        self.audioRecordingPopoverController.delegate = (id)self;
        self.audioRecordingPopoverController.popoverContentSize = audioPopoverSize;
    }
    else     //popover already instantiated.
    {
        if(buttonPressed == TEXT1_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioText1AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TEXT1_AUDIO;
        }
        if(buttonPressed == TEXT2_AUDIO)
        {
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).fileAbsURL = audioText2AbsPath;
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).wavAbsURL = [BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME];
            ((AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController).buttonNum = TEXT2_AUDIO;
            
        }
        [(AudioRecordingViewController *)self.audioRecordingPopoverController.contentViewController resetButtons];
    }
    
    self.audioRecordingPopoverController.contentViewController.preferredContentSize = CGSizeMake(400, 300);
    
    if(buttonPressed == TEXT1_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(300, 0, audioPopoverSize.width, audioPopoverSize.height + 10) inView:self.text1TextView permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
    }
    else if(buttonPressed == TEXT2_AUDIO)
    {
        [self.audioRecordingPopoverController presentPopoverFromRect:CGRectMake(300, 0, audioPopoverSize.width, audioPopoverSize.height) inView:self.text2TextView permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
}

//- (void)textViewDidChange:(UITextView *)textView
//{
//    CGFloat fixedWidth = textView.frame.size.width;
//    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//    CGRect newFrame = textView.frame;
//    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
//    textView.frame = newFrame;
//}


- (void)saveBookPage
{
    //[self.view endEditing:YES];
        
    //get desc1
    if ([self.text1TextView.text isEqualToString:NSLocalizedString(@"Enter the book text.", @"Description for page text.")])
        currentBookPage.text1 = nil;
    else
        currentBookPage.text1 = [self.text1TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //get desc2
    if([self.text2TextView.text isEqualToString:NSLocalizedString(@"Enter the book text.", @"Description for page text.")])
        currentBookPage.text2 = nil;
    else
        currentBookPage.text2 = [self.text2TextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    currentBookPage.videoPathArray = [NSKeyedArchiver archivedDataWithRootObject:videoPaths];
    
    [BookManager saveBookPage:currentBookPage];
    
    self.wizardDataObject = currentBookPage;
}

- (void)setup
{
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        Book *currentBook = (Book *)self.wizardDataObject;
        if(currentBookPage == nil)
        {
            currentBookPage = [BookManager getNewBookPageInstance];
            currentBookPage.book = currentBook;
            currentBookPage.backgroundColorCode = @"ffffff";
            currentBookPage.sortOrder = [NSNumber numberWithInt:[currentBook.pages count]];
        }
    }
    
    //book page already exists.
    if([self.wizardDataObject isKindOfClass:[BookPage class]]) {
        currentBookPage = self.wizardDataObject;        
    }
    

    self.pageLabel.text = [NSString stringWithFormat:@"%d", [currentBookPage.sortOrder intValue]];
    self.primaryLanguageTextLabel.text = currentBookPage.book.primaryLanguage.name;
    self.secondaryLanguageTextLabel.text = currentBookPage.book.secondaryLanguage.name;
    self.text1TextView.delegate = self;
    self.text2TextView.delegate = self;
    self.text1TextView.tag = TEXT1_TEXT_VIEW;
    self.text2TextView.tag = TEXT2_TEXT_VIEW;
    self.text1TextView.layer.cornerRadius = CORNER_RADIUS;
    self.text1TextView.layer.masksToBounds = YES;
    self.text2TextView.layer.cornerRadius = CORNER_RADIUS;
    self.text2TextView.layer.masksToBounds = YES;
    self.text1TextView.backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    self.text2TextView.backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    
    UIEdgeInsets inset = UIEdgeInsetsZero;
    inset.top = self.text1TextView.bounds.size.height-self.text1TextView.contentSize.height;
    self.text1TextView.contentInset = inset;
    
    inset.top = self.text2TextView.bounds.size.height-self.text2TextView.contentSize.height;
    self.text2TextView.contentInset = inset;

    
    self.text1TextView.text = (currentBookPage.text1 == nil)? NSLocalizedString(@"Enter the book text.", @"Description for page text."): currentBookPage.text1;
    
    self.text2TextView.text = (currentBookPage.text2 == nil)? NSLocalizedString(@"Enter the book text.", @"Description for page text."): currentBookPage.text2;
    
    //set the audio popover size.
    audioPopoverSize = CGSizeMake(400, 300);
    
    [BookManager createDirIfNotExist:currentBookPage]; //the id here is permanent.
    //get the path name of title1 and title2, desc1 and desc2.
    
    audioText1AbsPath = [self getAudioAbsPath:BOOK_PAGE_TEXT_1_AUDIO_FILENAME mp3FileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3]; 
    audioText2AbsPath = [self getAudioAbsPath:BOOK_PAGE_TEXT_2_AUDIO_FILENAME mp3FileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3];
    
    [self changeAudioButton];
    [self resetPlayAudioButtons];
    
    errorTextBoxBackgroudColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
    self.imageView.image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:currentBookPage fileName:BOOK_IMAGE_FILENAME]];
    self.imageView.backgroundColor = [UIColor colorWithHexString:currentBookPage.backgroundColorCode];
    self.imageView.frame = self.view.frame;
    self.view.backgroundColor =  self.imageView.backgroundColor;
    [self getVideo];
}

- (NSString *)getAudioAbsPath:(NSString *)wavFileName  mp3FileName:(NSString *)mp3FileName
{
    NSString * wavAbsPath = [BookManager getBookItemAbsPath:currentBookPage fileName:wavFileName];
    if([currentBookPage.book.approvalStatus intValue]== BookApprovalStatusRejected)
    {
        NSString * mp3AbsPath = [BookManager getBookItemAbsPath:currentBookPage fileName:mp3FileName];
        return ([[NSFileManager defaultManager] fileExistsAtPath:mp3AbsPath] == TRUE?  mp3AbsPath : wavAbsPath);
    }
    
    return wavAbsPath;
}
// ======================================================================================================================================
#pragma mark Text View data source methods

// set the max. length of title can be edited.
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    
    if(textView.tag == TEXT1_TEXT_VIEW || textView.tag == TEXT2_TEXT_VIEW)
    {
        if(newLength <= TEXT_MAX_LENGTH)
        {
            return YES;
        } else {
            NSUInteger emptySpace = TEXT_MAX_LENGTH - (textView.text.length - range.length);
            textView.text = [[[textView.text substringToIndex:range.location]
                              stringByAppendingString:[text substringToIndex:emptySpace]]
                             stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
            return NO;
        }
    }
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    currentText = textView;
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.drawButton.enabled=NO;
    self.drawButton.hidden = YES;
    //reset the text in textview.
    if(textView.tag == TEXT1_TEXT_VIEW || textView.tag == TEXT2_TEXT_VIEW)
    {
        if([textView.text isEqualToString:NSLocalizedString(@"Enter the book text.", @"Description for page text.")])
            textView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self saveBookPage];
    self.drawButton.enabled = YES;
    self.drawButton.hidden = NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:TRUE];
    //enable drawing button.
    self.drawButton.enabled=YES;
    self.drawButton.hidden = NO;
    
    self.text1AudioRecordButton.enabled = YES;
    self.text1AudioRecordButton.hidden = NO;
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
    }
    else
    {
        [audioPlayer play];
        [button setTag:PLAY_MODE];
        [button setBackgroundImage:[UIImage imageNamed:@"create_speaker_pause.png"] forState:UIControlStateNormal];
    }
}

-(IBAction) togglePlayStopText1AudioButton:(id)sender
{
    //stop -> play
    if(self.playText1AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playText1AudioButton fileAbsPath:audioText1AbsPath];
        [self enableButtonsForPlayText1:TRUE playText2:FALSE recordText1:FALSE recordText2:FALSE];
    }
    else
    {
        [self changeToStopMode:self.playText1AudioButton];
        [self enableButtonsForPlayText1:TRUE playText2:TRUE recordText1:TRUE recordText2:TRUE];
    }
}

-(IBAction) togglePlayStopText2AudioButton:(id)sender
{
    //stop -> play
    if(self.playText2AudioButton.tag == STOP_MODE)
    {
        [self changeToPlayMode:self.playText2AudioButton fileAbsPath:audioText2AbsPath];
        [self enableButtonsForPlayText1:FALSE playText2:TRUE recordText1:FALSE recordText2:FALSE];
    }
    else
    {
        [self changeToStopMode:self.playText2AudioButton];
        [self enableButtonsForPlayText1:TRUE playText2:TRUE recordText1:TRUE recordText2:TRUE];
    }
}

- (void)enableButtonsForPlayText1:(bool) playText1 playText2:(bool) playText2 recordText1:(bool)recordText1 recordText2:(bool)recordText2
{
    self.playText1AudioButton.enabled = playText1;
    self.playText2AudioButton.enabled = playText2;
    self.text1AudioRecordButton.enabled = recordText1;
    self.text2AudioRecordButton.enabled = recordText2;
}

- (void)resetPlayAudioButtons
{
    [self resetAudioButton:self.playText1AudioButton fileAbsURL:audioText1AbsPath];
    [self resetAudioButton:self.playText2AudioButton fileAbsURL:audioText2AbsPath];
}

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
    [self enableButtonsForPlayText1:TRUE playText2:TRUE recordText1:TRUE recordText2:TRUE];
    audioPlayer = nil;
    playURL = nil;
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player{}

-(void)dealloc
{
    audioPlayer=nil;
    playURL = nil;
}

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
    videoThumbnails =  [[NSMutableArray alloc] init];
    videoPaths =  [[NSMutableArray alloc] init];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [super viewDidLoad];
    [self setup];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Edit Book Page Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGFloat delta_Y = [UIScreen mainScreen].bounds.size.height - keyboardSize.height - currentText.frame.origin.y - currentText.frame.size.height;
    
    if (delta_Y > 0) {
        
    }
    else {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
                  ^{
                      self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+delta_Y, self.view.frame.size.width,self.view.frame.size.height);
                  } completion:^(BOOL finished){}];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGFloat delta_Y = self.view.bounds.size.height - keyboardSize.height - currentText.frame.origin.y - currentText.frame.size.height;
    
    if (delta_Y < 0) {
        [UIView animateWithDuration:TEXT_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             self.view.frame = CGRectMake(self.view.frame.origin.x, 0, self.view.frame.size.width,self.view.frame.size.height);
         } completion:^(BOOL finished){}];
    }
}


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
    [self enableButtonsForPlayText1:TRUE playText2:TRUE recordText1:TRUE recordText2:TRUE];    
}
- (void)viewDidUnload
{
    [self setText1TextView:nil];
    [self setText2TextView:nil];
    [self setImageView:nil];
    [self setDrawButton:nil];
    
    [self setAudioRecordingViewController:nil];
    [self setAudioRecordingPopoverController:nil];
    [self setText1AudioRecordButton:nil];
    [self setText2AudioRecordButton:nil];
    
    [self setPlayText1AudioButton:nil];
    [self setPlayText2AudioButton:nil];
    
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return videoThumbnails.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"thumbnailCell" forIndexPath:indexPath];
    UIImageView* imgThumbnail = (UIImageView*)[cell viewWithTag:100];
    imgThumbnail.image = [videoThumbnails objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* videoURL = [videoPaths objectAtIndex:indexPath.row];
    MPMoviePlayerViewController *videoPlayerView = [[MPMoviePlayerViewController alloc] initWithContentURL: [NSURL fileURLWithPath:videoURL]];
    [self presentMoviePlayerViewControllerAnimated:videoPlayerView];
    [videoPlayerView.moviePlayer play];
}

- (UIImage*) getVideoThumbnail:(NSString*)filePathLocal {
    NSURL *videoURL = [NSURL fileURLWithPath:filePathLocal];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    [generator setAppliesPreferredTrackTransform:YES];
    
    CMTime timestamp = CMTimeMake(1, 60);
    NSError *error = nil;
    CGImageRef imageRef = [generator copyCGImageAtTime:timestamp actualTime:nil error:&error];
    if (error == nil) {
        return [[UIImage alloc] initWithCGImage:imageRef];
    }
    else {
        return [UIImage imageNamed:@"Default-Landscape.png"];
    }
//    return nil;
}

- (void)getVideo {
    
    videoPaths = [NSMutableArray new];
    videoThumbnails = [NSMutableArray new];
    
    videoPaths = [NSKeyedUnarchiver unarchiveObjectWithData:currentBookPage.videoPathArray];
    
    for (int i = 0; i < videoPaths.count; i++) {
        NSString* path = [videoPaths objectAtIndex:i];
        UIImage* thumbnail = [self getVideoThumbnail:path];
        [videoThumbnails addObject:thumbnail];
    }
    [self.collectionView reloadData];
}

- (void)addVideo:(NSString*)videoPath {
    UIImage* thumbnail = [self getVideoThumbnail:videoPath];
    if (videoPaths == nil) {
        videoPaths = [NSMutableArray array];
    }
    [videoPaths addObject:videoPath];
    [videoThumbnails addObject:thumbnail];
    [self.collectionView reloadData];
    [self saveBookPage];
}

- (void)resetVideoView {
    [self saveBookPage];
    [videoPaths removeAllObjects];
    [videoThumbnails removeAllObjects];
    [self.collectionView reloadData];
    
}

@end

