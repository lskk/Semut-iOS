//
//  TaxiConfirmViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/19/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "TaxiConfirmViewController.h"
#import "EGOImageView.h"
#import "DYRateView.h"
#import "Tools.h"
#import "MBProgressHUD.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"

@interface TaxiConfirmViewController ()<UITextViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate, UIAlertViewDelegate>{
    IBOutlet EGOImageView *photo;
    IBOutlet UILabel *name;
    IBOutlet UILabel *nopol;
    IBOutlet UILabel *phone;
    IBOutlet DYRateView *rate;
    IBOutlet UILabel *messagePlaceholder;
    IBOutlet UITextView *message;
    IBOutlet UIButton *cancelButton;
    IBOutlet UIButton *submitButton;
    IBOutlet UIView *bg;
    
    NSInteger requestCount;
}

-(IBAction)hideKeyboard:(id)sender;
-(IBAction)submit:(id)sender;
-(IBAction)cancel:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;

@end

@implementation TaxiConfirmViewController

@synthesize data;
@synthesize delegate;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.loading = nil;
    [data release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    rate.alignment = RateViewAlignmentLeft;
    photo.superview.layer.masksToBounds = YES;
    photo.superview.layer.cornerRadius = 10;
    cancelButton.layer.masksToBounds = YES;
    cancelButton.layer.cornerRadius = 5.;
    [cancelButton setBackgroundImage:[Tools solidImageForColor:cancelButton.backgroundColor withSize:cancelButton.frame.size] forState:UIControlStateNormal];
    submitButton.layer.masksToBounds = YES;
    submitButton.layer.cornerRadius = 5.;
    [submitButton setBackgroundImage:[Tools solidImageForColor:submitButton.backgroundColor withSize:submitButton.frame.size] forState:UIControlStateNormal];
    
    photo.imageURL = [NSURL URLWithString:[self.data valueForKey:@"Photo"]];
    name.text = [self.data valueForKey:@"Driver"];
    nopol.text = [self.data valueForKey:@"Nopol"];
    phone.text = [NSString stringWithFormat:@"Phone: %@", [self.data valueForKey:@"Phone"]];
    rate.rate = [[self.data valueForKey:@"Reputation"] integerValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self prepareAnimation];
}

#pragma mark - Actions
-(void)prepareAnimation{
    bg.alpha = 0;
    name.superview.transform = CGAffineTransformMakeTranslation(0., self.view.frame.size.height);
}

-(void)show{
    [UIView animateWithDuration:0.3 animations:^{
        bg.alpha = 1.;
        name.superview.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)hideKeyboard:(id)sender{
    [message resignFirstResponder];
}

-(void)submit:(id)sender{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLTaxiConfirm]];
    [request addPostValue:[self.data valueForKey:@"ReservationID"] forKey:@"ReservationID"];
    [request addPostValue:message.text forKey:@"Mark"];
    request.delegate = self;
    [request startAsynchronous];
}

-(void)cancel:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sure to Cancel?" message:@"Your order already taken by the driver, if you cancel this order you will lose some point and reputation." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes, Cancel Order", nil];
    [alert show];
}

-(void)alertTitle:(NSString *)title message:(NSString *)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)finishWithConfirmed:(BOOL)confirmed{
    [UIView animateWithDuration:0.3 animations:^{
        bg.alpha = 0.;
        name.superview.transform = CGAffineTransformMakeTranslation(0., self.view.frame.size.height);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if(self.delegate){
            [self.delegate confirmation:self finishedWithConfirmation:confirmed];
        }
    }];
}

#pragma mark - delegate alert
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLTaxiCancel]];
        [request addPostValue:[self.data valueForKey:@"ReservationID"] forKey:@"ReservationID"];
        request.delegate = self;
        request.tag = 1;
        [request startAsynchronous];
    }
    
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
        if([[root valueForKey:@"success"] boolValue]){
            [self finishWithConfirmed:YES];
        }else{
            [self alertTitle:@"Failed" message:@"Confirmation failed, please try again."];
        }
    }else if (request.tag == 1){
        if([[root valueForKey:@"success"] boolValue]){
            [self finishWithConfirmed:NO];
        }else{
            [self alertTitle:@"Failed" message:@"Cancelation failed, please try again."];
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

#pragma mark - delegate textview
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSString *str = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    messagePlaceholder.hidden = str.length > 0;
    
    return YES;
}

#pragma mark - Observer keyboard
-(void)keyboardDidHide:(NSNotification *)sender{
    [UIView animateWithDuration:0.3 animations:^{
        name.superview.transform = CGAffineTransformIdentity;
    }];
}

-(void)keyboardDidShow:(NSNotification *)sender{
    //    CGRect keyboardRect = [[sender.userInfo valueForKeyPath:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    
    [UIView animateWithDuration:0.3 animations:^{
        name.superview.transform = CGAffineTransformMakeTranslation(0, -100);
    }];
}

@end
