//
//  LoginViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "LoginViewController.h"
#import "IconedTextField.h"
#import "ASIHTTPRequest+Semut.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "Tools.h"
#import "JSON.h"
#import "RegisterViewController.h"

@interface LoginViewController ()<ASIHTTPRequestDelegate, MBProgressHUDDelegate>{
    IBOutlet IconedTextField *email;
    IBOutlet IconedTextField *password;
    IBOutlet UIButton *loginButton;
    
    NSInteger requestCount;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)login:(id)sender;
-(IBAction)signup:(id)sender;
-(IBAction)forgotPassword:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;

@end

@implementation LoginViewController

@synthesize loading, loginForward, delegate;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.loading = nil;
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    email.type = IconedTextFieldIconTypeAccount;
    password.type = IconedTextFieldIconTypePassword;
    loginButton.layer.masksToBounds = YES;
    loginButton.layer.cornerRadius = 4.;
    [loginButton setBackgroundImage:[Tools solidImageForColor:loginButton.backgroundColor withSize:loginButton.frame.size] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)signup:(id)sender{
    [self hideKeyboard:nil];
    RegisterViewController *reg = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
    reg.loginForward = self.loginForward;
    reg.delegate = self.delegate;
    [self.navigationController pushViewController:reg animated:YES];
    [reg release];
}

-(void)forgotPassword:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Forgot Password?" message:@"To reset your password, please enter your email address" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *txt = [alert textFieldAtIndex:0];
    txt.placeholder = @"Email Address";
    txt.font = [txt.font fontWithSize:14.];
    [alert show];
}

-(void)hideKeyboard:(id)sender{
    [email resignFirstResponder];
    [password resignFirstResponder];
}

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(BOOL)formIsValid{
    if(email.text.length < 1){
        [self alertTitle:nil message:@"Please insert your email"];
        [email becomeFirstResponder];
        return NO;
    }
    if(password.text.length < 1){
        [self alertTitle:nil message:@"Please insert your password"];
        [password becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)login:(id)sender{
    [self hideKeyboard:nil];
    
    if(![self formIsValid])return;
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLLogin]];
    [request addPostValue:email.text forKey:@"Email"];
    [request addPostValue:password.text forKey:@"Password"];
    [request addPostValue:@"2" forKey:@"DeviceType"];
    [request addPostValue:@"0" forKey:@"PushID"];
    request.delegate = self;
    requestCount++;
    [request startAsynchronous];
}

#pragma mark - delegate UIAlertView
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0)return;
    
    UITextField *txt = [alertView textFieldAtIndex:0];
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    if(![emailTest evaluateWithObject:txt.text]){
        [self alertTitle:@"Failed" message:@"Cannot send to invalid email address."];
        return;
    }
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLResetPassword]];
    [request setPostValue:txt.text forKey:@"Email"];
    request.delegate = self;
    request.tag = 1;
    requestCount++;
    [request startAsynchronous];
    
    [alertView release];
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
    NSLog(@"\n==========\nlogin %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [request.responseString JSONValue];
    
    if(request.tag == 0){
        NSDictionary *profile = [root valueForKey:@"Profile"];
        if(profile){
            [AppConfig sharedConfig].sessionID = [root valueForKey:@"SessionID"];
            [AppConfig sharedConfig].loginInfo = profile;
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            [[AppDelegate currentDelegate] sendPushToken];
            
            if(self.delegate){
                [self.delegate loginSucceedWithForward:self.loginForward];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
        }else{
            [self alertTitle:@"Login Failed" message:@"Please check your input."];
        }
    }else if(request.tag == 1){
        [self alertTitle:nil message:request.responseString];
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

#pragma mark - Observer keyboard
-(void)keyboardDidHide:(NSNotification *)sender{
    [UIView animateWithDuration:0.3 animations:^{
        email.superview.transform = CGAffineTransformIdentity;
    }];
}

-(void)keyboardDidShow:(NSNotification *)sender{
//    CGRect keyboardRect = [[sender.userInfo valueForKeyPath:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    
    [UIView animateWithDuration:0.3 animations:^{
        email.superview.transform = CGAffineTransformMakeTranslation(0, -100);
    }];
}


@end
