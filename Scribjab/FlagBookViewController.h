//
//  FlagBookViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-02.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"

@protocol FlagBookViewControllerDelegate <NSObject>

-(void) bookFlagAdded;
-(void) bookFlaggingCancelled;
-(void) bookFlaggingErrorLoginRequired;

@end

@interface FlagBookViewController : UIViewController

@property (nonatomic, strong) Book * book;
@property (nonatomic, weak) id<FlagBookViewControllerDelegate> delegate;


@property (strong, nonatomic) IBOutlet UITextView *commentText;
- (IBAction)flagClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *flagButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end
