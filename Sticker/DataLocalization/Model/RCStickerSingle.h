//
//  RCStickerSingle.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCStickerSingle : NSObject

@property (nonatomic, strong) NSString *stickerId;

@property (nonatomic, strong) NSString *digest;

@property (nonatomic, strong) NSString *pkgId;

@property (nonatomic, strong) NSString *thumbUrl;

@property (nonatomic, strong) NSString *url;

@property (nonatomic, assign) long width;

@property (nonatomic, assign) long height;

@property (nonatomic, assign) long order;

+ (RCStickerSingle *)modelWithDict:(NSDictionary *)dict;

+ (NSDictionary *)dictWithModel:(RCStickerSingle *)model;

+ (NSArray *)modelArrayWithDictArray:(NSArray *)dicts;

+ (NSArray *)dictArrayWithModelArray:(NSArray *)models;

@end
