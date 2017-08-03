//
//  BookScrolleView.m
//  Scribjab
//
//  Created by Gladys Tang on 12-12-18.
//
//

#import "BookScrollView.h"
#import "CellInBookScrollView.h"
 
@interface BookScrollView()
{
    UIActivityIndicatorView * _activityIndicator;
}
@end

@implementation BookScrollView

// ======================================================================================================================================
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
    }
    return self;
}

// ======================================================================================================================================
// remove all subviews
- (void) removeAllSubviews
{
    for (UIView * view in self.subviews)
    {
        if ([view isKindOfClass:[CellInBookScrollView class]])
            [view removeFromSuperview];
    }
}

// ======================================================================================================================================
// Override addSubview to only accept BookViews
- (void) addSubview:(UIView *)view
{
    if (![view isKindOfClass:[CellInBookScrollView class]])
        return;
    [super addSubview:view];
}

// ======================================================================================================================================
// Layout all subviews
- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.subviews count] == 0)
    {
        self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
        return;
    }
    
    int currentXOffset = 1;
    if(self.tag == 2)
    {
        currentXOffset = 30;
    }
    // Do the layout
    for (UIView * view in self.subviews)
    {
        if (![view isKindOfClass:[CellInBookScrollView class]])
            continue;
        view.frame = CGRectMake(currentXOffset,  0, view.bounds.size.width, view.bounds.size.height);
        currentXOffset +=  view.bounds.size.width;
    }
    self.contentSize = CGSizeMake(currentXOffset, self.bounds.size.height);
}

// ======================================================================================================================================
- (void) showActivityIndicator
{
    // add spinner if needed
    if (_activityIndicator == nil)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.hidesWhenStopped = YES;
        [_activityIndicator setCenter:CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0)];
        [super addSubview:_activityIndicator]; // spinner is not visible until started
    }
    
    [_activityIndicator startAnimating];
}
// ======================================================================================================================================
- (void) hideActivityIndicator
{
    if (_activityIndicator != nil)
    {
        [_activityIndicator stopAnimating];
    }
}

// ======================================================================================================================================
- (void) reinitializeAfterViewAnimation
{
    if ([_activityIndicator isAnimating])
    {
        [_activityIndicator stopAnimating];
        [_activityIndicator startAnimating];
    }
}

//update the button from download to read.
- (void) updateBookStatusInScrollViewWithRemoteId:(NSNumber *) remoteId
{
    for (UIView * view in self.subviews)
    {
        if ([view isKindOfClass:[CellInBookScrollView class]])
        {
            Book * book = [((CellInBookScrollView *)view) getCurrentBook];
            if([book.remoteId intValue] == [remoteId intValue])
            {
                [((CellInBookScrollView *)view) changeDownloadToReadButton];
            }
        }
    }
}

- (void) removeSubviewWithBook:(Book *)book
{
    int removeTag = -1;
    for(UIView *subview in [self subviews])
    {
        if ([subview isKindOfClass:[CellInBookScrollView class]])
        {
            if(removeTag == -1)
            {
                Book * currentBook = [((CellInBookScrollView *)subview) getCurrentBook];
                if(currentBook == book)
                {
                    removeTag = subview.tag;
                    [subview removeFromSuperview];
                }
            }
            else
            {
                if(subview.tag > removeTag)
                {
                    [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
                     ^{
                         subview.frame = CGRectMake(subview.frame.origin.x - subview.frame.size.width, subview.frame.origin.y, subview.frame.size.width,subview.frame.size.height);
                     } completion:^(BOOL finished){}];                    
                }
            }
        }
    }
}

//check if the book is the selected one.
//- (BOOL) isBookInScrollViewWithRemoteId:(NSNumber *) remoteId;
//{
//    for (UIView * view in self.subviews)
//    {
//        if ([view isKindOfClass:[CellInBookScrollView class]])
//        {
//            if(view.tag == [remoteId intValue])
//                return TRUE;
//
//            Book * book = [((CellInBookScrollView *)view) getCurrentBook];
//            NSLog(@"view book: %d", [book.remoteId intValue]);
//            if([book.remoteId intValue] == [remoteId intValue])
//                return TRUE;
//        }
//    }
//    return FALSE;
//}
//remove the subview with selected tag.
//- (void) removeSubviewWithTag:(int) tag
//{
//    for(UIView *subview in [self subviews])
//    {
//        if(subview.tag == tag)
//        {
//            [subview removeFromSuperview];
//        }
//        else if(subview.tag > tag)
//        {
//            [UIView beginAnimations:nil context:NULL];
//            [UIView setAnimationDuration:1.0];
//            subview.frame = CGRectMake(subview.frame.origin.x - subview.frame.size.width, subview.frame.origin.y, subview.frame.size.width,subview.frame.size.height);
//            [UIView commitAnimations];
//        }
//    }
//}
@end
