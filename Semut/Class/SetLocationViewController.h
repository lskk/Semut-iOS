//
//  SetLocationViewController.h
//  Logbook
//
//  Created by Asep Mulyana on 10/31/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class SetLocationViewController;

@protocol SetLocationViewControllerDelegate <NSObject>

-(void)setLocationDidConfirmed:(SetLocationViewController *)sender;
-(void)setLocationDidCancel:(SetLocationViewController *)sender;

@end

@interface SetLocationViewController : UIViewController

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) NSString *placeTitle;
@property (nonatomic, unsafe_unretained) id<SetLocationViewControllerDelegate>delegate;

@end
