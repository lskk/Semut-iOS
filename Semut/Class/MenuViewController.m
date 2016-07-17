//
//  MenuViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "MenuViewController.h"
#import "Tools.h"
#import "AppDelegate.h"
#import "NotificationViewController.h"
#import "FriendsViewController.h"
#import "CCTVViewController.h"
#import "LandingViewController.h"
#import "PublicTransportViewController.h"

@interface MenuViewController ()<UIAlertViewDelegate, LoginDelegate>{
    IBOutlet UIView *bg;
    IBOutlet UIView *container;
    IBOutlet UILabel *headerLabel;
    IBOutlet UIButton *loginButton;
}

-(IBAction)hide:(id)sender;
-(IBAction)menuSelect:(id)sender;

@end

@implementation MenuViewController

@synthesize navigationHandler;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStateUpdated) name:SemutLoginStateUpdateNotification object:nil];
    
    container.layer.masksToBounds = YES;
    container.layer.cornerRadius = 5.;
    headerLabel.layer.masksToBounds = YES;
    headerLabel.layer.cornerRadius = 5.;
    
    for(int i=1; i<=5; i++){
        UIButton *v = (UIButton *)[container viewWithTag:i];
        [v setBackgroundImage:[Tools solidImageForColor:v.backgroundColor withSize:v.frame.size] forState:UIControlStateNormal];
    }
    
    [loginButton setTitle:([AppConfig sharedConfig].sessionID.integerValue >1 ?@"Logout" : @"Login") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
-(void)prepareForAppear{
    headerLabel.alpha = 0.;
    headerLabel.transform = CGAffineTransformMakeTranslation(0, headerLabel.frame.size.height);
    bg.alpha = 0.;
    for(int i=1; i<=5; i++){
        UIView *v = [container viewWithTag:i];
        v.transform = CGAffineTransformMakeTranslation(-v.frame.size.width, 0);
    }
}

-(void)show{
    [UIView animateWithDuration:.5 animations:^{
        bg.alpha = 1.;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.3 animations:^{
            headerLabel.alpha = 1;
            headerLabel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    for(int i=1; i<=5; i++){
        UIView *v = [container viewWithTag:i];
        
        [UIView animateWithDuration:0.25 delay:i*0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
            v.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
}

-(void)hide:(id)sender{
    [UIView animateWithDuration:.7 animations:^{
        bg.alpha = 0.;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
    
    [UIView animateWithDuration:.25 animations:^{
        headerLabel.alpha = 0.;
        headerLabel.transform = CGAffineTransformMakeTranslation(0, headerLabel.frame.size.height);
    } completion:^(BOOL finished) {
        for(int i=1; i<=5; i++){
            UIView *v = [container viewWithTag:i];
            
            [UIView animateWithDuration:0.25 delay:i*0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                v.transform = CGAffineTransformMakeTranslation(-v.frame.size.width, 0);
            } completion:^(BOOL finished) {
                
            }];
        }
    }];
}

-(void)showLoginWithForward:(enum LoginForward)forward{
    [[AppDelegate currentDelegate].landingViewController popToRootViewControllerAnimated:NO];
    LandingViewController *landing = [[[AppDelegate currentDelegate].landingViewController viewControllers] objectAtIndex:0];
    landing.loginForward = forward;
    landing.delegate = self;
    
    [[AppDelegate currentDelegate].mainViewController presentViewController:[AppDelegate currentDelegate].landingViewController animated:YES completion:nil];
}

-(void)menuSelect:(UIButton *)sender{
    switch (sender.tag) {
        case 1:{
            [self hide:nil];
            if([AppConfig sharedConfig].sessionID.integerValue < 1){
                [self showLoginWithForward:LoginForwardNotification];
                return;
            }
            
            NotificationViewController *notif = [[NotificationViewController alloc] initWithNibName:@"NotificationViewController" bundle:nil];
            [self.navigationHandler pushViewController:notif animated:YES];
            [notif release];
        }
            break;
        case 2:{
            [self hide:nil];
            if([AppConfig sharedConfig].sessionID.integerValue < 1){
                [self showLoginWithForward:LoginForwardFriends];
                return;
            }
            
            FriendsViewController *friend = [[FriendsViewController alloc] initWithNibName:@"FriendsViewController" bundle:nil];
            [self.navigationHandler pushViewController:friend animated:YES];
            [friend release];
        }
            break;
        case 3:{
            [self hide:nil];
            CCTVViewController *cctv = [[CCTVViewController alloc] initWithNibName:@"CCTVViewController" bundle:nil];
            [self.navigationHandler pushViewController:cctv animated:YES];
            [cctv release];
        }
            break;
        case 4:{
            [self hide:nil];
            PublicTransportViewController *pt = [[PublicTransportViewController alloc] initWithNibName:@"PublicTransportViewController" bundle:nil];
            [self.navigationHandler pushViewController:pt animated:YES];
            [pt release];
        }
            break;
        case 5:{
            if([AppConfig sharedConfig].sessionID.integerValue < 1){
                [self showLoginWithForward:LoginForwardNone];
                return;
            }
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout?" message:@"Are you sure to logout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Logout", nil];
            [alert show];
        }
            break;
            
        default:
            break;
    }
}

-(void)loginStateUpdated{
    [loginButton setTitle:([AppConfig sharedConfig].sessionID.integerValue >1 ?@"Logout" : @"Login") forState:UIControlStateNormal];
}

#pragma mark - alertView
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [self hide:nil];
        [AppConfig sharedConfig].sessionID = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
    }
    [alertView release];
}

#pragma mark - delegate login
-(void)loginSucceedWithForward:(enum LoginForward)forward{
    if(forward == LoginForwardNotification){
        NotificationViewController *notif = [[NotificationViewController alloc] initWithNibName:@"NotificationViewController" bundle:nil];
        [self.navigationHandler pushViewController:notif animated:YES];
        [notif release];
    }else if(forward == LoginForwardFriends){
        FriendsViewController *friend = [[FriendsViewController alloc] initWithNibName:@"FriendsViewController" bundle:nil];
        [self.navigationHandler pushViewController:friend animated:YES];
        [friend release];
    }else{
        [self hide:nil];
    }
}

@end
