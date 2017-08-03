//
//  CreateBookDescriptionViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-09-27.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "IWizardNavigationViewController.h"
#import "AudioRecordingViewController.h"

@interface BookDescriptionViewController : UIViewController<IWizardNavigationViewController, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;

@property (strong, nonatomic) IBOutlet UITextView *description1TextView;
@property (strong, nonatomic) IBOutlet UITextView *description2TextView;

@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;

@property (strong, nonatomic) IBOutlet UIButton *description1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *description2AudioRecordButton;

- (IBAction)recordAudio1Pressed:(id)sender;
- (IBAction)recordAudio2Pressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;
- (void) popoverDone:(id)sender;

@end
