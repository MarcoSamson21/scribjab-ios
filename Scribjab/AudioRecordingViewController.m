//
//  AudioRecordingViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-09-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioRecordingViewController.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

int const RECORD_MODE = 1;
int const RECORD_STOP_MODE = 2;
int const PLAY_MODE = 3;
int const PLAY_STOP_MODE = 4;

@interface AudioRecordingViewController ()
{
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    NSTimer *playbackTimer;
    NSTimer *recordTimer;
    int secondsPass;
    NSURL *playURL;
    BOOL didRecorded;
}

@end

@implementation AudioRecordingViewController

@synthesize timerLabel = _timerLabel;
@synthesize durationLabel = _durationLabel;
@synthesize slashLabel = _slashLabel;
@synthesize messageLabel = _messageLabel;
@synthesize timeProgressView = _timeProgressView;

@synthesize recordStopToggleButton = _recordStopToggleButton;
@synthesize playStopToggleButton = _playStopToggleButton;
@synthesize deleteButton = _deleteButton;
@synthesize okButton = _okButton;
@synthesize parentPopoverController = _parentPopoverController;
@synthesize fileAbsURL = _fileAbsURL;
@synthesize buttonNum = _buttonNum;
//record button is pressed.
-(IBAction) toggleRecordStopButton:(id)sender
{
    //button need to change backgroundimage.
    secondsPass = 0;
    if(self.recordStopToggleButton.tag == RECORD_MODE)
    {
        [self prepareAudioRecording];
        self.messageLabel.text = NSLocalizedString(@"You have 2 minutes to record.", @"Label for recording.");
        self.playStopToggleButton.enabled = NO;
        self.deleteButton.enabled = NO;
        self.okButton.enabled = NO;
        self.okButton.hidden = YES;
        self.slashLabel.hidden = NO;
        self.timerLabel.text = @"00:00";
        self.durationLabel.text = @"00:40";
        [self.timeProgressView setProgress:0.0 animated:YES];

        if (!audioRecorder.recording)
        {
            [audioRecorder record];
            didRecorded = TRUE;
            if(audioRecorder.recording)
            {
                recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimerLabelAndProgressView:) userInfo:[NSNumber numberWithFloat:40.0] repeats:YES];
            }
        }
        [self.recordStopToggleButton setTag:RECORD_STOP_MODE];
        [self.recordStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_stop.png"] forState:UIControlStateNormal];
    }
    else // it is in RECORD_Stop_MODE
    {
        [self changeToRecordStopMode];
    }
}

//play button is pressed.
-(IBAction) togglePlayStopButton:(id)sender
{
    secondsPass = 0;
    //button need to change backgroundimage.
    
    if(self.playStopToggleButton.tag == PLAY_MODE)
    {
        [self.playStopToggleButton setTag:PLAY_STOP_MODE];
        [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play_active.png"] forState:UIControlStateNormal];
        [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play_activehover.png"] forState:UIControlStateHighlighted];
        
        self.recordStopToggleButton.enabled = NO;
        self.deleteButton.enabled = NO;
        self.okButton.hidden = YES;
        NSError *error;
        
        playURL = [NSURL fileURLWithPath:(didRecorded==TRUE?self.wavAbsURL : self.fileAbsURL)];
        audioPlayer = [[AVAudioPlayer alloc]
                       initWithContentsOfURL:playURL
                       error:&error];
        audioPlayer.delegate = self;
        self.durationLabel.text = [self formatTime:[audioPlayer duration]];
        [self.timeProgressView setProgress:0.0 animated:NO];
        if (error)
        {
            self.messageLabel.text = NSLocalizedString(@"Fail to start the audio player.", @"Fail to start the audio player.");
        }
        else
        {
            [audioPlayer play];
            playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimerLabelAndProgressView:) userInfo:[NSNumber numberWithFloat:[audioPlayer duration]] repeats:YES];
        }
    }
    else //it is in PLAY_Stop_MODE
    {
        [self changeToPlayStopMode];
    }
}

-(void)changeToRecordStopMode
{
    [self.recordStopToggleButton setTag:RECORD_MODE];
    [self.recordStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_active.png"] forState:UIControlStateNormal];
    
    self.playStopToggleButton.enabled = YES;
    self.deleteButton.enabled = YES;
    self.okButton.enabled = YES;
    self.okButton.hidden = NO;
    secondsPass = 0;
    [recordTimer invalidate];
    
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
        audioRecorder = nil;
//        AVAudioSession *session = [AVAudioSession sharedInstance];
//        int flags = AVAudioSessionSetActiveFlags_NotifyOthersOnDeactivation;
//        [session setActive:NO withFlags:flags error:nil];
    }
}

