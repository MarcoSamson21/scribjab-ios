//
//  ProductTourToSView.h
//  Scribjab
//
//  Created by Oleg Titov on 12-07-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductTourToSView : UIWebView
@property (nonatomic) BOOL ignoreRequestLoadRequests;   // If set to YES, call to loadRequest method will be ignored 
@end
