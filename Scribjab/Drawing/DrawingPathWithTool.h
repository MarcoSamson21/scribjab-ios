//
//  DrawingPathWithTool.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "DrawingTool.h"
#import "PenTool.h"
#import "BrushTool.h"

// Data type for storing bezier paths with associated line colors etc.
@interface DrawingPathWithTool: NSObject
@property (nonatomic, readonly) UIBezierPath * path;
@property (nonatomic, readonly) DrawingTool * tool;
-(id) initWithTool:(DrawingTool*) tool;
-(void) moveToPoint:(CGPoint)point;
-(void) addPointToPath:(CGPoint)point;
-(void) closePathAtPoint:(CGPoint)endPoint;    // A place to finilize the path that is drawn by this tool
-(void) drawPathWithContext:(CGContextRef)context boundedBy:(CGRect)rect;
@end
