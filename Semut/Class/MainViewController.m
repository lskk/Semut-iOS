//
//  MainViewController.m
//  Semut
//
//  Created by Asep Mulyana on 4/29/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "MainViewController.h"
#import "MenuViewController.h"
#import "RouteMe.h"
#import "RMOpenStreetMapSource.h"
#import "ASIHTTPRequest+Semut.h"
#import "JSON.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MapFilterViewController.h"
#import "PostViewController.h"
#import "ReputationView.h"
#import "PointLabel.h"
#import "SettingsViewController.h"
#import "PinDetailViewController.h"

typedef enum {
    TypeMarkerSendiri,
    TypeMarkerTeman,
    TypeMarkerCamera,
    TypeMarkerPolisi,
    TypeMarkerAccident,
    TypeMarkerTraffic,
    TypeMarkerOther
} TypeMarker;

@interface MainViewController ()<RMMapViewDelegate>{
    IBOutlet RMMapView *mapView;
    IBOutlet UIView *menuContainer;
    IBOutlet UIView *detailContainer;
    IBOutlet UILabel *name;
    IBOutlet PointLabel *points;
    IBOutlet ReputationView *reputation;
    IBOutlet UIImageView *avatar;
    
    BOOL autoBackToMyLocation;
    BOOL continueMakeRequest;
}

-(IBAction)showMenu:(id)sender;
-(IBAction)moveToMyLocation:(id)sender;
-(IBAction)showFilter:(id)sender;
-(IBAction)settings:(id)sender;

@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) UINavigationController *postController;
@property (nonatomic, retain) PinDetailViewController *detail;

@end

@implementation MainViewController

@synthesize menu, filter;
@synthesize queue, timer, coordinate;
@synthesize postController;
@synthesize detail;

- (void)dealloc
{
    [menu release];
    [filter release];
    [postController release];
    [detail release];
    
    for(ASIHTTPRequest *req in self.queue.operations){
        req.delegate = nil;
        [req cancel];
    }
    [queue release];
    
    [timer invalidate];
    [timer release];
    self.timer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStateUpdated) name:SemutLoginStateUpdateNotification object:nil];
    
    autoBackToMyLocation = YES;
    continueMakeRequest = YES;
    
    self.queue = [[[NSOperationQueue alloc] init] autorelease];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5. target:self selector:@selector(makeRequest) userInfo:nil repeats:YES];
    
    id myTilesource = [[RMOpenStreetMapSource alloc] init];
    id content = [[RMMapContents alloc] initWithView:mapView tilesource:myTilesource];
    [myTilesource release];
    [content release];
    
    mapView.delegate = self;
    
    self.coordinate = CLLocationCoordinate2DMake([[AppConfig sharedConfig].latitude doubleValue], [[AppConfig sharedConfig].latitude doubleValue]);
    
    MenuViewController *newMenu = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    newMenu.navigationHandler = self.navigationController;
    self.menu = newMenu;
    [newMenu release];
    
    MapFilterViewController *mfilter = [[MapFilterViewController alloc] initWithNibName:@"MapFilterViewController" bundle:nil];
    self.filter = mfilter;
    self.filter.filterValue = 63;
    [mfilter release];
    
    PostViewController *post = [[PostViewController alloc] initWithNibName:@"PostViewController" bundle:nil];
    UINavigationController *postNav = [[UINavigationController alloc] initWithRootViewController:post];
    postNav.navigationBarHidden = YES;
    self.postController = postNav;
    [postNav release];
    [post release];
    
    self.postController.view.frame = menuContainer.bounds;
    [menuContainer addSubview:self.postController.view];
    menuContainer.backgroundColor = [UIColor colorWithWhite:1. alpha:0.75];
    menuContainer.transform = CGAffineTransformMakeTranslation(0, 300.);
    menuContainer.layer.cornerRadius = 10.;
    menuContainer.layer.masksToBounds = YES;
    menuContainer.layer.borderColor = [UIColor colorWithRed:0x11/255. green:0x5b/255. blue:0x81/255. alpha:1.].CGColor;
    menuContainer.layer.borderWidth = 2.;
    
    detailContainer.transform = CGAffineTransformMakeTranslation(0, detailContainer.frame.size.height);
    name.superview.transform = CGAffineTransformMakeTranslation(0, -name.superview.frame.size.height);
    
    reputation.reputation = 250;
    reputation.backgroundColor = [UIColor clearColor];
    points.point = 1000;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if(autoBackToMyLocation){
        [self moveToMyPlace];
        autoBackToMyLocation = NO;
    }
    
    [self getProfile];
    continueMakeRequest = YES;
    [self updateProfileInfo];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    continueMakeRequest = NO;
}

#pragma mark - ACtions
-(void)showMenu:(id)sender{
    self.menu.view.frame = self.view.bounds;
    [self.menu prepareForAppear];
    [self.view addSubview:self.menu.view];
    [self.menu show];
}

