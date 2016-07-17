//
//  EGOImageLoader.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOImageLoader.h"
#import "EGOImageLoadConnection.h"
#import "EGOCache.h"
#import <sys/utsname.h>

//#define MEMORY_CACHE_LIMIT      50

static EGOImageLoader* __imageLoader;

inline static NSString* keyForURL(NSURL* url, NSString* style) {
	if(style) {
		return [NSString stringWithFormat:@"EGOImageLoader-%u-%u", [[url description] hash], [style hash]];
	} else {
		return [NSString stringWithFormat:@"EGOImageLoader-%u", [[url description] hash]];
	}
}

#if __EGOIL_USE_BLOCKS
	#define kNoStyle @"EGOImageLoader-nostyle"
	#define kCompletionsKey @"completions"
	#define kStylerKey @"styler"
	#define kStylerQueue _operationQueue
	#define kCompletionsQueue dispatch_get_main_queue()
#endif

#if __EGOIL_USE_NOTIF
	#define kImageNotificationLoaded(s) [@"kEGOImageLoaderNotificationLoaded-" stringByAppendingString:keyForURL(s, nil)]
	#define kImageNotificationLoadFailed(s) [@"kEGOImageLoaderNotificationLoadFailed-" stringByAppendingString:keyForURL(s, nil)]
#endif

@interface EGOImageLoader () <NSStreamDelegate>{
    NSMutableDictionary *dataBank;
    NSMutableDictionary *streamBank;
    NSMutableArray *imageBank;
    
    NSInteger MEMORY_CACHE_LIMIT;
}
#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection*)connection image:(UIImage*)image error:(NSError*)error;
#endif
@end

@implementation EGOImageLoader
@synthesize currentConnections=_currentConnections;

+ (EGOImageLoader*)sharedImageLoader {
	@synchronized(self) {
		if(!__imageLoader) {
			__imageLoader = [[[self class] alloc] init];
		}
	}
	
	return __imageLoader;
}

+(NSString *)deviceModel{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iPhone Simulator",
      @"x86_64":   @"iPad Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini(WiFi)",
      @"iPad2,6":  @"iPad Mini(GSM)",
      @"iPad2,7":  @"iPad Mini(GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      
      };
    
    NSString *deviceName = commonNamesDictionary[machineName];
    
    if (deviceName == nil) {
        deviceName = machineName;
    }
    
    return deviceName;
}

