//
//  EraserToolPropertiesPickerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-20.
//
//

#import "EraserToolPropertiesPickerViewController.h"

@interface EraserToolPropertiesPickerViewController ()
-(void) initializeControllers;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation EraserToolPropertiesPickerViewController

@synthesize delegate = _delegate;
@synthesize toolWidth = _toolWidth;

// ======================================================================================================================================
-(void)setToolWidth:(float)toolWidth
{
    _toolWidth = toolWidth;
    self.toolWidthSlider.value = _toolWidth;
    self.previewArea.width = _toolWidth;
}

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
	[self initializeControllers];
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

- (void)viewDidUnload {
    [self setPreviewArea:nil];
    [self setToolWidthSlider:nil];
    [super viewDidUnload];
}

-(void)initializeControllers
{
    self.previewArea.width = self.toolWidthSlider.value;
    self.previewArea.color = [UIColor colorWithRed:0.0F green:0.0F blue:0.0F alpha:1.0F];
    self.previewArea.showSoftEdges = NO;
    _toolWidth = self.toolWidthSlider.value;
    self.contentSizeForViewInPopover = CGSizeMake(500.0F, 100.0F);
}
- (IBAction)widthSliderChanged:(id)sender
{
    _toolWidth = self.toolWidthSlider.value;
    self.previewArea.width = _toolWidth;
    [self.delegate drawingToolWidthChanged:self toWidth:_toolWidth];
}
@end
