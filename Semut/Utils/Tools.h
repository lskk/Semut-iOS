//
//  Tools.h
//  Federal Oil
//
//  Created by Asep Mulyana on 5/21/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tools : NSObject

+(UIImage *)solidImageForColor:(UIColor *)color withSize:(CGSize)size;
+(NSData *)dataForImage:(UIImage *)image;
+(UIImage *)createScreenshot:(id)target;
+(NSArray *)decodeRouteGeometry:(NSString *)geometri;


@end
