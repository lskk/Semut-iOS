//
//  TimestampLabel.m
//  CyclAsia
//
//  Created by Asep Mulyana on 4/22/15.
//  Copyright (c) 2015 Asep Mulyana. All rights reserved.
//

#import "TimestampLabel.h"

static NSTimer *timer = nil;

@implementation TimestampLabel

@synthesize dateString = _dateString;


+(NSTimer *)sharedTimer{
    if(timer == nil){
        timer = [NSTimer scheduledTimerWithTimeInterval:60. target:[self class] selector:@selector(timerHit:) userInfo:nil repeats:YES];
    }
    
    return timer;
}

+(void)timerHit:(NSTimer *)timer{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TolongUpdateLabelTimestamp" object:nil];
}

- (void)dealloc
{
    [_dateString release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize{
    [[self class] sharedTimer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLabel) name:@"TolongUpdateLabelTimestamp" object:nil];
}

-(void)updateLabel{
    self.text = [self dateFormatFromString:self.dateString];
}

-(void)setDateString:(NSString *)dateString{
    if(_dateString){
        [_dateString release];
    }
    
    _dateString = [dateString retain];
    
    [self updateLabel];
}

-(NSString *)dateFormatFromString:(NSString *)strDate{
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [format dateFromString:strDate];
    NSTimeInterval detik = [[NSDate date] timeIntervalSinceDate:date];
    
    if(detik < 60){
        return @"Just Now";
    }else if(detik < 60 * 60){
        NSInteger n = detik / (60.);
        return [NSString stringWithFormat:@"%zd minute%@ ago", n, n!=1?@"s":@""];
    }else if(detik < 60 * 60 * 24){
        NSInteger n = detik / (60. * 60);
        return [NSString stringWithFormat:@"%zd hour%@ ago", n, n!=1?@"s":@""];
    }else if(detik < 60 * 60 * 24 * 7){
        NSInteger n = detik / (60. * 60 * 24.);
        return [NSString stringWithFormat:@"%zd day%@ ago", n, n!=1?@"s":@""];
    }else if(detik < 60 * 60 * 24 * 30){
        NSInteger n = detik / (60. * 60 * 24. * 7);
        return [NSString stringWithFormat:@"%zd week%@ ago", n, n!=1?@"s":@""];
    }else if(detik < 60 * 60 * 24 * 365.25){
        NSInteger n = detik / (60. * 60 * 24. * 30);
        return [NSString stringWithFormat:@"%zd month%@ ago", n, n!=1?@"s":@""];
    }
    
    NSInteger n = detik / (60. * 60 * 24. * 365.25);
    return [NSString stringWithFormat:@"%zd year%@ ago", n, n!=1?@"s":@""];
}

@end
