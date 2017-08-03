//
//  SearchCollectionScrollView.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-09.
//
//

#import "SearchCollectionScrollView.h"
#import "BookThumbnailButton.h"

#define HORIZONTAL_SPACING 12.0
#define VERTICAL_SPACING 30.0

@interface SearchCollectionScrollView()
{
    UIActivityIndicatorView * _activityIndicator;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************


@implementation SearchCollectionScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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
    [super addSubview:view];
}

// ======================================================================================================================================
// Layout all subviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL isEmpty = YES;
    
    int currentXOffset = 1;
    int currentYOffset = 1;
    int currentContentHeight = self.bounds.size.height;
    
    // Do the layout
    for (UIView * view in self.subviews)
    {
        if (![view isKindOfClass:[BookThumbnailButton class]])
            continue;
        
        view.frame = CGRectMake(currentXOffset, currentYOffset, view.bounds.size.width, view.bounds.size.height);
        currentXOffset += HORIZONTAL_SPACING + view.bounds.size.width;
        
        if (currentXOffset + view.bounds.size.width >= self.bounds.size.width)
        {
            currentXOffset = 1;
            currentYOffset += VERTICAL_SPACING + view.bounds.size.height;
            currentContentHeight = currentYOffset + VERTICAL_SPACING + view.bounds.size.height;
            
            if (_activityIndicator != nil)
            {
                currentContentHeight += _activityIndicator.bounds.size.height + VERTICAL_SPACING;
            }
        }
        
        isEmpty = NO;
    }
    
    if (isEmpty)
    {
        self.contentSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
        [_activityIndicator setCenter:CGPointMake(self.contentSize.width / 2.0, self.contentSize.height / 2)];
        return;
    }
    
    self.contentSize = CGSizeMake(self.bounds.size.width, currentContentHeight);
}

// ======================================================================================================================================
-(void)showActivityIndicator
{
    // add spinner if needed
    if (_activityIndicator == nil)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.hidesWhenStopped = YES;
        [_activityIndicator setCenter:CGPointMake(self.bounds.size.width / 2.0, VERTICAL_SPACING + self.bounds.size.height / 2.0)];
        [super addSubview:_activityIndicator]; // spinner is not visible until started
        return;
    }
    
    BOOL isEmpty = YES;
    
    for (UIView * view in self.subviews)
    {
        if ([view isKindOfClass:[BookThumbnailButton class]])
        {
            isEmpty = NO;
            break;
        }
    }
    
    if (!isEmpty)
        [_activityIndicator setCenter:CGPointMake(self.contentSize.width / 2.0, self.contentSize.height - _activityIndicator.bounds.size.height)];
    
    [_activityIndicator startAnimating];
}
// ======================================================================================================================================
-(void)hideActivityIndicator
{
    if (_activityIndicator != nil)
    {
        [_activityIndicator stopAnimating];
    }
}

// ======================================================================================================================================
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
