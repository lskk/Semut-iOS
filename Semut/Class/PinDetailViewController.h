//
//  PinDetailViewController.h
//  Semut
//
//  Created by Asep Mulyana on 5/15/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ENUM(NSUInteger, DetailType){
    DetailTypePeople,
    DetailTypeCCTV,
    DetailTypeReport
};

@interface PinDetailViewController : UIViewController

-(instancetype)initWithType:(enum DetailType)type;

@property (nonatomic, retain) NSDictionary *data;

@end
