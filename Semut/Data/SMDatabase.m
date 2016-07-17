//
//  SMDatabase.m
//  Simple Health
//
//  Created by Asep Mulyana on 12/7/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import "SMDatabase.h"
#import "SMUserLocation.h"

@implementation SMDatabase

+(NSString *)dataFilePath{
    NSArray *pahts = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [pahts objectAtIndex:0];
    return [docDir stringByAppendingPathComponent:@"Semutdata.sq3"];
}

+(BOOL)databaseFileIsExist{
    return [[NSFileManager defaultManager] fileExistsAtPath:[SMDatabase dataFilePath]];
}

+(sqlite3 *)openDatabase{
    sqlite3 *database;
    if(sqlite3_open([[SMDatabase dataFilePath] UTF8String], &database) != SQLITE_OK){
        NSLog(@"Error open database");
        return nil;
    }
    return database;
}

+(void)closeDatabase:(sqlite3 *)db{
    sqlite3_close(db);
}

+(void)writeDatabase:(NSData *)data{
    [data writeToFile:[self dataFilePath] atomically:YES];
}

+(void)initiate{
    [SMUserLocation initiateTable];
}

@end
