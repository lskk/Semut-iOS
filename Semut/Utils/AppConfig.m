//
//  AppConfig.m
//  Federal Oil
//
//  Created by Asep Mulyana on 5/28/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import "AppConfig.h"
#import <CoreLocation/CoreLocation.h>
#import <Accounts/Accounts.h>
#import "JSON.h"
#import "SMUserLocation.h"

static AppConfig *sharedObject = nil;

@interface AppConfig()<CLLocationManagerDelegate>{
    CLLocationManager *locationManager;
    NSInteger locationUpdateCounter;
}

@property (nonatomic, retain) NSDate *lastHit;

@end


@implementation AppConfig

@synthesize deviceIdentifier, latitude, longitude;
@synthesize userID, sessionID;
@synthesize lastHit;
@synthesize twAccount;
@synthesize pushToken;
@synthesize menuNeedRefresh;
@synthesize defaultMenuID;
@synthesize fullname;
@synthesize publishMode;
@synthesize promoArray, validPromoArray;
@synthesize promoDontShowUntilDate;
@synthesize relations, relationReceive, relationSent;

+(AppConfig *)sharedConfig{
    if(sharedObject == nil){
        sharedObject = [[AppConfig alloc] init];
    }
    
    return sharedObject;
}

+(NSString *)createUUID{
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    return [uuidString autorelease];
}

#pragma  mark -
-(void)dealloc{
    [deviceIdentifier release];
    [latitude release];
    [longitude release];
    [lastHit release];
    self.pushToken = nil;
    self.relationSent = nil;
    self.relationReceive = nil;
    self.relations = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.latitude = @"-6.890362";
        self.longitude = @"107.609907";
        self.lastHit = [NSDate dateWithTimeIntervalSince1970:0];
        self.menuNeedRefresh = YES;
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
            [locationManager requestAlwaysAuthorization];
        }
        locationManager.distanceFilter = 100.;
        [locationManager startUpdatingLocation];
    }
    return self;
}

-(NSString *)deviceIdentifier{
    NSString *device = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceIdentifier"];
    
    if(device == nil){
        if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]){
            device = [UIDevice currentDevice].identifierForVendor.UUIDString;
        }else{
            device = [AppConfig createUUID];
        }
//        device = [device stringByReplacingOccurrencesOfString:@"-" withString:@""];
        self.deviceIdentifier = device;
    }
    
    return device;
}

