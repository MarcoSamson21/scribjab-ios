//
//  BookPageDescriptionViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-05.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "IWizardNavigationViewController.h"
#import "AudioRecordingViewController.h"

@interface BookPageTextViewController : UIViewController<IWizardNavigationViewController, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;

@property (strong, nonatomic) IBOutlet UITextView *text1TextView;
@property (strong, nonatomic) IBOutlet UITextView *text2TextView;

@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;

@property (strong, nonatomic) IBOutlet UIButton *text1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *text2AudioRecordButton;

@property int sortOrder;

- (IBAction)recordAudio1Pressed:(id)sender;
- (IBAction)recordAudio2Pressed:(id)sender;
- (void) popoverDone:(id)sender;
@end
