//
//  TaxiViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/16/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "TaxiViewController.h"
#import "Tools.h"
#import "ProgressView.h"
#import "SetLocationViewController.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import "TaxiConfirmViewController.h"

@interface TaxiViewController ()<UIAlertViewDelegate, SetLocationViewControllerDelegate, ASIHTTPRequestDelegate, TaxiConfirmViewControllerDelegate>{
    IBOutlet UIButton *orderButton;
    IBOutlet ProgressView *progress;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *descLabel;
    IBOutlet UILabel *commandLabel;
    IBOutlet UILabel *estimationLabel;
    IBOutlet UIActivityIndicatorView *loadingIndicator;
    
    CGFloat counter;
    NSOperationQueue *queue;
    BOOL takerFound;
    BOOL timedOut;
}

-(IBAction)back:(id)sender;
-(IBAction)order:(id)sender;

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, copy) NSString *placeName;
@property (nonatomic, copy) NSString *orderID;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic, unsafe_unretained) ASIHTTPRequest *currentRequest;

@end

@implementation TaxiViewController

@synthesize timer, placeName, location, orderID;

- (void)dealloc
{
    [placeName release];
    [orderID release];
    
    for(ASIHTTPRequest *req in queue.operations){
        req.delegate = nil;
        [req cancel];
    }
    [queue release];
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
    orderButton.layer.masksToBounds = YES;
    orderButton.layer.cornerRadius = 0.5 * orderButton.frame.size.height;
    [orderButton setBackgroundImage:[Tools solidImageForColor:orderButton.backgroundColor withSize:orderButton.frame.size] forState:UIControlStateNormal];
    orderButton.titleLabel.numberOfLines = 2;
    
    progress.hidden = YES;
    self.location = CLLocationCoordinate2DMake(20000., 20000.);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - ACtions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)order:(id)sender{
//    [self showDriverIdentityWithData:nil]; return;
    orderButton.selected = !orderButton.selected;
    
    commandLabel.text = orderButton.selected?@"CANCEL\nORDER":@"ORDER\nNOW";
    if(orderButton.selected){
        if(CLLocationCoordinate2DIsValid(self.location)){
            [self startOrder];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your Destination" message:@"Do you want to set your destination so we can estimate the cost?" delegate:self cancelButtonTitle:@"Order Taxi Now" otherButtonTitles:@"Set Destination", nil];
            alert.tag = 0.;
            [alert show];
        }
    }else{
        [self cancelOrder];
    }
}

-(void)cancelOrder{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLTaxiCancel]];
    [request addPostValue:self.orderID forKey:@"ReservationID"];
    request.delegate = self;
    request.tag = 1;
    [queue addOperation:request];
}

-(void)startOrder{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLTaxiOrder]];
    request.delegate = self;
    [request setPostValue:[AppConfig sharedConfig].latitude forKey:@"LocationLat"];
    [request setPostValue:[AppConfig sharedConfig].longitude forKey:@"LocationLon"];
    
    if(CLLocationCoordinate2DIsValid(self.location)){
        [request setPostValue:self.placeName forKey:@"Direction"];
        [request setPostValue:[NSNumber numberWithDouble:self.location.latitude] forKey:@"DirectionLat"];
        [request setPostValue:[NSNumber numberWithDouble:self.location.longitude] forKey:@"DirectionLon"];
    }else{
        [request setPostValue:@"Unnamed Address" forKey:@"Direction"];
        [request setPostValue:[AppConfig sharedConfig].latitude forKey:@"DirectionLat"];
        [request setPostValue:[AppConfig sharedConfig].longitude forKey:@"DirectionLon"];
    }
    [loadingIndicator startAnimating];
    [queue addOperation:request];
}

-(void)startTimer{
    timedOut = NO;
    
    titleLabel.text = @"SEARCHING...";
    CGRect f = titleLabel.frame;
    f.origin.x = (self.view.frame.size.width - [titleLabel.text sizeWithFont:titleLabel.font].width) * 0.5;
    titleLabel.frame = f;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    descLabel.text = @"We are searching the nearest taxi that will serve your order.";
    
    progress.hidden = NO;
    progress.progress = 1.;
    counter = 60.;
    if(!self.timer){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    }
}

-(void)stopTimer{
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    
    progress.hidden = YES;
    
    orderButton.selected = NO;
    titleLabel.text = @"ORDER TAXI";
    titleLabel.center = CGPointMake(self.view.frame.size.width * 0.5, titleLabel.center.y);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.text = @"Order taxi easily by tapping order button. And we'll do the rest for you.";
    orderButton.selected = NO;
    commandLabel.text = orderButton.selected?@"CANCEL\nORDER":@"ORDER\nNOW";
}

