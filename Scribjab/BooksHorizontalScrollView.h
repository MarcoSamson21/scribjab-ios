//
//  BooksHorizontalScrollView
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import <UIKit/UIKit.h>

@interface BooksHorizontalScrollView : UIScrollView
- (void) removeAllSubviews;
- (void) showActivityIndicator;
- (void) hideActivityIndicator;
- (void) showLoadingMoreActivityIndicator;
- (void) reinitializeAfterViewAnimation;
- (void) prependSubview:(UIView*)subview atIndex:(int)index;
@end
