//
//  ASIHTTPRequest+Semut.h
//  Semut
//
//  Created by Asep Mulyana on 11/27/14.
//  Copyright (c) 2014 Asep Mulyana. All rights reserved.
//

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@interface ASIHTTPRequest (Semut)

+(id)requestWithSemutURL:(NSURL *)newURL;

@end

@interface ASIFormDataRequest (Semut)

+(id)requestWithSemutURL:(NSURL *)newURL;

@end
