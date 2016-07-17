//
//  SettingsViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/15/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "SettingsViewController.h"
#import "MBProgressHUD.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"

@interface SettingsViewController ()<UITableViewDataSource, UITableViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate>{
    IBOutlet UITableView *table;
    
    NSArray *visibilities;
    NSInteger expandedSection;
    NSInteger requestCount;
}

-(IBAction)back:(id)sender;

@property (nonatomic, retain) MBProgressHUD *loading;

@end

@implementation SettingsViewController

@synthesize loading;

- (void)dealloc
{
    [loading release];
    [visibilities release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    visibilities = [@[@"Public", @"Friends", @"Invisible"] retain];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

-(void)setVisibilityTo:(NSInteger)vi{
    requestCount++;
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLSetVisibility]];
    [request addPostValue:[NSNumber numberWithInteger:vi] forKey:@"Visibility"];
    request.userInfo = @{@"to": [NSNumber numberWithInteger:vi]};
    request.delegate = self;
    [request startAsynchronous];
}

-(void)setAvatarTo:(NSInteger)vi{
    requestCount++;
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLSetAvatar]];
    [request addPostValue:[NSNumber numberWithInteger:vi] forKey:@"AvatarID"];
    request.tag = 1;
    request.userInfo = @{@"to": [NSNumber numberWithInteger:vi]};
    request.delegate = self;
    [request startAsynchronous];
}

#pragma mark - datasource dan delegate table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 1){
        return visibilities.count;
    }else if(section == 3){
        return 5;
    }
    
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section % 2 == 1){
        return expandedSection == indexPath.section?48:0;
    }
    
    return indexPath.section%2==0?48:38;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section % 2 == 1){
        return 3;
    }
    
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section % 2 == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"judulCell"];
        
        if(!cell){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"judulCell"] autorelease];
            cell.detailTextLabel.textColor = [UIColor blueColor];
            cell.textLabel.font = [UIFont systemFontOfSize:16.];
        }
        
        if(indexPath.section == 0){
            NSInteger v = [[[AppConfig sharedConfig].loginInfo valueForKey:@"Visibility"] integerValue];
            
            cell.textLabel.text = @"Visibility";
            cell.detailTextLabel.text = [visibilities objectAtIndex:v];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }else if(indexPath.section == 2){
            UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
            img.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", [[[AppConfig sharedConfig].loginInfo valueForKey:@"AvatarID"] integerValue]]];
            img.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.textLabel.text = @"Avatar";
            cell.accessoryView = img;
            
            [img release];
        }
        
        return cell;
    }else if (indexPath.section % 2 == 1){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sec0cell"];
        
        if(!cell){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sec0cell"] autorelease];
            cell.textLabel.textColor = [UIColor blueColor];
            cell.clipsToBounds = YES;
            cell.textLabel.font = [UIFont systemFontOfSize:14.];
        }
        
        if(indexPath.section == 1){
            cell.textLabel.text = [visibilities objectAtIndex:indexPath.row];
            cell.accessoryView = UITableViewCellAccessoryNone;
        }else if(indexPath.section == 3){
            cell.textLabel.text = [NSString stringWithFormat:@"Avatar ke - %d", indexPath.row + 1];
            
            UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
            img.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", indexPath.row]];
            img.contentMode = UIViewContentModeScaleAspectFit;
            cell.accessoryView = img;
            
            [img release];
        }
        
        return cell;
    }
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section % 2 == 0){
        NSInteger target = indexPath.section + 1;
        expandedSection = (expandedSection == target)?0:target;
        [tableView beginUpdates];
        [tableView endUpdates];
    }else if(indexPath.section == 1){
        [self setVisibilityTo:indexPath.row];
    }else if(indexPath.section == 3){
        [self setAvatarTo:indexPath.row];
    }
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
    NSLog(@"\n==========\nsetting %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [request.responseString JSONValue];
    BOOL success = [[root valueForKey:@"success"] boolValue];
    
    if(request.tag == 0){
        if(success){
            NSNumber *to = [request.userInfo valueForKey:@"to"];
            
            NSMutableDictionary *info = (NSMutableDictionary *)[AppConfig sharedConfig].loginInfo;
            [info setValue:to forKey:@"Visibility"];
            [AppConfig sharedConfig].loginInfo = info;
            [table reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [self alertTitle:nil message:@"Failed. Please try again."];
        }
        
        expandedSection = 0;
        [table beginUpdates];
        [table endUpdates];
    }else if(request.tag == 1){
        if(success){
            NSNumber *to = [request.userInfo valueForKey:@"to"];
            
            NSMutableDictionary *info = (NSMutableDictionary *)[AppConfig sharedConfig].loginInfo;
            [info setValue:to forKey:@"AvatarID"];
            [AppConfig sharedConfig].loginInfo = info;
            [table reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [self alertTitle:nil message:@"Failed. Please try again."];
        }
        
        expandedSection = 0;
        [table beginUpdates];
        [table endUpdates];
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

@end
