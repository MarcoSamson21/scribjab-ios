//
//  DrawingTool.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

@interface DrawingTool : NSObject
@property (nonatomic, strong) UIColor * color;
@property (nonatomic) float width;
@property (nonatomic) float alpha;

-(id) initWithColor:(UIColor*) color width:(float)width andAlpha:(float)alpha;
-(void) closePath:(UIBezierPath*)path atPoint:(CGPoint)endPoint;    // A place to finilize the path that is drawn by this tool
-(void) createPath:(UIBezierPath*)path fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;
-(void) drawPath:(UIBezierPath*)path withContext:(CGContextRef)context boundedBy:(CGRect)rect;
@end
