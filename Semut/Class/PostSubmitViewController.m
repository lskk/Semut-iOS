//
//  PostSubmitViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/6/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "PostSubmitViewController.h"
#import "Tools.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import "LandingViewController.h"
#import "AppDelegate.h"

@interface PostSubmitViewController ()<UITextViewDelegate>{
    IBOutlet UIImageView *thumbnail;
    IBOutlet UILabel *postTitle;
    IBOutlet UILabel *timeStamp;
    IBOutlet UITextView *remarks;
    IBOutlet UIButton *submitButton;
    IBOutlet UILabel *counter;
}

-(IBAction)back:(id)sender;
-(IBAction)close:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)submit:(id)sender;

@property (nonatomic, retain) NSDate *date;

@end

@implementation PostSubmitViewController

@synthesize postInfo, date;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [date release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [submitButton setBackgroundImage:[Tools solidImageForColor:submitButton.backgroundColor withSize:submitButton.frame.size] forState:UIControlStateNormal];
    submitButton.layer.masksToBounds = YES;
    submitButton.layer.cornerRadius = 5;
    remarks.layer.masksToBounds = YES;
    remarks.layer.cornerRadius = 5;
    remarks.backgroundColor = [UIColor whiteColor];
    remarks.layer.borderColor = submitButton.backgroundColor.CGColor;
    remarks.layer.borderWidth = 1.;
    thumbnail.layer.masksToBounds = YES;
    thumbnail.layer.cornerRadius = 0.5 * thumbnail.frame.size.height;
    thumbnail.backgroundColor = [UIColor orangeColor];
    
    self.date = [NSDate date];
    
    thumbnail.image = [UIImage imageNamed:[NSString stringWithFormat:@"menu-post-sub-%02zd.png", [[self.postInfo valueForKey:@"id"] integerValue]]];
    postTitle.text = [[self.postInfo valueForKey:@"name"] capitalizedString];
    remarks.text = @"";
    
    timeStamp.text = [NSDateFormatter localizedStringFromDate:self.date dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterLongStyle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)close:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.view.superview.transform = CGAffineTransformMakeTranslation(0, 300.);
    } completion:^(BOOL finished) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
}

-(void)hideKeyboard:(id)sender{
    [self.view endEditing:YES];
}

-(void)submit:(id)sender{
    [self hideKeyboard:nil];
    
    if([AppConfig sharedConfig].sessionID.integerValue < 1){
        [self showLoginWithForward:LoginForwardNone];
        return;
    }
    
    NSDateFormatter *format = [NSDateFormatter new];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLPost]];
    [request addPostValue:[self.postInfo valueForKey:@"id"] forKey:@"Type"];
    [request addPostValue:[format stringFromDate:self.date] forKey:@"Times"];
    [request addPostValue:[AppConfig sharedConfig].latitude forKey:@"Latitude"];
    [request addPostValue:[AppConfig sharedConfig].longitude forKey:@"Longitude"];
    [request addPostValue:remarks.text forKey:@"Description"];
    [request setCompletionBlock:^{
        NSLog(@"Post Tag: param:%@ \n\n\nreply:%@", request.postBody, request.responseString);
        [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
    }];
    [request startAsynchronous];
    
    [format release];
    
    [self close:nil];
}

-(void)showLoginWithForward:(enum LoginForward)forward{
    [[AppDelegate currentDelegate].landingViewController popToRootViewControllerAnimated:NO];
    LandingViewController *landing = [[[AppDelegate currentDelegate].landingViewController viewControllers] objectAtIndex:0];
    landing.loginForward = forward;
    
    [[AppDelegate currentDelegate].mainViewController presentViewController:[AppDelegate currentDelegate].landingViewController animated:YES completion:nil];
}

#pragma mark - textView delegate
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSString *str = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if(str.length <= 128){
        counter.text = [NSString stringWithFormat:@"%zd of 128", str.length];
        return YES;
    }
    
    return NO;
}

#pragma mark - Observer keyboard
-(void)keyboardDidHide:(NSNotification *)sender{
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.view.superview.transform = CGAffineTransformIdentity;
    }];
}

-(void)keyboardDidShow:(NSNotification *)sender{
    CGRect keyboardRect = [[sender.userInfo valueForKeyPath:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.view.superview.transform = CGAffineTransformMakeTranslation(0, -keyboardRect.size.height);
    }];
}

@end
