//
//  PinDetailViewController.m
//  Semut
//
//  Created by Asep Mulyana on 5/15/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "PinDetailViewController.h"
#import "PointLabel.h"
#import "ReputationView.h"
#import "Tools.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "TimestampLabel.h"
#import "XHImageViewer.h"
#import "MBProgressHUD.h"

@interface PinDetailViewController ()<ASIHTTPRequestDelegate, XHImageViewerDelegate, UIActionSheetDelegate, MBProgressHUDDelegate>{
    IBOutlet UIImageView *avatar;
    IBOutlet UILabel *name;
    IBOutlet UILabel *level;
    IBOutlet PointLabel *point;
    IBOutlet ReputationView *reputation;
    IBOutlet UIButton *friendButton;
    IBOutlet UIButton *cctvButton;
    IBOutlet UIButton *reportTag;
    IBOutlet UIButton *retag;
    IBOutlet UIButton *imgButton;
    IBOutlet UIActivityIndicatorView *loading;
    IBOutlet UILabel *city;
    IBOutlet UILabel *province;
    IBOutlet UILabel *reporter;
    IBOutlet TimestampLabel *time;
    IBOutlet UILabel *info;
    
    enum DetailType myType;
    NSOperationQueue *queue;
}

-(IBAction)addFriend:(id)sender;
-(IBAction)watch:(id)sender;
-(IBAction)retag:(id)sender;
-(IBAction)reportTag:(id)sender;
-(IBAction)showImage:(id)sender;

@property (nonatomic, retain) MBProgressHUD *mloading;

@end

@implementation PinDetailViewController

@synthesize data, mloading;

- (void)dealloc
{
    [data release];
    
    for(ASIHTTPRequest *req in queue.operations){
        req.delegate = nil;
        [req cancel];
    }
    [queue release];
    
    [super dealloc];
}

-(instancetype)initWithType:(enum DetailType)type{
    myType = type;
    NSString *nib = @"";
    
    if(type == DetailTypePeople){
        nib = @"PinDetailViewControllerFriend";
    }else if(type == DetailTypeCCTV){
        nib = @"PinDetailViewControllerCCTV";
    }else if(type == DetailTypeReport){
        nib = @"PinDetailViewControllerReport";
    }
    
    self = [super initWithNibName:nib bundle:nil];
    
    if(self){
    
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
    if(myType == DetailTypePeople){
        reputation.backgroundColor = [UIColor clearColor];
        [friendButton setBackgroundImage:[Tools solidImageForColor:friendButton.backgroundColor withSize:friendButton.frame.size] forState:UIControlStateNormal];
        [friendButton setBackgroundImage:[Tools solidImageForColor:friendButton.backgroundColor withSize:friendButton.frame.size] forState:UIControlStateSelected];
        [friendButton setBackgroundImage:[Tools solidImageForColor:friendButton.superview.backgroundColor withSize:friendButton.frame.size] forState:UIControlStateDisabled];
        friendButton.layer.masksToBounds = YES;
        friendButton.layer.cornerRadius = .25 * friendButton.frame.size.height;
        
        [self loadFriendData];
    }else if(myType == DetailTypeCCTV){
        [cctvButton setBackgroundImage:[Tools solidImageForColor:cctvButton.backgroundColor withSize:cctvButton.frame.size] forState:UIControlStateNormal];
        cctvButton.layer.masksToBounds = YES;
        cctvButton.layer.cornerRadius = .25 * cctvButton.frame.size.height;
    }else if(myType == DetailTypeReport){
        [reportTag setBackgroundImage:[Tools solidImageForColor:reportTag.backgroundColor withSize:reportTag.frame.size] forState:UIControlStateNormal];
        [reportTag setBackgroundImage:[Tools solidImageForColor:[UIColor darkGrayColor] withSize:reportTag.frame.size] forState:UIControlStateDisabled];
        reportTag.layer.masksToBounds = YES;
        reportTag.layer.cornerRadius = .25 * reportTag.frame.size.height;
        
        [retag setBackgroundImage:[Tools solidImageForColor:retag.backgroundColor withSize:retag.frame.size] forState:UIControlStateNormal];
        [retag setBackgroundImage:[Tools solidImageForColor:[UIColor darkGrayColor] withSize:retag.frame.size] forState:UIControlStateDisabled];
        retag.layer.masksToBounds = YES;
        retag.layer.cornerRadius = .25 * retag.frame.size.height;
        
        avatar.layer.masksToBounds = YES;
        avatar.layer.cornerRadius = .25 * avatar.frame.size.height;
        avatar.layer.borderColor = [UIColor blackColor].CGColor;
        avatar.layer.borderWidth = 1.;
        avatar.backgroundColor = [UIColor whiteColor];
    }
    NSLog(@"%@", self.data);
    [self updateView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions
-(void)updateView{
    if(myType == DetailTypePeople){
        reputation.backgroundColor = [UIColor clearColor];
        
        name.text = [[self.data valueForKey:@"Name"] capitalizedString];
        level.text = [self.data valueForKey:@"Poinlevel"];
        level.text = level.text.length < 1?@"Newbie":level.text;
        point.point = [[self.data valueForKey:@"Poin"] integerValue];
        reputation.reputation = [[self.data valueForKey:@"Reputation"] integerValue];
        avatar.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", [[self.data valueForKey:@"AvatarID"] integerValue]]];
        
        NSDictionary *rel = [self.data valueForKey:@"RelationInfo"];
        if([rel isKindOfClass:[NSDictionary class]]){
            NSInteger relStatus = [[rel valueForKey:@"Status"] integerValue];
            
            friendButton.selected = relStatus == 1;
            friendButton.enabled = relStatus == 2;
            
            [friendButton setTitle:[[self.data valueForKey:@"IsRequest"] boolValue]?@"Confirm Friend":@"Pending Friend" forState:UIControlStateSelected];
            friendButton.tag = [[self.data valueForKey:@"IsRequest"] boolValue]?0:-1;
        }else{
            friendButton.selected = NO;
            friendButton.enabled = YES;
        }
        
        if(friendButton.enabled){
            [friendButton setTitleEdgeInsets:UIEdgeInsetsZero];
        }else{
            [friendButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 25., 0, 0)];
        }
    }else if(myType == DetailTypeCCTV){
        name.text = [self.data valueForKey:@"Name"];
        city.text = [self.data valueForKey:@"City"];
        province.text = [self.data valueForKey:@"Province"];
        
        ASIHTTPRequest *req = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:[self.data valueForKey:@"Screenshot"]]];
        req.tag = 3;
        req.delegate = self;
        [queue addOperation:req];
    }else if(myType == DetailTypeReport){
        name.text = [self.data valueForKey:@"TypeName"];
        avatar.image = [UIImage imageNamed:[NSString stringWithFormat:@"menu-post-sub-%02zd", [[self.data valueForKey:@"Type"] integerValue]]];
        reporter.text = [[self.data valueForKey:@"PostBy"] capitalizedString];
        time.dateString = [self.data valueForKey:@"Time"];
        info.text = [self.data valueForKey:@"Description"];
        
        [info sizeToFit];
        CGRect f = info.frame;
        f.size.height = MIN(36., f.size.height);
        info.frame = f;
    }
}

