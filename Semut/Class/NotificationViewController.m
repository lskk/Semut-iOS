//
//  NotificationViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "NotificationViewController.h"

@interface NotificationViewController ()

-(IBAction)back:(id)sender;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
