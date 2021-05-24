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

#import "RCloudImageLoader.h"
#import "RCloudCache.h"
#import "RCloudImageLoadConnection.h"
#import <RongIMLib/RongIMLib.h>

static RCloudImageLoader *__imageLoader;

inline static NSString *keyForURL(NSURL *url, NSString *style) {
    if (style) {
        return [NSString stringWithFormat:@"EGOImageLoader-%@-%@", [RCFileUtility getFileKey:[url description]],
                                          [RCFileUtility getFileKey:style]];
    } else {
        return [NSString stringWithFormat:@"EGOImageLoader-%@", [RCFileUtility getFileKey:[url description]]];
    }
}


//#define maxImageSize 1024 * 1024 * 5

#if __EGOIL_USE_BLOCKS
#define kNoStyle @"EGOImageLoader-nostyle"
#define kCompletionsKey @"completions"
#define kStylerKey @"styler"
#define kStylerQueue _operationQueue
#define kCompletionsQueue dispatch_get_main_queue()
#endif

#if __EGOIL_USE_NOTIF
#define kImageNotificationLoaded(s) [@"kEGOImageLoaderNotificationLoaded-" stringByAppendingString:keyForURL(s, nil)]
#define kImageNotificationLoadFailed(s)                                                                                \
    [@"kEGOImageLoaderNotificationLoadFailed-" stringByAppendingString:keyForURL(s, nil)]
#endif

@interface RCloudImageLoader ()
#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection *)connection
                                 image:(UIImage *)image
                                 error:(NSError *)error;
#endif
@end

@implementation RCloudImageLoader
@synthesize currentConnections = _currentConnections;

+ (RCloudImageLoader *)sharedImageLoader {
    @synchronized(self) {
        if (!__imageLoader) {
            __imageLoader = [[[self class] alloc] init];
        }
    }

    return __imageLoader;
}

- (instancetype)init {
    if ((self = [super init])) {
        connectionsLock = [[NSLock alloc] init];
        currentConnections = [[NSMutableDictionary alloc] init];

#if __EGOIL_USE_BLOCKS
        _operationQueue = dispatch_queue_create("com.enormego.EGOImageLoader", NULL);
        dispatch_queue_t priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(priority, _operationQueue);
#endif
    }

    return self;
}

- (RCloudImageLoadConnection *)loadingConnectionForURL:(NSURL *)aURL {
    RCloudImageLoadConnection *connection = (self.currentConnections)[aURL];
    if (!connection)
        return nil;
    else
        return connection;
}

- (void)cleanUpConnection:(RCloudImageLoadConnection *)connection {
    if (!connection.imageURL)
        return;

    connection.delegate = nil;

    [connectionsLock lock];
    [currentConnections removeObjectForKey:connection.imageURL];
    self.currentConnections = [currentConnections copy];
    [connectionsLock unlock];
}

- (void)clearCacheForURL:(NSURL *)aURL {
    [self clearCacheForURL:aURL style:nil];
}

- (void)clearCacheForURL:(NSURL *)aURL style:(NSString *)style {
    [[RCloudCache currentCache] removeCacheForKey:keyForURL(aURL, style)];
}

- (NSString *)cachePathForURL:(NSURL *)aURL {
    return [[RCloudCache currentCache] imagePathForKey:keyForURL(aURL, nil)];
}

- (BOOL)isLoadingImageURL:(NSURL *)aURL {
    return [self loadingConnectionForURL:aURL] != nil;
}

- (void)cancelLoadForURL:(NSURL *)aURL {
    RCloudImageLoadConnection *connection = [self loadingConnectionForURL:aURL];
    [NSObject cancelPreviousPerformRequestsWithTarget:connection selector:@selector(start) object:nil];
    [connection cancel];
    [self cleanUpConnection:connection];
}

- (RCloudImageLoadConnection *)loadImageForURL:(NSURL *)aURL {
    RCloudImageLoadConnection *connection;
    if (!aURL) {
        return nil;
    }
    if ((connection = [self loadingConnectionForURL:aURL])) {
        return connection;
    } else {
        connection = [[RCloudImageLoadConnection alloc] initWithImageURL:aURL delegate:self];

        [connectionsLock lock];
        currentConnections[aURL] = connection;
        self.currentConnections = [currentConnections copy];
        [connectionsLock unlock];
        [connection performSelector:@selector(start) withObject:nil afterDelay:0.01];
        return connection;
    }
}

