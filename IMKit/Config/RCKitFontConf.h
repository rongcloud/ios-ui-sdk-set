//
//  RCKitFontConf.h
//  RongIMKit
//
//  Created by Sin on 2020/6/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
/*!
 *  \~chinese
 IMKit 字体配置
 IMKit 内部禁用 UIFont 构建字体，只通过该类构建字体，方便统一管理
 
 *  \~english
 IMKit font configuration
 * IMKit disables UIFont to build fonts internally, and only builds fonts through this class, which is convenient for unified management
 */
@interface RCKitFontConf : NSObject

/*!
 *  \~chinese
 一级标题，默认 fontSize 为 18
 
 *  \~english
 First-level title. Default fontSize is 18
 */
@property (nonatomic, assign) CGFloat firstLevel;

/*!
 *  \~chinese
 二级标题，默认 fontSize 为 17 (文本消息，引用消息内容，会话列表 title)
 
 *  \~english
 Second-level title, default fontSize is 17 (text message, reference message content, conversation list title)
 */
@property (nonatomic, assign) CGFloat secondLevel;

/*!
 *  \~chinese
 三级标题，默认 fontSize 为 15
 
 *  \~english
 Level 3 title. The default fontSize is 15
 */
@property (nonatomic, assign) CGFloat thirdLevel;

/*!
 *  \~chinese
 四级标题，默认 fontSize 为 14 (富文本消息的标题，小灰条消息，引用消息引用内容)
 
 *  \~english
 Level 4 title, default fontSize is 14 (rich text message title, small gray bar message, reference message reference content)
 */
@property (nonatomic, assign) CGFloat fourthLevel;

/*!
 *  \~chinese
 引导文字，默认 fontSize 为 13
 
 *  \~english
 Boot text, default fontSize is 13
 */
@property (nonatomic, assign) CGFloat guideLevel;

/*!
 *  \~chinese
 少数注释文字，默认 fontSize 为 12 (富文本消息的内容)
 
 *  \~english
 A small number of comment text, default fontSize is 12 (rich text message content)
 */
@property (nonatomic, assign) CGFloat annotationLevel;

/*!
 *  \~chinese
 极少数辅助说明，默认 fontSize 为 10 (gif 消息大小)
 
 *  \~english
 Few auxiliary instructions, default fontSize is 10 (gif message size)
 */
@property (nonatomic, assign) CGFloat assistantLevel;

/*!
 *  \~chinese
 firstLevel 的 font，默认 fontSize 为 18
 
 *  \~english
 FirstLevel front, the default fontSize is 18
 */
- (UIFont *)fontOfFirstLevel;

/*!
 *  \~chinese
 secondLevel 的 font，默认 fontSize 为 17
 
 *  \~english
 SecondLevel front, the default fontSize is 17
 */
- (UIFont *)fontOfSecondLevel;

/*!
 *  \~chinese
 thirdLevel 的 font，默认 fontSize 为 15
 
 *  \~english
 ThirdLevel front, the default fontSize is 15
 */
- (UIFont *)fontOfThirdLevel;

/*!
 *  \~chinese
 fourthLevel 的 font，默认 fontSize 为 14
 
 *  \~english
 fourthLevel front, the default fontSize is 14
 */
- (UIFont *)fontOfFourthLevel;

/*!
 *  \~chinese
 guideLevel 的 font，默认 fontSize 为 13
 
 *  \~english
 GuideLevel front, the default fontSize is 13
 */
- (UIFont *)fontOfGuideLevel;

/*!
 *  \~chinese
 annotationLevel 的 font，默认 fontSize 为 12
 
 *  \~english
 AnnotationLevel front, the default fontSize is 12
 */
- (UIFont *)fontOfAnnotationLevel;

/*!
 *  \~chinese
 assistantLevel 的 font，默认 fontSize 为 10
 
 *  \~english
 AssistantLevel  front, the default fontSize is 10
 */
- (UIFont *)fontOfAssistantLevel;

/*!
 *  \~chinese
 自定义字体大小
 * @param size 字体大小
 
 *  \~english
 *  Custom font size
 *  @param size  Font size
 */
- (UIFont *)fontOfSize:(CGFloat)size;
@end
