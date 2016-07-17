//
//  MapFilterViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "MapFilterViewController.h"
#import "Tools.h"

@interface MapFilterViewController (){
    IBOutlet UIView *bg;
    IBOutlet UIView *container;
    IBOutlet UILabel *headerLabel;
}

-(IBAction)hide:(id)sender;
-(IBAction)menuSelect:(id)sender;

@end

@implementation MapFilterViewController

@synthesize filterValue;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.filterValue = 63;
    
    container.layer.masksToBounds = YES;
    container.layer.cornerRadius = 5.;
    headerLabel.layer.masksToBounds = YES;
    headerLabel.layer.cornerRadius = 5.;
    
    for(int i=0; i<6; i++){
        int tag = 1 << i;
        UIButton *v = (UIButton *)[container viewWithTag:tag];
        [v setBackgroundImage:[Tools solidImageForColor:v.backgroundColor withSize:v.frame.size] forState:UIControlStateNormal];
    }
    
    [self updateSelection];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
-(void)prepareForAppear{
    headerLabel.alpha = 0.;
    headerLabel.transform = CGAffineTransformMakeTranslation(0, headerLabel.frame.size.height);
    bg.alpha = 0.;
    for(int i=0; i<6; i++){
        int tag = 1 << i;
        UIView *v = [container viewWithTag:tag];
        v.transform = CGAffineTransformMakeTranslation(v.frame.size.width, 0);
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
    
    for(int i=0; i<6; i++){
        int tag = 1 << i;
        UIView *v = [container viewWithTag:tag];
        
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
        for(int i=0; i<6; i++){
            int tag = 1 << i;
            UIView *v = [container viewWithTag:tag];
            
            [UIView animateWithDuration:0.25 delay:i*0.05 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                v.transform = CGAffineTransformMakeTranslation(v.frame.size.width, 0);
            } completion:^(BOOL finished) {
                
            }];
        }
    }];
}

-(void)menuSelect:(UIButton *)sender{
    self.filterValue ^= sender.tag;
        
    [self updateSelection];
}

-(void)updateSelection{
    for(int i=0; i<6; i++){
        int tag = 1 << i;
        UIButton *v = (UIButton *)[container viewWithTag:tag];
        v.selected = (tag & self.filterValue) > 0;
        
        NSLog(@"tag %d, filter %d, result %d", tag, self.filterValue, tag & self.filterValue);
    }
}

@end
