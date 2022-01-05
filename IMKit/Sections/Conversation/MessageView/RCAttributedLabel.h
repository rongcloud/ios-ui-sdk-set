//
//  RCAttributedLabel.h
//  iOS-IMKit
//
//  Created by YangZigang on 14/10/29.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  RCAttributedDataSource
 */
@protocol RCAttributedDataSource <NSObject>
/**
 *  attributeDictionaryForTextType
 *
 *  @param textType textType
 *
 *  @return return NSDictionary
 */
- (NSDictionary *)attributeDictionaryForTextType:(NSTextCheckingTypes)textType;
/**
 *  highlightedAttributeDictionaryForTextType
 *
 *  @param textType textType
 *
 *  @return NSDictionary
 */
- (NSDictionary *)highlightedAttributeDictionaryForTextType:(NSTextCheckingType)textType;

@end

@protocol RCAttributedLabelDelegate;

/**
 *  Override UILabel @property to accept both NSString and NSAttributedString
 */
@protocol RCAttributedLabel <NSObject>

/**
 *  text
 */
@property (nonatomic, copy) id text;

@end

/**
 *  RCAttributedLabel
 */
@interface RCAttributedLabel : UILabel <RCAttributedDataSource, UIGestureRecognizerDelegate>
/**
 *  \~chinese
 * 可以通过设置attributeDataSource或者attributeDictionary、highlightedAttributeDictionary来自定义不同文本的字体颜色
 
 *  \~english
 * you can customize the font colors of different text by setting attributeDataSource or attributeDictionary or highlightedAttributeDictionary. 
 */
@property (nonatomic, strong) id<RCAttributedDataSource> attributeDataSource;
/**
 *  \~chinese
 * 可以通过设置attributedStrings可以给一些字符添加点击事件等，例如在实现的会话列表里修改文本消息内容
 *  -(void)willDisplayConversationTableCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath{
 *
 *   if ([cell isKindOfClass:[RCTextMessageCell class]]) {
 *      RCTextMessageCell *newCell = (RCTextMessageCell *)cell;
 *      if (newCell.textLabel.text.length>3) {
 *          NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:(NSMakeRange(0,
 *3)) URL:[NSURL URLWithString:@"http://www.baidu.com"]]; [newCell.textLabel.attributedStrings
 *addObject:textCheckingResult]; [newCell.textLabel setTextHighlighted:YES atPoint:CGPointMake(0, 3)];
 *       }
 *    }
 *}
 
 *  \~english
 * You can add click events to some characters by setting attributedStrings, e.g. modifying the text message content in the list of implemented conversations.
 *  -(void)willDisplayConversationTableCell:(RCMessageBaseCell *)cell atIndexPath:(NSIndexPath *)indexPath{
 *
 *   if ([cell isKindOfClass:[RCTextMessageCell class]]) {
 *      RCTextMessageCell *newCell = (RCTextMessageCell *)cell;
 *      if (newCell.textLabel.text.length>3) {
 *          NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:(NSMakeRange(0,
 *3)) URL:[NSURL URLWithString:@"http://www.baidu.com"]]; [newCell.textLabel.attributedStrings
 *addObject:textCheckingResult]; [newCell.textLabel setTextHighlighted:YES atPoint:CGPointMake(0, 3)];
 *       }
 *    }
 *}
 *
 */
@property (nonatomic, strong) NSMutableArray *attributedStrings;
/*!
 *  \~chinese
 点击回调
 
 *  \~english
 Callback for clicking
 */
@property (nonatomic, weak) id<RCAttributedLabelDelegate> delegate;
/**
 *  attributeDictionary
 */
@property (nonatomic, strong) NSDictionary *attributeDictionary;
/**
 *  highlightedAttributeDictionary
 */
@property (nonatomic, strong) NSDictionary *highlightedAttributeDictionary;
/**
 *  \~chinese
 *  NSTextCheckingTypes 格式类型
 
 *  \~english
 * NSTextCheckingTypes format type.
 */
@property (nonatomic, assign) NSTextCheckingTypes textCheckingTypes;
/**
 *  \~chinese
 *  NSTextCheckingTypes current格式类型
 
 *  \~english
 * NSTextCheckingTypes current format type.
 */
@property (nonatomic, readonly, assign) NSTextCheckingType currentTextCheckingType;
/**
 *  setTextdataDetectorEnabled
 *
 *  @param text                text
 *  @param dataDetectorEnabled dataDetectorEnabled
 */
- (void)setText:(NSString *)text dataDetectorEnabled:(BOOL)dataDetectorEnabled;

/**
 *  setTextHighlighted
 *
 *  @param highlighted highlighted
 *  @param point       point
 */
- (void)setTextHighlighted:(BOOL)highlighted atPoint:(CGPoint)point;

@end

/*!
 *  \~chinese
 RCAttributedLabel点击回调
 
 *  \~english
 Callback for clicking RCAttributedtag 
 */
@protocol RCAttributedLabelDelegate <NSObject>
@optional

/*!
 *  \~chinese
 点击URL的回调

 @param label 当前Label
 @param url   点击的URL
 
 *  \~english
 Callback for clicking the URL.

 @param label Current label.
 @param url Clicked URL.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url;

/*!
 *  \~chinese
 点击电话号码的回调

 @param label       当前Label
 @param phoneNumber 点击的URL
 
 *  \~english
 Callback for clicking the phone number.

 @param label Current label.
 @param phoneNumber Clicked URL.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber;

/*!
 *  \~chinese
 点击Label的回调

 @param label   当前Label
 @param content 点击的内容
 
 *  \~english
 Callback for clicking label

 @param label Current label.
 @param content Clicked content.
 */
- (void)attributedLabel:(RCAttributedLabel *)label didTapLabel:(NSString *)content;

@end