-(void)moveToMyLocation:(id)sender{
    [self moveToMyPlace];
    
    [self performSelector:@selector(showPostMenu) withObject:nil afterDelay:0.3];
}

-(void)moveToMyPlace{
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[AppConfig sharedConfig].latitude doubleValue], [[AppConfig sharedConfig].longitude doubleValue]);
    
    [mapView moveToLatLong:location];
    
    if(autoBackToMyLocation){
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin-male"] anchorPoint:CGPointMake(0.5, 1.)] autorelease];
        marker.data = @{@"type":[NSNumber numberWithInt:TypeMarkerSendiri], @"id":@"0"};
        [mapView.contents.markerManager addMarker:marker AtLatLong:location];
    }
}

-(void)showFilter:(id)sender{
    self.filter.view.frame = self.view.bounds;
    [self.filter prepareForAppear];
    [self.view addSubview:self.filter.view];
    [self.filter show];
}

-(void)makeRequest{
    if(!continueMakeRequest)return;
    if(self.queue.operationCount > 1)return;
    
    CGFloat kmradius = mapView.contents.metersPerPixel * 0.5 * mapView.frame.size.height * [UIScreen mainScreen].scale / 1000.;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?Limit=10&Radius=%lf&Latitude=%lf&Longitude=%lf&Item=%zd", kURLMapView, kmradius,self.coordinate.latitude, self.coordinate.longitude, self.filter.filterValue]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithSemutURL:url];
    request.delegate = self;
    [self.queue addOperation:request];
}

-(void)addOrUpdateMarkerForType:(TypeMarker)type andID:(NSString *)_id toLocation:(CLLocationCoordinate2D)location withData:(NSDictionary *)data{
    RMMarker *marker = nil;
    
//    for(RMMarker *one in mapView.markerManager.markers){
//        NSDictionary *dict = (NSDictionary *)one.data;
//        if([[dict valueForKey:@"type"] integerValue] == type && [[dict valueForKey:@"id"] integerValue] == [_id integerValue]){
//            marker = one;
//            break;
//        }
//    }
    
    if(marker){
        [mapView.markerManager moveMarker:marker AtLatLon:location];
    }else{
        UIImage *imagePin = nil;
        
        if(type == TypeMarkerSendiri){
            imagePin = [UIImage imageNamed:@"pin-male"];
        }else if(type == TypeMarkerTeman){
            imagePin = ([[data valueForKey:@"Gender"] intValue] == 1)?[UIImage imageNamed:@"pin-male"]:[UIImage imageNamed:@"pin-female"];
        }else if(type == TypeMarkerCamera){
            imagePin = [UIImage imageNamed:@"pin-cctv"];
        }else if(type == TypeMarkerPolisi){
            imagePin = [UIImage imageNamed:@"pin-police"];
        }else if(type == TypeMarkerAccident){
            imagePin = [UIImage imageNamed:@"pin-caution"];
        }else if(type == TypeMarkerTraffic){
            imagePin = [UIImage imageNamed:@"pin-vlc"];
        }else if(type == TypeMarkerOther){
            imagePin = [UIImage imageNamed:@"pin-close"];
        }
        
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:imagePin anchorPoint:CGPointMake(0.5, 1.)] autorelease];
        marker.data = @{@"type":[NSNumber numberWithInt:type], @"id":_id, @"data":data};
        [mapView.contents.markerManager addMarker:marker AtLatLong:location];
    }
}

