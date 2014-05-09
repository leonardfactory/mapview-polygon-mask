//
//  LFViewController.m
//  MapViewPolygonMask
//
//  Copyright (c) 2014 Leonardo Ascione (https://github.com/leonardfactory)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "LFMapViewController.h"
#import <MapKit/MapKit.h>

@interface LFMapViewController () <MKMapViewDelegate>
{
    CLLocationCoordinate2D mapCenter;
}

@property (weak, nonatomic) IBOutlet MKMapView *mainMapView;
@property (weak, nonatomic) IBOutlet MKMapView *backgroundMapView;

@end

@implementation LFMapViewController

static const CGFloat kLFDefaultSpanMeters = 2000;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Randomizer
    srand48(time(0));
    
    /**
     *  Setting map visible region
     */
    mapCenter = CLLocationCoordinate2DMake(37.774929, -122.419416);
    [self.mainMapView setRegion:MKCoordinateRegionMakeWithDistance(mapCenter, kLFDefaultSpanMeters, kLFDefaultSpanMeters)];
    
    // Here we are simply setting the background mapView to be a zoomed map, but you
    // can handle it to satisfy your needs.
    [self.backgroundMapView setRegion:MKCoordinateRegionMakeWithDistance(mapCenter, kLFDefaultSpanMeters/2.0, kLFDefaultSpanMeters/2.0)];
    
    /**
     *  Create a random polygon to be shown.
     *  Ignore this if you just have your polygon.
     */
    MKPolygon *polygon = [self randomPolygon];
    
    /**
     *  Add the polygon to the map if you need
     */
    //[self.mainMapView addOverlay:polygon];
    
    /**
     *  Create a mask from MKPolygon.
     *
     *  To do this we need a CGPath to be used as layer mask, so we are going
     *  to generate it using MKPolygon points, converting these in CGPoint
     *  (from MKMapPoint) thanks to MKMapView method `convertCoordinate:toPointInView:`
     */
    
    // Create a CAShapeLayer to hold masking path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    CGMutablePathRef mask   = CGPathCreateMutable();

    // First point...
    CGPoint firstPoint      = [self convertPointToMapView:polygon.points[0]];
    CGPathMoveToPoint(mask, NULL, firstPoint.x, firstPoint.y);
    
    // Then with some simple CG functions we can draw all the mask
    for(NSUInteger i = 0; i < polygon.pointCount - 1; i++)
    {
        CGPoint nextPoint   = [self convertPointToMapView:polygon.points[i+1]];
        CGPathAddLineToPoint(mask, NULL, nextPoint.x, nextPoint.y);
    }
    
    // Close path
    CGPathCloseSubpath(mask);
    
    maskLayer.path  = mask;
    CGPathRelease(mask);
    
    /**
     *  Mask the second mapView.
     */
    self.backgroundMapView.layer.mask           = maskLayer;
}

/**
 *  Convert between MKMapPoint and CGPoint, to be used as masking path point.
 *
 *  @param point The MKMapPoint to be converted
 *
 *  @return The CGPoint, converted in UIView coords from MKMapPoint provided
 */
- (CGPoint) convertPointToMapView:(MKMapPoint) point
{
    return [self.mainMapView convertCoordinate:MKCoordinateForMapPoint(point) toPointToView:self.mainMapView];
}

/**
 *  Creates a random polygon, having between 3 and 7 sides.
 *
 *  @return A random MKPolygon
 */
- (MKPolygon *) randomPolygon
{
    // C-Array to store coordinates.
    NSUInteger pointsCount         = arc4random_uniform(4) + 5;// At least a triangle.
    CLLocationCoordinate2D *points = malloc(sizeof(CLLocationCoordinate2D) * pointsCount);
    
    for(NSUInteger i = 0; i < pointsCount; i++)
    {
        // In degrees. since drand48() provides a double between 0 and 1, dividing by 40 provides a reasonable radius for this example.
        double distanceFromCenter  = drand48()/90.0;
        
        // Angle (in radians) to draw these points "ordered" counter-clockwise
        double pointDirectionAngle = ((2 * M_PI)/((double) pointsCount) ) * (double)i;
        
        points[i] = CLLocationCoordinate2DMake(mapCenter.latitude  + cos(pointDirectionAngle) * distanceFromCenter,
                                               mapCenter.longitude + sin(pointDirectionAngle) * distanceFromCenter);
    }
    
    MKPolygon *polygon  = [MKPolygon polygonWithCoordinates:points count:pointsCount];
    
    return polygon;
}

@end
