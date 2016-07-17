//
//  LandingViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/28/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "LandingViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "LoginViewController.h"

@interface LandingViewController ()<UIScrollViewDelegate, FBLoginViewDelegate, MBProgressHUDDelegate, ASIHTTPRequestDelegate>{
    IBOutlet UIButton *loginButton;
    IBOutlet FBLoginView *fbButton;
    IBOutlet UIScrollView *scroll;
    IBOutlet UIView *contentView;
    
    NSTimer *timer;
    NSInteger requestCount;
}

-(IBAction)loginByEmail:(id)sender;
-(IBAction)skipLogin:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;

@end

@implementation LandingViewController

@synthesize loading, loginForward, delegate;

- (void)dealloc
{
    [self stopTimer];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    loginButton.layer.borderColor = [UIColor whiteColor].CGColor;
    loginButton.layer.borderWidth = 1.;
    loginButton.layer.cornerRadius = 3.;
    
    fbButton.readPermissions = @[@"public_profile", @"email" ,@"user_friends"];
    
    contentView.backgroundColor = [UIColor clearColor];
    [scroll addSubview:contentView];
    scroll.contentSize = CGSizeMake(960, 200);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startTimer];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self stopTimer];
}

#pragma mark - Actions
-(void)slideToNext{
    CGPoint offset = scroll.contentOffset;
    
    offset.x += 320;
    if(offset.x > 640){
        offset.x = 0;
    }
    
    [scroll setContentOffset:offset animated:YES];
    
    [UIView animateWithDuration:1. animations:^{
        for(int i=1; i<=3; i++){
            UIView *img = [self.view viewWithTag:i];
            
            img.alpha = i-1 == (int)(offset.x / 320);
        }
    } completion:nil];
}

-(void)stopTimer{
    [timer invalidate];
    [timer release];
    timer = nil;
}

-(void)startTimer{
    if(timer)[self stopTimer];
    
    timer = [[NSTimer scheduledTimerWithTimeInterval:4. target:self selector:@selector(slideToNext) userInfo:nil repeats:YES] retain];
}

#pragma mark - delegate scrollView
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [UIView animateWithDuration:1. animations:^{
        for(int i=1; i<=3; i++){
            UIView *img = [self.view viewWithTag:i];
            
            img.alpha = i-1 == (int)(scrollView.contentOffset.x / 320);
        }
    } completion:^(BOOL finished) {
        [self startTimer];
    }];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopTimer];
}

#pragma mark - delegate FBLoginView
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        alertTitle = @"Login Canceled";
        alertMessage = @"You've canceled to login. Please log in again.";
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[[UIAlertView alloc] initWithTitle:alertTitle
                                     message:alertMessage
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] autorelease] show];
    }
}

-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user{
    NSLog(@"fb info %@", user);
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLLoginFB]];
    [request setPostValue:[@"fb" stringByAppendingString:[(NSDictionary *)user valueForKey:@"id"]] forKey:@"facebookID"];
    request.delegate = self;
    request.userInfo = (NSDictionary *)user;
    request.tag = 0;
    requestCount++;
    [request startAsynchronous];
    
    [FBSession.activeSession closeAndClearTokenInformation];
}

-(void)loginViewShowingLoggedInUser:(FBLoginView *)loginView{
    NSLog(@"Logout");
}

-(void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView{
    
}

#pragma mark - Actions
-(void)loginByEmail:(id)sender{
    LoginViewController *login = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    login.loginForward = self.loginForward;
    login.delegate = self.delegate;
    [self.navigationController pushViewController:login animated:YES];
    [login release];
}

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)skipLogin:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    if(!self.loading){
        self.loading = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.loading.labelText = @"Loading..";
        self.loading.delegate = self;
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [self countDownRequest];
    [self alertTitle:nil message:@"Failed connect to server."];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [self countDownRequest];
    NSLog(@"\n==========\nloginfb %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [request.responseString JSONValue];
    
    if(request.tag == 0){
        if([[root valueForKey:@"success"] boolValue]){
            [AppConfig sharedConfig].sessionID = [root valueForKey:@"SessionID"];
            [AppConfig sharedConfig].loginInfo = [root valueForKey:@"Profile"];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if(self.delegate){
                [self.delegate loginSucceedWithForward:self.loginForward];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
        }else{
            ASIFormDataRequest *newrequest = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLSignUpFB]];
            [newrequest setPostValue:[@"fb" stringByAppendingString:[request.userInfo valueForKey:@"id"]] forKey:@"facebookID"];
            [newrequest setPostValue:[request.userInfo valueForKey:@"name"] forKey:@"Name"];
            [newrequest setPostValue:[request.userInfo valueForKey:@"email"] forKey:@"Email"];
            [newrequest setPostValue:[[request.userInfo valueForKey:@"gender"] isEqualToString:@"male"]?@1:@2 forKey:@"Gender"];
            [newrequest setPostValue:@"0000-00-00" forKey:@"Birthday"];
            newrequest.delegate = self;
            newrequest.tag = 1;
            requestCount++;
            [newrequest startAsynchronous];
        }
    }else{
        if([[root valueForKey:@"success"] boolValue]){
            [AppConfig sharedConfig].sessionID = [root valueForKey:@"SessionID"];
            [AppConfig sharedConfig].loginInfo = [root valueForKey:@"Profile"];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if(self.delegate){
                [self.delegate loginSucceedWithForward:self.loginForward];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
        }else{
            [self alertTitle:nil message:[root valueForKey:@"Message"]];
        }
    }
}

-(void)countDownRequest{
    requestCount--;
    
    if(requestCount < 1){
        [self.loading hide:NO];
    }
}

#pragma mark - delegate loading
-(void)hudWasHidden:(MBProgressHUD *)hud{
    self.loading = nil;
}

@end
