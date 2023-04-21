//
//  RCiFlyKitExtensionModule.m
//  RongiFlyKit
//
//  Created by Sin on 16/11/15.
//  Copyright © 2016年 Sin. All rights reserved.
//

#pragma clang diagnostic ignored "-Wincomplete-umbrella"
#import "RCiFlyKitExtensionModule.h"
#import "RCiFlyInputView.h"
#import <iflyMSC/iflyMSC.h>
#import "RongiFlyAdaptiveHeader.h"
//默认的讯飞输入sdk的appKey
#define iFlyKey @""
@interface UIImage (RCDynamicImage)
+ (UIImage *)rc_imageWithLocalPath:(NSString *)path;
@property (nonatomic, copy) NSString *rc_imageLocalPath;
- (BOOL)rc_needReloadImage;
@end

@interface RCiFlyKitExtensionModule () <RCiFlyInputViewDelegate>
@property (nonatomic, strong) RCiFlyInputView *iflyInputView;
@property (nonatomic, strong) RCChatSessionInputBarControl *chatBarControl;
@property (nonatomic, assign) RCConversationType conversationType;
@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, assign) KBottomBarStatus currentStatus;
@property (nonatomic, copy) NSString *iflyAppKey;
@end

@implementation RCiFlyKitExtensionModule
+ (instancetype)loadRongExtensionModule {
    return [self sharedRCiFlyKitExtensionModule];
}

+ (instancetype)sharedRCiFlyKitExtensionModule {
    static RCiFlyKitExtensionModule *module = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        module = [[self alloc] init];
        module.iflyAppKey = iFlyKey;
    });
    return module;
}

- (void)destroyModule {
}

- (BOOL)isAudioHolding {
    return self.isSpeechHolding;
}

- (void)setiFlyAppkey:(NSString *)key {
    _iflyAppKey = key;
}

- (void)inputBarStatusDidChange:(KBottomBarStatus)status inInputBar:(RCChatSessionInputBarControl *)inputBarControl {
    if (KBottomBarPluginStatus == _currentStatus && KBottomBarPluginStatus != status) {
        if (!_iflyInputView) {
            return;
        }
        [_iflyInputView stopListening];
        // 记录 audio 使用状态
        self.isSpeechHolding = NO;
    }
    _currentStatus = status;
}
- (void)didTapMessageCell:(RCMessageModel *)messageModel {
}

- (NSArray<RCExtensionPluginItemInfo *> *)getPluginBoardItemInfoList:(RCConversationType)conversationType
                                                            targetId:(NSString *)targetId {

    __weak typeof(self) ws = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //创建语音配置,appid必须要传入，仅执行一次则可
        NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", ws.iflyAppKey];
        if (ws.iflyAppKey.length == 0) {
            RCLogE(@"iflyAppKey is nil, "
                   @"请参考讯飞官网(https://www.xfyun.cn/doc/asr/voicedictation/"
                   @"iOS-SDK.html)注册账号，在讯飞开放平台申请应用获得 appkey, 下载与 appkey 绑定的 iflyMSC.framework "
                   @"库,之后调用 RCiFlyKit 类中方法 setiFlyAppKey 注册 appkey");
            return;
        }
        //所有服务启动前，需要确保执行createUtility
        [IFlySpeechUtility createUtility:initString];
    });
    if (conversationType != ConversationType_Encrypted) {
        self.conversationType = conversationType;
        self.targetId = targetId;
    }

    NSMutableArray *itemList = [[NSMutableArray alloc] init];

    RCExtensionPluginItemInfo *item = [[RCExtensionPluginItemInfo alloc] init];
    item.normalImage = [self imageFromiFlyBundle:@"plugin_item_voice_input"];
    item.highlightedImage = [self imageFromiFlyBundle:@"plugin_item_voice_input_highlighted"];
    item.title = RCLocalizedString(@"VoiceInput");
    item.tapBlock = ^(RCChatSessionInputBarControl *chatSessionInputBar) {
        [ws checkPermissionIfSuccess:chatSessionInputBar];
    };
    item.tag = PLUGIN_BOARD_ITEM_VOICE_INPUT_TAG;
    [itemList addObject:item];
    return [itemList copy];
}

