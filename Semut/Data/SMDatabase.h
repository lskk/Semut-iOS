//
//  SMDatabase.h
//  Simple Health
//
//  Created by Asep Mulyana on 12/7/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

#define kTableTextLocation               @"semut_location"

@interface SMDatabase : NSObject

+(void)initiate;
+(sqlite3 *)openDatabase;
+(void)closeDatabase:(sqlite3 *)db;
+(BOOL)databaseFileIsExist;
+(void)writeDatabase:(NSData *)data;

@end
