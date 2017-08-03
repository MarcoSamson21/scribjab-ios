//
//  BookPreviewViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-10.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"

// Delegate Desclaration
@protocol BookPreviewViewControllerDelegate <NSObject>
- (void) downloadRequestedForBook:(Book *)book;
@end

// Preview Controller declaration
@interface BookPreviewViewController : UIViewController
@property (nonatomic, strong) Book * book;
@property (nonatomic, weak) id<BookPreviewViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UILabel *title1Lable;
@property (strong, nonatomic) IBOutlet UILabel *title2Lable;
@property (strong, nonatomic) IBOutlet UILabel *description1Label;
@property (strong, nonatomic) IBOutlet UILabel *description2Label;
@property (strong, nonatomic) IBOutlet UILabel *languagesLabel;
@property (strong, nonatomic) IBOutlet UILabel *tagsLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *imageBorderView;
- (IBAction)download:(id)sender;
- (IBAction)closeView:(id)sender;
@end
