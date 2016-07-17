//
//  RegisterViewController.h
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LandingViewController.h"

@interface RegisterViewController : UIViewController

@property (nonatomic) enum LoginForward loginForward;
@property (nonatomic, unsafe_unretained) id<LoginDelegate>delegate;

@end
