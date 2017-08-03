//
//  EditTitlePageViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-12-09.
//
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "AudioRecordingViewController.h"

@interface EditTitlePageViewController : UIViewController<IWizardNavigationViewController, UITextViewDelegate, UITextFieldDelegate>
{
    AudioRecordingViewController *audioRecordingViewController;
    UIPopoverController *audioRecordingPopoverController;
}

@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;

@property (strong, nonatomic) IBOutlet UITextField *title1TextField;
@property (strong, nonatomic) IBOutlet UITextField *title2TextField;
//@property (strong, nonatomic) IBOutlet UITextView *description1TextView;
//@property (strong, nonatomic) IBOutlet UITextView *description2TextView;
@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageDescLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageDescLabel;
@property (strong, nonatomic) IBOutlet UILabel *pageLabel;

@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;

@property (nonatomic, strong)IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *drawButton;

@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;

@property (strong, nonatomic) IBOutlet UIButton *title1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *title2AudioRecordButton;
//@property (strong, nonatomic) IBOutlet UIButton *description1AudioRecordButton;
//@property (strong, nonatomic) IBOutlet UIButton *description2AudioRecordButton;

@property (nonatomic, strong)IBOutlet UIButton *playTitle1AudioButton;
@property (nonatomic, strong)IBOutlet UIButton *playTitle2AudioButton;
//@property (nonatomic, strong)IBOutlet UIButton *playDesc1AudioButton;
//@property (nonatomic, strong)IBOutlet UIButton *playDesc2AudioButton;

-(IBAction) togglePlayStopTitle1AudioButton:(id)sender;
-(IBAction) togglePlayStopTitle2AudioButton:(id)sender;
//-(IBAction) togglePlayStopDesc1AudioButton:(id)sender;
//-(IBAction) togglePlayStopDesc2AudioButton:(id)sender;

- (IBAction)recordAudioTitle1Pressed:(id)sender;
- (IBAction)recordAudioTitle2Pressed:(id)sender;
//- (IBAction)recordAudioDesc1Pressed:(id)sender;
//- (IBAction)recordAudioDesc2Pressed:(id)sender;

- (IBAction)drawButtonIsPressed:(id)sender;
- (void) popoverDone:(id)sender;
- (void) validate;

- (void)reset;

@end