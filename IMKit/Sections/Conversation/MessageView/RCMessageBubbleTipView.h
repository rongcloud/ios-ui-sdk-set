//
//  RCMessageBubbleTipView.h
//  RCIM
//
//  Created by xugang on 14-6-20.
//  Copyright (c) 2014 xugang. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 角标的位置
 
 *  \~english
 The position of the superscript mark 
 */
typedef NS_ENUM(NSInteger, RCMessageBubbleTipViewAlignment) {
    /*!
     *  \~chinese
     左上
     
     *  \~english
     Upper left
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT,
    /*!
     *  \~chinese
     右上
     
     *  \~english
     Upper right
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT,
    /*!
     *  \~chinese
     中上
     
     *  \~english
     Upper middle
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_CENTER,
    /*!
     *  \~chinese
     左中
     
     *  \~english
     Middle left
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_LEFT,
    /*!
     *  \~chinese
     右中
     
     *  \~english
     Middle right
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_RIGHT,
    /*!
     *  \~chinese
     左下
     
     *  \~english
     Lower left
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_LEFT,
    /*!
     *  \~chinese
     右下
     
     *  \~english
     Lower right
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_RIGHT,
    /*!
     *  \~chinese
     中下
     
     *  \~english
     Middle and lower
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_CENTER,
    /*!
     *  \~chinese
     正中
     
     *  \~english
     In the middle
     */
    RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER
};

/*!
 *  \~chinese
 消息未读提示角标的View
 
 *  \~english
 The message did not read the View of the prompt corner tag
 */
@interface RCMessageBubbleTipView : UIView

/*!
 *  \~chinese
 角标显示的文本
 
 *  \~english
 Text displayed by superscript mark
 */
@property (nonatomic, copy) NSString *bubbleTipText;

/*!
 *  \~chinese
 The color of the superscript text.
 角标的位置

 @discussion 默认值为RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT，即右上。
 
 *  \~english
 The position of the superscript mark.

 @ discussion The default value is RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT, which is the upper right.
 */
@property (nonatomic, assign) RCMessageBubbleTipViewAlignment bubbleTipAlignment;

/*!
 *  \~chinese
 角标文本的颜色
 
 *  \~english
 The color of the superscript text.
 */
@property (nonatomic, strong) UIColor *bubbleTipTextColor;

/*!
 *  \~chinese
 角标文本的阴影值
 
 *  \~english
 Shadow value of corner tag text.
 */
@property (nonatomic, assign) CGSize bubbleTipTextShadowOffset;

/*!
 *  \~chinese
 角标文本的阴影颜色
 
 *  \~english
 Shadow color of superscript text.
 */
@property (nonatomic, strong) UIColor *bubbleTipTextShadowColor;

/*!
 *  \~chinese
 角标文本的字体
 
 *  \~english
 Font of superscript text
 */
@property (nonatomic, strong) UIFont *bubbleTipTextFont;

/*!
 *  \~chinese
 角标的背景颜色
 
 *  \~english
 The background color of the superscript mark.
 */
@property (nonatomic, strong) UIColor *bubbleTipBackgroundColor;

/*!
 *  \~chinese
 角标View偏移的Rect
 
 *  \~english
 Rect of angle mark View offset.
 */
@property (nonatomic, assign) CGPoint bubbleTipPositionAdjustment;

/*!
 *  \~chinese
 角标依附于的View Rect
 
 *  \~english
 The View Rect to which the superscript mark is attached
 */
@property (nonatomic, assign) CGRect frameToPositionInRelationWith;

/*!
 *  \~chinese
 角标是否显示数字

 @discussion 如果为NO，会显示红点，不显示具体数字。
 
 *  \~english
 Does the superscript mark show a number?

 @ discussion display a red dot if it is NO, but do not show a specific number.
 */
@property (nonatomic) BOOL isShowNotificationNumber;

/*!
 *  \~chinese
 初始化角标View

 @param parentView  角标依附于的View
 @param alignment   角标的位置
 @return            角标View对象
 
 *  \~english
 Initialize the superscript mark View.

 @param parentView The View to which the superscript mark is attached.
 @param alignment The position of the superscript mark.
 @ return Corner View object.
 */
- (instancetype)initWithParentView:(UIView *)parentView alignment:(RCMessageBubbleTipViewAlignment)alignment;

/*!
 *  \~chinese
 设置角标的值

 @param msgCount 角标值
 
 *  \~english
 Set the value of the superscript mark.

 @param msgCount superscript value.
 */
- (void)setBubbleTipNumber:(int)msgCount;

@end
