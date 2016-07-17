//
//  TiledMenuItem.h
//  Skata
//
//  Created by Asep Mulyana on 4/6/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TiledMenuItem : UIButton

@property (nonatomic, unsafe_unretained) NSString *title;
@property (nonatomic, unsafe_unretained) UIImage *icon;
@property (nonatomic) NSInteger level;

@end
