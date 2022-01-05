//
//  RCLocationMessageCell.h
//  RongIMKit
//
//  Created by xugang on 15/2/2.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCImageMessageProgressView.h"
#import "RCMessageCell.h"

/*!
 *  \~chinese
 位置消息Cell
 
 *  \~english
 Location message Cell 
 */
@interface RCLocationMessageCell : RCMessageCell

/*!
 *  \~chinese
 当前位置在地图中的概览图
 
 *  \~english
 An overview of the current location in the map
 */
@property (nonatomic, strong) UIImageView *pictureView;

/*!
 *  \~chinese
 显示位置名称的Label
 
 *  \~english
 Label for displaying the location name
 */
@property (nonatomic, strong) UILabel *locationNameLabel;

@end
