//
//  SMUserLocation.m
//  OneTouch
//
//  Created by asepmoels on 1/2/13.
//  Copyright (c) 2013 Better-B. All rights reserved.
//

#import "SMDatabase.h"
#import "SMUserLocation.h"
#import "JSON.h"
#import "ASIHTTPRequest+Semut.h"

static SMUserLocation *sharedData = nil;

@interface SMUserLocation(){
}

@end

@implementation SMUserLocation

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

-(void)addRecord:(SMUserLocationRecord *)record{
    NSLog(@"add user location record");
    sqlite3 *database = [SMDatabase openDatabase];
    
    if(database != nil){
        NSString *query = @"INSERT INTO userlocation VALUES(?, ?, ?, ?, ?, ?);";
        sqlite3_stmt *statement = nil;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            sqlite3_bind_double(statement, 2, [record.date timeIntervalSinceReferenceDate]);
            sqlite3_bind_double(statement, 3, record.altitude);
            sqlite3_bind_double(statement, 4, record.latitude);
            sqlite3_bind_double(statement, 5, record.longitude);
            sqlite3_bind_double(statement, 6, record.speed);
        }
        int kode = sqlite3_step(statement);
        if(kode != SQLITE_DONE)
            NSLog(@"Error ketika menambah user loc %d", kode);
        sqlite3_finalize(statement);
    }
    
    [SMDatabase closeDatabase:database];
    
    [self sync];
}

-(NSMutableArray *)get10Data{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database = [SMDatabase openDatabase];
    
    if(database != nil){
        NSString *query = @"SELECT * FROM userlocation ORDER BY tgl ASC LIMIT 10;";
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            
            while(sqlite3_step(statement) == SQLITE_ROW){
                NSInteger _id = sqlite3_column_int(statement, 0);
                double tgl = sqlite3_column_double(statement, 1);
                double alt = sqlite3_column_double(statement, 2);
                double lat = sqlite3_column_double(statement, 3);
                double lon = sqlite3_column_double(statement, 4);
                double spe = sqlite3_column_double(statement, 5);
                
                SMUserLocationRecord *add = [[SMUserLocationRecord alloc] init];
                add.idRecord = _id;
                add.date = [NSDate dateWithTimeIntervalSinceReferenceDate:tgl];
                add.altitude = alt;
                add.latitude = lat;
                add.longitude = lon;
                add.speed = spe;
            
                [data addObject:add];
                [add release];
            }
        }
        sqlite3_finalize(statement);
    }
    
    [SMDatabase closeDatabase:database];
    
    return data;
}

-(void)deleteUserLocation:(SMUserLocationRecord *)record{
    sqlite3 *database = [SMDatabase openDatabase];
    
    if(database != nil){
        NSString *query = @"DELETE FROM userlocation WHERE id=?;";
        sqlite3_stmt *statement = nil;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            sqlite3_bind_int(statement, 1, record.idRecord);
        }
        int kode = sqlite3_step(statement);
        if(kode != SQLITE_DONE)
            NSLog(@"Error ketika menghapus userloc %d", kode);
        sqlite3_finalize(statement);
    }
    
    [SMDatabase closeDatabase:database];
}

-(void)sync{
    NSMutableArray *arr = [self get10Data];
    if(arr.count >= 10){
        NSMutableArray *data = [NSMutableArray array];
        for(SMUserLocationRecord *record in arr){
            [data addObject:record.dictionary];
        }
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithSemutURL:[NSURL URLWithString:kURLLocationStore]];
        [request addPostValue:[data JSONRepresentation] forKey:@"Location"];
        [request setCompletionBlock:^{
            NSLog(@"Sync %@ %@", request.url.absoluteString, request.responseString);
            NSDictionary *root = [request.responseString JSONValue];
            if([[root valueForKey:@"success"] boolValue]){
                for(SMUserLocationRecord *record in arr){
                    [self deleteUserLocation:record];
                }
            }
        }];
        [request setFailedBlock:^{
            NSLog(@"Sync failed");
        }];
        [request startAsynchronous];
    }
}

// class method

+(void)initiateTable{
    char *error;
    sqlite3 *database = [SMDatabase openDatabase];
    NSString *createUser = @"CREATE TABLE IF NOT EXISTS userlocation (id INTEGER PRIMARY KEY AUTOINCREMENT, tgl DOUBLE, altitude DOUBLE, latitude DOUBLE, longitude DOUBLE, speed DOUBLE);";
    if(sqlite3_exec(database, [createUser UTF8String], NULL, NULL, &error) != SQLITE_OK){
        NSLog(@"Error ketika membuat tabel location %s", error);
    }
    [SMDatabase closeDatabase:database];
}

+(SMUserLocation *)sharedData{
    if(sharedData == nil){
        sharedData = [[SMUserLocation alloc] init];
    }
    return sharedData;
}

@end


@implementation SMUserLocationRecord

@synthesize date, latitude, longitude, altitude, speed, idRecord;

- (id)init
{
    self = [super init];
    if (self) {    }
    return self;
}

-(NSDictionary *)dictionary{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[format stringFromDate:self.date] forKey:@"Timespan"];
    [dict setValue:[NSNumber numberWithDouble:self.altitude] forKey:@"Altitude"];
    [dict setValue:[NSNumber numberWithDouble:self.latitude] forKey:@"Latitude"];
    [dict setValue:[NSNumber numberWithDouble:self.longitude] forKey:@"Longitude"];
    [dict setValue:[NSNumber numberWithDouble:self.speed] forKey:@"Speed"];
    
    [format release];
    
    return dict;
}

- (void)dealloc
{
    [date release];
    [super dealloc];
}

@end