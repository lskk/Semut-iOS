//
//  SetLocationViewController.m
//  Logbook
//
//  Created by Asep Mulyana on 10/31/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SetLocationViewController.h"
#import "AppConfig.h"
#import <MapKit/MapKit.h>

@interface SetLocationViewController ()<MKAnnotation, MKMapViewDelegate, UITextFieldDelegate, UISearchBarDelegate>{
    IBOutlet MKMapView *map;
    IBOutlet UITextField *searchText;
    IBOutlet UILabel *infoLabel;
    IBOutlet UIButton *doneButton;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)save:(id)sender;

@end

@implementation SetLocationViewController

@synthesize placeTitle, delegate;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [placeTitle release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [map setCenterCoordinate:self.coordinate];
    [map addAnnotation:self];
    [self setZoom];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)setZoom{
    MKCoordinateRegion region = MKCoordinateRegionMake(self.coordinate, MKCoordinateSpanMake(0.1, 0.1));
    [map setRegion:region animated:YES];
}

-(NSString *)locationStringFromPLacemark:(CLPlacemark *)place{
    NSString *str = place.thoroughfare.length > 0?place.thoroughfare:@"";
    str = [str stringByAppendingString:@" "];
    str = [str stringByAppendingString:place.locality.length > 0?place.locality:@""];
    str = [str stringByAppendingString:@" "];
    str = [str stringByAppendingString:place.subLocality.length > 0?place.subLocality:@""];
    str = [str stringByAppendingString:@" "];
    str = [str stringByAppendingString:place.administrativeArea.length > 0?place.administrativeArea:@""];
    str = [str stringByAppendingString:@" "];
    str = [str stringByAppendingString:place.subAdministrativeArea.length > 0?place.subAdministrativeArea:@""];
    str = [str stringByAppendingString:@" "];
    
    NSLog(@"%@", str);
    return str;
}

#pragma mark - Observer keyboard
-(void)keyboardDidHide:(NSNotification *)sender{
    NSDictionary *info = sender.userInfo;
    NSTimeInterval duration = [[info valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];
    //CGRect toRect = [[info valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = map.frame;
    frame.size.height = self.view.frame.size.height - frame.origin.y;
    map.frame = frame;
    [UIView commitAnimations];
}

-(void)keyboardDidShow:(NSNotification *)sender{
    NSDictionary *info = sender.userInfo;
    NSTimeInterval duration = [[info valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] doubleValue];
    CGRect toRect = [[info valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = map.frame;
    frame.size.height = toRect.origin.y - frame.origin.y - (IS_IOS_7?0:20);
    map.frame = frame;
    [UIView commitAnimations];
}

#pragma mark - delegate map view
-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState{
    doneButton.enabled = NO;
    if(newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling){
        self.coordinate = [view.annotation coordinate];
        [self infoShow:@"Searching place name..."];
        
        CLGeocoder *coder = [[CLGeocoder alloc] init];
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude] autorelease];
        [coder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            NSString *position = @"Unknown Place Name";
            for(CLPlacemark *one in placemarks){
                if(one.locality.length > 0 && one.administrativeArea.length > 0){
                    NSString *placeName = [self locationStringFromPLacemark:one];
                    position = placeName;
                    break;
                }else if(one.subLocality.length > 0 && one.administrativeArea.length > 0){
                    NSString *placeName = [self locationStringFromPLacemark:one];
                    position = placeName;
                    break;
                }else if(one.administrativeArea.length > 0){
                    position = one.administrativeArea;
                    break;
                }
            }
            
            self.placeTitle = position;
            [self infoShow:position];
            [self performSelector:@selector(infoHide) withObject:nil afterDelay:2];
            
            [coder release];
            
            doneButton.enabled = YES;
        }];
    }else if(newState == MKAnnotationViewDragStateStarting){
        [self infoShow:@"Set Your Location"];
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    MKPinAnnotationView *annot = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myannot"];
    annot.animatesDrop = YES;
    annot.pinColor = MKPinAnnotationColorGreen;
    annot.draggable = YES;
    
    return [annot autorelease];
}

#pragma mark - delegate textfield
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if(searchBar.text.length < 1){
        return;
    }
    
    [searchBar resignFirstResponder];
    [self infoShow:@"Searching place..."];
    doneButton.enabled = NO;
    
    CLGeocoder *coder = [[CLGeocoder alloc] init];
    [coder geocodeAddressString:searchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if(placemarks.count > 0){
            CLPlacemark *place = [placemarks objectAtIndex:0];
            self.coordinate = place.location.coordinate;
            
            [self infoShow:@"Found"];
            [self setZoom];
            [self performSelector:@selector(infoHide) withObject:nil afterDelay:2];
            
            CLGeocoder *coder = [[CLGeocoder alloc] init];
            CLLocation *location = [[[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude] autorelease];
            [coder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
                NSString *position = @"Unknown place name";
                for(CLPlacemark *one in placemarks){
                    if(one.locality.length > 0 && one.administrativeArea.length > 0){
                        NSString *placeName = [self locationStringFromPLacemark:one];
                        position = placeName;
                        break;
                    }else if(one.subLocality.length > 0 && one.administrativeArea.length > 0){
                        NSString *placeName = [self locationStringFromPLacemark:one];
                        position = placeName;
                        break;
                    }else if(one.administrativeArea.length > 0){
                        position = one.administrativeArea;
                        break;
                    }
                }
                
                self.placeTitle = position;
                [self infoShow:position];
                [self performSelector:@selector(infoHide) withObject:nil afterDelay:2];
                
                [coder release];
            }];
        }else{
            [self infoShow:@"Not found"];
            [self performSelector:@selector(infoHide) withObject:nil afterDelay:2];
        }
        [coder release];
        doneButton.enabled = YES;
    }];
}

#pragma mark - annotation untuk map
-(NSString *)title{
    return @"My Position";
}

-(NSString *)subtitle{
    return nil;
}

#pragma mark - Action
-(void)back:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(setLocationDidCancel:)]){
            [self.delegate setLocationDidCancel:self];
        }
    }];
}

-(void)hideKeyboard:(id)sender{
    [searchText resignFirstResponder];
}

-(void)infoShow:(NSString *)info{
    infoLabel.text = info;
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.2];
    infoLabel.alpha = 1.;
    [UIView commitAnimations];
}

-(void)infoHide{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:1.];
    infoLabel.alpha = 0.;
    [UIView commitAnimations];
}

-(void)save:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(setLocationDidConfirmed:)]){
            [self.delegate setLocationDidConfirmed:self];
        }
    }];
}

@end
