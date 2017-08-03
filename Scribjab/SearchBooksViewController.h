//
//  SearchBooksViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-09.
//
//

#import <UIKit/UIKit.h>
#import "SearchCollectionScrollView.h"

@interface SearchBooksViewController : UIViewController


@property (strong, nonatomic) IBOutlet SearchCollectionScrollView *searchResultScrollView;
- (IBAction)navigateToHomeView:(id)sender;
- (IBAction)navigateToBrowseSection:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *searchLabel;
@property (strong, nonatomic) IBOutlet UILabel *noResultsLabel;

- (void) searchForBooksWithGroupId:(NSNumber*)groupId firstLanguageId:(NSNumber*)firstLanguageId secondLanguageId:(NSNumber*)secondLanguageId keywords:(NSString *) keywords;
@end
