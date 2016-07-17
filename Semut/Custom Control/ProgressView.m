//
//  ProgressView.m
//  Semut
//
//  Created by Asep Mulyana on 5/16/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

@synthesize progress = _progress;

-(void)awakeFromNib{
    self.backgroundColor = [UIColor clearColor];
    self.progress = 1.;
}

-(void)setProgress:(CGFloat)progress{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGRect allRect = self.bounds;
    CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw background
    CGContextSetRGBStrokeColor(context, 1.0f-self.progress, self.progress, 0.0f, 1.f); // white
    CGContextSetLineWidth(context, 1.f);
    CGContextStrokeEllipseInRect(context, circleRect);
    CGContextStrokeEllipseInRect(context, CGRectInset(circleRect, 30., 30.));
    // Draw progress
    CGPoint center = CGPointMake(allRect.size.width / 2, allRect.size.height / 2);
    CGFloat radius = (allRect.size.width - 4) / 2;
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
    
    CGContextSetRGBFillColor(context, 1.0f-self.progress, self.progress, 0.0f, .3f); // white
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, endAngle, (M_PI * 1.5), 0);
    CGContextClosePath(context);
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius-30, endAngle, (M_PI * 1.5), 0);
    CGContextClosePath(context);
    CGContextEOFillPath(context);
    
    CGContextSetRGBFillColor(context, 1.0f-self.progress, self.progress, 0.0f, 1.f); // white
    CGContextMoveToPoint(context, center.x, center.y);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextAddArc(context, center.x, center.y, radius-30, startAngle, endAngle, 0);
    CGContextClosePath(context);
    CGContextEOFillPath(context);
}

@end
