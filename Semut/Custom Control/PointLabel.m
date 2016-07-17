//
//  PointLabel.m
//  Semut
//
//  Created by Asep Mulyana on 5/15/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "PointLabel.h"

@implementation PointLabel

@synthesize point;

-(void)awakeFromNib{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = .2 * self.frame.size.height;
}

-(void)setPoint:(NSInteger)npoint{
    point = npoint;
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setMinimumFractionDigits:0];
    [f setMaximumFractionDigits:0];
    
    self.text = [f stringFromNumber:[NSNumber numberWithInteger:point]];
    [f release];
    
    CGRect frame = self.frame;
    
    [self sizeToFit];
    frame.size.width = self.frame.size.width + 6;
    
    self.frame = frame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