- (void) changeToPlayStopMode
{
    [self.playStopToggleButton setTag:PLAY_MODE];
    [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play.png"] forState:UIControlStateNormal];

    self.recordStopToggleButton.enabled = YES;
    self.deleteButton.enabled = YES;
    self.okButton.hidden = NO;
    [playbackTimer invalidate];
    self.timerLabel.text = @"00:00";
    [self.timeProgressView setProgress:0.0 animated:NO];
    
    if([audioPlayer play])
    {
        [audioPlayer stop];
        audioPlayer = nil;
        playURL = nil;
    }
}

-(void)updateTimerLabelAndProgressView:(NSTimer *)timer
{
    secondsPass ++;
    
    self.timerLabel.text = [self formatTime:secondsPass];

    float length = (secondsPass / ([(NSNumber *)[timer userInfo] floatValue]-1)) ;
    [self.timeProgressView setProgress:length animated:YES];
    
 //    NSLog(@"%f", [self.timeProgressView progress]);    
    if(secondsPass==40)
    {
        [self changeToRecordStopMode];
    }
 }

-(NSString *)formatTime:(int)time
{
    int minutes, seconds;
    minutes = (time % 3600) / 60;
    seconds = (time % 3600) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

//delete button is pressed.
-(IBAction) deleteButtonIsPressed:(id)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(![self.fileAbsURL isEqualToString:self.wavAbsURL])
    {
        [fileManager removeItemAtURL:[NSURL fileURLWithPath:self.fileAbsURL] error:&error];
    }
    [fileManager removeItemAtURL:[NSURL fileURLWithPath:self.wavAbsURL] error:&error];
    
    didRecorded = FALSE;
    if(error)
    {
        self.messageLabel.text = NSLocalizedString(@"Fail to start the audio player.", @"Fail to start the audio player.");
    }
    [self resetButtons];
    
}

//ok button is pressed.
-(IBAction) okButtonIsPressed:(id)sender
{
    if([audioPlayer play])
    {
        [self changeToPlayStopMode];
    }
    [self.parentPopoverController.delegate performSelector:@selector(popoverDone:) withObject:self];
}


-(void) prepareAudioRecording
{
    
   /* NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    //[NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:8000.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:8], AVLinearPCMBitDepthKey,
                                    nil];
*/
     NSDictionary *recordSettings = [NSDictionary
                                dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:AVAudioQualityHigh],
                                AVEncoderAudioQualityKey,
                                [NSNumber numberWithInt:16],
                                AVEncoderBitRateKey,
                                [NSNumber numberWithInt: 2],
                                AVNumberOfChannelsKey,
                                [NSNumber numberWithFloat:44100.0],
                                AVSampleRateKey,
                                nil];

    NSError *error = nil;
    audioRecorder = [[AVAudioRecorder alloc]
                 initWithURL:[NSURL fileURLWithPath:self.wavAbsURL]
                 settings:recordSettings
                 error:&error];

    if (error)
    {
        self.messageLabel.text = NSLocalizedString(@"Fail to start the audio player.", @"Fail to start the audio player.");
    }
    else
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [audioSession setActive:YES error:nil];
        
        [audioRecorder prepareToRecord];
    }
}


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
    [self.recordStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_active.png"] forState:UIControlStateNormal];
    [self.recordStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_active_hover.png"] forState:UIControlStateHighlighted];
    [self.recordStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_off.png"] forState:UIControlStateDisabled];

    [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play.png"] forState:UIControlStateNormal];
    [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play_hover.png"] forState:UIControlStateHighlighted];
    [self.playStopToggleButton setBackgroundImage:[UIImage imageNamed:@"rec_play_off.png"] forState:UIControlStateDisabled];

    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"rec_trash.png"] forState:UIControlStateNormal];
    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"rec_trash_hover.png"] forState:UIControlStateHighlighted];
    [self.deleteButton setBackgroundImage:[UIImage imageNamed:@"rec_trash_off.png"] forState:UIControlStateDisabled];
   
    [self resetButtons];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Audio Recording Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.modalInPopover = YES;
}

- (void) resetButtons{
    //set record button.
    didRecorded = FALSE;
    [self.recordStopToggleButton setTag:RECORD_MODE];
    [self.playStopToggleButton setTag:PLAY_MODE];

    self.recordStopToggleButton.enabled = YES;
    secondsPass = 0;
//    audioPlayer = nil;
    //disable play button if fileURL not exist.
    if([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL fileURLWithPath:self.fileAbsURL] path]])
    {
        self.playStopToggleButton.enabled = YES;
        self.deleteButton.enabled = YES;
        self.timerLabel.text = @"00:00";
        
        NSError *error;
        audioPlayer = [[AVAudioPlayer alloc]
                       initWithContentsOfURL:[NSURL fileURLWithPath:self.fileAbsURL]
                       error:&error];
        
        if(error)
        {
            self.messageLabel.text = NSLocalizedString(@"Fail to start the audio player.", @"Fail to start the audio player.");
        }
        self.durationLabel.text = [self formatTime:[audioPlayer duration]];
        self.slashLabel.hidden = NO;
        self.messageLabel.text = NSLocalizedString(@"You have 2 minutes to record.", @"Label for recording.");
    }
    else
    {
        self.playStopToggleButton.enabled = NO;
        self.deleteButton.enabled = NO;
        self.messageLabel.text = NSLocalizedString(@"You have 2 minutes to record.", @"Label for recording.");
        self.slashLabel.hidden = YES;
        self.durationLabel.text = NULL;
        self.timerLabel.text = NULL;
    }
    [self.timeProgressView setProgress:0.0];
    self.okButton.enabled = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    audioRecorder = nil;
    audioPlayer = nil;
    playURL = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


// delegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self changeToPlayStopMode];
//    audioPlayer = nil;
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{}

-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{}

-(void)audioPlayerEndInterruption:(AVAudioPlayer *)player{}

-(void)dealloc
{
    audioPlayer = nil;
    audioRecorder = nil;
    playURL = nil;
}
@end
