//
//  ReadTitlePageViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-19.
//
//

#import <UIKit/UIKit.h>
#import "ReadBookManagerViewController.h"
#import "Book.h"

@interface ReadBookCoverPageViewController : UIViewController

@property (nonatomic, strong) Book * book;
@property (readonly) BOOL isMenuHidden;

- (void) stopAllSoundPlayback;
- (void) setMenuHidden:(BOOL) hidden;



@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) IBOutlet UITextView *title1;
@property (strong, nonatomic) IBOutlet UITextView *title2;
@property (strong, nonatomic) IBOutlet UITextView *text1;
@property (strong, nonatomic) IBOutlet UITextView *text2;
@property (strong, nonatomic) IBOutlet UILabel *author;

@property (strong, nonatomic) IBOutlet UIButton *playTitle1Button;
@property (strong, nonatomic) IBOutlet UIButton *playTitle2Button;
@property (strong, nonatomic) IBOutlet UIButton *playText1Button;
@property (strong, nonatomic) IBOutlet UIButton *playText2Button;

@property (strong, nonatomic) IBOutlet UIView *menuBarView;
@property (strong, nonatomic) IBOutlet UIButton *menuExpandButton;

@property (strong, nonatomic) IBOutlet UIButton *readToMeButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentsButton;
@property (strong, nonatomic) IBOutlet UIButton *flagBookButton;
@property (strong, nonatomic) IBOutlet UIButton *facebookButton;


- (IBAction)playTitle1:(id)sender;
- (IBAction)playTitle2:(id)sender;
- (IBAction)playText1:(id)sender;
- (IBAction)playText2:(id)sender;

- (IBAction)closeBook:(id)sender;
- (IBAction)menuButtonClick:(id)sender;

- (IBAction)readToMe:(id)sender;
- (IBAction)likeBook:(id)sender;
- (IBAction)viewComments:(id)sender;
- (IBAction)flagBook:(id)sender;
- (IBAction)facebookShare:(id)sender;

@end
