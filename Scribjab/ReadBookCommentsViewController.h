//
//  ReadBookCommentsViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-03.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"
#import "LoginViewControllerDelegate.h"

@interface ReadBookCommentsViewController : UIViewController

@property (nonatomic, strong) Book * book;
@property (nonatomic, weak) UIPopoverController * popoverController;
@property (nonatomic, weak) id<LoginViewControllerDelegate> loginDelegate;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UITextView *commentText;
@property (strong, nonatomic) IBOutlet UILabel *commentTitle1;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UIButton *pleaseLoginButton;

- (IBAction)closePopup:(id)sender;
- (IBAction)flagComment:(id)sender;
- (IBAction)deleteComment:(id)sender;
- (IBAction)addComment:(id)sender;
- (IBAction)openLoginView:(id)sender;
@end
