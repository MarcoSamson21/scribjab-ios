//
//  BookViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-03.
//
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "EditTitlePageViewController.h"
#import "EditBookPageViewController.h"

@interface BookViewController : UIViewController<IWizardNavigationViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
 
@property (nonatomic, strong)IBOutlet UIScrollView *pageScrollView;
@property (nonatomic, strong)IBOutlet UIView *pageView;
@property (nonatomic, strong)IBOutlet UIButton *addPageButton;
@property (nonatomic, strong)IBOutlet UIButton *publishButton;
@property (nonatomic, strong)IBOutlet UIButton *saveAndCloseButton;
@property (nonatomic, strong) IBOutlet UIButton *uploadButton;

- (IBAction)publishBook:(id)sender;
- (IBAction)saveAndClose:(id)sender;
- (IBAction)goToCreatePage:(id)sender;
- (IBAction)uploadBtnClick:(id)sender;

@end