-(void)showPostMenu{
    [UIView animateWithDuration:0.3 animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)showDetailWithData:(NSDictionary *)data{
    enum DetailType type = DetailTypeReport;
    
    TypeMarker t = [[data valueForKey:@"type"] integerValue];
    if(t == TypeMarkerTeman){
        type = DetailTypePeople;
    }else if(t == TypeMarkerCamera){
        type = DetailTypeCCTV;
    }
    
    PinDetailViewController *pindetail = [[PinDetailViewController alloc] initWithType:type];
    self.detail = pindetail;
    [pindetail release];
    
    self.detail.data = [data valueForKey:@"data"];
    self.detail.view.frame = detailContainer.bounds;
    [detailContainer addSubview:self.detail.view];
    
    [UIView animateWithDuration:0.3 animations:^{
        detailContainer.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)hideDetail{
    [UIView animateWithDuration:0.3 animations:^{
        detailContainer.transform = CGAffineTransformMakeTranslation(0, detailContainer.frame.size.height);
    } completion:^(BOOL finished) {
        self.detail = nil;
    }];
}

-(void)getProfile{
    if([AppConfig sharedConfig].sessionID.intValue < 1){
        [self hideProfile];
        return;
    }
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithSemutURL:[NSURL URLWithString:kURLMyProfile]];
    request.tag = 1;
    request.delegate = self;
    [queue addOperation:request];
}

-(void)showProfile{
    [UIView animateWithDuration:0.3 animations:^{
        name.superview.transform = CGAffineTransformIdentity;
    }];
}

-(void)hideProfile{
    [UIView animateWithDuration:0.3 animations:^{
        name.superview.transform = CGAffineTransformMakeTranslation(0., -name.superview.frame.size.height);
    }];
}

-(void)settings:(id)sender{
    [self hideDetail];
    
    SettingsViewController *setting = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    [self.navigationController pushViewController:setting animated:YES];
    [setting release];
}

-(void)updateProfileInfo{
    NSDictionary *dict = [AppConfig sharedConfig].loginInfo;
    name.text = [[dict valueForKey:@"Name"] capitalizedString];
    points.point = [[dict valueForKey:@"Poin"] integerValue];
    reputation.reputation = [[dict valueForKey:@"Reputation"] integerValue];
    avatar.image = [[AppConfig sharedConfig] avatarForCode:[NSString stringWithFormat:@"%zd", [[dict valueForKey:@"AvatarID"] integerValue]]];
}

-(void)loginStateUpdated{
    if([AppConfig sharedConfig].sessionID.integerValue < 1){
        [self hideProfile];
    }else{
        [self getProfile];
        [self showProfile];
    }
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    NSLog(@"failed %@", request.error);
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSLog(@"\n==========\nmain %@ : %@\n\n", request.url.absoluteString, request.responseString);
    
    NSDictionary *root = [[request.responseString stringByReplacingOccurrencesOfString:@"null" withString:@"\"\""] JSONValue];
    
    if(![[root valueForKey:@"success"] boolValue])return;
    
    if(request.tag == 0){
        // bersih bersih marker lalu ditambahin ulang
        [mapView.contents.markerManager removeMarkers];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[AppConfig sharedConfig].latitude doubleValue], [[AppConfig sharedConfig].longitude doubleValue]);
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin-male"] anchorPoint:CGPointMake(0.5, 1.)] autorelease];
        marker.data = @{@"type":[NSNumber numberWithInt:TypeMarkerSendiri], @"id":@"0"};
        [mapView.contents.markerManager addMarker:marker AtLatLong:location];
        
        NSArray *arr = [root valueForKey:@"Users"];
        for(NSDictionary *dict in arr){
            NSString *uid = [dict valueForKey:@"ID"];
            
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);
            
            [self addOrUpdateMarkerForType:TypeMarkerTeman andID:uid toLocation:location withData:dict];
        }
        
        for(NSDictionary *dict in [root valueForKey:@"Cameras"]){
            NSString *uid = [dict valueForKeyPath:@"ID"];

            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);

            [self addOrUpdateMarkerForType:TypeMarkerCamera andID:uid toLocation:location withData:dict];
        }
        
        for(NSDictionary *dict in [root valueForKey:@"Polices"]){
            NSString *uid = [dict valueForKeyPath:@"ID"];
            
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);
            
            [self addOrUpdateMarkerForType:TypeMarkerPolisi andID:uid toLocation:location withData:dict];
        }
        
        for(NSDictionary *dict in [root valueForKey:@"Accidents"]){
            NSString *uid = [dict valueForKeyPath:@"ID"];
            
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);
            
            [self addOrUpdateMarkerForType:TypeMarkerAccident andID:uid toLocation:location withData:dict];
        }
        
        for(NSDictionary *dict in [root valueForKey:@"Traffics"]){
            NSString *uid = [dict valueForKeyPath:@"ID"];
            
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);
            
            [self addOrUpdateMarkerForType:TypeMarkerTraffic andID:uid toLocation:location withData:dict];
        }
        
        for(NSDictionary *dict in [root valueForKey:@"Others"]){
            NSString *uid = [dict valueForKeyPath:@"ID"];
            
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] doubleValue], [[dict valueForKey:@"Longitude"] doubleValue]);
            
            [self addOrUpdateMarkerForType:TypeMarkerOther andID:uid toLocation:location withData:dict];
        }
    }else if(request.tag == 1){
        NSDictionary *dict = [root valueForKey:@"Profile"];
        [AppConfig sharedConfig].loginInfo = dict;
        
        [self updateProfileInfo];
        [self showProfile];
    }
}

#pragma mark - delegate mapview
-(void)mapViewRegionDidChange:(RMMapView *)m{
    self.coordinate = m.contents.mapCenter;
}

-(void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map{
    NSDictionary *dict = (NSDictionary *)marker.data;
    
    NSInteger type = [[dict valueForKey:@"type"] integerValue];
    if(type == TypeMarkerSendiri)return;
    
    [self showDetailWithData:dict];
}

-(void)singleTapOnMap:(RMMapView *)map At:(CGPoint)point{
    if(CGAffineTransformIsIdentity(detailContainer.transform)){
        [self hideDetail];
    }
}

@end
