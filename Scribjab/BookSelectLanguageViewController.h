//
//  SelectLanguageViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-09-24.
//
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "User.h"

@interface BookSelectLanguageViewController : UIViewController <IWizardNavigationViewController,UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>


//primary language selection
@property (strong, nonatomic) IBOutlet UILabel *primaryLanguageLabel;
//@property (strong, nonatomic) IBOutlet UIButton *togglePrimaryLanguageDropDownButton;
//@property (strong, nonatomic) IBOutlet UITableView *primaryLanguageListTableView;
@property (weak, nonatomic) IBOutlet UIPickerView *primaryLanguagePickerView;


//secondary language selection
@property (strong, nonatomic) IBOutlet UILabel *secondaryLanguageLabel;
//@property (strong, nonatomic) IBOutlet UIButton *toggleSecondaryLanguageDropDownButton;
//@property (strong, nonatomic) IBOutlet UITableView *secondaryLanguageListTableView;
@property (weak, nonatomic) IBOutlet UIPickerView *secondaryLanguagePickerView;


//other iboutlet.
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *goToLibraryButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivity;

@property (nonatomic, strong) User *loginUser;
@property BOOL isFromHome;
//- (IBAction)nextButtonIsPressed:(id)sender;
//- (IBAction)togglePrimaryLanguageDropDown:(id)sender;
//- (IBAction)toggleSecondaryLanguageDropDown:(id)sender;
- (IBAction)cancelCreateBook:(id)sender;
- (IBAction)cancelCreateBookAndGoToLibrary:(id)sender;
- (IBAction)nextButtonIsPress:(id)sender;
@end
