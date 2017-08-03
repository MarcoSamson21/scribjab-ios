//
//  PublishBookViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-22.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"
#import "AudioRecordingViewController.h"

@protocol PublishBookViewControllerDelegate <NSObject>

-(void) publishBook;
-(void) publishBookCancelled;
-(void) publishBookErrorLoginRequired;

@end

@interface PublishBookViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate,UITextViewDelegate, UITableViewDataSource,UITextFieldDelegate>
{
    AudioRecordingViewController *audioRecordingViewController;
    UIPopoverController *audioRecordingPopoverController;
}

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *noGroupLabel;
@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIImageView *thumbImageView;

@property (strong, nonatomic) IBOutlet UITextField *searchTagTextField;
@property (strong, nonatomic) IBOutlet UITableView *ageGroupTableView;
@property (strong, nonatomic) IBOutlet UITableView *userGroupTableView;

@property (strong, nonatomic) IBOutlet UIButton *termsButton;

@property (strong, nonatomic) IBOutlet UIButton *publishButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *uploadActivity;
@property (strong, nonatomic) IBOutlet UIProgressView *uploadProgress;
@property (strong, nonatomic) IBOutlet UILabel *uploadingLabel;

@property (strong, nonatomic) IBOutlet UITextField *description1TextField;
@property (strong, nonatomic) IBOutlet UITextField *description2TextField;

//@property (strong, nonatomic) IBOutlet UITextView *description1TextView;
//@property (strong, nonatomic) IBOutlet UITextView *description2TextView;
@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageDescLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageDescLabel;
@property (strong, nonatomic) AudioRecordingViewController *audioRecordingViewController;
@property (strong, nonatomic) UIPopoverController *audioRecordingPopoverController;

@property (strong, nonatomic) IBOutlet UIButton *description1AudioRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *description2AudioRecordButton;

@property (nonatomic, strong)IBOutlet UIButton *playDesc1AudioButton;
@property (nonatomic, strong)IBOutlet UIButton *playDesc2AudioButton;

-(IBAction) togglePlayStopDesc1AudioButton:(id)sender;
-(IBAction) togglePlayStopDesc2AudioButton:(id)sender;

- (IBAction)recordAudioDesc1Pressed:(id)sender;
- (IBAction)recordAudioDesc2Pressed:(id)sender;


@property Book * book;
@property (nonatomic, weak) id<PublishBookViewControllerDelegate> delegate;

-(IBAction) cancelButtonPressed:(id)sender;
-(IBAction) publishButtonPressed:(id)sender;

- (IBAction)showTermsOfUseView:(id)sender;

@end
