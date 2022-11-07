//
//  EGOImageLoadConnection.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 12/1/09.
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

#import "RCloudImageLoadConnection.h"
#import "RCDownloadHelper.h"
#import <RongIMLib/RongIMLib.h>

@implementation RCloudImageLoadConnection
@synthesize imageURL = _imageURL, response = _response, delegate = _delegate, timeoutInterval = _timeoutInterval;

#if __EGOIL_USE_BLOCKS
@synthesize handlers;
#endif

- (instancetype)initWithImageURL:(NSURL *)aURL delegate:(id)delegate {
    if ((self = [super init])) {
        _imageURL = aURL;
        self.delegate = delegate;
        _responseData = [[NSMutableData alloc] init];
        self.timeoutInterval = 30;

#if __EGOIL_USE_BLOCKS
        handlers = [[NSMutableDictionary alloc] init];
#endif
    }

    return self;
}

- (void)start {
    RCDownloadHelper *downloadHelper = [RCDownloadHelper new];
    [downloadHelper getDownloadFileToken:MediaType_IMAGE
                           completeBlock:^(NSString *_Nonnull token) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [self startDownload:token];
                               });
                           }];
}

- (void)startDownload:(NSString *)token {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.imageURL
                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                            timeoutInterval:self.timeoutInterval];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    if (token) {
        [request setValue:token forHTTPHeaderField:@"authorization"];
    }
    request.timeoutInterval = 10;
    
    NSURLSessionConfiguration *configuration = [self rcSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration
                                             delegate:self
                                        delegateQueue:nil];
    _dataTask = [_session dataTaskWithRequest:request];
    [_dataTask resume];
}

- (NSURLSessionConfiguration *)rcSessionConfiguration {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    RCIMProxy *currentProxy = [[RCCoreClient sharedCoreClient] getCurrentProxy];
    
    if (currentProxy && [currentProxy isValid]) {
        NSString *proxyHost = currentProxy.host;
        NSNumber *proxyPort = @(currentProxy.port);
        NSString *proxyUserName = currentProxy.userName;
        NSString *proxyPassword = currentProxy.password;

        NSDictionary *proxyDict = @{
            (NSString *)kCFStreamPropertySOCKSProxyHost: proxyHost,
            (NSString *)kCFStreamPropertySOCKSProxyPort: proxyPort,
            (NSString *)kCFStreamPropertySOCKSUser : proxyUserName,
            (NSString *)kCFStreamPropertySOCKSPassword: proxyPassword
        };

        sessionConfiguration.connectionProxyDictionary = proxyDict;
    }
    return sessionConfiguration;
}

- (void)cancel {
    [_dataTask cancel];
}

- (NSData *)responseData {
    return _responseData;
}

//MARK:-- NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSURLResponse *response = task.response;
    self.response = response;
    
    if (nil == error) {
        if ([self.delegate respondsToSelector:@selector(imageLoadConnectionDidFinishLoading:)]) {
            [self.delegate imageLoadConnectionDidFinishLoading:self];
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(imageLoadConnection:didFailWithError:)]) {
            [self.delegate imageLoadConnection:self didFailWithError:error];
        }
    }

    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
}


- (void)dealloc {
    self.response = nil;
    self.delegate = nil;

#if __EGOIL_USE_BLOCKS
    [handlers release], handlers = nil;
#endif
    _dataTask = nil;
    _session = nil;
    _imageURL = nil;
    _responseData = nil;
}

@end
