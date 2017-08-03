//
//  CGPointUtils.h
//  Scribjab
//
//  Created by Oleg Titov on 13-02-06.
//
//

#ifndef Scribjab_CGPointUtils_h
#define Scribjab_CGPointUtils_h

// Calculate a point between specified points
static inline CGPoint spuMidPoint(const CGPoint p1, const CGPoint p2)
{
    return CGPointMake((p1.x + p2.x) * 0.5f, (p1.y + p2.y) * 0.5f);
}

// Distance between two points
static inline float spuDistanceBetweenPoints(const CGPoint startPoint, const CGPoint endPoint)
{
    float dx = endPoint.x - startPoint.x;
    float dy = endPoint.y - startPoint.y;
    return sqrtf(powf(dx, 2.0F) + powf(dy, 2.0F));
}

// angle between two points in radians
static inline float spuAngleBetweenPointsInRadians(const CGPoint startPoint, const CGPoint endPoint)
{
    float dx = endPoint.x - startPoint.x;
    float dy = endPoint.y - startPoint.y;
    return atan2f(dy, dx);
}

// Calculate difference of two points.
static inline CGPoint spuSubtractPoints(const CGPoint p1, const CGPoint p2)
{
	return CGPointMake(p1.x - p2.x, p1.y - p2.y);
}
// Calculates sum of two points.
static inline CGPoint spuAddPoints(const CGPoint v1, const CGPoint v2)
{
	return CGPointMake(v1.x + v2.x, v1.y + v2.y);
}
// Returns point multiplied by given factor.
static inline CGPoint spuMultiplyPoint(const CGPoint v, const CGFloat s)
{
	return CGPointMake(v.x*s, v.y*s);
}

// Calculates dot product of two points.
static inline CGFloat spuDotProduct(const CGPoint v1, const CGPoint v2)
{
	return v1.x*v2.x + v1.y*v2.y;
}

// Calculates the square length of a CGPoint (not calling sqrt())
static inline CGFloat spuSquareLengthOfPoint(const CGPoint v)
{
	return spuDotProduct(v, v);
}

static inline CGFloat spuLengthOfPoint(const CGPoint v)
{
	return sqrtf(spuSquareLengthOfPoint(v));
}

static inline CGPoint spuNormalizeVector(const CGPoint v)
{
	return spuMultiplyPoint(v, 1.0f/spuLengthOfPoint(v));
}

// Calculate perpendicular of vector, rotated 90 degrees counter-clockwise -- cross(v, perp(v)) >= 0
static inline CGPoint spuPerpendicularVector(const CGPoint point)
{
	return CGPointMake(-point.y, point.x);
}

// calculate if points are equal to a specified precision. e.g. 0.001f
static BOOL spuFuzzyEqualPoints(CGPoint a, CGPoint b, float var)
{
	if(a.x - var <= b.x && b.x <= a.x + var)
		if(a.y - var <= b.y && b.y <= a.y + var)
			return true;
	return false;
}


#endif
