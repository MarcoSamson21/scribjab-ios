//
//  MyLibarryViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-09.
//
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "BookScrollView.h"

@interface MyLibraryViewController : UIViewController<UIAlertViewDelegate,UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong)IBOutlet BookScrollView *myBooksScrollView;
@property (nonatomic, strong)IBOutlet BookScrollView *myFavouriteBooksScrollView;
@property (nonatomic, strong)IBOutlet BookScrollView *myGroupBooksScrollView;
@property (nonatomic, strong)IBOutlet UILabel *myBookLabel;
@property (nonatomic, strong)IBOutlet UILabel *myGroupLabel;
@property (nonatomic, strong)IBOutlet UILabel *noBookFavouriteLabel;
@property (nonatomic, strong)IBOutlet UILabel *noBookGroupLabel;
@property (nonatomic, strong)IBOutlet UIActivityIndicatorView *deleteActivity;
@property (nonatomic, strong)IBOutlet UITableView *userGroupTableView;
@property (nonatomic, strong)IBOutlet UIScrollView *parentScrollView;
@property (nonatomic, strong)IBOutlet UIImageView *groupImageView;

@property (nonatomic, strong)IBOutlet UIButton * accountMenuButton;
@property (nonatomic, strong)IBOutlet UIButton * logoutMenuButton;
//@property (nonatomic, strong)IBOutlet UIButton * aboutMenuButton;
//@property (nonatomic, strong)IBOutlet UIButton * createMenuButton;
//@property (nonatomic, strong)IBOutlet UIButton * readMenuButton;
@property (nonatomic, strong)IBOutlet UIButton * createButton;
@property (nonatomic, strong)IBOutlet UIButton * readButton;

@property (nonatomic, strong) User *loginUser;
-(IBAction) logoutButtonIsPressed:(id)sender;
-(IBAction) accountButtonIsPressed:(id)sender;
-(IBAction) createButtonIsPressed:(id)sender;
-(IBAction) readButtonIsPressed:(id)sender;
//-(IBAction) aboutButtonIsPressed:(id)sender;

@end