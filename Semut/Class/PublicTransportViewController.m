//
//  PublicTransportViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/16/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "PublicTransportViewController.h"
#import "Tools.h"
#import "TaxiViewController.h"

@interface PublicTransportViewController (){
    IBOutlet UIView *menuContainer;
}

-(IBAction)back:(id)sender;
-(IBAction)angkot:(id)sender;
-(IBAction)taxi:(id)sender;

@end

@implementation PublicTransportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    for(UIView *v in menuContainer.subviews){
        v.backgroundColor = [UIColor clearColor];
        
        for(UIButton *btn in v.subviews){
            if([btn isKindOfClass:[UIButton class]]){
                btn.layer.masksToBounds = YES;
                btn.layer.cornerRadius = 0.25 * btn.frame.size.height;
                btn.layer.borderColor = [UIColor blackColor].CGColor;
                btn.layer.borderWidth = 1.;
                
                [btn setBackgroundImage:[Tools solidImageForColor:btn.backgroundColor withSize:btn.frame.size] forState:UIControlStateNormal];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

#pragma mark - Actoins
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)angkot:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming Soon" message:@"Please be patient. This feature will be available soon." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)taxi:(id)sender{
    TaxiViewController *taxi = [[TaxiViewController alloc] initWithNibName:@"TaxiViewController" bundle:nil];
    [self.navigationController pushViewController:taxi animated:YES];
    [taxi release];
}

@end
