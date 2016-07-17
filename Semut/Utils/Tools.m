//
//  Tools.m
//  Federal Oil
//
//  Created by Asep Mulyana on 5/21/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import "Tools.h"
#import <QuartzCore/QuartzCore.h>
#import <EventKit/EventKit.h>

@implementation Tools

+(UIImage *)solidImageForColor:(UIColor *)color withSize:(CGSize)size{
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [color CGColor]);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

+(NSData *)dataForImage:(UIImage *)image{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1., -1);
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *data = UIImageJPEGRepresentation(newImage, 1.);
//    NSData *data = UIImagePNGRepresentation(newImage);
    return data;
}

+(UIImage *)createScreenshot:(id)target{
    UIView *view = (UIView *)target;
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

+(NSArray *)decodeRouteGeometry:(NSString *)geometri{
    double precision = pow(10, -6);
    int len = geometri.length, index=0;
    double lat=0, lng = 0;
    
    NSMutableArray *array = [NSMutableArray array];
    while (index < len) {
        int b, shift = 0, result = 0;
        do {
            b = [geometri characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        double dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do {
            b = [geometri characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        double dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        
        NSDictionary *dict = @{@"latitude": [NSNumber numberWithDouble:lat * precision], @"longitude": [NSNumber numberWithDouble:lng * precision]};
        
        [array addObject:dict];
    }
    
    return array;
}

@end
