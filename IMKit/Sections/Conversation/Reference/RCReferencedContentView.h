//
//  RCReferencedContentView.h
//  RongIMKit
//
//  Created by RongCloud on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCMessageModel.h"
#define name_and_image_view_space 5
@protocol RCReferencedContentViewDelegate <NSObject>
@optional

- (void)didTapReferencedContentView:(RCMessageModel *)message;

@end
@interface RCReferencedContentView : UIView
/*!
 *  \~chinese
 被引用消息显示左边线
 
 *  \~english
 The referenced message shows the left side of the line 
 */
@property (nonatomic, strong) UIView *leftLimitLine;

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
 被引用图片消息显示的 View
 
 *  \~english
 View displayed by referenced image message
*/
@property (nonatomic, strong) UIImageView *msgImageView;

@property (nonatomic, weak) id<RCReferencedContentViewDelegate> delegate;

- (void)setMessage:(RCMessageModel *)message contentSize:(CGSize)contentSize;
@end
