//
//  TaxiConfirmViewController.h
//  Semut
//
//  Created by Asep Mulyana on 5/19/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TaxiConfirmViewController;

@protocol TaxiConfirmViewControllerDelegate
-(void)confirmation:(TaxiConfirmViewController*)sender finishedWithConfirmation:(BOOL)confirm;
@end

@interface TaxiConfirmViewController : UIViewController

-(void)prepareAnimation;
-(void)show;

@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, unsafe_unretained) id<TaxiConfirmViewControllerDelegate>delegate;

@end
