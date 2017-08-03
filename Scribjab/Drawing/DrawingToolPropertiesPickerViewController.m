//
//  BrushToolPickerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-15.
//
//

#import "DrawingToolPropertiesPickerViewController.h"

@interface DrawingToolPropertiesPickerViewController ()
-(void) initializeControllers;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation DrawingToolPropertiesPickerViewController

@synthesize delegate = _delegate;
@synthesize toolWidth = _toolWidth;
//@synthesize toolHeight = _toolHeight;
@synthesize toolColor = _toolColor;
@synthesize savedColor = _savedColor;
@synthesize showSoftEdges = _showSoftEdges;
@synthesize maxWidth = _maxWidth;
@synthesize minWidth = _minWidth;

//int selectedTag;

-(void)setMaxWidth:(float)maxWidth
{
    self.widthSelectionSlider.maximumValue = maxWidth;
    if (_toolWidth > maxWidth)
        _toolWidth = maxWidth;
}

-(void)setMinWidth:(float)minWidth
{
    self.widthSelectionSlider.minimumValue = minWidth;
    if (_toolWidth < minWidth)
        _toolWidth = minWidth;
}

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

    [self initializeControllers];
  
}

-(void)getWidth {
    
    
    
    [self setWidthSelectionSlider:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setHueColorPicker:nil];
    [self setSaturationBrightnessColorPicker:nil];
    [self setSelectionPreview:nil];
    [self setWidthSelectionSlider:nil];
    [self setGreyColorPicker:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
// ======================================================================================================================================
-(void) setToolWidth:(float)width
{
    _toolWidth = width;
    self.widthSelectionSlider.value = width;
    self.selectionPreview.width = width;
}
// ======================================================================================================================================
//-(void) setToolHeight:(float)height
//{
//    _toolHeight = height;
//    self.heightSelectionSlider.value = height;
//    self.selectionPreview.height = height;
//}
// ======================================================================================================================================
-(void) setToolColor:(UIColor*) theColor
{
    UIColor *color = theColor;
    CGFloat hue, sat, br, alpha;
    BOOL b = [theColor getHue:&hue saturation:&sat brightness:&br alpha:&alpha];

    self.hueColorPicker.hueValue = hue;
    self.saturationBrightnessColorPicker.hueValue = hue;
    self.saturationBrightnessColorPicker.saturationValue = sat;
    self.saturationBrightnessColorPicker.brightnessValue = br;
    
    self.selectionPreview.color = color;
}

-(void) setSavedColor:(UIColor *)theColor
{
    self.savedBtn.backgroundColor = theColor;
}

// ===============  Get the color  ====================
// ======================================================================================================================================
// Set preview mode.
-(void)setShowSoftEdges:(BOOL)showSoftEdges
{
    _showSoftEdges = showSoftEdges;
    self.selectionPreview.showSoftEdges = showSoftEdges;
}
// ======================================================================================================================================
// Initialize color piker
-(void)initializeControllers
{
    _toolWidth = self.widthSelectionSlider.value;
    self.selectionPreview.width = self.widthSelectionSlider.value;
    
    self.selectionPreview.color = [UIColor colorWithHue:self.hueColorPicker.hueValue saturation:self.saturationBrightnessColorPicker.saturationValue brightness:self.saturationBrightnessColorPicker.brightnessValue alpha:1.0F];

    _toolColor = self.selectionPreview.color;
    self.contentSizeForViewInPopover = CGSizeMake(500.0F, 260.0F);
}

// ======================================================================================================================================
// Handle hue value change event
- (IBAction)hueValueChanged:(id)sender
{
    self.saturationBrightnessColorPicker.hueValue = self.hueColorPicker.hueValue;
    self.selectionPreview.color = [UIColor colorWithHue:self.hueColorPicker.hueValue saturation:self.saturationBrightnessColorPicker.saturationValue brightness:self.saturationBrightnessColorPicker.brightnessValue alpha:1.0F];
    [self.delegate drawingToolColorChanged:self toColor:self.selectionPreview.color];

}
// ======================================================================================================================================
- (IBAction)saturationBrightnessValueChanged:(id)sender
{
    self.selectionPreview.color = [UIColor colorWithHue:self.hueColorPicker.hueValue saturation:self.saturationBrightnessColorPicker.saturationValue brightness:self.saturationBrightnessColorPicker.brightnessValue alpha:1.0F];
 
    _toolColor = self.selectionPreview.color;
    [self.delegate drawingToolColorChanged:self toColor:self.selectionPreview.color];
}
// ======================================================================================================================================
- (IBAction)widthValueChanged:(id)sender
{
    self.selectionPreview.width = self.widthSelectionSlider.value;
    _toolWidth = self.widthSelectionSlider.value;
    [self.delegate drawingToolWidthChanged:self toWidth:self.widthSelectionSlider.value];
}

- (IBAction)greyValueChanged:(id)sender
{
    self.selectionPreview.color = [UIColor colorWithRed:self.greyColorPicker.greyValue green:self.greyColorPicker.greyValue blue:self.greyColorPicker.greyValue alpha:1.0F];
    
    _toolColor = self.selectionPreview.color;
    [self.delegate drawingToolColorChanged:self toColor:self.selectionPreview.color];
}

- (IBAction)saveBtnClick:(id)sender {    
    [self.delegate onClickSave];
}

- (IBAction)savedColorBtnClick:(id)sender {
    [self.delegate onClickSavedColorBtn:sender];
}
@end
