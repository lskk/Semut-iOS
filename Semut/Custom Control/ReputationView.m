//
//  ReputationView.m
//  Semut
//
//  Created by Asep Mulyana on 5/15/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "ReputationView.h"

#define kReputationLimit        800

@implementation ReputationView

@synthesize reputation;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self standardInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self standardInit];
    }
    return self;
}

-(void)standardInit{
    for (int i=0; i< (kReputationLimit / 100); i++) {
        CGRect r = CGRectMake(0, 0, 2./3.*self.frame.size.height, self.frame.size.height);
        r.origin.x = i* (r.size.width + 2.);
        
        UIView *v = [[UIView alloc] initWithFrame:r];
        v.tag = -1;
        v.layer.masksToBounds = YES;
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.;
        v.layer.cornerRadius = v.frame.size.width * 0.2;
        v.backgroundColor = [UIColor blackColor];
        [self addSubview:v];
        
        UIView *s = [[UIView alloc] initWithFrame:v.bounds];
        s.tag = i+10;
        [v addSubview:s];
        
        [v release];
        [s release];
    }
}

-(void)updateView{
    NSInteger rep = abs(reputation);
    
    for (int i=0; i< (kReputationLimit / 100); i++) {
        UIView *v = [self viewWithTag:i+10];
        
        if(rep > 0){
            v.hidden = NO;
            
            CGRect f = v.frame;
            f.size.height = self.frame.size.height * MIN(100., rep) / 100.;
            f.origin.y = self.frame.size.height - f.size.height;
            v.frame = f;
            
            v.backgroundColor = reputation<0?[UIColor redColor]:[UIColor greenColor];
            
            rep -= 100;
        }else{
            v.hidden = YES;
        }
    }
}

-(void)setReputation:(NSInteger)_reputation{
    reputation = MIN(kReputationLimit, _reputation);
    
    [self updateView];
}

@end
