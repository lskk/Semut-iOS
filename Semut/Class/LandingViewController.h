//
//  LandingViewController.h
//  Semut
//
//  Created by Asep Mulyana on 4/28/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginDelegate <NSObject>
-(void)loginSucceedWithForward:(enum LoginForward)forward;
@end

@interface LandingViewController : UIViewController

@property (nonatomic) enum LoginForward loginForward;
@property (nonatomic, unsafe_unretained) id<LoginDelegate>delegate;

@end
