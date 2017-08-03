//
//  BookPreviewViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-10.
//
//

#import "BookPreviewViewController.h"
#import "Language+Utils.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import <QuartzCore/QuartzCore.h>

@interface BookPreviewViewController ()
{
    UITapGestureRecognizer * _tapRecognizer;
}
-(void) initializePreview;
-(void) handleDismissalTap:(id) sender;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation BookPreviewViewController

@synthesize book = _book;

// ======================================================================================================================================
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
	[self initializePreview];
}

- (void)viewDidUnload {
    [self setTitle1Lable:nil];
    [self setTitle2Lable:nil];
    [self setDescription1Label:nil];
    [self setDescription2Label:nil];
    [self setLanguagesLabel:nil];
    [self setTagsLabel:nil];
    [self setImageView:nil];
    [self setImageBorderView:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void)viewDidAppear:(BOOL)animated
{
    // dismiss preview on tap ouside the bounds
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissalTap:)];
    
    [_tapRecognizer setNumberOfTapsRequired:1];
    _tapRecognizer.cancelsTouchesInView = NO; // So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:_tapRecognizer];
}

// ======================================================================================================================================
-(void)initializePreview
{
    if (_book == nil)
        return;
    
    self.title1Lable.text = _book.title1;
    self.title2Lable.text = _book.title2;
    self.description1Label.text = _book.description1;
    self.description2Label.text = _book.description2;
    self.languagesLabel.text = [self.languagesLabel.text stringByAppendingFormat:@"%@ / %@", _book.primaryLanguage.name, _book.secondaryLanguage.name];
    self.tagsLabel.text = [self.tagsLabel.text stringByAppendingString:_book.tagSummary];
    
    
    UIImage * image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:_book fileName:BOOK_IMAGE_FILENAME]];
    self.imageView.image = image;
    self.imageView.backgroundColor = [UIColor colorWithHexString:_book.backgroundColorCode];
    
    self.imageView.layer.cornerRadius = 9.0;
    self.imageView.layer.masksToBounds = YES;
    self.imageBorderView.layer.cornerRadius = 9.0;
    self.imageBorderView.layer.masksToBounds = YES;
}

// ======================================================================================================================================
-(void)handleDismissalTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint locationOfTap = [sender locationInView:nil];    // passing nil gives coordinates in window
        locationOfTap = [self.view convertPoint:locationOfTap fromView:self.view.window];
        
        if (![self.view pointInside:locationOfTap withEvent:nil])
        {
            [self.view.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:^{}];
        }
    }
}

// ======================================================================================================================================
- (IBAction)download:(id)sender
{
    [self.view.window removeGestureRecognizer:_tapRecognizer]; 
    [self.delegate downloadRequestedForBook:_book];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

// ======================================================================================================================================
- (IBAction)closeView:(id)sender
{
    [self.view.window removeGestureRecognizer:_tapRecognizer];
    [self dismissViewControllerAnimated:YES completion:^{}];
}
@end
