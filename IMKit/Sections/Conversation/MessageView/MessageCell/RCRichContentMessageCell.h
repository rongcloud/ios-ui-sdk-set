//
//  RCRichContentMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCAttributedLabel.h"
#import "RCMessageCell.h"

/*!
 *  \~chinese
 富文本（图文）消息Cell
 
 *  \~english
 Rich text (Teletext) message Cell 
 */
@interface RCRichContentMessageCell : RCMessageCell

/*!
 *  \~chinese
 图片内容显示的View
 
 *  \~english
 The View displayed in the image content.
 */
@property (nonatomic, strong) RCloudImageView *richContentImageView;

/*!
 *  \~chinese
 文本内容显示的Label
 
 *  \~english
 Label for text content display
 */
@property (nonatomic, strong) RCAttributedLabel *digestLabel;

/*!
 *  \~chinese
 标题显示的Label
 
 *  \~english
 Label displayed by title.
 */
@property (nonatomic, strong) RCAttributedLabel *titleLabel;

@end
