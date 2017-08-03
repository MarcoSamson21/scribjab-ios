//
//  CreateBookTitleViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-09-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "IWizardNavigationViewController.h"
#import "AudioRecordingViewController.h"
#import "User.h"

@interface BookTitleViewController : UIViewController<IWizardNavigationViewController, UITextViewDelegate>
{
    AudioRecordingViewController *audioRecordingViewController;
     UIPopoverController *audioRecordingPopoverController;
}
@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;

@property (strong, nonatomic) IBOutlet UITextView *title1TextView;
@property (strong, nonatomic) IBOutlet UITextView *title2TextView;

@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;

@property (strong, nonatomic) IBOutlet UIButton *title1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *title2AudioRecordButton;

- (IBAction)recordAudio1Pressed:(id)sender;
- (IBAction)recordAudio2Pressed:(id)sender;
- (IBAction)cancelEditBook:(id)sender;

- (void) popoverDone:(id)sender;
@end