- (id)init {
	if((self = [super init])) {
		connectionsLock = [[NSLock alloc] init];
		currentConnections = [[NSMutableDictionary alloc] init];
		
		#if __EGOIL_USE_BLOCKS
		_operationQueue = dispatch_queue_create("com.enormego.EGOImageLoader",NULL);
		dispatch_queue_t priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
		dispatch_set_target_queue(priority, _operationQueue);
		#endif
        
        dataBank = [[NSMutableDictionary alloc] init];
        streamBank = [[NSMutableDictionary alloc] init];
        imageBank = [[NSMutableArray alloc] init];
        
        // Ukuran RAM
        // iPhone 3, 3gs        : 256 MB
        // iPhone 4, 4s         : 512 MB
        // iPhone 5, 5s, 5c     : 1024 MB
        // iPad 1               : 256 MB
        // iPad 2               : 512 MB
        // iPad 3 & 4           : 1024 MB
        // iPad Air             : 1024 MB
        // iPad Mini 1          : 512 MB
        // iPad Mini 2          : 1024 MB
        
        NSString *model = [[self class] deviceModel];
        if([[model uppercaseString] rangeOfString:@"IPHONE 5"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 50;
        }else if([[model uppercaseString] rangeOfString:@"IPHONE 4"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 35;
        }else if([[model uppercaseString] rangeOfString:@"IPHONE 3"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 20;
        }else if([[model uppercaseString] rangeOfString:@"IPAD 4"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 50;
        }else if([[model uppercaseString] rangeOfString:@"IPAD 3"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 50;
        }else if([[model uppercaseString] rangeOfString:@"IPAD 2"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 35;
        }else if([[model uppercaseString] rangeOfString:@"IPAD MINI"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 35;
        }else if([[model uppercaseString] rangeOfString:@"IPAD"].location != NSNotFound){
            MEMORY_CACHE_LIMIT = 20;
        }
	}
	
	return self;
}

- (EGOImageLoadConnection*)loadingConnectionForURL:(NSURL*)aURL {
	EGOImageLoadConnection* connection = [[self.currentConnections objectForKey:aURL] retain];
	if(!connection) return nil;
	else return [connection autorelease];
}

- (void)cleanUpConnection:(EGOImageLoadConnection*)connection {
	if(!connection.imageURL) return;
	
	connection.delegate = nil;
	
	[connectionsLock lock];
	[currentConnections removeObjectForKey:connection.imageURL];
	self.currentConnections = [[currentConnections copy] autorelease];
	[connectionsLock unlock];	
}

- (void)clearCacheForURL:(NSURL*)aURL {
	[self clearCacheForURL:aURL style:nil];
    
    id target = nil;
    for(NSDictionary *dict in imageBank){
        NSString *key = [dict.keyEnumerator.allObjects lastObject];
        if([key isEqualToString:aURL.absoluteString]){
            target = dict;
        }
    }
    
    if(target)[imageBank removeObject:target];
}

- (void)clearCacheForURL:(NSURL*)aURL style:(NSString*)style {
	[[EGOCache currentCache] removeCacheForKey:keyForURL(aURL, style)];
}

-(void)clearCacheOnRAM{
    [imageBank removeAllObjects];
}

- (BOOL)isLoadingImageURL:(NSURL*)aURL {
	return [self loadingConnectionForURL:aURL] ? YES : NO;
}

- (void)cancelLoadForURL:(NSURL*)aURL {
	EGOImageLoadConnection* connection = [self loadingConnectionForURL:aURL];
	[NSObject cancelPreviousPerformRequestsWithTarget:connection selector:@selector(start) object:nil];
	[connection cancel];
	[self cleanUpConnection:connection];
}

- (EGOImageLoadConnection*)loadImageForURL:(NSURL*)aURL {
	EGOImageLoadConnection* connection;
	
	if((connection = [self loadingConnectionForURL:aURL])) {
		return connection;
	} else {
		connection = [[EGOImageLoadConnection alloc] initWithImageURL:aURL delegate:self];
	
        if([aURL.scheme isEqualToString:@"assets-library"]){
            [connection start];
        }else{
            [connectionsLock lock];
            [currentConnections setObject:connection forKey:aURL];
            self.currentConnections = [[currentConnections copy] autorelease];
            [connectionsLock unlock];
            [connection performSelector:@selector(start) withObject:nil afterDelay:0.01];
            [connection release];
        }
		
		return connection;
	}
}

#if __EGOIL_USE_NOTIF
- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer {
	if(!aURL) return;
	
	if([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidLoad:) name:kImageNotificationLoaded(aURL) object:self];
	}
	
	if([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidFailToLoad:) name:kImageNotificationLoadFailed(aURL) object:self];
	}

	[self loadImageForURL:aURL];
}

- (UIImage*)imageForURL:(NSURL*)aURL shouldLoadWithObserver:(id<EGOImageLoaderObserver>)observer {
//	if(!aURL) return nil;
//	
//	UIImage* anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,nil)];
//	
//	if(anImage) {
//		return anImage;
//	} else {
//		[self loadImageForURL:aURL observer:observer];
//		return nil;
//	}
    
    // ini modifikasi saya untuk coba load via stream by. asepmoels
    
    for(NSDictionary *dict in imageBank){
        NSString *key = [dict.keyEnumerator.allObjects lastObject];
        if([key isEqualToString:aURL.absoluteString]){
            return [dict valueForKey:key];
        }
    }
    
    if([self hasLoadedImageURL:aURL]){
        if([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
            [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidLoad:) name:kImageNotificationLoaded(aURL) object:self];
        }
        
        if([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
            [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidFailToLoad:) name:kImageNotificationLoadFailed(aURL) object:self];
        }
        
        NSString *path = [[EGOCache currentCache] pathForKey:keyForURL(aURL, nil)];
        
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
        
        [streamBank setValue:inputStream forKey:aURL.absoluteString];
        [dataBank setValue:[NSMutableData data] forKey:aURL.absoluteString];
        
        [inputStream setDelegate:self];
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream open];
        
        NSURL *thumbURL = [aURL URLByAppendingPathExtension:@"thumbnail"];
        UIImage* thumb = [[EGOCache currentCache] imageForKey:keyForURL(thumbURL,nil)];
        
        if(thumb)return thumb;
    }else{
        [self loadImageForURL:aURL observer:observer];
    }
    
    return nil;
}

- (void)removeObserver:(id<EGOImageLoaderObserver>)observer {
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:nil object:self];
}

- (void)removeObserver:(id<EGOImageLoaderObserver>)observer forURL:(NSURL*)aURL {
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoaded(aURL) object:self];
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoadFailed(aURL) object:self];
}

#endif

#if __EGOIL_USE_BLOCKS
- (void)loadImageForURL:(NSURL*)aURL completion:(void (^)(UIImage* image, NSURL* imageURL, NSError* error))completion {
	[self loadImageForURL:aURL style:nil styler:nil completion:completion];
}

- (void)loadImageForURL:(NSURL*)aURL style:(NSString*)style styler:(UIImage* (^)(UIImage* image))styler completion:(void (^)(UIImage* image, NSURL* imageURL, NSError* error))completion {
	UIImage* anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,style)];

	if(anImage) {
		completion(anImage, aURL, nil);
	} else if(!anImage && styler && style && (anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,nil)])) {
		dispatch_async(kStylerQueue, ^{
			UIImage* image = styler(anImage);
			[[EGOCache currentCache] setImage:image forKey:keyForURL(aURL, style) withTimeoutInterval:604800];
			dispatch_async(kCompletionsQueue, ^{
				completion(image, aURL, nil);
			});
		});
	} else {
		EGOImageLoadConnection* connection = [self loadImageForURL:aURL];
		void (^completionCopy)(UIImage* image, NSURL* imageURL, NSError* error) = [completion copy];
		
		NSString* handlerKey = style ? style : kNoStyle;
		NSMutableDictionary* handler = [connection.handlers objectForKey:handlerKey];
		
		if(!handler) {
			handler = [[NSMutableDictionary alloc] initWithCapacity:2];
			[connection.handlers setObject:handler forKey:handlerKey];

			[handler setObject:[NSMutableArray arrayWithCapacity:1] forKey:kCompletionsKey];
			if(styler) {
				UIImage* (^stylerCopy)(UIImage* image) = [styler copy];
				[handler setObject:stylerCopy forKey:kStylerKey];
				[stylerCopy release];
			}
			
			[handler release];
		}
		
		[[handler objectForKey:kCompletionsKey] addObject:completionCopy];
		[completionCopy release];
	}
}
#endif

