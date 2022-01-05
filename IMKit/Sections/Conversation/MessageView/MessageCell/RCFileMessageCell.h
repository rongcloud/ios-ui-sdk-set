//
//  RCFileMessageCell.h
//  RongIMKit
//
//  Created by liulin on 16/7/21.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"
#import <UIKit/UIKit.h>
#import "RCProgressView.h"
/*!
 *  \~chinese
 文件消息Cell
 
 *  \~english
 File message Cell 
 */
@interface RCFileMessageCell : RCMessageCell

/*!
 *  \~chinese
 显示文件名的Label
 
 *  \~english
 Label for displaying the file name
 */
@property (strong, nonatomic) UILabel *nameLabel;

/*!
 *  \~chinese
 显示文件大小的Label
 
 *  \~english
 Label for displaying the file size
 */
@property (strong, nonatomic) UILabel *sizeLabel;

/*!
 *  \~chinese
 文件类型的ImageView
 
 *  \~english
 ImageView of the file type
 */
@property (strong, nonatomic) UIImageView *typeIconView;

/*!
 *  \~chinese
 上传或下载的进度条View
 
 *  \~english
 View for uploading or downloading progress bar
 */
@property (nonatomic, strong) RCProgressView *progressView;

/*!
 *  \~chinese
 取消发送的Button
 
 *  \~english
 Button for canceling sending
 */
@property (nonatomic, strong) UIButton *cancelSendButton;

/*!
 *  \~chinese
 显示“已取消”的Label
 
 *  \~english
 Label for showing “canceled”
 */
@property (nonatomic, strong) UILabel *cancelLabel;

@end
