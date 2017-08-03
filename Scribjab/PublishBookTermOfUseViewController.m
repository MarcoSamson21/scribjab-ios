//
//  PublishBookTermOfUseViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 13-02-28.
//
//

#import "PublishBookTermOfUseViewController.h"
//#import "ProductTourToSView.h"
#import "Utilities.h"
#import "Globals.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface PublishBookTermOfUseViewController () <UIWebViewDelegate>

@end

@implementation PublishBookTermOfUseViewController
@synthesize webView = _webView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.webView.delegate = self;
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_TERMS_OF_USE];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Terms of Use Popup in Publish Book Screen ", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)close:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

// **************************************************************************************************************************************

#pragma mark UIWebViewDelegate Method Implementations

// ====================================================================================================================================================
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
// ====================================================================================================================================================
-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
// ====================================================================================================================================================
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString * str = NSLocalizedString(@"<html><body><h1>Timeout Error</h1><p>Failed to load Terms of Use. Please make sure your iPad is connected to the network.</p></body></html>", @"Error message when failed to load Terms of Use web page in Project Tour section");
    
    self.webView.ignoreRequestLoadRequests = NO;
    [self.webView loadHTMLString:str baseURL:nil];
}
// ====================================================================================================================================================
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}
@end
