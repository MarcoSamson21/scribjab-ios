//
//  ReadBookPageViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-19.
//
//

#import <UIKit/UIKit.h>
#import "ReadBookManagerViewController.h"
#import "BookPage.h"

@interface ReadPageViewController : UIViewController

@property (nonatomic, strong) BookPage * page;
@property (readonly) BOOL isMenuHidden;

- (void) stopAllSoundPlayback;
- (void) setMenuHidden:(BOOL) hidden;


@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) IBOutlet UITextView *text1;
@property (strong, nonatomic) IBOutlet UITextView *text2;
@property (strong, nonatomic) IBOutlet UIButton *playText1Button;
@property (strong, nonatomic) IBOutlet UIButton *playText2Button;
@property (strong, nonatomic) IBOutlet UIView *menuBarView;
@property (strong, nonatomic) IBOutlet UIButton *menuExpendButton;

@property (strong, nonatomic) IBOutlet UIButton *readToMeButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentsButton;
@property (strong, nonatomic) IBOutlet UIButton *flagButton;
@property (strong, nonatomic) IBOutlet UIButton *facebookButton;


- (IBAction)closeBook:(id)sender;
- (IBAction)showOrHideMenuBar:(id)sender;

- (IBAction)playText1:(id)sender;
- (IBAction)playText2:(id)sender;

- (IBAction)readToMe:(id)sender;
- (IBAction)likeBook:(id)sender;
- (IBAction)viewComments:(id)sender;
- (IBAction)flagBook:(id)sender;
- (IBAction)facebookShare:(id)sender;
@end
