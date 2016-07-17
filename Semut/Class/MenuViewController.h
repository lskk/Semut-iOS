//
//  MenuViewController.h
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController

@property (nonatomic, unsafe_unretained) UINavigationController *navigationHandler;

-(void)prepareForAppear;
-(void)show;

@end
