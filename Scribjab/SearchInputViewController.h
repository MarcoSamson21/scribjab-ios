//
//  SearchInputViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-07.
//
//

#import <UIKit/UIKit.h>

@protocol SearchInputViewControllerDelegate <NSObject>
- (void) searchCriteriaSelectedAgeGroupId:(NSNumber*)ageGroupId firstLanguage:(NSNumber*)firstLanguageId secondLanguage:(NSNumber*)secontLanguageId keywords:(NSString*)keywords searchSummary:(NSString*)searchSummary;
@end




@interface SearchInputViewController : UIViewController

@property (nonatomic, weak) id<SearchInputViewControllerDelegate> delegate;
@property (nonatomic, strong) UIPopoverController * parentPopover;

@property (strong, nonatomic) IBOutlet UIButton *ageGroupButton;
@property (strong, nonatomic) IBOutlet UIButton *firstLanguageButton;
@property (strong, nonatomic) IBOutlet UIButton *secondLanguageButton;
@property (strong, nonatomic) IBOutlet UITextField *tagsTextInput;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)submitSearch:(id)sender;

// put any object in a dictionary and specify which name to display in the selection table view
+ (NSDictionary*) wrapObjectInDictionary:(id)object withDisplayName:(NSString*)name;

@end
