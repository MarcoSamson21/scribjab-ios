//
//  ReadBookCommentTableViewCell.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-03.
//
//

#import <UIKit/UIKit.h>

@interface ReadBookCommentTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *fromLabel;
@property (strong, nonatomic) IBOutlet UITextView *commentText;
@property (strong, nonatomic) IBOutlet UIButton *flagCommentButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteCommentButton;
@property (strong, nonatomic) IBOutlet UIImageView *avatar;
@end
