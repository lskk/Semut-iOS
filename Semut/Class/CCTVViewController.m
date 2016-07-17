//
//  CCTVViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "CCTVViewController.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import "MBProgressHUD.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CCTVViewController () <MBProgressHUDDelegate, ASIHTTPRequestDelegate, UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *table;
    
    NSInteger requestCount;
    NSOperationQueue *queue;
}

-(IBAction)back:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;
@property (nonatomic, retain) NSMutableArray *data;

@end

@implementation CCTVViewController

@synthesize loading, data;

- (void)dealloc
{
    self.loading = nil;
    [data release];
    
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
    
    [self makeRequest];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)makeRequest{
    requestCount++;
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:[NSString stringWithFormat:kURLCCTV, @"1"]]];
    request.delegate = self;
    [queue addOperation:request];
}

#pragma mark - delegate dan datasource table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cctvcell"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cctvcell"] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:14.];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:9.];
    }
    
    NSDictionary *dict = [self.data objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict valueForKey:@"Name"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@-%@ %@", [dict valueForKey:@"City"], [dict valueForKey:@"Province"], [dict valueForKey:@"Country"]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [self.data objectAtIndex:indexPath.row];
    
    //    CCTVPlayerViewController *player = [[[CCTVPlayerViewController alloc] init] autorelease];
    //    player.urlStream = [dict valueForKey:@"Stream"];
    //    [self.navigationController pushViewController:player animated:YES];
    
    NSURL *url = [NSURL URLWithString:[dict valueForKey:@"Video"]];
    MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [self presentMoviePlayerViewControllerAnimated:player];
    [player release];
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
    NSLog(@"\n==========\ncctv %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSMutableArray *root = [request.responseString JSONValue];
    self.data = [root valueForKey:@"Result"];
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
