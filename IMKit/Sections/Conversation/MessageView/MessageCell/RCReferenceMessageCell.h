//
//  RCReferenceMessageCell.h
//  RongIMKit
//
//  Created by RongCloud on 2020/2/27.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import "RongIMKit.h"
#import "RCAttributedLabel.h"
#import "RCReferencedContentView.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCReferenceMessageCell : RCMessageCell
/*!
 *  \~chinese
 引用内容展示的容器
 
 *  \~english
 A container for displaying reference contents 
 */
@property (nonatomic, strong) RCReferencedContentView *referencedContentView;

/*!
 *  \~chinese
 文本内容的Label
 
 *  \~english
 tag of text content
 */
@property (nonatomic, strong) RCAttributedLabel *contentLabel;

@end

NS_ASSUME_NONNULL_END
