//
//  SMUserLocation.h
//  OneTouch
//
//  Created by asepmoels on 1/2/13.
//  Copyright (c) 2013 Better-B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class SMUserLocationRecord, SMUserLocation;

@interface SMUserLocation : NSObject
+(void)initiateTable;
+(SMUserLocation *)sharedData;

-(void)addRecord:(SMUserLocationRecord *)record;

@end

@interface SMUserLocationRecord : NSObject
@property (nonatomic) NSInteger idRecord;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic) CLLocationDegrees altitude;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) CLLocationDegrees speed;

-(NSDictionary *)dictionary;

@end