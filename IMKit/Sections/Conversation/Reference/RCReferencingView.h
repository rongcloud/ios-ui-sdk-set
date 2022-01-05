//
//  RCReferencingView.h
//  RongIMKit
//
//  Created by RongCloud on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCMessageModel.h"
@class RCReferencingView;

@protocol RCReferencingViewDelegate <NSObject>
@optional
- (void)didTapReferencingView:(RCMessageModel *)messageModel;

- (void)dismissReferencingView:(RCReferencingView *)referencingView;

@end

@interface RCReferencingView : UIView

/*!
 *  \~chinese
 关闭引用 button
 
 *  \~english
 Turn off reference button 
*/
@property (nonatomic, strong) UIButton *dismissButton;

/*!
 *  \~chinese
 被引用消息发送者名称
 
 *  \~english
 Name of the referenced message sender
*/
@property (nonatomic, strong) UILabel *nameLabel;

/*!
 *  \~chinese
 被引用消息内容文本 label
 
 *  \~english
 Content text label of referenced message
 */
@property (nonatomic, strong) UILabel *textLabel;

/*!
 *  \~chinese
 被引用消息体
 
 *  \~english
 Referenced message body
 */
@property (nonatomic, strong) RCMessageModel *referModel;
/*!
 *  \~chinese
 引用代理
 
 *  \~english
 Reference agent
 */
@property (nonatomic, weak) id<RCReferencingViewDelegate> delegate;
/*!
 *  \~chinese
 初始化引用 View
 
 *  \~english
 Initialize reference View
 */
- (instancetype)initWithModel:(RCMessageModel *)model inView:(UIView *)view;

/*!
 *  \~chinese
 当前 view 的 Y 值
 
 *  \~english
 Y value of the current view
*/
- (void)setOffsetY:(CGFloat)offsetY;
@end
