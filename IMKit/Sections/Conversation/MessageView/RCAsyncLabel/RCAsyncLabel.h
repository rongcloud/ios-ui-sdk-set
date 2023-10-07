//
//  RCAsyncLabel.h
//  CartoonTest
//
//  Created by RobinCui on 2022/5/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol RCAsyncLabelDelegate;

@interface RCAsyncLabel : UIView
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, weak) id<RCAsyncLabelDelegate> delegate;

/**
 *  attributeDictionary
 */
@property (nonatomic, strong) NSDictionary *attributeDictionary;
/**
 *  highlightedAttributeDictionary
 */
@property (nonatomic, strong) NSDictionary *highlightedAttributeDictionary;
 
@end


/*!
 RCAttributedLabel点击回调
 */
@protocol RCAsyncLabelDelegate <NSObject>
@optional


- (NSDictionary *)textAttributesInfo;


/// 是否支持检测特殊字符: 电话 链接
- (BOOL)shouldDetectText;
/*!
 点击URL的回调

 @param label 当前Label
 @param url   点击的URL
 */
- (void)asyncLabel:(RCAsyncLabel *)label didSelectLinkWithURL:(NSURL *)url;

/*!
 点击电话号码的回调

 @param label       当前Label
 @param phoneNumber 点击的URL
 */
- (void)asyncLabel:(RCAsyncLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber;

/*!
 点击Label的回调

 @param label   当前Label
 @param content 点击的内容
 */
- (void)didTapAsyncLabel:(RCAsyncLabel *)label;
@end
NS_ASSUME_NONNULL_END
