//
//  PublishBookTermOfUseViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 13-02-28.
//
//

#import <UIKit/UIKit.h>
#import "ProductTourToSView.h"

@interface PublishBookTermOfUseViewController : UIViewController<UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet ProductTourToSView *webView;
- (IBAction)close:(id)sender;

@end
