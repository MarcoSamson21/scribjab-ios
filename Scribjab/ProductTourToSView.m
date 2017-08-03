//
//  ProductTourToSView.m
//  Scribjab
//
//  Created by Oleg Titov on 12-07-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProductTourToSView.h"

@implementation ProductTourToSView

@synthesize ignoreRequestLoadRequests = _ignoreRequestLoadRequests;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


// Overridden method allows to load a request once in the life time of the view
// to save time.
-(void) loadRequest:(NSURLRequest *)request
{
    if (self.ignoreRequestLoadRequests)
        return;
    
    [super loadRequest:request];
    self.ignoreRequestLoadRequests = YES;
}

@end