-(void)loadFriendData{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?UserID=%@", kURLGetProfile, [self.data valueForKey:@"ID"]]]];
    request.delegate = self;
    [queue addOperation:request];
}

-(void)addFriend:(UIButton *)sender{
    if(sender.tag < 0)return;
    
    if(!sender.selected){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLRelationRequest]];
        [request addPostValue:[self.data valueForKey:@"ID"] forKey:@"ReceiverID"];
        request.delegate = self;
        request.tag = 1;
        [queue addOperation:request];
    }else{
        NSDictionary *dict = [self.data valueForKey:@"RelationInfo"];
        
        if([dict isKindOfClass:[NSDictionary class]]){
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLRelationAccept]];
            [request addPostValue:[dict valueForKey:@"RelationID"] forKey:@"RelationID"];
            request.delegate = self;
            request.tag = 2;
            [queue addOperation:request];
        }
    }
}

-(void)watch:(id)sender{
    NSURL *url = [NSURL URLWithString:[self.data valueForKey:@"Video"]];
    MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [[AppDelegate currentDelegate].window.rootViewController presentMoviePlayerViewControllerAnimated:player];
    [player release];
}

-(void)reportTag:(id)sender{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"This tag is invalid?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Report" otherButtonTitles:nil];
    [sheet showInView:[AppDelegate currentDelegate].window];
}

-(void)retag:(id)sender{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLPostRetag]];
    [request addPostValue:[self.data valueForKey:@"ID"] forKey:@"PostID"];
    request.tag = 4;
    request.delegate = self;
    [queue addOperation:request];
}

-(void)showImage:(id)sender{
    UIImageView *img = [[UIImageView alloc] initWithFrame:[self.view.superview.superview convertRect:avatar.frame fromView:avatar.superview]];
    img.image = avatar.image;
    
    XHImageViewer *imageViewer = [[XHImageViewer alloc] init];
    imageViewer.delegate = self;
    [imageViewer showWithImageViews:@[img] selectedView:img];
    
    [img release];
}

#pragma mark - delegate XHImageViewer
-(void)imageViewer:(XHImageViewer *)imageViewer didDismissWithSelectedView:(UIImageView *)selectedView{
    [imageViewer removeFromSuperview];
    [selectedView removeFromSuperview];
    [imageViewer release];
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    [loading startAnimating];
    
    if(request.tag == 4 || request.tag == 5){
        if(!self.mloading){
            self.mloading = [MBProgressHUD showHUDAddedTo:[AppDelegate currentDelegate].window animated:YES];
            self.mloading.labelText = @"Loading..";
            self.mloading.delegate = self;
        }
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading stopAnimating];
    [self.mloading hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [loading stopAnimating];
    [self.mloading hide:YES];
    
    if(request.tag == 3){
        avatar.image = [UIImage imageWithData:request.responseData];
        imgButton.enabled = YES;
        return;
    }
    
    NSLog(@"\n==========\ndetail %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [[request.responseString stringByReplacingOccurrencesOfString:@"null" withString:@"\"\""] JSONValue];
    if([[root valueForKey:@"success"] boolValue]){
        if(request.tag == 0){
            self.data = [root valueForKey:@"Profile"];
            [self updateView];
        }else if(request.tag == 1 || request.tag == 2){
            NSMutableDictionary *profile = [root valueForKey:@"Profile"];
            NSMutableDictionary *rel = [root valueForKey:@"Relation"];
            [profile setValue:rel forKey:@"RelationInfo"];
            self.data = profile;
            [self updateView];
        }else if(request.tag == 4){
            retag.enabled = NO;
        }else if(request.tag == 5){
            reportTag.enabled = NO;
        }
    }
}

#pragma mark - delegate loading
-(void)hudWasHidden:(MBProgressHUD *)hud{
    self.mloading = nil;
}

#pragma mark - Actions sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLPostReport]];
        [request addPostValue:[self.data valueForKey:@"ID"] forKey:@"PostID"];
        request.tag = 5;
        request.delegate = self;
        [queue addOperation:request];
    }
    [actionSheet release];
}


@end