#if __EGOIL_USE_NOTIF
- (void)loadImageForURL:(NSURL *)aURL observer:(id<RCloudImageLoaderObserver>)observer {
    if (!aURL)
        return;

    if ([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:observer
                                                 selector:@selector(imageLoaderDidLoad:)
                                                     name:kImageNotificationLoaded(aURL)
                                                   object:self];
    }

    if ([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:observer
                                                 selector:@selector(imageLoaderDidFailToLoad:)
                                                     name:kImageNotificationLoadFailed(aURL)
                                                   object:self];
    }

    [self loadImageForURL:aURL];
}

- (UIImage *)imageForURL:(NSURL *)aURL shouldLoadWithObserver:(id<RCloudImageLoaderObserver>)observer {
    if (!aURL)
        return nil;
    if ([self hasLoadedImageURL:aURL]) {
        UIImage *anImage = [[RCloudCache currentCache] imageForKey:keyForURL(aURL, nil)];
        return anImage;
    } else {
        if (aURL.scheme == nil) {
            UIImage *anImage = [UIImage imageNamed:[aURL absoluteString]];
            if (anImage) {
                [[RCloudCache currentCache] setImage:anImage forKey:keyForURL(aURL, nil)];
                return anImage;
            }
        }
        [self loadImageForURL:aURL observer:observer];
        return nil;
    }
}

- (NSData *)getImageDataForURL:(NSURL *)aURL {
    NSData *imageData = [[RCloudCache currentCache] imageDataForKey:keyForURL(aURL, nil)];
    return imageData;
}

- (void)removeObserver:(id<RCloudImageLoaderObserver>)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:nil object:self];
}

- (void)removeObserver:(id<RCloudImageLoaderObserver>)observer forURL:(NSURL *)aURL {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoaded(aURL) object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoadFailed(aURL) object:self];
}

#endif

#if __EGOIL_USE_BLOCKS
- (void)loadImageForURL:(NSURL *)aURL completion:(void (^)(UIImage *image, NSURL *imageURL, NSError *error))completion {
    [self loadImageForURL:aURL style:nil styler:nil completion:completion];
}

- (void)loadImageForURL:(NSURL *)aURL
                  style:(NSString *)style
                 styler:(UIImage * (^)(UIImage *image))styler
             completion:(void (^)(UIImage *image, NSURL *imageURL, NSError *error))completion {
    UIImage *anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL, style)];

    if (anImage) {
        completion(anImage, aURL, nil);
    } else if (!anImage && styler && style && (anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL, nil)])) {
        dispatch_async(kStylerQueue, ^{
            UIImage *image = styler(anImage);
            [[EGOCache currentCache] setImage:image
                                       forKey:keyForURL(aURL, style)
                          withTimeoutInterval:[RCloudCache currentCache].defaultTimeoutInterval];
            dispatch_async(kCompletionsQueue, ^{
                completion(image, aURL, nil);
            });
        });
    } else {
        EGOImageLoadConnection *connection = [self loadImageForURL:aURL];
        void (^completionCopy)(UIImage *image, NSURL *imageURL, NSError *error) = [completion copy];

        NSString *handlerKey = style ? style : kNoStyle;
        NSMutableDictionary *handler = [connection.handlers objectForKey:handlerKey];

        if (!handler) {
            handler = [[NSMutableDictionary alloc] initWithCapacity:2];
            [connection.handlers setObject:handler forKey:handlerKey];

            [handler setObject:[NSMutableArray arrayWithCapacity:1] forKey:kCompletionsKey];
            if (styler) {
                UIImage * (^stylerCopy)(UIImage *image) = [styler copy];
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

- (BOOL)hasLoadedImageURL:(NSURL *)aURL {
    return [[RCloudCache currentCache] hasCacheForKey:keyForURL(aURL, nil)];
}

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize {
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}
#pragma mark -
#pragma mark URL Connection delegate methods

- (void)imageLoadConnectionDidFinishLoading:(RCloudImageLoadConnection *)connection {
    UIImage *anImage = [UIImage imageWithData:connection.responseData];
    NSData *targetData = connection.responseData;
    if (!anImage) {
        NSString *contentType = [self contentTypeForImageData:connection.responseData];
        if ([[contentType lowercaseString] isEqualToString:@"image/webp"]) {
#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
            // 运行时，开始处理webp格式的图片
            if ([NSObject respondsToSelector:@selector(rc_imageWithWebP:)]) {
                
                anImage = [NSObject performSelector:@selector(rc_imageWithWebP:) withObject:connection.responseData];
                
                if (anImage != nil) {
                    targetData = UIImageJPEGRepresentation(anImage, 1.0);
                }
            }
#pragma clang diagnostic push
        }
    }
    if (!anImage) {
        NSErrorDomain errDomain = [connection.imageURL host];

        if (!errDomain) {
            errDomain = NSURLErrorDomain;
        }
        NSError *error = [NSError errorWithDomain:errDomain code:406 userInfo:nil];
#if __EGOIL_USE_NOTIF
        NSNotification *notification =
            [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
                                          object:self
                                        userInfo:@{
                                            @"error" : error,
                                            @"imageURL" : connection.imageURL
                                        }];

        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notification
                                                            waitUntilDone:YES];
#endif

#if __EGOIL_USE_BLOCKS
        [self handleCompletionsForConnection:connection image:nil error:error];
#endif

    } else {
        NSData *originalImageData = targetData;
        [[RCloudCache currentCache] setData:targetData
                                     forKey:keyForURL(connection.imageURL, nil)
                        withTimeoutInterval:[RCloudCache currentCache].defaultTimeoutInterval];
        [currentConnections removeObjectForKey:connection.imageURL];

        self.currentConnections = [currentConnections copy];
#if __EGOIL_USE_NOTIF
        NSNotification *notification =
            [NSNotification notificationWithName:kImageNotificationLoaded(connection.imageURL)
                                          object:self
                                        userInfo:@{
                                            @"image" : anImage,
                                            @"imageURL" : connection.imageURL,
                                            @"originalImageData" : originalImageData
                                        }];

        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                               withObject:notification
                                                            waitUntilDone:YES];
#endif

#if __EGOIL_USE_BLOCKS
        [self handleCompletionsForConnection:connection image:anImage error:nil];
#endif
    }

    [self cleanUpConnection:connection];
}

- (void)imageLoadConnection:(RCloudImageLoadConnection *)connection didFailWithError:(NSError *)error {
    [currentConnections removeObjectForKey:connection.imageURL];

    self.currentConnections = [currentConnections copy];
#if __EGOIL_USE_NOTIF
    NSNotification *notification =
        [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
                                      object:self
                                    userInfo:@{
                                        @"error" : error,
                                        @"imageURL" : connection.imageURL
                                    }];

    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:)
                                                           withObject:notification
                                                        waitUntilDone:YES];
