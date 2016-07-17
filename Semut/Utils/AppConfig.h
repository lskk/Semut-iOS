//
//  AppConfig.h
//  Federal Oil
//
//  Created by Asep Mulyana on 5/28/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

#define USE_PRODUCTION_API                  0
#define AUTH_API                            @"SEMUT_IOS"

#if USE_PRODUCTION_API

    #define kURLMain                        @""

#else

    #define kURLMain                        @"http://bsts-svc.lskk.ee.itb.ac.id/dev/api/"

#endif

#define kURLLogin                       kURLMain @"users/signin"
#define kURLLoginFB                     kURLMain @"users/fbsignin"
#define kURLSignUp                      kURLMain @"users/signup"
#define kURLSignUpFB                    kURLMain @"users/registerfb"
#define kURLResetPassword               kURLMain @"users/resetpass"
#define kURLRelationSearch              kURLMain @"users/search"
#define kURLSetPushToken                kURLMain @"users/setnotif"
#define kURLMyProfile                   kURLMain @"users/myprofile"
#define kURLSetVisibility               kURLMain @"users/setvisibility"
#define kURLSetAvatar                   kURLMain @"users/setavatar"
#define kURLGetProfile                  kURLMain @"users/userprofile"
#define kURLPostRetag                   kURLMain @"post/retag"
#define kURLPostReport                  kURLMain @"post/reporttag"

#define kURLTaxiOrder                   kURLMain @"taxi/reservation"
#define kURLTaxiCheckTaker              kURLMain @"taxi/cektaker"
#define kURLTaxiConfirm                 kURLMain @"taxi/sendmark"
#define kURLTaxiCancel                  kURLMain @"taxi/cancelrequest"
#define kURLTaxiGetLocation             kURLMain @"taxi/taxilocation"
#define kURLTaxiRate                    kURLMain @"taxi/rate"
#define kURLTaxiReservationHistory      kURLMain @"taxi/reservationhistory"

#define kURLLocationStore               kURLMain @"location/store"

#define kURLCCTV                        kURLMain @"cctv/list/CityID/%@"
#define kURLRelation                    kURLMain @"friend/friendlist"
#define kURLRelationRequest             kURLMain @"friend/request"
#define kURLRelationAccept              kURLMain @"friend/accept"
#define kURLRelationIgnore              kURLMain @"relation/ignore.php"
#define kURLRelationRemove              kURLMain @"relation/remove.php"
#define kURLMapView                     kURLMain @"location/mapview"
#define kURLLocationStore               kURLMain @"location/store"
#define kURLPost                        kURLMain @"post/submit"

#define IS_IOS_7                        ([[UIDevice currentDevice].systemVersion floatValue] >= 7.)

#define SemutLocationUpdateNotification     @"id.ac.itb.lskk.semut.SemutLocationUpdateNotification"
#define SemutRelationUpdateNotification     @"id.ac.itb.lskk.semut.SemutRelationUpdateNotification"
#define SemutLoginStateUpdateNotification   @"id.ac.itb.lskk.semut.SemutLoginStateUpdateNotification"

NS_ENUM(NSUInteger, LoginForward){
    LoginForwardNone,
    LoginForwardNotification,
    LoginForwardFriends
};

typedef enum {
    FontRegular,
    FontCondensed,
    FontButtonKotak,
    FontLight
} AppFont;

static inline UIFont* FONT(AppFont type, CGFloat size){
    UIFont *font = [UIFont fontWithName:@"LeagueGothic-CondensedRegular" size:size];
    switch (type) {
        case FontRegular:{
            font = [UIFont fontWithName:@"LeagueGothic-Regular" size:size];
        }
            break;
        case FontCondensed:{
            font = [UIFont fontWithName:@"LeagueGothic-CondensedRegular" size:size];
        }
            break;
        case FontButtonKotak:{
            font = [UIFont fontWithName:@"Gotham-Medium" size:size];
        }
            break;
        case FontLight:{
            font = [UIFont fontWithName:@"Gotham-Book" size:size];
        }
            break;
            
        default:{
        }
            break;
    }
    
    return font;
}

@interface AppConfig : NSObject

+(AppConfig *)sharedConfig;
+(NSString *)createUUID;

-(void)requestTwitterAccountWithCompletion:(void (^)(BOOL, ACAccount *))completion;
-(UIImage *)avatarForCode:(NSString *)code;

@property (nonatomic, retain) NSString *deviceIdentifier;
@property (nonatomic, retain) NSString *latitude;
@property (nonatomic, retain) NSString *longitude;

@property (nonatomic, unsafe_unretained) NSString *userID;
@property (nonatomic, unsafe_unretained) NSString *sessionID;
@property (nonatomic, unsafe_unretained) NSString *fullname;
@property (nonatomic, unsafe_unretained) NSDictionary *loginInfo;
@property (nonatomic, unsafe_unretained) ACAccount *twAccount;

@property (nonatomic, unsafe_unretained) NSArray *promoArray;
@property (nonatomic, unsafe_unretained) NSDate *promoDontShowUntilDate;
@property (nonatomic, readonly) NSArray *validPromoArray;

@property (nonatomic) BOOL menuNeedRefresh;
@property (nonatomic, retain) NSString *pushToken;
@property (nonatomic, retain) NSString *defaultMenuID;

@property (nonatomic) BOOL publishMode;

@property (nonatomic, retain) NSMutableArray *relationSent;
@property (nonatomic, retain) NSMutableArray *relationReceive;
@property (nonatomic, retain) NSMutableArray *relations;

@end
