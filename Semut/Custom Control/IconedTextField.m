//
//  IconedTextField.m
//  Skata
//
//  Created by Asep Mulyana on 4/1/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "IconedTextField.h"

@implementation IconedTextField{
    UIImageView *imgV;
}

@synthesize type = _type;

-(void)awakeFromNib{
    self.layer.masksToBounds = YES;
//    self.layer.borderColor = [UIColor grayColor].CGColor;
//    self.layer.borderWidth = 1.;
    self.layer.cornerRadius = 4.;
    self.backgroundColor = [UIColor whiteColor];
    
    CGRect f = self.bounds;
    f.origin.x = f.size.width - 10.;
    f.size.width = 10.;
    UIView *r = [[[UIView alloc] initWithFrame:f] autorelease];
    r.backgroundColor = [UIColor clearColor];
    self.rightView = r;
    self.rightViewMode = UITextFieldViewModeAlways;
    
    f.size.width = f.size.height + 5;
    f.origin.x = 0;
    UIView *l = [[[UIView alloc] initWithFrame:f] autorelease];
    l.backgroundColor = [UIColor clearColor];
    
    f.size.width = f.size.height;
    imgV = [[[UIImageView alloc] initWithFrame:CGRectInset(f, 5, 5)] autorelease];
    imgV.backgroundColor = [UIColor clearColor];
    imgV.contentMode = UIViewContentModeCenter;
    [l addSubview:imgV];
    
    self.leftView = l;
    self.leftViewMode = UITextFieldViewModeAlways;
    
    self.type = self.type;
    [self setValue:[UIColor grayColor] forKeyPath:@"_placeholderLabel.textColor"];
    
}

-(void)setType:(IconedTextFieldIconType)type{
    _type = type;
    NSLog(@"%@", NSStringFromCGRect(imgV.frame));
    switch (type) {
        case IconedTextFieldIconTypeEmail:
            imgV.image = [UIImage imageNamed:@"icon-email"];
            break;
        case IconedTextFieldIconTypePassword:
            imgV.image = [UIImage imageNamed:@"icon-password"];
            break;
        case IconedTextFieldIconTypeAccount:
            imgV.image = [UIImage imageNamed:@"icon-account"];
            break;
        case IconedTextFieldIconTypePhone:
            imgV.image = [UIImage imageNamed:@"icon-phone"];
            break;
        case IconedTextFieldIconTypeDate:
            imgV.image = [UIImage imageNamed:@"icon-calendar"];
            break;
            
        default:
            break;
    }
}

@end
