//
//  ReadBookLastPageViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-03.
//
//

#import <UIKit/UIKit.h>
#import "ReadBookManagerViewController.h"

@interface ReadBookLastPageViewController : UIViewController

@property (nonatomic, strong) ReadBookManagerViewController * pageManager;

@property (strong, nonatomic) IBOutlet UILabel *bookTitle1Label;
@property (strong, nonatomic) IBOutlet UILabel *bookTitle2Label;
@property (strong, nonatomic) IBOutlet UIImageView *image;
- (IBAction)readAgain:(id)sender;
- (IBAction)closeBook:(id)sender;
- (IBAction)openCommentsView:(id)sender;
- (IBAction)navigateHome:(id)sender;
@end
