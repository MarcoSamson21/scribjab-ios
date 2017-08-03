//
//  SearchBookItemSelectionTableViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-08.
//
//

#import <UIKit/UIKit.h>

@protocol SearchBookItemSelectionTableViewControllerDelegate <NSObject>
- (void) searchItemSelected:(id)item;
@end






@interface SearchBookItemSelectionTableViewController : UITableViewController
@property (nonatomic, strong) NSArray * dataSource;
@property int tag;
@property (nonatomic, weak) id<SearchBookItemSelectionTableViewControllerDelegate> delegate;
@property (nonatomic, strong) UIPopoverController * parentPopover;
@end