- (BOOL)hasLoadedImageURL:(NSURL*)aURL {
	return [[EGOCache currentCache] hasCacheForKey:keyForURL(aURL,nil)];
}

#pragma mark -
#pragma mark URL Connection delegate methods

-(NSData *)dataForImage:(UIImageView *)image{
    CGSize imageSize = image.frame.size;
//    imageSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(1./[UIScreen mainScreen].scale, 1./[UIScreen mainScreen].scale));
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO,[UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextTranslateCTM(context, 0, imageSize.height);
//    CGContextScaleCTM(context, 1., -1);
//    CGContextDrawImage(context, CGRectMake(0, 0, imageSize.width, imageSize.height), image.CGImage);
    [image.layer renderInContext:context];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *data = UIImageJPEGRepresentation(newImage, 1.);
    
    [image release];
    
    return data;
}

-(NSData *)resizedImageData:(NSData *)imgData{
    UIImage *img = [UIImage imageWithData:imgData];
    UIImageView *imgV = [[UIImageView alloc] initWithImage:img];
    CGRect frame = imgV.frame;
    frame.size.height = 100. * img.size.height / img.size.width;
    frame.size.width = 100.;
    imgV.frame = frame;
    
    return [self dataForImage:imgV];
}

- (void)imageLoadConnectionDidFinishLoading:(EGOImageLoadConnection *)connection {
	UIImage* anImage = [UIImage imageWithData:connection.responseData];
	
    // tambahan gua nih
    [imageBank addObject:[NSDictionary dictionaryWithObjectsAndKeys:anImage, connection.imageURL.absoluteString, nil]];
    [self checkImageBankLimit];
    // tambahan gua nih sampe disini
    
	if(!anImage) {
		NSError* error = [NSError errorWithDomain:[connection.imageURL host] code:406 userInfo:nil];
		
		#if __EGOIL_USE_NOTIF
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",connection.imageURL,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		#endif
		
		#if __EGOIL_USE_BLOCKS
		[self handleCompletionsForConnection:connection image:nil error:error];
		#endif
	} else {
		[[EGOCache currentCache] setData:connection.responseData forKey:keyForURL(connection.imageURL,nil) withTimeoutInterval:604800];

        NSData *resizedData = [self resizedImageData:connection.responseData];
        NSURL *thumbURL = [connection.imageURL URLByAppendingPathExtension:@"thumbnail"];
        [[EGOCache currentCache] setData:resizedData forKey:keyForURL(thumbURL,nil) withTimeoutInterval:604800];
		
		[currentConnections removeObjectForKey:connection.imageURL];
		self.currentConnections = [[currentConnections copy] autorelease];
		
		#if __EGOIL_USE_NOTIF
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoaded(connection.imageURL)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anImage,@"image",connection.imageURL,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		#endif
		
		#if __EGOIL_USE_BLOCKS
		[self handleCompletionsForConnection:connection image:anImage error:nil];
		#endif
	}
	
	

	[self cleanUpConnection:connection];
}

- (void)imageLoadConnection:(EGOImageLoadConnection *)connection didFailWithError:(NSError *)error {
	[currentConnections removeObjectForKey:connection.imageURL];
	self.currentConnections = [[currentConnections copy] autorelease];
	
	#if __EGOIL_USE_NOTIF
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",connection.imageURL,@"imageURL",nil]];
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
	#endif
	
	#if __EGOIL_USE_BLOCKS
	[self handleCompletionsForConnection:connection image:nil error:error];
	#endif

	[self cleanUpConnection:connection];
}

#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection*)connection image:(UIImage*)image error:(NSError*)error {
	if([connection.handlers count] == 0) return;

	NSURL* imageURL = connection.imageURL;
	
	void (^callCompletions)(UIImage* anImage, NSArray* completions) = ^(UIImage* anImage, NSArray* completions) {
		dispatch_async(kCompletionsQueue, ^{
			for(void (^completion)(UIImage* image, NSURL* imageURL, NSError* error) in completions) {
				completion(anImage, connection.imageURL, error);
			}
		});
	};
	
	for(NSString* styleKey in connection.handlers) {
		NSDictionary* handler = [connection.handlers objectForKey:styleKey];
		UIImage* (^styler)(UIImage* image) = [handler objectForKey:kStylerKey];
		if(!error && image && styler) {
			dispatch_async(kStylerQueue, ^{
				UIImage* anImage = styler(image);
				[[EGOCache currentCache] setImage:anImage forKey:keyForURL(imageURL, styleKey) withTimeoutInterval:604800];
				callCompletions(anImage, [handler objectForKey:kCompletionsKey]);
			});
		} else {
			callCompletions(image, [handler objectForKey:kCompletionsKey]);
		}
	}
}
#endif