-(void)tick:(NSTimer *)t{
    counter -= 0.1;
    
    progress.progress = counter / 60.;
    
    if(fmodf(counter, 0.5f) < 0.1){
        if([titleLabel.text isEqualToString:@"SEARCHING..."]){
            titleLabel.text = @"SEARCHING";
        }else{
            titleLabel.text = [titleLabel.text stringByAppendingString:@"."];
        }
    }
    
    if(progress.progress <= 0.){
        [self stopTimer];
        timedOut = YES;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry.." message:@"There is still no taxi driver give a response to your order. Do you want to try again?" delegate:self cancelButtonTitle:@"Cancel Order" otherButtonTitles:@"Try Again", nil];
        alert.tag = 1;
        [alert show];
    }
}

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)checkTaker{
    if(timedOut)return;
    
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?ReservationID=%@", kURLTaxiCheckTaker, self.orderID]]];
    [req setCompletionBlock:^{
        NSLog(@"%@ => %@", req.url.absoluteString, req.responseString);
        
        NSDictionary *root = [req.responseString JSONValue];
        
        if([[root valueForKey:@"success"] boolValue]){
            takerFound = YES;
            [self stopTimer];
            
            NSDictionary *data = [root valueForKey:@"TaxiData"];
            [self showDriverIdentityWithData:data];
        }else{
            [self performSelector:@selector(checkTaker) withObject:nil afterDelay:1.];
        }
    }];
    self.currentRequest = req;
    [queue addOperation:req];
}

-(void)stopCheckTaker{
    self.currentRequest.delegate = nil;
    [self.currentRequest cancel];
}

-(void)showDriverIdentityWithData:(NSDictionary *)dict{
    TaxiConfirmViewController *confirm = [[TaxiConfirmViewController alloc] initWithNibName:@"TaxiConfirmViewController" bundle:nil];
    confirm.data = dict;
    confirm.delegate = self;
    
    confirm.view.frame = self.view.bounds;
    [self.view addSubview:confirm.view];
    
    [confirm show];
}

#pragma mark - delegate taxiconfirm
-(void)confirmation:(TaxiConfirmViewController *)sender finishedWithConfirmation:(BOOL)confirm{
    [sender release];
}

#pragma mark - delegate alert
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 0){
        if(buttonIndex == 0){
            [self startOrder];
        }else{
            SetLocationViewController *loc = [[SetLocationViewController alloc] initWithNibName:@"SetLocationViewController" bundle:nil];
            loc.coordinate = CLLocationCoordinate2DMake([AppConfig sharedConfig].latitude.doubleValue, [AppConfig sharedConfig].longitude.doubleValue);
            loc.delegate = self;
            [self presentViewController:loc animated:YES completion:^{
                
            }];
        }
    }else if(alertView.tag == 1){
        if(buttonIndex == 0){
            [self cancelOrder];
        }else{
            [self startTimer];
            [self checkTaker];
        }
    }
    
    [alertView release];
}

#pragma mark - setlocation delegate
-(void)setLocationDidCancel:(SetLocationViewController *)sender{
    [self stopTimer];
    [sender release];
}

-(void)setLocationDidConfirmed:(SetLocationViewController *)sender{
    self.placeName = sender.placeTitle;
    self.location = sender.coordinate;
    [self startOrder];
    [sender release];
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    [loadingIndicator startAnimating];
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    if(request.tag == 0){
        [self alertTitle:nil message:@"Failed connect to server."];
        [self stopTimer];
    }
    [loadingIndicator stopAnimating];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [loadingIndicator stopAnimating];
    NSLog(@"\n==========\ntaxi %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSMutableArray *root = [request.responseString JSONValue];
    if(request.tag == 0){
        if([[root valueForKey:@"success"] boolValue]){
            self.orderID = [root valueForKey:@"ReservationID"];
            [self checkTaker];
            [self startTimer];
        }else{
            [self stopTimer];
            [self alertTitle:@"We apologize" message:@"No Taxi available for now. Please try again later."];
        }
    }else if(request.tag == 1){
        if([[root valueForKey:@"success"] boolValue]){
            [self stopTimer];
        }else{
            [self alertTitle:nil message:@"Cancelation Failed. Please try again."];
        }
    }
}

@end
