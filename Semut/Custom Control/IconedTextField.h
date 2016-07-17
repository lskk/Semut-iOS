//
//  IconedTextField.h
//  Skata
//
//  Created by Asep Mulyana on 4/1/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, IconedTextFieldIconType) {
    IconedTextFieldIconTypeEmail,
    IconedTextFieldIconTypePassword,
    IconedTextFieldIconTypeAccount,
    IconedTextFieldIconTypePhone,
    IconedTextFieldIconTypeDate
};

@interface IconedTextField : UITextField

@property (nonatomic) IconedTextFieldIconType type;

@end
