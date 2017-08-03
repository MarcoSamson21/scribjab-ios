//
//  AudioRecordingViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-09-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioRecordingViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *slashLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *timeProgressView;
@property (strong, nonatomic) IBOutlet UIButton *recordStopToggleButton;
@property (strong, nonatomic) IBOutlet UIButton *playStopToggleButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *okButton;

@property (strong, nonatomic) UIPopoverController *parentPopoverController;
@property NSString * fileAbsURL;
@property NSString * wavAbsURL;
@property int buttonNum;

-(IBAction) toggleRecordStopButton:(id)sender;
-(IBAction) togglePlayStopButton:(id)sender;
-(IBAction) deleteButtonIsPressed:(id)sender;
-(IBAction) okButtonIsPressed:(id)sender;

- (void) resetButtons;
- (void) prepareAudioRecording;
@end
