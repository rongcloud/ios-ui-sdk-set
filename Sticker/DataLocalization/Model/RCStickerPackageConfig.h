//
//  RCStickerPackageConfig.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCStickerPackageConfig : NSObject <NSCoding>

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

+ (RCStickerPackageConfig *)modelWithDict:(NSDictionary *)dict;

+ (NSDictionary *)dictWithModel:(RCStickerPackageConfig *)model;

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts;

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models;

@end
