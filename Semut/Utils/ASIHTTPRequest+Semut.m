//
//  ASIHTTPRequest+Semut.m
//  Semut
//
//  Created by Asep Mulyana on 11/27/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import "ASIHTTPRequest+Semut.h"
#import "AppConfig.h"

@implementation ASIHTTPRequest (Semut)

+(id)requestWithSemutURL:(NSURL *)newURL{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:newURL];
    
    [request addRequestHeader:@"API_KEY" value:AUTH_API];
    [request addRequestHeader:@"sessid" value:[AppConfig sharedConfig].sessionID];
    [request addRequestHeader:@"deviceid" value:[AppConfig sharedConfig].deviceIdentifier];
    [request setProxyUsername:@"asepmoels"];
    [request setProxyPassword:@"qwerty"];
    
    request.timeOutSeconds = 60.;
    
    return request;
}

@end


@implementation ASIFormDataRequest (Semut)

+(id)requestWithSemutURL:(NSURL *)newURL{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:newURL];
    
    [request addRequestHeader:@"API_KEY" value:AUTH_API];
    [request addRequestHeader:@"sessid" value:[AppConfig sharedConfig].sessionID];
    [request addRequestHeader:@"deviceid" value:[AppConfig sharedConfig].deviceIdentifier];
    [request setProxyUsername:@"asepmoels"];
    [request setProxyPassword:@"qwerty"];
    
    request.timeOutSeconds = 60.;
    
    return request;
}

@end