-(void)setDeviceIdentifier:(NSString *)_deviceIdentifier{
    [[NSUserDefaults standardUserDefaults] setValue:_deviceIdentifier forKey:@"deviceIdentifier"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - delegate Location Manager
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    NSLog(@"location %@", newLocation);
    
    [locationManager stopUpdatingLocation];
    [locationManager performSelector:@selector(startUpdatingLocation) withObject:nil afterDelay:5.];
    
    self.latitude = [NSString stringWithFormat:@"%lf", newLocation.coordinate.latitude];
    self.longitude = [NSString stringWithFormat:@"%lf", newLocation.coordinate.longitude];
    [[NSNotificationCenter defaultCenter] postNotificationName:SemutLocationUpdateNotification object:newLocation];
    
    locationUpdateCounter += 1;
    
    if(locationUpdateCounter >= 6){
        locationUpdateCounter = 0;
        
        if(self.sessionID.integerValue > 0){
            SMUserLocationRecord *record = [[SMUserLocationRecord alloc] init];
            record.altitude = newLocation.altitude;
            record.latitude = newLocation.coordinate.latitude;
            record.longitude = newLocation.coordinate.longitude;
            record.speed = newLocation.speed;
            record.date = [NSDate date];
            
            [[SMUserLocation sharedData] addRecord:record];
            
            [record release];
        }
    }
}

#pragma custom property

-(void)setUserID:(NSString *)newuserID{
    if(newuserID){
        [[NSUserDefaults standardUserDefaults] setValue:newuserID forKey:@"userID"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userID"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)userID{
    NSString *usr = [[NSUserDefaults standardUserDefaults] valueForKey:@"userID"];
    
    if(usr == nil){
        return @"";
    }
    
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"userID"];
}

-(NSString *)sessionID{
    NSString *session = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionID"];
    
    if(session == nil){
        session = @"0";
    }
    
    return session;
}

-(void)setSessionID:(NSString *)newsessionID{
    if(newsessionID){
        [[NSUserDefaults standardUserDefaults] setValue:newsessionID forKey:@"sessionID"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionID"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)fullname{
    NSString *session = [[NSUserDefaults standardUserDefaults] valueForKey:@"fullname"];
    
    if(session == nil){
        session = @"";
    }
    
    return session;
}

-(void)setFullname:(NSString *)_fullname{
    if(_fullname){
        [[NSUserDefaults standardUserDefaults] setValue:_fullname forKey:@"fullname"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fullname"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)defaultMenuID{
    NSString *d = [[NSUserDefaults standardUserDefaults] valueForKey:@"menuIDDef"];
    
    if(d == nil){
        d = @"";
    }
    
    return d;
}

-(void)setDefaultMenuID:(NSString *)_defaultMenuID{
    if(_defaultMenuID){
        [[NSUserDefaults standardUserDefaults] setValue:_defaultMenuID forKey:@"menuIDDef"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"menuIDDef"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(ACAccount *)twAccount{
    NSString *accID = [[NSUserDefaults standardUserDefaults] valueForKey:@"twAccount"];
    
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccount *acc = [account accountWithIdentifier:accID];
    ACAccountType *account_type_twitter = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    acc.accountType = account_type_twitter;
    [account release];
    
    return acc;
}

-(void)setTwAccount:(ACAccount *)newtwAccount{
    if(newtwAccount){
        [[NSUserDefaults standardUserDefaults] setValue:newtwAccount.identifier forKey:@"twAccount"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"twAccount"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDictionary *)loginInfo{
    NSDictionary *info = [[[NSUserDefaults standardUserDefaults] valueForKey:@"logininfo"] JSONValue];
    return info;
}

-(void)setLoginInfo:(NSDictionary *)_loginInfo{
    if(_loginInfo){
        [[NSUserDefaults standardUserDefaults] setValue:[_loginInfo JSONRepresentation] forKey:@"logininfo"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"logininfo"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(NSArray *)promoArray{
    NSArray *info = [[NSUserDefaults standardUserDefaults] valueForKey:@"promoArray"];
    
    if(info == nil){
        return [NSArray array];
    }
    
    return info;
}

-(void)setPromoArray:(NSArray *)_promoArray{
    if(_promoArray){
        [[NSUserDefaults standardUserDefaults] setValue:_promoArray forKey:@"promoArray"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"promoArray"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(NSArray *)validPromoArray{
    NSMutableArray *arr = [NSMutableArray array];
    NSArray *promos = [self promoArray];
    
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"yyyy-MM-dd"];
    for(NSDictionary *dict in promos){
        NSDate *sdate = [format dateFromString:[dict valueForKey:@"sdate"]];
        NSDate *edate = [format dateFromString:[dict valueForKey:@"edate"]];
        
        if([sdate timeIntervalSinceNow] / (60*60.*24.) <= 0 && [edate timeIntervalSinceNow] >= 0 / (60*60.*24.)){
            [arr addObject:dict];
        }
    }
    
    return arr;
}

-(NSDate *)promoDontShowUntilDate{
    NSDate *info = [[NSUserDefaults standardUserDefaults] valueForKey:@"promoDontShowUntilDate"];
    
    if(info == nil){
        return [NSDate dateWithTimeIntervalSinceNow:-60*60];
    }
    
    return info;
}

-(void)setPromoDontShowUntilDate:(NSDate *)_promoDontShowUntilDate{
    if(_promoDontShowUntilDate){
        [[NSUserDefaults standardUserDefaults] setValue:_promoDontShowUntilDate forKey:@"promoDontShowUntilDate"];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"promoDontShowUntilDate"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

#pragma mark - implement method
-(void)requestTwitterAccountWithCompletion:(void (^)(BOOL, ACAccount *))completion{
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    // Request access from the user to use their Twitter accounts.
    [account requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             // Populate array with all available Twitter accounts
             NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
             
             if(arrayOfAccounts.count < 1){
                 completion(NO, nil);
             }else{
                 ACAccount *acc = [arrayOfAccounts lastObject];
                 [AppConfig sharedConfig].twAccount = acc;
                 completion(YES, acc);
                 
             }
         }else{
             completion(NO, nil);
         }
         
         [account release];
         NSLog(@"minta permisi twitter selesai");
     }];
}

-(UIImage *)avatarForCode:(NSString *)code{
    return [UIImage imageNamed:[NSString stringWithFormat:@"post-bg-%@", code]];
}

@end