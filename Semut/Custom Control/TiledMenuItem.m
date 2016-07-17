//
//  TiledMenuItem.m
//  Skata
//
//  Created by Asep Mulyana on 4/6/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "TiledMenuItem.h"

@implementation TiledMenuItem{
    UILabel *lbl;
}

@synthesize icon, title, level = _level;

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self standardInit];
    }
    return self;
}

-(void)standardInit{
    self.frame = CGRectMake(0, 0, 80., 100.);
    [self setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 100-80, 0)];
    
    lbl = [[[UILabel alloc] initWithFrame:CGRectMake(0., 80, 80, 100-80)] autorelease];
    lbl.textColor = [UIColor blackColor];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.numberOfLines = 2;
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.font = [UIFont systemFontOfSize:10.];
    lbl.minimumScaleFactor = 0.5;
    lbl.adjustsFontSizeToFitWidth = YES;
    [self addSubview:lbl];
}

-(void)setTitle:(NSString *)newtitle{
    lbl.text = [newtitle uppercaseString];
}

-(NSString *)title{
    return lbl.text;
}

-(void)setIcon:(UIImage *)newicon{
    [self setImage:newicon forState:UIControlStateNormal];
}

-(UIImage *)icon{
    return [self imageForState:UIControlStateNormal];
}

-(NSInteger)level{
    return _level;
}

-(void)setLevel:(NSInteger)level{
    _level = level;
    
    [self setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"post-bg-%zd.png", level]] forState:UIControlStateNormal];
}

@end
