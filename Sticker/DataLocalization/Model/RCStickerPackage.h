//
//  RCStickerPackage.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCStickerPackageConfig.h"

@interface RCStickerPackage : NSObject

@property (nonatomic, strong) NSString *packageId;

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *author;

@property (nonatomic, strong) NSString *icon;

@property (nonatomic, assign) BOOL isPreload;

@property (nonatomic, strong) NSString *cover;

@property (nonatomic, strong) NSString *copyright;

@property (nonatomic, strong) NSString *createTime;

@property (nonatomic, strong) NSString *digest;

@property (nonatomic, assign) long order;

@property (nonatomic, assign) long pkgType;

@property (nonatomic, assign) BOOL isDownloaded;

@property (nonatomic, assign) BOOL isDeleted;

- (void)setConfig:(RCStickerPackageConfig *)packageConfig;

+ (RCStickerPackage *)modelWithDict:(NSDictionary *)dict;

+ (NSDictionary *)dictWithModel:(RCStickerPackage *)model;

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts;

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models;

@end
