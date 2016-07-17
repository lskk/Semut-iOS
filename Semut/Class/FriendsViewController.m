//
//  FriendsViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "FriendsViewController.h"
#import "MBProgressHUD.h"
#import "ASIHTTPRequest+Semut.h"
#import "SearchUserViewController.h"
#import "JSON.h"
#import "Tools.h"

@interface FriendsViewController ()<MBProgressHUDDelegate, ASIHTTPRequestDelegate, UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *table;
    IBOutlet UIView *segmentContainer;
    
    NSInteger requestCount;
    NSOperationQueue *queue;
    NSInteger selectedSegment;
}

-(IBAction)back:(id)sender;
-(IBAction)segmentChanged:(id)sender;
-(IBAction)searchUser:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;
@property (nonatomic, retain) NSMutableArray *data;

@end

@implementation FriendsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];;
    self.loading = nil;
    self.data = nil;
    
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
    
    segmentContainer.layer.masksToBounds = YES;
    segmentContainer.layer.borderColor = [UIColor blackColor].CGColor;
    segmentContainer.layer.borderWidth = 1.;
    segmentContainer.layer.cornerRadius = 5.;
    
    for(UIButton *btn in segmentContainer.subviews){
        if(btn.tag == 1){
            btn.layer.borderColor = [UIColor blackColor].CGColor;
            btn.layer.borderWidth = 1.;
        }
        
        [btn setBackgroundImage:[Tools solidImageForColor:[UIColor whiteColor] withSize:btn.frame.size] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [btn setBackgroundImage:[Tools solidImageForColor:[UIColor blackColor] withSize:btn.frame.size] forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relationDataUpdated) name:SemutRelationUpdateNotification object:nil];
    
    [self makeRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions
-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)makeRequest{
    requestCount++;
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:kURLRelation]];
    //    [request addPostValue:[AppConfig sharedConfig].sessionID forKey:@"sessID"];
    request.delegate = self;
    [queue addOperation:request];
}

-(void)relationDataUpdated{
    [self makeRequest];
    [table reloadData];
}

-(void)searchUser:(id)sender{
    SearchUserViewController *search = [[SearchUserViewController alloc] initWithNibName:@"SearchUserViewController" bundle:nil];
    [self.navigationController pushViewController:search animated:YES];
    [search release];
}

-(void)segmentChanged:(UIButton *)sender{
    selectedSegment = sender.tag;
    
    for(UIButton *btn in segmentContainer.subviews){
        btn.selected = sender == btn;
    }
    
    [table reloadData];
}

#pragma mark - delegate dan datasource table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(selectedSegment == 0){
        return [AppConfig sharedConfig].relations.count;
    }else if(selectedSegment == 1){
        return [AppConfig sharedConfig].relationSent.count;
    }
    
    return [AppConfig sharedConfig].relationReceive.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"relationcell"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"relationcell"] autorelease];
    }
    
    NSArray *sources = [AppConfig sharedConfig].relationReceive;
    
    if(selectedSegment == 0){
        sources = [AppConfig sharedConfig].relations;
    }else if(selectedSegment == 1){
        sources = [AppConfig sharedConfig].relationSent;
    }
    
    NSDictionary *dict = [sources objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict valueForKey:@"Name"];
    cell.detailTextLabel.text = [dict valueForKey:@"Email"];
    cell.imageView.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", [dict valueForKey:@"AvatarID"]]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    NSArray *sources = [AppConfig sharedConfig].relationReceive;
//    
//    if(segment.selectedSegmentIndex == 0){
//        sources = [AppConfig sharedConfig].relations;
//    }else if(segment.selectedSegmentIndex == 1){
//        sources = [AppConfig sharedConfig].relationSent;
//    }
//    
//    NSDictionary *source = [sources objectAtIndex:indexPath.row];
//    
//    ProfileViewController *profile = [[[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil] autorelease];
//    profile.data = source;
//    [self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    if(!self.loading){
        self.loading = [MBProgressHUD showHUDAddedTo:table animated:YES];
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
    NSLog(@"\n==========\nrelation %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSMutableArray *root = [request.responseString JSONValue];
    
    [AppConfig sharedConfig].relations = [root valueForKey:@"Friends"];
    [AppConfig sharedConfig].relationSent = [root valueForKey:@"Sent"];
    [AppConfig sharedConfig].relationReceive = [root valueForKey:@"Received"];
    
    [table reloadData];
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
