//
//  EditBookPageViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-12-13.
//
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "AudioRecordingViewController.h"

@interface EditBookPageViewController : UIViewController<IWizardNavigationViewController, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource>
{
    AudioRecordingViewController *audioRecordingViewController;
    UIPopoverController *audioRecordingPopoverController;
}

//@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
//@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;

//@property (strong, nonatomic) IBOutlet UITextView *title1TextView;
//@property (strong, nonatomic) IBOutlet UITextView *title2TextView;
@property (strong, nonatomic) IBOutlet UITextView *text1TextView;
@property (strong, nonatomic) IBOutlet UITextView *text2TextView;
@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageTextLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageTextLabel;
@property (strong, nonatomic) IBOutlet UILabel *pageLabel;

@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;

@property (nonatomic, strong)IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *drawButton;

@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;
@property int sortOrder;
//@property id delegate;
//@property (strong, nonatomic) IBOutlet UIButton *title1AudioRecordButton;
//@property (strong, nonatomic) IBOutlet UIButton *title2AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *text1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *text2AudioRecordButton;

//@property (nonatomic, strong)IBOutlet UIButton *playTitle1AudioButton;
//@property (nonatomic, strong)IBOutlet UIButton *playTitle2AudioButton;
@property (nonatomic, strong)IBOutlet UIButton *playText1AudioButton;
@property (nonatomic, strong)IBOutlet UIButton *playText2AudioButton;

//-(IBAction) togglePlayStopTitle1AudioButton:(id)sender;
//-(IBAction) togglePlayStopTitle2AudioButton:(id)sender;
-(IBAction) togglePlayStopText1AudioButton:(id)sender;
-(IBAction) togglePlayStopText2AudioButton:(id)sender;

//- (IBAction)recordAudioTitle1Pressed:(id)sender;
//- (IBAction)recordAudioTitle2Pressed:(id)sender;
- (IBAction)recordAudioText1Pressed:(id)sender;
- (IBAction)recordAudioText2Pressed:(id)sender;

- (IBAction)drawButtonIsPressed:(id)sender;
- (void) popoverDone:(id)sender;
- (void) reset;
- (void) setup;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
- (void)addVideo:(NSString*)videoPath;
- (void)resetVideoView;
//- (void) validate;
@end
