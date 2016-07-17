//
//  PostViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/6/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "PostViewController.h"
#import "TiledMenuContainer.h"
#import "TiledMenuItem.h"
#import "PostSubmitViewController.h"

@interface PostViewController (){
    IBOutlet TiledMenuContainer *container;
    IBOutlet UIButton *backButton;
    IBOutlet UILabel *headerLabel;
}

-(IBAction)closeMe:(id)sender;
-(IBAction)back:(id)sender;

@property (nonatomic, retain) NSArray *menuArray;

@end

@implementation PostViewController

@synthesize menuArray;
@synthesize menus, level;

- (void)dealloc
{
    [menuArray release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = self.level==0?[UIColor clearColor]:[UIColor whiteColor];
    
    headerLabel.text = self.title.length>0?self.title:@"Post";
    
    backButton.hidden = self.level == 0;
    
    if(self.level == 0){
        NSInteger tag = 0;
        self.menuArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PostsType" ofType:@"plist"]];
        
        for(NSDictionary *dict in self.menuArray){
            TiledMenuItem *item = [[TiledMenuItem alloc] init];
            
            item.title = [dict valueForKey:@"name"];
            item.icon = [UIImage imageNamed:[NSString stringWithFormat:@"menu-post-%02zd.png", [[dict valueForKey:@"id"] integerValue]]];
            item.level = 0;
            item.tag = tag++;
            
            [item addTarget:self action:@selector(openSubMenu:) forControlEvents:UIControlEventTouchUpInside];
            
            [container addSubview:item];
            [item release];
        }
    }else{
        NSInteger l = 0;
        for(NSDictionary *dict in self.menus){
            TiledMenuItem *item = [[TiledMenuItem alloc] init];
            
            item.title = [dict valueForKey:@"name"];
            item.icon = [UIImage imageNamed:[NSString stringWithFormat:@"menu-post-sub-%02zd.png", [[dict valueForKey:@"id"] integerValue]]];
            item.level = l++;
            item.tag = item.level;
            [item addTarget:self action:@selector(beginPost:) forControlEvents:UIControlEventTouchUpInside];
            
            [container addSubview:item];
            [item release];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.view layoutIfNeeded];
}

#pragma mark - Actions
-(void)closeMe:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationController.view.superview.transform = CGAffineTransformMakeTranslation(0, 300.);
    } completion:^(BOOL finished) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)openSubMenu:(UIButton *)sender{
    NSDictionary *dict = [self.menuArray objectAtIndex:sender.tag];
    
    PostViewController *post = [[PostViewController alloc] initWithNibName:@"PostViewController" bundle:nil];
    post.level = self.level + 1;
    post.menus = [dict valueForKey:@"children"];
    post.title = [dict valueForKey:@"name"];
    [self.navigationController pushViewController:post animated:YES];
    [post release];
}

-(void)beginPost:(UIButton *)sender{
    NSDictionary *dict = [self.menus objectAtIndex:sender.tag];
    
    PostSubmitViewController *post = [[PostSubmitViewController alloc] initWithNibName:@"PostSubmitViewController" bundle:nil];
    post.postInfo = dict;
    [self.navigationController pushViewController:post animated:YES];
    [post release];
}

@end
