//
//  ProductTourViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProductTourViewController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIButton *tourButton;
@property (strong, nonatomic) IBOutlet UIButton *aboutButton;
@property (strong, nonatomic) IBOutlet UIButton *teacherButton;
@property (strong, nonatomic) IBOutlet UIButton *termsButton;
@property (strong, nonatomic) IBOutlet UIButton *creditsButton;
- (IBAction)exitTour:(id)sender;
- (IBAction)showProjectInfoView:(id)sender;
- (IBAction)showDemoVideoView:(id)sender;
- (IBAction)showTermsOfUseView:(id)sender;
- (IBAction)showTeacherInfo:(id)sender;
- (IBAction)showCreditsPage:(id)sender;
@end
