//
//  RCStickerDownloader.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Sticker downloader
 */
@interface RCStickerDownloader : NSObject

+ (instancetype)shareDownloader;

/**
 begin download

 @param URLString download URL
 @param identifier download identifier
 @param progressBlock progress Block
 @param successBlock success Block
 @param errorBlock error Block
 */
- (void)downloadWithURLString:(NSString *)URLString
                   identifier:(NSString *)identifier
                     progress:(void (^)(int progress))progressBlock
                      success:(void (^)(NSURL *localURL))successBlock
                        error:(void (^)(int errorCode))errorBlock;

@end