- (void)checkPermissionIfSuccess:(RCChatSessionInputBarControl *)chatSessionInputBar {
    __weak typeof(self) ws = self;
    [self checkRecordPermission:^{
        // 记录 audio 使用状态
        ws.isSpeechHolding = YES;
        
        ws.chatBarControl = chatSessionInputBar;
        [chatSessionInputBar.pluginBoardView.extensionView setHidden:NO];
        [chatSessionInputBar.pluginBoardView.extensionView addSubview:ws.iflyInputView];
        CGRect frame = chatSessionInputBar.pluginBoardView.extensionView.frame;
        if (frame.size.width != chatSessionInputBar.frame.size.width) {
            frame.size.width = chatSessionInputBar.frame.size.width;
            chatSessionInputBar.pluginBoardView.extensionView.frame = frame;
        }
        [ws.iflyInputView show:YES inputBarWidth:chatSessionInputBar.frame.size.width];
        NSString *text = chatSessionInputBar.inputTextView.text;
        if (text.length > 0) {
            [ws.iflyInputView showBottom:YES];
        }
    }];
}

- (UIImage *)imageFromiFlyBundle:(NSString *)imageName {
    NSString *imagePath = [[[NSBundle mainBundle] pathForResource:@"RongCloudiFly" ofType:@"bundle"]
        stringByAppendingPathComponent:imageName];
    if (![imagePath hasSuffix:@".png"]) {
        imagePath = [NSString stringWithFormat:@"%@.png", imagePath];
    }
    UIImage *bundleImage = [UIImage rc_imageWithLocalPath:imagePath];
    return bundleImage;
}

- (RCiFlyInputView *)iflyInputView {
    if (!_iflyInputView) {
        _iflyInputView =
            [RCiFlyInputView iFlyInputViewWithFrame:self.chatBarControl.pluginBoardView.extensionView.bounds];
        _iflyInputView.backgroundColor = [UIColor clearColor];
        _iflyInputView.delegate = self;
    }
    return _iflyInputView;
}

#pragma mark - RCiFlyInputViewDelegate
//清空按钮的点击回调
- (void)clearText {
    self.chatBarControl.inputTextView.text = @"";
}

//发送按钮的点击回调
- (void)sendText {
    NSString *text = self.chatBarControl.inputTextView.text;
    if ([text isEqualToString:@""] || text.length < 1) {
        self.chatBarControl.inputTextView.text = @"";
        return;
    }
    RCTextMessage *txtMsg = [RCTextMessage messageWithContent:text];
    [[RCIM sharedRCIM] sendMessage:self.conversationType
                          targetId:self.targetId
                           content:txtMsg
                       pushContent:nil
                          pushData:nil
                           success:nil
                             error:nil];
    //发送完成清空输入框内容
    self.chatBarControl.inputTextView.text = @"";
}

//正常解析到文本的回调
- (void)voiceTransferToText:(NSString *)text {
    NSString *txt = self.chatBarControl.inputTextView.text;
    self.chatBarControl.inputTextView.text = [NSString stringWithFormat:@"%@%@", txt, text];
    
    [self.chatBarControl endVoiceTransfer];
}

//发生错误的回调
- (void)onError:(NSString *)errDesc {
}

- (void)checkRecordPermission:(void (^)(void))successBlock {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        BOOL firstTime = NO;
        if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(recordPermission)]) {
            firstTime = [AVAudioSession sharedInstance].recordPermission == AVAudioSessionRecordPermissionUndetermined;
        }
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    if (!firstTime) {
                        successBlock();
                    }
                } else {
                    UIViewController *rootVC = [RCKitUtility getKeyWindow].rootViewController;
                    UIAlertController *alertController = [UIAlertController
                        alertControllerWithTitle:RCLocalizedString(@"AccessRightTitle")
                                         message:RCLocalizedString(@"speakerAccessRight")
                                  preferredStyle:UIAlertControllerStyleAlert];
                    [alertController
                        addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"OK")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil]];
                    [rootVC presentViewController:alertController animated:YES completion:nil];
                }
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock();
        });
    }
}

@end
