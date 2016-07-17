//
//  RegisterViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "RegisterViewController.h"
#import "ASIHTTPRequest+Semut.h"
#import "MBProgressHUD.h"
#import "JSON.h"
#import "AppDelegate.h"
#import "Tools.h"
#import "IconedTextField.h"

@interface RegisterViewController ()<ASIHTTPRequestDelegate, MBProgressHUDDelegate>{
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIView *formView;
    IBOutlet IconedTextField *fullname;
    IBOutlet IconedTextField *email;
    IBOutlet IconedTextField *phoneNumber;
    IBOutlet UIButton *maleButton;
    IBOutlet UIButton *femaleButton;
    IBOutlet IconedTextField *birthday;
    IBOutlet IconedTextField *password;
    IBOutlet IconedTextField *repassword;
    IBOutlet UIButton *signupButton;
    IBOutlet UIDatePicker *datePicker;
    
    NSInteger requestCount;
    CGRect initialScrollViewFrame;
}

-(IBAction)back:(id)sender;
-(IBAction)regist:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)toggleGender:(id)sender;
-(IBAction)dateChanged:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;

@end

@implementation RegisterViewController

@synthesize loginForward, delegate;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.loading = nil;
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Sign Up";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    formView.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:formView];
    scrollView.contentSize = formView.frame.size;
    
    birthday.inputView = datePicker;
    fullname.type = IconedTextFieldIconTypeAccount;
    email.type = IconedTextFieldIconTypeEmail;
    phoneNumber.type = IconedTextFieldIconTypePhone;
    birthday.type = IconedTextFieldIconTypeDate;
    password.type = IconedTextFieldIconTypePassword;
    repassword.type = IconedTextFieldIconTypePassword;
    
    [signupButton setBackgroundImage:[Tools solidImageForColor:signupButton.backgroundColor withSize:signupButton.frame.size] forState:UIControlStateNormal];
    signupButton.layer.masksToBounds = YES;
    signupButton.layer.cornerRadius = 4.;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    initialScrollViewFrame = scrollView.frame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    for(UITextField *one in formView.subviews){
        if([one isKindOfClass:[UITextField class]]){
            [one resignFirstResponder];
        }
    }
}

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)toggleGender:(id)sender{
    maleButton.selected = sender == maleButton;
    femaleButton.selected = sender == femaleButton;
}

-(void)dateChanged:(UIDatePicker *)sender{
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"dd MMMM yyyy"];
    birthday.text = [format stringFromDate:sender.date];
}

-(BOOL)formIsValid{
    if(fullname.text.length < 1){
        [self alertTitle:nil message:@"Please insert your fullname"];
        [fullname becomeFirstResponder];
        return NO;
    }
    
    if(email.text.length < 1){
        [self alertTitle:nil message:@"Please insert your email"];
        [email becomeFirstResponder];
        return NO;
    }
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    if(![emailTest evaluateWithObject:email.text] || email.text.length < 5){
        [self alertTitle:nil message:@"Mohon isi email yang valid."];
        [email becomeFirstResponder];
        return NO;
    }
    
    if(phoneNumber.text.length < 1){
        [self alertTitle:nil message:@"Please insert your phone number"];
        [phoneNumber becomeFirstResponder];
        return NO;
    }
    
    if(!maleButton.selected && !femaleButton.selected){
        [self alertTitle:nil message:@"Please select your gender"];
        return NO;
    }
    
    if(birthday.text.length < 1){
        [self alertTitle:nil message:@"Please insert your birthdate"];
        [birthday becomeFirstResponder];
        return NO;
    }
    
    if(password.text.length < 1){
        [self alertTitle:nil message:@"Please insert your password"];
        [password becomeFirstResponder];
        return NO;
    }
    
    if(repassword.text.length < 1){
        [self alertTitle:nil message:@"Please retype your password"];
        [repassword becomeFirstResponder];
        return NO;
    }
    
    if(![repassword.text isEqualToString:[password text]]){
        [self alertTitle:nil message:@"Your password doesn't match with retype password"];
        [repassword becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

-(void)regist:(id)sender{
    [self hideKeyboard:nil];
    
    if(![self formIsValid])return;
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLSignUp]];
    [request addPostValue:email.text forKey:@"Email"];
    [request addPostValue:password.text forKey:@"Password"];
    [request addPostValue:@"2" forKey:@"DeviceType"];
    [request addPostValue:fullname.text forKey:@"Name"];
    [request addPostValue:@"62" forKey:@"CountryCode"];
    [request addPostValue:maleButton.selected?@"1":@"2" forKey:@"Gender"];
    [request addPostValue:@"" forKey:@"PushID"];
    
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"dd MMMM yyyy"];
    NSDate *dt = [format dateFromString:birthday.text];
    [format setDateFormat:@"yyyy-MM-dd"];
    
    [request addPostValue:[format stringFromDate:dt] forKey:@"Birthday"];
    [request addPostValue:phoneNumber.text forKey:@"PhoneNumber"];
    request.delegate = self;
    requestCount++;
    [request startAsynchronous];
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
    NSLog(@"\n==========\nregister %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [request.responseString JSONValue];
    NSDictionary *profile = [root valueForKey:@"Profile"];
    if(profile){
        [AppConfig sharedConfig].sessionID = [root valueForKey:@"sessID"];
        [AppConfig sharedConfig].loginInfo = profile;
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [[AppDelegate currentDelegate] sendPushToken];
        
        if(self.delegate){
            [self.delegate loginSucceedWithForward:self.loginForward];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SemutLoginStateUpdateNotification object:nil];
    }else{
        [self alertTitle:@"Signup Failed" message:@"Please try again."];
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
        scrollView.frame = initialScrollViewFrame;
    }];
}

-(void)keyboardDidShow:(NSNotification *)sender{
    CGRect keyboardRect = [[sender.userInfo valueForKeyPath:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = scrollView.frame;
        frame.size.height = self.view.frame.size.height - keyboardRect.size.height - frame.origin.y;
        scrollView.frame = frame;
    }];
}

@end
