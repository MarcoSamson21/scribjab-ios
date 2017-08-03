//
//  ProductTourViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Foundation/Foundation.h"
#import "ProductTourViewController.h"
#import "NavigationManager.h"
#import "Utilities.h"
#import "Globals.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"


#define VIEW_X 308
#define VIEW_Y 20
#define VIEW_WIDTH 696
#define VIEW_HEIGHT 708


// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************


@interface ProductTourViewController () <UIWebViewDelegate>
{
//    NSArray * m_tourViews;      // Preload tour views here
//    ProductTourAboutView * m_aboutView;
//    ProductTourToSView * m_termsView;
//    ProductTourDemoView * m_demoView;
//    UIView * m_currentView;     // View that is currently displayed
}

-(void)loadTourSubViewsFromNib;
-(void)visibleViewDidChangeFromView:(UIView*) fromView toView:(UIView*)toView;
-(void)selectButtonExclusively:(UIButton*) button;
//@property (nonatomic, strong) MPMoviePlayerController * moviePlayer;  // Movie Player Controller

@end



// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************




@implementation ProductTourViewController

//@synthesize moviePlayer = _moviePlayer;

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
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [self setTourButton:nil];
    [self setAboutButton:nil];
    [self setTeacherButton:nil];
    [self setTermsButton:nil];
    [self setCreditsButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
-(void)viewDidAppear:(BOOL)animated
{
    [self showDemoVideoView:nil];
    [self selectButtonExclusively:self.tourButton];
}

// ============================================================================================================================================================
// Close the tour view and return to where this view was called from
- (IBAction)exitTour:(id)sender 
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.webView loadHTMLString:nil baseURL:nil];  // unload last web page (to stop video playback)
    [NavigationManager navigateToHomeAnimatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
}

// ============================================================================================================================================================
// Show project info View
- (IBAction)showProjectInfoView:(id)sender 
{
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_ABOUT];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self selectButtonExclusively:sender];
    
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Product Tour (About Page) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    /*
    [self loadTourSubViewsFromNib];
    if (m_currentView == m_aboutView) return;        // Already in this view?
    [m_currentView removeFromSuperview];
    [self.view addSubview:m_aboutView];
    
    [self visibleViewDidChangeFromView:m_currentView toView:m_aboutView];
    m_currentView = m_aboutView; 
     */
}

// ============================================================================================================================================================
// Show Demo Video View
- (IBAction)showDemoVideoView:(id)sender 
{
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_TOUR];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self selectButtonExclusively:sender];
    
    
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Product Tour (Demo Page) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    /*
    [self loadTourSubViewsFromNib];
    if (m_currentView == m_demoView) return;        // Already in this view?
    [m_currentView removeFromSuperview];
    [self.view addSubview:m_demoView];
    
    [self visibleViewDidChangeFromView:m_currentView toView:m_demoView];
    m_currentView = m_demoView;
    
    // If player has been loaded already, but the view is hidden - don't reload the player again.
    if (m_demoView.playerLoaded)
        return;
    
    NSURL * url = [NSURL URLWithString:NSLocalizedString(@"http://www.w3schools.com/html5/movie.mp4", @"Demo Video in Project Tour section")]; //[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Arrays" ofType:@"m4v"]];
    
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    self.moviePlayer.controlStyle = MPMovieControlStyleDefault;
    self.moviePlayer.shouldAutoplay = NO;
    
    [[self.moviePlayer view] setFrame:CGRectMake(150, 150, 300, 300)];
    
    [m_demoView addSubview:self.moviePlayer.view];
    
    //[self.moviePlayer setFullscreen:YES animated:YES];
    
    m_demoView.playerLoaded = YES;
     */
}

// ====================================================================================================================================================
// Show ToS View
- (IBAction)showTermsOfUseView:(id)sender 
{
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_TERMS_OF_USE];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self selectButtonExclusively:sender];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Product Tour (Terms Page) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    
    /*
    [self loadTourSubViewsFromNib];
    if (m_currentView == m_termsView) return;        // Already in this view?
    [m_currentView removeFromSuperview];
    [self.view addSubview:m_termsView];
    
    [self visibleViewDidChangeFromView:m_currentView toView:m_termsView];
    m_currentView = m_termsView;
    
    //"http://maps.google.com/help/terms_maps.html";
    
    NSString * url = URL
    [m_termsView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:NSLocalizedString(@"http://maps.google.com/help/terms_maps.html", @"URL of Terms of Service page for Project Tour section")]]];
     */
}
// ====================================================================================================================================================
// Show Teacher's Info
- (IBAction)showTeacherInfo:(id)sender
{
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_TEACHER];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self selectButtonExclusively:sender];
    
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Product Tour (Teachers and Parents Info Page) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

// ====================================================================================================================================================
- (IBAction)showCreditsPage:(id)sender
{
    NSString * url = [URL_SERVER_BASE_WEB_URL stringByAppendingString:URL_ABOUT_CREDITS];
    url = [@"" stringByAppendingFormat:url, [Utilities locale]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self selectButtonExclusively:sender];
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Product Tour (Credits Page) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}


// ====================================================================================================================================================
// Show project info View
-(void)loadTourSubViewsFromNib
{
    
//    if (m_tourViews != nil) return;
//    
//    m_tourViews = [[NSBundle mainBundle] loadNibNamed:@"ProductTourViews" owner:self options:nil];
//    
//    for (UIView * view in m_tourViews) 
//    {
//        view.frame = CGRectMake(VIEW_X, VIEW_Y, VIEW_WIDTH, VIEW_HEIGHT);
//        
//        if ([view isKindOfClass:[ProductTourAboutView class]])
//            m_aboutView = (ProductTourAboutView*) view;
//        if ([view isKindOfClass:[ProductTourToSView class]]) 
//        {
//            m_termsView = (ProductTourToSView*) view;
//            m_termsView.delegate = self;
//        }
//        if ([view isKindOfClass:[ProductTourDemoView class]])
//            m_demoView = (ProductTourDemoView*) view;
//    }
}

//// ====================================================================================================================================================
//// Notification that a visible Subview has changed.
//-(void)visibleViewDidChangeFromView:(UIView*) fromView toView:(UIView*)toView
//{
//    if (fromView == m_demoView)
//    {
//        [self.moviePlayer pause]; // pause demo video playback 
//    }
//}

// ====================================================================================================================================================
// Un-highlights all buttons but the pesified one
-(void)selectButtonExclusively:(UIButton*) button
{
    [self.tourButton setSelected:NO];
    [self.aboutButton setSelected:NO];
    [self.teacherButton setSelected:NO];
    [self.termsButton setSelected:NO];
    [self.creditsButton setSelected:NO];
    [button setSelected:YES];
}

// **************************************************************************************************************************************
// **************************************************************************************************************************************
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
    
//    m_termsView.ignoreRequestLoadRequests = NO;
//    [m_termsView loadHTMLString:str baseURL:nil];
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
