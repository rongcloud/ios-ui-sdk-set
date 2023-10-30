//
//  RCStickerDownloader.m
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStickerDownloader.h"
#import "RCStickerUtility.h"

/**
 Async download queue

 @return download queue
 */
static NSOperationQueue *rong_st_download_queue() {
    static NSOperationQueue *rong_st_download_queue;
    static dispatch_once_t queueOnceToken;
    dispatch_once(&queueOnceToken, ^{
        rong_st_download_queue = [[NSOperationQueue alloc] init];
        rong_st_download_queue.maxConcurrentOperationCount = 24;
    });
    return rong_st_download_queue;
}

@interface RCStickerDownloader () <NSURLSessionDownloadDelegate>

/**
 block cache
 */
@property (nonatomic, strong) NSMutableDictionary *progressBlocks;
@property (nonatomic, strong) NSMutableDictionary *successBlocks;
@property (nonatomic, strong) NSMutableDictionary *errorBlocks;

@end

@implementation RCStickerDownloader

+ (instancetype)shareDownloader {
    static RCStickerDownloader *shareDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareDownloader = [[RCStickerDownloader alloc] init];
    });
    return shareDownloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.progressBlocks = [[NSMutableDictionary alloc] init];
        self.successBlocks = [[NSMutableDictionary alloc] init];
        self.errorBlocks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

// begin download
- (void)downloadWithURLString:(NSString *)URLString
                   identifier:(NSString *)identifier
                     progress:(void (^)(int progress))progressBlock
                      success:(void (^)(NSURL *localURL))successBlock
                        error:(void (^)(int errorCode))errorBlock {

    [self.progressBlocks setObject:progressBlock forKey:identifier];
    [self.successBlocks setObject:successBlock forKey:identifier];
    [self.errorBlocks setObject:errorBlock forKey:identifier];
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:[RCStickerUtility rcSessionConfiguration]
                                      delegate:self
                                 delegateQueue:rong_st_download_queue()];
    session.sessionDescription = identifier;
    NSURL *url = [NSURL URLWithString:URLString];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url];
    [downloadTask resume];
}



#pragma mark - NSURLSessionDownloadDelegate

// download progress
- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *sessionIdentifier = session.sessionDescription;
    void (^progressBlock)(int) = [self.progressBlocks objectForKey:sessionIdentifier];
    if (progressBlock) {
        progressBlock((int)(100 * totalBytesWritten / totalBytesExpectedToWrite));
    }
}

// recover download
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
}

// download completed
- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
    NSString *sessionIdentifier = session.sessionDescription;
    void (^successBlock)(NSURL *localURL) = [self.successBlocks objectForKey:sessionIdentifier];
    if (successBlock) {
        successBlock(location);
    }
    [self.progressBlocks removeObjectForKey:sessionIdentifier];
    [self.successBlocks removeObjectForKey:sessionIdentifier];
    [self.errorBlocks removeObjectForKey:sessionIdentifier];
    [session finishTasksAndInvalidate];
}

// download failed
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSString *sessionIdentifier = session.sessionDescription;
    void (^errorBlock)(int errorCode) = [self.errorBlocks objectForKey:sessionIdentifier];
    if (errorBlock) {
        errorBlock((int)error.code);
    }
    [self.progressBlocks removeObjectForKey:sessionIdentifier];
    [self.successBlocks removeObjectForKey:sessionIdentifier];
    [self.errorBlocks removeObjectForKey:sessionIdentifier];
    [session finishTasksAndInvalidate];
}

@end