#pragma mark - delegate Stream
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    NSString *key = @"";
    
    for(NSString *oneKey in streamBank.keyEnumerator.allObjects){
        if([streamBank valueForKey:oneKey] == aStream){
            key = oneKey;
            break;
        }
    }
    
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            NSMutableData *_data = [dataBank valueForKey:key];
            
            uint8_t buf[1024];
            unsigned int len = 0;
            len = [(NSInputStream *)aStream read:buf maxLength:1024];
            if(len) {
                [_data appendBytes:(const void *)buf length:len];
            } else {
                //NSLog(@"no buffer!");
            }
        }
            break;
    
        case NSStreamEventEndEncountered:
        {
            NSData *newData = [dataBank valueForKey:key];
            //NSLog(@"dapet data %@", newData);
            
            [imageBank addObject:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageWithData:newData], key, nil]];
            [self checkImageBankLimit];
            
#if __EGOIL_USE_NOTIF
            NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoaded([NSURL URLWithString:key])
                                                                         object:self
                                                                       userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageWithData:newData],@"image",[NSURL URLWithString:key],@"imageURL",nil]];
            
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
#endif
            
#if __EGOIL_USE_BLOCKS
            [self handleCompletionsForConnection:connection image:[UIImage imageWithData:newData] error:nil];
#endif
            
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            [streamBank removeObjectForKey:key];
            [dataBank removeObjectForKey:key];
            [aStream release];
            aStream = nil; // stream is ivar, so reinit it
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -

- (void)dealloc {
    [dataBank release];
    [streamBank release];
    [imageBank release];
    
	#if __EGOIL_USE_BLOCKS
		dispatch_release(_operationQueue), _operationQueue = nil;
	#endif
	
	self.currentConnections = nil;
	[currentConnections release], currentConnections = nil;
	[connectionsLock release], connectionsLock = nil;
	[super dealloc];
}

#pragma mark - tambahan method saya
-(void)checkImageBankLimit{
    while(imageBank.count > MEMORY_CACHE_LIMIT){
        [imageBank removeObjectAtIndex:0];
    }
}

@end