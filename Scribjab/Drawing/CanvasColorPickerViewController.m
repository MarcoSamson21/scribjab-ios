//
//  CanvasColorPickerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-20.
//
//

#import "CanvasColorPickerViewController.h"

@interface CanvasColorPickerViewController ()

@end

@implementation CanvasColorPickerViewController
@synthesize delegate = _delegate;

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
     self.contentSizeForViewInPopover = CGSizeMake(800.0F, 300.0F);
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

// ======================================================================================================================================
- (IBAction)colorChanged:(id)sender
{
    UIColor * color = ((UIButton*)sender).backgroundColor;
    [self.delegate canvasToolColorChanged:self toColor:color];
}
@end
