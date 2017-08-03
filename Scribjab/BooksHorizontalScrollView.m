//
//  BooksHorizontalScrollView
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import "BooksHorizontalScrollView.h"
#import "BookThumbnailButton.h"

#define HORIZONTAL_SPACING 12.0
#define RIGHT_PADDING 70.0
#define Y_OFFSET 7

@interface BooksHorizontalScrollView()
{
    UIActivityIndicatorView * _activityIndicator;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation BooksHorizontalScrollView

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
-(void)removeAllSubviews
{
    for (UIView * view in self.subviews)
    {
        if ([view isKindOfClass:[BookThumbnailButton class]])
            [view removeFromSuperview];
    }
}

// ======================================================================================================================================
// Override addSubview to only accept BookViews
-(void)addSubview:(UIView *)view
{
 //   if (![view isKindOfClass:[BookThumbnailButton class]])
 //       return;
    [super addSubview:view];
}

// ======================================================================================================================================
// Add subview at specified index
- (void) prependSubview:(UIView*)subview atIndex:(int)index
{
    if (index < self.subviews.count)
    {
        [super insertSubview:subview atIndex:index];
    }
    else
    {
        [super addSubview:subview];
    }
}

// ======================================================================================================================================
// Layout all subviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.subviews count] == 0)
    {
        self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
        return;
    }
    
    int currentXOffset = HORIZONTAL_SPACING + 10;
        
    // Do the layout
    for (UIView * view in self.subviews)
    {
        if ([view isKindOfClass:[BookThumbnailButton class]])
        {
            view.frame = CGRectMake(currentXOffset, Y_OFFSET, view.bounds.size.width, view.bounds.size.height);
            currentXOffset += HORIZONTAL_SPACING + view.bounds.size.width;
        }
    }
    
    self.contentSize = CGSizeMake(currentXOffset + RIGHT_PADDING, self.bounds.size.height);
}

// ======================================================================================================================================
-(void)showActivityIndicator
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
-(void)hideActivityIndicator
{
    if (_activityIndicator != nil)
    {
        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
        _activityIndicator = nil;
    }
}

// ======================================================================================================================================
// add spinner to the end of the button list
- (void) showLoadingMoreActivityIndicator
{
//    if ([self.subviews count] == 0)
//    {
//        self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
//        return;
//    }
    
    // add spinner if needed
    if (_activityIndicator == nil)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.hidesWhenStopped = YES;
        [_activityIndicator setCenter:CGPointMake(self.contentSize.width - RIGHT_PADDING + HORIZONTAL_SPACING + _activityIndicator.bounds.size.width / 2.0, self.bounds.size.height / 2.0)];
        _activityIndicator.tag = 99;
        
        [super addSubview:_activityIndicator]; // spinner is not visible until started
    }
    
    self.contentSize = CGSizeMake(self.contentSize.width + HORIZONTAL_SPACING + _activityIndicator.bounds.size.width, self.bounds.size.height);
    
    [_activityIndicator startAnimating];
}


// ======================================================================================================================================
-(void)reinitializeAfterViewAnimation
{
    if ([_activityIndicator isAnimating])
    {
        [_activityIndicator stopAnimating];
        [_activityIndicator startAnimating];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
 
 
 
 UIActivityIndicatorView *   _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
 _activityIndicator.hidesWhenStopped = YES;
 [_activityIndicator setCenter:CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0)];
 [self.view addSubview:_activityIndicator]; // spinner is not visible until started
 
 
 [_activityIndicator startAnimating];
*/

@end
