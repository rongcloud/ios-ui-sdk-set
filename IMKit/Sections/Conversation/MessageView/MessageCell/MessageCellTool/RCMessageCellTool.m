//
//  RCMessageTool.m
//  RongIMKit
//
//  Created by 张改红 on 2020/6/11.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RCMessageCellTool.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
@implementation RCMessageCellTool
+ (UIImage *)getDefaultMessageCellBackgroundImage:(RCMessageModel *)model{
    UIImage *bubbleImage;
    if (MessageDirection_RECEIVE == model.messageDirection) {
        bubbleImage = RCResourceImage(@"chat_from_bg_normal");
    } else {
        if ([self isWhiteBubbleImageWithSendMesageCell:model.objectName]) {
            bubbleImage = RCResourceImage(@"chat_to_bg_white");
        }else{
            bubbleImage = RCResourceImage(@"chat_to_bg_normal");
        }
    }
    if ([RCKitUtility isRTL]) {
        bubbleImage = [bubbleImage imageFlippedForRightToLeftLayoutDirection];
    }
    bubbleImage = [self getResizableImage:bubbleImage];
    return bubbleImage;
}

+ (BOOL)isWhiteBubbleImageWithSendMesageCell:(NSString *)objectName{
    NSArray *list = @[@"RC:FileMsg",@"RC:CardMsg",[RCLocationMessage getObjectName]];
    if ([list containsObject:objectName]) {
        return YES;
    }
    return NO;
}

+ (CGFloat)getMessageContentViewMaxWidth{
    float screenRatio = 0.637;
    if (SCREEN_WIDTH <= 320) {
        screenRatio = 0.6;
    }
    float maxWidth = (int)(SCREEN_WIDTH * screenRatio) + 7;
    return maxWidth;
}

+ (CGSize)getThumbnailImageSize:(UIImage *)image{
    //图片消息最小值为 100 X 100，最大值为 240 X 240
    // 重新梳理规则，如下：
    // 1、宽高任意一边小于 100 时，如：20 X 40 ，则取最小边，按比例放大到 100 进行显示，如最大边超过240 时，居中截取 240
    // 进行显示
    // 2、宽高都小于 240 时，大于 100 时，如：120 X 140 ，则取最长边，按比例放大到 240 进行显示
    // 3、宽高任意一边大于240时，分两种情况：
    //(1）如果宽高比没有超过 2.4，等比压缩，取长边 240 进行显示。
    //(2）如果宽高比超过 2.4，等比缩放（压缩或者放大），取短边 100，长边居中截取 240 进行显示。
    CGSize imageSize = image.size;
    CGFloat imageMaxLength = 120;
    CGFloat imageMinLength = 50;
    if (imageSize.width == 0 || imageSize.height == 0) {
        return CGSizeMake(imageMaxLength, imageMinLength);
    }
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;
    if (imageSize.width < imageMinLength || imageSize.height < imageMinLength) {
        if (imageSize.width < imageSize.height) {
            imageWidth = imageMinLength;
            imageHeight = imageMinLength * imageSize.height / imageSize.width;
            if (imageHeight > imageMaxLength) {
                imageHeight = imageMaxLength;
            }
        } else {
            imageHeight = imageMinLength;
            imageWidth = imageMinLength * imageSize.width / imageSize.height;
            if (imageWidth > imageMaxLength) {
                imageWidth = imageMaxLength;
            }
        }
    } else if (imageSize.width < imageMaxLength && imageSize.height < imageMaxLength &&
               imageSize.width >= imageMinLength && imageSize.height >= imageMinLength) {
        if (imageSize.width > imageSize.height) {
            imageWidth = imageMaxLength;
            imageHeight = imageMaxLength * imageSize.height / imageSize.width;
        } else {
            imageHeight = imageMaxLength;
            imageWidth = imageMaxLength * imageSize.width / imageSize.height;
        }
    } else if (imageSize.width >= imageMaxLength || imageSize.height >= imageMaxLength) {
        if (imageSize.width > imageSize.height) {
            if (imageSize.width / imageSize.height < imageMaxLength / imageMinLength) {
                imageWidth = imageMaxLength;
                imageHeight = imageMaxLength * imageSize.height / imageSize.width;
            } else {
                imageHeight = imageMinLength;
                imageWidth = imageMinLength * imageSize.width / imageSize.height;
                if (imageWidth > imageMaxLength) {
                    imageWidth = imageMaxLength;
                }
            }
        } else {
            if (imageSize.height / imageSize.width < imageMaxLength / imageMinLength) {
                imageHeight = imageMaxLength;
                imageWidth = imageMaxLength * imageSize.width / imageSize.height;
            } else {
                imageWidth = imageMinLength;
                imageHeight = imageMinLength * imageSize.height / imageSize.width;
                if (imageHeight > imageMaxLength) {
                    imageHeight = imageMaxLength;
                }
            }
        }
    }
    return CGSizeMake(imageWidth, imageHeight);
}

+ (NSDictionary *)getTextLinkOrPhoneNumberAttributeDictionary:(RCMessageDirection)msgDirection{
    if (msgDirection == MessageDirection_SEND ) {
        return @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : RCDYCOLOR(0x0099ff, 0x005F9E)},@(NSTextCheckingTypeRegularExpression) : @{NSForegroundColorAttributeName : RCDYCOLOR(0x0099ff, 0x005F9E)},
                 @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : [RCKitUtility generateDynamicColor:HEXCOLOR(0x0099ff) darkColor:HEXCOLOR(0x005F9E)]
                 }
        };
    }else{
        return @{@(NSTextCheckingTypeLink) : @{NSForegroundColorAttributeName : RCDYCOLOR(0x0099ff, 0x1290e2)},@(NSTextCheckingTypeRegularExpression) : @{NSForegroundColorAttributeName : RCDYCOLOR(0x0099ff, 0x1290e2)},
                 @(NSTextCheckingTypePhoneNumber) : @{ NSForegroundColorAttributeName : [RCKitUtility generateDynamicColor:HEXCOLOR(0x0099ff) darkColor:HEXCOLOR(0x1290e2)]
                 }
        };
    }
    
}

#pragma mark - Private Methods
+ (UIImage *)getResizableImage:(UIImage *)image{
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height * 0.5, image.size.width * 0.5, image.size.height * 0.5, image.size.width * 0.5)];
}
@end
