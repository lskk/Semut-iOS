//
//  AppDelegate.m
//  Semut
//
//  Created by Asep Mulyana on 4/28/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "AppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "LandingViewController.h"
#import "MainViewController.h"
#import "ASIHTTPRequest+Semut.h"
#import "SMDatabase.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize landingViewController, mainViewController;

- (void)dealloc
{
    [landingViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    
    [SMDatabase initiate];
    [FBLoginView class];
    
    self.window.rootViewController = self.mainViewController;
        
    [self.window makeKeyAndVisible];
    
    if([AppConfig sharedConfig].sessionID.integerValue < 1){
        [self.mainViewController presentViewController:self.landingViewController animated:YES completion:nil];
    }
        
    [FBAppEvents activateApp];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Implementasi facebook sdk
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

#pragma mark -
+(AppDelegate *)currentDelegate{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - Actions
-(void)sendPushToken{
    if([AppConfig sharedConfig].sessionID.length > 0 && [AppConfig sharedConfig].sessionID.intValue > 0){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLSetPushToken]];
        [request setCompletionBlock:^{
            NSLog(@"\n\nRegPush: %@\n\n", request.responseString);
        }];
        [request setPostValue:@"2" forKey:@"DeviceType"];
        [request setPostValue:[AppConfig sharedConfig].pushToken forKey:@"PushID"];
        [request startAsynchronous];
    }
}

#pragma mark - Custom Property
-(UINavigationController *)landingViewController{
    if(!landingViewController){
        LandingViewController *landing = [[LandingViewController alloc] initWithNibName:@"LandingViewController" bundle:nil];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:landing];
        nav.navigationBarHidden = YES;
        self.landingViewController = nav;
        [nav release];
        [landing release];
    }
    
    return landingViewController;
}

-(UINavigationController *)mainViewController{
    if(!mainViewController){
        MainViewController *main = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:main];
        nav.navigationBarHidden = YES;
        self.mainViewController = nav;
        [nav release];
        [main release];
    }
    
    return mainViewController;
}

#pragma mark - push handling
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    NSString *token = [NSString stringWithFormat:@"%@", deviceToken];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    [AppConfig sharedConfig].pushToken = token;
    
    [self sendPushToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"error register %@", error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
//    NSLog(@"notif dari server %@", userInfo);
//    
//    NSInteger badgeNum = [[userInfo valueForKeyPath:@"aps.badge"] integerValue];
//    
//    if(willHandleNotif){
//        UINavigationController *root = (UINavigationController *)[AppDelegate currentDelegate].mainViewController.centerController;
//        
//        NSString *pagetype = [userInfo valueForKeyPath:@"pagetype"];
//        if([pagetype isEqualToString:@"P01"]){
//            NSString *refID = [[userInfo valueForKey:@"urldetail"] lastPathComponent];
//            
//            [root popToRootViewControllerAnimated:NO];
//            
//            ReviewViewController *review = [[ReviewViewController alloc] initWithNibName:@"ReviewViewController" bundle:nil];
//            review.restoID = refID;
//            [root pushViewController:review animated:NO];
//            [review release];
//            
//            badgeNum--;
//        }else if([pagetype isEqualToString:@"P02"]){
//            NSString *refID = [[userInfo valueForKey:@"urldetail"] lastPathComponent];
//            
//            [root popToRootViewControllerAnimated:NO];
//            ResepDetailViewController *review = [[ResepDetailViewController alloc] initWithNibName:@"ResepDetailViewController" bundle:nil];
//            review.resepID = refID;
//            [root pushViewController:review animated:NO];
//            [review release];
//            
//            badgeNum--;
//        }else if([pagetype isEqualToString:@"P03"]){
//            [root popToRootViewControllerAnimated:NO];
//            ProfileViewController *review = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
//            [root pushViewController:review animated:NO];
//            [review release];
//            
//            badgeNum--;
//        }
//    }
//    
//    badgeNum = MAX(0, badgeNum);
//    [[NSNotificationCenter defaultCenter] postNotificationName:BangoPushNotifArrivedNotification object:[NSNumber numberWithInteger:badgeNum]];
//    [UIApplication sharedApplication].applicationIconBadgeNumber = badgeNum;
}

-(void)clearNotification{
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
//    [[UIApplication sharedApplication] cancelAllLocalNotifications];
//    
//    ASIFormDataRequest *request = [ASIFormDataRequest requestWithBangoURL:[NSURL URLWithString:kURLPushReset]];
//    [request setCompletionBlock:^{
//        NSLog(@"\n\nRegPush: %@\n\n", request.responseString);
//        [[NSNotificationCenter defaultCenter] postNotificationName:BangoPushNotifResettedNotification object:nil];
//    }];
//    [request setPostValue:kPushAppToken forKey:@"apptoken"];
//    [request setPostValue:[AppConfig sharedConfig].userID forKey:@"alias"];
//    [request setPostValue:[AppConfig sharedConfig].pushToken forKey:@"devid"];
//    [self.queue addOperation:request];
}

@end
