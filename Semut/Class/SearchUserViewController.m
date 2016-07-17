//
//  SearchUserViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "SearchUserViewController.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import "MBProgressHUD.h"

@interface SearchUserViewController ()<MBProgressHUDDelegate, ASIHTTPRequestDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>{
    IBOutlet UISearchBar *searchBar;
    IBOutlet UITableView *table;
    
    NSInteger requestCount;
    NSOperationQueue *queue;
}

-(IBAction)back:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;
@property (nonatomic, retain) NSMutableArray *data;


@end

@implementation SearchUserViewController

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

-(void)alertTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)makeRequest{
    requestCount++;
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLRelationSearch]];
    [request addPostValue:searchBar.text forKey:@"Key"];
    request.delegate = self;
    [queue addOperation:request];
    
    [searchBar resignFirstResponder];
}

-(void)addFriend:(UIButton *)sender{
    NSDictionary *dict = [self.data objectAtIndex:sender.tag];
    
    requestCount++;
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLRelationRequest]];
    [request addPostValue:[dict valueForKey:@"ID"] forKey:@"ReceiverID"];
    request.delegate = self;
    request.userInfo = dict;
    request.tag = 1;
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
    NSDictionary *source = [self.data objectAtIndex:indexPath.row];
    
    BOOL isFriend = [[source valueForKey:@"Friend"] boolValue];
    
    UITableViewCell *cell = nil;
    
    if(isFriend){
        cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        
        if(!cell){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FriendCell"] autorelease];
        }
    }else{
        NSDictionary *rel = [source valueForKey:@"RelationInfo"];
        if([rel isKindOfClass:[NSDictionary class]]){
            BOOL isRequest = [[rel valueForKey:@"isRequest"] boolValue];
            
            if(isRequest){
                cell = [tableView dequeueReusableCellWithIdentifier:@"FriendRequestCell"];
                
                if(!cell){
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FriendRequestCell"] autorelease];
                    
                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                    [btn setTitle:@"Accept\nRequest" forState:UIControlStateNormal];
                    btn.titleLabel.numberOfLines = 2;
                    btn.titleLabel.font = [UIFont systemFontOfSize:11.];
                    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
                    btn.frame = CGRectMake(0, 0, 50., 30);
                    cell.accessoryView = btn;
                }
            }else{
                cell = [tableView dequeueReusableCellWithIdentifier:@"FriendSentCell"];
                
                if(!cell){
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FriendSentCell"] autorelease];
                    
//                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//                    [btn setTitle:@"Cancel\nRequest" forState:UIControlStateNormal];
//                    btn.titleLabel.numberOfLines = 2;
//                    btn.titleLabel.font = [UIFont systemFontOfSize:11.];
//                    btn.titleLabel.textAlignment = NSTextAlignmentCenter;
//                    btn.frame = CGRectMake(0, 0, 50., 30);
//                    cell.accessoryView = btn;
                }
            }
        }else{
            cell = [tableView dequeueReusableCellWithIdentifier:@"NonfriendCell"];
            
            if(!cell){
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NonfriendCell"] autorelease];
                
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
                [btn addTarget:self action:@selector(addFriend:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = btn;
            }
        }
    }
    
    cell.textLabel.text = [source valueForKey:@"Name"];
    cell.detailTextLabel.text = [source valueForKey:@"Email"];
    cell.imageView.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", [source valueForKey:@"AvatarID"]]];
    cell.accessoryView.tag = indexPath.row;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    NSLog(@"\n==========\nsearch user %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [request.responseString JSONValue];
    
    if(request.tag == 0){
        if([[root valueForKey:@"success"] boolValue]){
            self.data = [root valueForKey:@"Result"];
        }else{
            [self alertTitle:nil message:[root valueForKey:@"Message"]];
        }
    }else if(request.tag == 1){
        if([[root valueForKey:@"success"] boolValue]){
            NSMutableDictionary *dict = (NSMutableDictionary *)request.userInfo;
            [dict setValue:[root valueForKey:@"Relation"] forKey:@"RelationInfo"];
            [[NSNotificationCenter defaultCenter] postNotificationName:SemutRelationUpdateNotification object:nil];
        }else{
            [self alertTitle:nil message:[root valueForKey:@"Message"]];
        }
    }
        
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

#pragma mark - delegate searchbar
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self makeRequest];
}

@end
