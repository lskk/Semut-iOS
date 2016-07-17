//
//  AppDelegate.h
//  Semut
//
//  Created by Asep Mulyana on 4/28/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+(AppDelegate *)currentDelegate;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) UINavigationController *landingViewController;
@property (nonatomic, retain) UINavigationController *mainViewController;

-(void)sendPushToken;

@end

