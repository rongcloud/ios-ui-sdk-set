//
//  RCStickerHelper.h
//  RongCloudOpenSource
//
//  Created by SandBox01 on 2025/8/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RCStickerCustomModel;

@interface RCStickerHelper : NSObject

@property (nonatomic, strong, readonly) NSArray *emojiArray;

/// 获取单例实例
+ (instancetype)shared;

/// 将表情符号字符串转换为属性字符串
/// @param content 表情符号字符串
/// /// @param itemSize 表情符号大小
- (NSAttributedString *)attributeString:(NSString *)content itemSize:(CGSize)itemSize;

/// 获取所有表情符号数组
- (NSArray<NSDictionary *> *)emojiArray;

/// 预加载表情数据（可选，可在应用启动时调用）
- (void)preloadEmojiData;

/// 是否存在表情
- (BOOL)containSticker:(NSString *)sticker;

/// 模型转jsonSting
- (NSString *)transformJsonString:(RCStickerCustomModel *)model;
/// jsonString转模型
- (RCStickerCustomModel *)tranformStickerModel:(NSString *)sticker;

@end

NS_ASSUME_NONNULL_END
