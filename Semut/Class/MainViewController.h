//
//  MainViewController.h
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuViewController;
@class MapFilterViewController;

@interface MainViewController : UIViewController

@property (nonatomic, retain) MenuViewController *menu;
@property (nonatomic, retain) MapFilterViewController *filter;

@end
