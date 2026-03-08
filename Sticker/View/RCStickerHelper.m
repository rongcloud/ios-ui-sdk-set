//
//  RCStickerHelper.m
//  RongCloudOpenSource
//
//  Created by SandBox01 on 2025/8/26.
//

#import "RCStickerHelper.h"
#import "RCStickerCustomModel.h"
#import "NSObject+model.h"

@interface RCStickerHelper ()
/// 表情字典数组
@property (nonatomic, strong) NSArray *emojiArray;

@end

@implementation RCStickerHelper

+ (instancetype)shared {
    static RCStickerHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RCStickerHelper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self loadEmojiData];
    }
    return self;
}

- (void)loadEmojiData {
    @try {
        NSArray *jsonArray = [self loadStrickModelArray];
        self.emojiArray = [RCStickerCustomModel rcModelArrayWithJsonArray:jsonArray];
    } @catch (NSException *exception) {
        NSLog(@"解析plist错误");
    }
}

- (void)preloadEmojiData {
    // 确保数据已加载
    [self emojiArray];
}

// 提取所有 contentKey 并转换为 JSON 对象数组
- (NSArray *)loadStrickModelArray {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"RongSticker" ofType:@"plist"];
    NSArray *plistArray = [NSArray arrayWithContentsOfFile:path];
    if (!plistArray) {
        NSLog(@"无法读取 PLIST 文件: RongSticker");
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSDictionary *item in plistArray) {
        NSString *contentKey = item[@"contentKey"];
        
        if (!contentKey || ![contentKey isKindOfClass:[NSString class]]) {
            continue;
        }
        
        // 转换字符串为 JSON 对象
        NSError *error = nil;
        NSData *data = [contentKey dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingMutableContainers
                                                        error:&error];
        
        if (error) {
            NSLog(@"JSON 解析错误: %@", error.localizedDescription);
            NSLog(@"原始字符串: %@", contentKey);
            continue;
        }
        
        if (jsonObject) {
            [result addObject:jsonObject];
        }
    }
    return [result copy];
}

- (NSArray<RCStickerCustomModel *> *)emojiArray {
    if (!_emojiArray) {
        _emojiArray = [NSArray array];
    }
    return _emojiArray;
}

- (NSAttributedString *)attributeString:(NSString *)content itemSize:(CGSize)itemSize {
    if (!content || content.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    NSString *imageString = [self matchSticker:content];
    if (!imageString || imageString.length == 0) {
        // 如果没有找到对应的表情，返回原始文本
        return [[NSAttributedString alloc] initWithString:content];
    }
    
    UIImage *image = [UIImage imageNamed:imageString inBundle:[self stickerBundle] compatibleWithTraitCollection:nil];
    
    if (!image) {
        // 如果图片加载失败，返回原始文本
        return [[NSAttributedString alloc] initWithString:content];
    }
    
    NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
    imageAttachment.image = image;
    
    // 调整图片大小（可根据需要调整）
    CGFloat imageHeight = itemSize.height;
    CGFloat imageWidth = itemSize.width;
    imageAttachment.bounds = CGRectMake(0, -5, imageWidth, imageHeight);
    
    return [NSAttributedString attributedStringWithAttachment:imageAttachment];
}

/// 获取表情资源包
- (NSBundle *)stickerBundle {
    // 根据实际情况调整bundle的获取方式
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *bundleURL = [mainBundle URLForResource:@"RongSticker" withExtension:@"bundle"];
    if (bundleURL) {
        return [NSBundle bundleWithURL:bundleURL];
    }
    // 如果找不到指定的bundle，返回主bundle
    return mainBundle;
}

- (RCStickerCustomModel *)tranformStickerModel:(NSString *)sticker {
    RCStickerCustomModel *model = [[RCStickerCustomModel alloc] init];
    if (!sticker || sticker.length == 0) {
        return model;
    }
    // 转换字符串为 JSON 对象
    NSError *error = nil;
    NSData *data = [sticker dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    if (error) {
        NSLog(@"JSON 解析错误: %@", error.localizedDescription);
        NSLog(@"原始字符串: %@", sticker);
        return model;
    }
    if (jsonObject) {
        model = [RCStickerCustomModel rcModelWithJson:jsonObject];
    }
    return model;
}

- (BOOL)containSticker:(NSString *)sticker {
    BOOL contain = NO;
    RCStickerCustomModel *model = [self tranformStickerModel:sticker];
    if (model.emojiData.length > 0 && contain == NO) {
        for (RCStickerCustomModel *localModel in self.emojiArray) {
            if ([localModel.emojiData isEqualToString:model.emojiData]) {
                contain = YES;
                break;
            }
        }
    }
    
    if (model.emojiId != 0 && contain == NO) {
        for (RCStickerCustomModel *localModel in self.emojiArray) {
            if (localModel.emojiId == model.emojiId) {
                contain = YES;
                break;
            }
        }
    }
    return contain;
}

- (NSString *)matchSticker:(NSString *)sticker {
    NSString *imageString = @"";
    BOOL match = NO;
    RCStickerCustomModel *model = [self tranformStickerModel:sticker];
    if (model.emojiData.length > 0 && match == NO) {
        for (RCStickerCustomModel *localModel in self.emojiArray) {
            if ([localModel.emojiData isEqualToString:model.emojiData]) {
                imageString = localModel.image;
                match = YES;
                break;
            }
        }
    }
    if (model.emojiId != 0 && match == NO) {
        for (RCStickerCustomModel *localModel in self.emojiArray) {
            if (localModel.emojiId == model.emojiId) {
                imageString = localModel.image;
                match = YES;
                break;
            }
        }
    }
    return imageString;
}

- (NSString *)transformJsonString:(RCStickerCustomModel *)model {
    NSString *jsonString = @"";
    NSDictionary *dictionary = [model rcDictionary];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&error];
    if (error) {
        NSLog(@"JSON 转换错误: %@", error.localizedDescription);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"JSON 字符串:\n%@", jsonString);
    }
    return jsonString;
}
    
@end