#endif

#if __EGOIL_USE_BLOCKS
    [self handleCompletionsForConnection:connection image:nil error:error];
#endif

    [self cleanUpConnection:connection];
}

#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection *)connection
                                 image:(UIImage *)image
                                 error:(NSError *)error {
    if ([connection.handlers count] == 0)
        return;

    NSURL *imageURL = connection.imageURL;

    void (^callCompletions)(UIImage *anImage, NSArray *completions) = ^(UIImage *anImage, NSArray *completions) {
        dispatch_async(kCompletionsQueue, ^{
            for (void (^completion)(UIImage *image, NSURL *imageURL, NSError *error) in completions) {
                completion(anImage, connection.imageURL, error);
            }
        });
    };

    for (NSString *styleKey in connection.handlers) {
        NSDictionary *handler = [connection.handlers objectForKey:styleKey];
        UIImage * (^styler)(UIImage *image) = [handler objectForKey:kStylerKey];
        if (!error && image && styler) {
            dispatch_async(kStylerQueue, ^{
                UIImage *anImage = styler(image);
                [[EGOCache currentCache] setImage:anImage
                                           forKey:keyForURL(imageURL, styleKey)
                              withTimeoutInterval:[RCloudCache currentCache].defaultTimeoutInterval];
                callCompletions(anImage, [handler objectForKey:kCompletionsKey]);
            });
        } else {
            callCompletions(image, [handler objectForKey:kCompletionsKey]);
        }
    }
}
#endif

#pragma mark -

- (void)dealloc {
#if __EGOIL_USE_BLOCKS
    dispatch_release(_operationQueue), _operationQueue = nil;
#endif

    self.currentConnections = nil;

#if !__has_feature(objc_arc)
    [currentConnections release];
    currentConnections = nil;
    [connectionsLock release];
    connectionsLock = nil;
    [super dealloc];
#else
    currentConnections = nil;
    connectionsLock = nil;
#endif
}
- (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
    case 0xFF:
        return @"image/jpeg";
    case 0x89:
        return @"image/png";
    case 0x47:
        return @"image/gif";
    case 0x49:
    case 0x4D:
        return @"image/tiff";
    case 0x52:
        // R as RIFF for WEBP
        if ([data length] < 12) {
            return nil;
        }

        NSString *testString =
            [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
        if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
            return @"image/webp";
        }

        return nil;
    }
    return nil;
}
@end
