//
//  SearchCollectionScrollView.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-09.
//
//

#import <UIKit/UIKit.h>

@interface SearchCollectionScrollView : UIScrollView

- (void) removeAllSubviews;
- (void) showActivityIndicator;
- (void) hideActivityIndicator;

@end
