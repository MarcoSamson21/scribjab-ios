//
//  BookScrolleView.h
//  Scribjab
//
//  Created by Gladys Tang on 12-12-18.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"

@interface BookScrollView : UIScrollView
- (void) removeAllSubviews;
- (void) showActivityIndicator;
- (void) hideActivityIndicator;
- (void) reinitializeAfterViewAnimation;

- (void) removeSubviewWithBook:(Book *)book;
- (void) updateBookStatusInScrollViewWithRemoteId:(NSNumber *) remoteId;
//- (BOOL) isBookInScrollViewWithRemoteId:(NSNumber *) remoteId;
//- (void) removeSubviewWithTag:(int) tag;
@end
