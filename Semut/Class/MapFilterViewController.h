//
//  MapFilterViewController.h
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapFilterViewController : UIViewController

-(void)prepareForAppear;
-(void)show;

@property (nonatomic) NSInteger filterValue;

@end
