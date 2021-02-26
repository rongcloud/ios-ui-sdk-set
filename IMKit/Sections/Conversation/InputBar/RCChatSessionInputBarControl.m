//
//  RCChatSessionInputBarControl.m
//  RongExtensionKit
//
//  Created by xugang on 15/2/12.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCChatSessionInputBarControl.h"
#import "RCAlumListTableViewController.h"
#import "RCAssetHelper.h"
#import "RCKitCommonDefine.h"
#import "RCExtensionService.h"
#import "RCFileSelectorViewController.h"
#import "RCLocationPickerViewController.h"
#import "RCMentionedStringRangeInfo.h"

#import "RCUserListViewController.h"
#import "RCExtNavigationController.h"
#import <CoreText/CoreText.h>
#import "RCCommonPhrasesListView.h"
#import "RCVoiceRecordControl.h"
#import "RCAlertView.h"
#import "RCKitConfig.h"
#import "RCActionSheetView.h"
#import "RCInputContainerView+internal.h"
#import "RCSightViewController+imkit.h"

//单个cell的高度是70（RCPlaginBoardCellSize）*2 + 上下padding的高度14*2 ＋
//上下两个图标之间的padding
#define Height_EmojBoardView 223.5f
#define Height_PluginBoardView 223.5f
#define Height_CommonPhrasesView 223.5f
#define RC_CommonPhrasesView_Height 38

// 标准系统状态栏高度
#define SYS_STATUSBAR_HEIGHT 20
// 热门栏高度
#define HOTSPOT_STATUSBAR_HEIGHT 20
#define APP_STATUSBAR_HEIGHT (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame))
// 根据APP_STATUSBAR_HEIGHT判断是不是存在热门栏
#define IS_HOTSPOT_CONNECTED (APP_STATUSBAR_HEIGHT == (SYS_STATUSBAR_HEIGHT + HOTSPOT_STATUSBAR_HEIGHT) ? YES : NO)

#define SwitchButtonWidth 44

@interface RCChatSessionInputBarControl () <RCEmojiViewDelegate, RCPluginBoardViewDelegate, UINavigationControllerDelegate,
    UIImagePickerControllerDelegate, RCLocationPickerViewControllerDelegate, RCAlbumListViewControllerDelegate,
    RCFileSelectorViewControllerDelegate, RCSelectingUserDataSource,
    RCCommonPhrasesListViewDelegate, RCVoiceRecordControlDelegate, RCInputContainerViewDelegate,
    RCMenuContainerViewDelegate>

@property (nonatomic) CGRect keyboardFrame;

@property (nonatomic) BOOL isContainViewAppeared;

@property (nonatomic) int isNew;

@property (nonatomic, strong) RCVoiceRecordControl *voiceRecordControl;

@property (nonatomic, assign, readonly) CGFloat inputBarHeight;

@property (nonatomic, strong) NSMutableArray *mentionedRangeInfoList;

@property (nonatomic, strong) NSMutableDictionary *pluginTapBlockDic;

@property (nonatomic, assign) RCChatSessionInputBarControlType currentControlType;

@property (nonatomic, assign) RCChatSessionInputBarControlStyle currentControlStyle;

@property (nonatomic, strong) NSArray *commonPhrasesSource;

@property (nonatomic, strong) UIView *commonPhrasesView;

@property (nonatomic, strong) UIButton *commonPhrasesButton;

@property (nonatomic, strong) RCCommonPhrasesListView *commonPhrasesListView;

@end

@implementation RCChatSessionInputBarControl
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame
            withContainerView:(UIView *)containerView
                  controlType:(RCChatSessionInputBarControlType)controlType
                 controlStyle:(RCChatSessionInputBarControlStyle)controlStyle
             defaultInputType:(RCChatSessionInputBarInputType)defaultInputType {
    self = [super initWithFrame:frame];
    if (self) {
        _containerView = containerView;
        [self rcinit];
        [self setInputBarType:controlType style:controlStyle];
        [self setDefaultInputType:defaultInputType];
    }
    return self;
}

- (void)rcinit {
    self.backgroundColor = RCDYCOLOR(0xF5F6F9, 0x1c1c1c);
    self.keyboardFrame = CGRectZero;
    self.isNew = 0;
    [self addBottomAreaView];
}

#pragma mark - Super Methods
- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    if ([self.delegate respondsToSelector:@selector(chatInputBar:shouldChangeFrame:)]) {
        [self.delegate chatInputBar:self shouldChangeFrame:frame];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    //上边线
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
    layer.backgroundColor = RCDYCOLOR(0xe3e5e6, 0x2f2f2f).CGColor;
    [self.layer addSublayer:layer];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(onSubMenuPushed:)) {
        return YES;
    }
    return NO; //隐藏系统默认的菜单项
}

#pragma mark - Public Methods
- (void)setInputBarType:(RCChatSessionInputBarControlType)type style:(RCChatSessionInputBarControlStyle)style {
    self.currentControlType = type;
    self.currentControlStyle = style;
    [self resetInputBar];
    if (self.commonPhrasesSource.count > 0 && (self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP)) {
        [self addSubview:self.commonPhrasesView];
    }

    if (RCChatSessionInputBarControlDefaultType == type) {
        [self addSubview:self.inputContainerView];
    } else if (type == RCChatSessionInputBarControlPubType) {
        self.inputContainerView.hidden = YES;
        self.menuContainerView.hidden = NO;
        [self addSubview:self.inputContainerView];
        [self addSubview:self.menuContainerView];
        [self addSubview:self.pubSwitchButton];
    } else if (type == RCChatSessionInputBarControlCSRobotType) {
        self.inputContainerView.hidden = NO;
        [self addSubview:self.inputContainerView];
        [self addSubview:self.robotSwitchButton];
    } else if (type == RCChatSessionInputBarControlNoAvailableType) {
        [self addSubview:_inputContainerView];
        [self.inputTextView setEditable:NO];
        [self.emojiButton setEnabled:NO];
    }
    [self updateSubviewsLayout];
    [self setDraft:self.inputTextView.text];
}

- (void)addMentionedUser:(RCUserInfo *)userInfo {
    [self insertMentionedUser:userInfo symbolRequset:YES];
}

- (void)pluginBoardView:(RCPluginBoardView *)pluginBoardView clickedItemWithTag:(NSInteger)tag {
    if ([self.delegate respondsToSelector:@selector(pluginBoardView:clickedItemWithTag:)]) {
        [self.delegate pluginBoardView:pluginBoardView clickedItemWithTag:tag];
    }
}

// 打开相册
- (void)openSystemAlbum {
    RCAlumListTableViewController *albumListVC = [[RCAlumListTableViewController alloc] init];
    albumListVC.delegate = self;
    albumListVC.photoEditEnable = [self photoEditEnable];
    RCExtNavigationController *rootVC = [[RCExtNavigationController alloc] initWithRootViewController:albumListVC];
    [self.delegate presentViewController:rootVC functionTag:PLUGIN_BOARD_ITEM_ALBUM_TAG];
}

// 打开相机
- (void)openSystemCamera {
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined) {
        [self requestCameraAccess:^(BOOL granted) {
            if (granted) {
                [self startCamera];
            } else {
                [self checkAndAlertCameraAccessRight];
            }
        }];
    } else {
        if ([self checkAndAlertCameraAccessRight]) {
            [self startCamera];
        }
    }
}

- (void)requestCameraAccess:(void (^)(BOOL granted))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                handler(YES);
            } else {
                handler(NO);
            }
        });
    }];
}

- (void)startCamera {
    Class sightType = NSClassFromString(@"RCSightViewController");
    if (sightType) {
        if ([[RCExtensionService sharedService] isAudioHolding] ||
            [[RCExtensionService sharedService] isCameraHolding]) {
            NSString *alertMessage =
            [[RCExtensionService sharedService] isCameraHolding]
            ? RCLocalizedString(@"VoIPVideoCallExistedWarning")
            : RCLocalizedString(@"VoIPAudioCallExistedWarning");
            [RCAlertView showAlertController:alertMessage message:nil hiddenAfterDelay:1 inViewController:nil];
            return;
        }
        RCSightViewController *svc = [[sightType alloc] init];
        svc.delegate = self;
        [self.delegate presentViewController:svc functionTag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
#if TARGET_IPHONE_SIMULATOR
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
        [self.delegate presentViewController:picker functionTag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
    }
}

- (void)locationPicker:(RCLocationPickerViewController *)locationPicker
     didSelectLocation:(CLLocationCoordinate2D)location
          locationName:(NSString *)locationName
         mapScreenShot:(UIImage *)mapScreenShot {
    if ([self.delegate respondsToSelector:@selector(locationDidSelect:locationName:mapScreenShot:)]) {
        [self.delegate locationDidSelect:location locationName:locationName mapScreenShot:mapScreenShot];
    }
}

//打开地理位置拾取器
- (void)openLocationPicker {
    RCLocationPickerViewController *picker = [[RCLocationPickerViewController alloc] init];
    picker.delegate = self;
    UINavigationController *rootVC = [[UINavigationController alloc] initWithRootViewController:picker];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate presentViewController:rootVC functionTag:PLUGIN_BOARD_ITEM_LOCATION_TAG];
    });
}

//进入选择文件页面
- (void)openFileSelector {
    RCFileSelectorViewController *picker =
        [[RCFileSelectorViewController alloc] initWithRootPath:[RCIMClient sharedRCIMClient].fileStoragePath];
    picker.delegate = self;
    UINavigationController *rootVC = [[UINavigationController alloc] initWithRootViewController:picker];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate presentViewController:rootVC functionTag:PLUGIN_BOARD_ITEM_FILE_TAG];
    });
}

- (void)openDynamicFunction:(NSInteger)functionTag {
    if (self.pluginTapBlockDic[@(functionTag)]) {
        RCConversationPluginItemTapBlock tapBlock = self.pluginTapBlockDic[@(functionTag)];
        tapBlock(self);
    }
}

- (BOOL)setCommonPhrasesList:(NSArray<NSString *> *)commonPhrasesList {
    if (commonPhrasesList.count <= 0) {
        return NO;
    }
    for (NSString *commonPhrasesStr in commonPhrasesList) {
        if (commonPhrasesStr.length <= 0) {
            RCLogI(@"Common Phrases list Each content can be configured with up to 30 words");
            return NO;
        }
    }
    if (self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP) {
        self.commonPhrasesSource = commonPhrasesList;
        self.commonPhrasesListView.dataSource = commonPhrasesList;
        CGRect currentFrame = self.frame;
        self.frame = CGRectMake(currentFrame.origin.x, currentFrame.origin.y-RC_CommonPhrasesView_Height, currentFrame.size.width,
                                RC_CommonPhrasesView_Height + RC_ChatSessionInputBar_Height);
        [self resetInputContainerView];
        return YES;
    } else {
        RCLogI(@"Common Phrases list conversationType must be ConversationType_PRIVATE or ConversationType_GROUP");
    }
    return NO;
}

- (void)containerViewWillAppear {
    self.isContainViewAppeared = YES;
    [self rcInputBar_registerForNotifications];
    if (_isNew == 0) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO];
    }
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO];
    }
}

- (void)containerViewDidAppear {
    if (self.inputTextView.text && self.inputTextView.text.length > 0 &&
        (self.currentBottomBarStatus == KBottomBarKeyboardStatus ||
         (self.currentBottomBarStatus == KBottomBarDefaultStatus && _isNew == 0) ||
         self.currentBottomBarStatus == KBottomBarDestructStatus)) {
        [self changeTextViewHeight:self.inputTextView.text];
    }
    _isNew = 1;
}

- (void)containerViewWillDisappear {
    self.isContainViewAppeared = NO;
    [self rcInputBar_unregisterForNotifications];
}

- (void)containerViewSizeChangedNoAnnimation {
    [self updateSubviewsLayout];
    [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:NO];
}

- (void)containerViewSizeChanged {
    [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:YES];
}

- (void)updateStatus:(KBottomBarStatus)inputBarStatus animated:(BOOL)animated {
    [self animationLayoutBottomBarWithStatus:inputBarStatus animated:animated];
}

- (void)resetToDefaultStatus {
    [self dismissPublicServiceMenuPopupView];
    if (self.currentBottomBarStatus != KBottomBarDefaultStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    }
}

- (void)setDefaultInputType:(RCChatSessionInputBarInputType)defaultInputType {
    if (defaultInputType == RCChatSessionInputBarInputVoice) {
        [self animationLayoutBottomBarWithStatus:KBottomBarRecordStatus animated:YES];
    } else if (defaultInputType == RCChatSessionInputBarInputExtention) {
        [self animationLayoutBottomBarWithStatus:KBottomBarPluginStatus animated:YES];
    } else if (defaultInputType == RCChatSessionInputBarInputDestructMode) {
        [self resetToDefaultStatus];
        [self animationLayoutBottomBarWithStatus:KBottomBarDestructStatus animated:YES];
    }
}

- (void)cancelVoiceRecord {
    [self.voiceRecordControl onCancelRecordEvent];
}

- (void)endVoiceRecord {
    [self.voiceRecordControl onEndRecordEvent];
}

#pragma mark - RCVoiceRecordControlDelegate
- (BOOL)recordWillBegin{
    if ([self.delegate respondsToSelector:@selector(recordWillBegin)]) {
        RCLogF(@"recordWillBegin:==============> %d", [self.delegate recordWillBegin]);
        return [self.delegate recordWillBegin];
    }
    return YES;
}

- (void)voiceRecordControlDidBegin:(RCVoiceRecordControl *)voiceRecordControl {
    if ([self.delegate respondsToSelector:@selector(recordDidBegin)]) {
        [self.delegate recordDidBegin];
    }
}

- (void)voiceRecordControlDidCancel:(RCVoiceRecordControl *)voiceRecordControl {
    if ([self.delegate respondsToSelector:@selector(recordDidCancel)]) {
        [self.delegate recordDidCancel];
    }
}

- (void)voiceRecordControl:(RCVoiceRecordControl *)voiceRecordControl
                    didEnd:(NSData *)recordData
                  duration:(long)duration
                     error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(recordDidEnd:duration:error:)]) {
        [self.delegate recordDidEnd:recordData duration:duration error:nil];
    }
}

#pragma mark - RCInputContainerViewDelegate
- (void)inputContainerViewSwitchButtonClicked:(RCInputContainerView *)inputContainerView {
    if (self.currentBottomBarStatus == KBottomBarRecordStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarRecordStatus animated:YES];
    }
}

- (void)inputContainerViewEmojiButtonClicked:(RCInputContainerView *)inputContainerView {
    if (self.destructMessageMode) {
        [self openDestructAlbum];
        return;
    }
    if (self.currentBottomBarStatus == KBottomBarEmojiStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarEmojiStatus animated:YES];
    }
    [self enableEmojiBoardViewSendButton];
}

- (void)inputContainerViewAdditionalButtonClicked:(RCInputContainerView *)inputContainerView {
    if (self.destructMessageMode) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
        return;
    }
    if (RC_IOS_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [[RCAssetHelper shareAssetHelper] hasAuthorizationStatusAuthorized];
    }
    if (self.currentBottomBarStatus == KBottomBarPluginStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarPluginStatus animated:YES];
    }
}

- (void)inputContainerView:(RCInputContainerView *)inputContainerView forControlEvents:(UIControlEvents)controlEvents {
    [self didTouchRecordButtonEvent:controlEvents];
}

- (void)inputContainerView:(RCInputContainerView *)inputContainerView didChangeFrame:(CGRect)frame {
    CGRect vRect = self.frame;
    if ((self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP) && self.commonPhrasesSource.count > 0) {
        vRect.size.height = frame.size.height + RC_CommonPhrasesView_Height;
    } else {
        vRect.size.height = frame.size.height;
    }
    vRect.origin.y += self.frame.size.height - vRect.size.height;
    self.frame = vRect;
}

- (BOOL)inputTextView:(UITextView *)inputTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([self.delegate respondsToSelector:@selector(inputTextView:shouldChangeTextInRange:replacementText:)]) {
        [self.delegate inputTextView:inputTextView shouldChangeTextInRange:range replacementText:text];
    }

    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(inputTextViewDidTouchSendKey:)]) {
            NSString *formatString =
                [inputTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (formatString.length > 0) {
                [self.delegate inputTextViewDidTouchSendKey:inputTextView];
                [self.mentionedRangeInfoList removeAllObjects];
            }
        }
        DebugLog(@"Enter key call inputTextViewDidChange");
        return NO;
    }

    BOOL shouldUseDefaultChangeText = [self willUpdateInputTextMetionedInfo:text range:range];
    return shouldUseDefaultChangeText;
}

#pragma mark - RCMenuContainerViewDelegate
- (void)onPublicServiceMenuItemSelected:(RCPublicServiceMenuItem *)selectedMenuItem {
    if ([self.delegate respondsToSelector:@selector(onPublicServiceMenuItemSelected:)]) {
        [self.delegate onPublicServiceMenuItemSelected:selectedMenuItem];
    }
}

#pragma mark -  RCEmojiViewDelegate
- (void)didTouchEmojiView:(RCEmojiBoardView *)emojiView touchedEmoji:(NSString *)string {
    if (nil == string) {
        [self.inputTextView deleteBackward];
        NSRange range = NSMakeRange(self.inputTextView.selectedRange.location, string.length);
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(inputTextView:shouldChangeTextInRange:replacementText:)]) {
            [self.delegate inputTextView:self.inputTextView shouldChangeTextInRange:range replacementText:string];
        }
    } else {
        NSString *replaceString = string;
        if (replaceString.length < 5000) {
            NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:replaceString];
            [attStr addAttribute:NSFontAttributeName
                           value:self.inputTextView.font
                           range:NSMakeRange(0, replaceString.length)];
            [attStr addAttribute:NSForegroundColorAttributeName
                           value:RCDYCOLOR(0x000000, 0x999999)
                           range:NSMakeRange(0, replaceString.length)];
            NSInteger cursorPosition;
            if (self.inputTextView.selectedTextRange) {
                cursorPosition = self.inputTextView.selectedRange.location;
            } else {
                cursorPosition = 0;
            }
            //获取光标位置
            if (cursorPosition > self.inputTextView.textStorage.length)
                cursorPosition = self.inputTextView.textStorage.length;
            [self.inputTextView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
            //输入表情触发文本框变化，更新@信息的range
            if ([self.inputTextView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
                [self.inputTextView.delegate textView:self.inputTextView shouldChangeTextInRange:self.inputTextView.selectedRange replacementText:string];
            }
            
            NSRange range;
            range.location = self.inputTextView.selectedRange.location + string.length;
            range.length = 0;
            self.inputTextView.selectedRange = range;
        }
    }
    
    UITextView *textView = self.inputTextView;
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow =
    line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height -
                                        textView.contentInset.bottom - textView.contentInset.top);
    if (overflow > 0) {
        // We are at the bottom of the visible text and introduced a line feed,
        // scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        __weak typeof(textView) weakTextView = textView;
        [UIView animateWithDuration:.2
                         animations:^{
            [weakTextView setContentOffset:offset];
        }];
    }
    [self enableEmojiBoardViewSendButton];
   
    if ([self.delegate respondsToSelector:@selector(emojiView:didTouchedEmoji:)]) {
        [self.delegate emojiView:emojiView didTouchedEmoji:string];
    }
}

- (void)didSendButtonEvent:(RCEmojiBoardView *)emojiView sendButton:(UIButton *)sendButton {
    NSString *_sendText = self.inputTextView.text;

    NSString *_formatString = [_sendText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (0 == [_formatString length]) {
        [self showAlertController:nil
                          message:RCLocalizedString(@"whiteSpaceMessage")
                      cancelTitle:RCLocalizedString(@"OK")];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(emojiView:didTouchSendButton:)]) {
        [self.delegate emojiView:emojiView didTouchSendButton:sendButton];
    }

    self.inputTextView.text = @"";
    [self.mentionedRangeInfoList removeAllObjects];
    [self enableEmojiBoardViewSendButton];
}

#pragma mark - UIImagePickerControllerDelegate method
//选择相册图片或者拍照回调
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(imageDidCapture:)]) {
        [self.delegate imageDidCapture:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RCSightViewControllerDelegate
- (void)sightViewController:(UIViewController *)sightVC didFinishCapturingStillImage:(UIImage *)image {
    [self.delegate imageDidCapture:image];
    [sightVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)sightViewController:(UIViewController *)sightVC
         didWriteSightAtURL:(NSURL *)url
                  thumbnail:(UIImage *)thumnail
                   duration:(NSUInteger)duration {
    __weak typeof(self) weakSelf = self;
    [sightVC
        dismissViewControllerAnimated:YES
                           completion:^{
                               [weakSelf.delegate sightDidFinishRecord:url.path thumbnail:thumnail duration:duration];
                           }];
}

#pragma mark - RCFileSelectorViewControllerDelegate
- (void)fileDidSelect:(NSArray *)filePathList {
    if ([self.delegate respondsToSelector:@selector(fileDidSelect:)]) {
        [self.delegate fileDidSelect:filePathList];
    }
}

- (BOOL)canBeSelectedAtPath:(NSString *)path {
    if ([self.delegate respondsToSelector:@selector(canBeSelectedAtFilePath:)]) {
        return [self.delegate canBeSelectedAtFilePath:path];
    }
    return YES;
}

#pragma mark - RCAlbumListViewControllerDelegate
- (void)albumListViewController:(RCAlumListTableViewController *)albumListViewController
                 selectedImages:(NSArray *)selectedImageDatas
                isSendFullImage:(BOOL)enable {
    if ([self.delegate respondsToSelector:@selector(imageDataDidSelect:fullImageRequired:)]) {
        [self.delegate imageDataDidSelect:selectedImageDatas fullImageRequired:enable];
    }
}

- (void)onClickEditPhoto:(UIViewController *)rootCtrl previewImage:(UIImage *)previewImage {
    if (self.photoEditorDelegate &&
        [self.photoEditorDelegate respondsToSelector:@selector(onClickEditPicture:originalImage:editCompletion:)]) {
        [self.photoEditorDelegate onClickEditPicture:rootCtrl
                                       originalImage:previewImage
                                      editCompletion:^(UIImage *editedImage) {
                                          [[NSNotificationCenter defaultCenter]
                                              postNotificationName:@"onClickEditPictureCompletion"
                                                            object:editedImage];
                                      }];
    }
}

#pragma mark - RCSelectingUserDataSource
- (void)getSelectingUserIdList:(void (^)(NSArray<NSString *> *userIdList))completion {
    if ([self.dataSource respondsToSelector:@selector(getSelectingUserIdList:functionTag:)]) {
        [self.dataSource getSelectingUserIdList:^(NSArray<NSString *> *userIdList) {
            completion(userIdList);
        }
                                    functionTag:INPUT_MENTIONED_SELECT_TAG];
    } else {
        completion(nil);
    }
}

- (RCUserInfo *)getSelectingUserInfo:(NSString *)userId {
    if ([self.dataSource respondsToSelector:@selector(getSelectingUserInfo:)]) {
        return [self.dataSource getSelectingUserInfo:userId];
    } else {
        return nil;
    }
}

#pragma mark - RCPictureEditDelegate

- (void)setphotoEditorDelegate:(id<RCPictureEditDelegate>)photoEditorDelegate {
    if (photoEditorDelegate &&
        [photoEditorDelegate respondsToSelector:@selector(onClickEditPicture:originalImage:editCompletion:)]) {
        _photoEditorDelegate = photoEditorDelegate;
    }
}

//photoEditEnable
- (BOOL)photoEditEnable {
    if (self.photoEditorDelegate &&
        [self.photoEditorDelegate respondsToSelector:@selector(onClickEditPicture:originalImage:editCompletion:)]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Notifications

- (void)rcInputBar_registerForNotifications {
    [self rcInputBar_unregisterForNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rcInputBar_didReceiveKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rcInputBar_didReceiveKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeDeviceOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didCreateNewSession)
                                                 name:@"RCCallNewSessionCreation Notification"
                                               object:nil];
}

- (void)didChangeDeviceOrientationNotification:(NSNotification *)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationPortrait) {
        [self animationLayoutBottomBarWithStatus:self.currentBottomBarStatus animated:YES];
    }
}

- (void)rcInputBar_unregisterForNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rcInputBar_didReceiveKeyboardWillShowNotification:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
    //textViewBeginEditing 是在 inputTextView 代理 textViewShouldBeginEditing 中赋值
    //此判断是避免会话页面其他输入框的响应导致会话输入框弹起
    if (self.inputContainerView.textViewBeginEditing) {
        NSDictionary *userInfo = [notification userInfo];
        CGRect keyboardBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        if (!CGRectEqualToRect(keyboardBeginFrame, keyboardEndFrame)) {
            UIViewAnimationCurve animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
            NSInteger animationCurveOption = (animationCurve << 16);
            
            double animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            [UIView animateWithDuration:animationDuration delay:0.0 options:animationCurveOption animations:^{
                self.keyboardFrame = keyboardEndFrame;
                [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO];
            }completion:^(BOOL finished){
                
            }];
        }
    }else{
        //部分情况键盘弹起会先发通知再走 textViewShouldBeginEditing， 如摇动手机撤回输入内容
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.inputContainerView.textViewBeginEditing) {
                [weakSelf rcInputBar_didReceiveKeyboardWillShowNotification:notification];
            }
        });
    }
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenuFromView:self];
    } else {
        [[UIMenuController sharedMenuController] setMenuItems:nil];
        [UIMenuController sharedMenuController].menuVisible = NO;
    }
}

- (void)rcInputBar_didReceiveKeyboardWillHideNotification:(NSNotification *)notification {
    DebugLog(@"%s", __FUNCTION__);
    if (self.currentBottomBarStatus == KBottomBarKeyboardStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:NO];
    }
}

- (void)didCreateNewSession {
    [self endVoiceRecord];
}

#pragma mark - Public Service
- (void)dismissPublicServiceMenuPopupView {
    [self.menuContainerView dismissPublicServiceMenuPopupView];
}

- (void)setPublicServiceMenu:(RCPublicServiceMenu *)publicServiceMenu {
    self.menuContainerView.publicServiceMenu = publicServiceMenu;
}

#pragma mark -  Custom Service
- (void)onRobotSwitch:(id)sender {
    if ([self.delegate respondsToSelector:@selector(robotSwitchButtonDidTouch)]) {
        [self.delegate robotSwitchButtonDidTouch];
    }
}

#pragma mark - CommonPhrasesView
- (NSArray *)commonPhrasesSource {
    if (!_commonPhrasesSource) {
        _commonPhrasesSource = [[NSArray alloc] init];
    }
    return _commonPhrasesSource;
}

- (UIView *)commonPhrasesView {
    if (!_commonPhrasesView) {
        _commonPhrasesView =
            [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, RC_CommonPhrasesView_Height)];
        _commonPhrasesView.backgroundColor =
            [RCKitUtility generateDynamicColor:RGBCOLOR(245, 245, 245) darkColor:HEXCOLOR(0x1c1c1c)];
        [_commonPhrasesView addSubview:self.commonPhrasesButton];
    }
    return _commonPhrasesView;
}

- (UIButton *)commonPhrasesButton {
    if (!_commonPhrasesButton) {
        _commonPhrasesButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 10, 66, 25)];
        _commonPhrasesButton.backgroundColor = RCDYCOLOR(0xffffff, 0x1a1a1a);
        [_commonPhrasesButton.titleLabel setFont:[[RCKitConfig defaultConfig].font fontOfAnnotationLevel]];
        [_commonPhrasesButton setTitle:RCLocalizedString(@"common_phrases")
                              forState:UIControlStateNormal];
        _commonPhrasesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_commonPhrasesButton addTarget:self
                                 action:@selector(commonPhrasesButtonAction:)
                       forControlEvents:UIControlEventTouchUpInside];
        _commonPhrasesButton.layer.cornerRadius = 12.5f;
        _commonPhrasesButton.layer.borderColor =
            [RCKitUtility generateDynamicColor:RGBCOLOR(151, 151, 151)
                                           darkColor:[HEXCOLOR(0x808080) colorWithAlphaComponent:0.3]]
                .CGColor;
        _commonPhrasesButton.layer.borderWidth = 0.5f; //设置边框颜色
        [_commonPhrasesButton setTitleColor:RCDYCOLOR(0x000000, 0xffffff) forState:(UIControlStateNormal)];
    }
    return _commonPhrasesButton;
}

- (RCCommonPhrasesListView *)commonPhrasesListView {
    if (!_commonPhrasesListView) {
        _commonPhrasesListView = [[RCCommonPhrasesListView alloc]
            initWithFrame:CGRectMake(0, [self getBoardViewBottomOriginY], self.containerView.bounds.size.width,
                                     Height_CommonPhrasesView)
               dataSource:self.commonPhrasesSource];
        _commonPhrasesListView.delegate = self;
        [self.containerView addSubview:_commonPhrasesListView];
    }
    return _commonPhrasesListView;
}

- (void)didTouchCommonPhrasesView:(NSString *)commonPhrase {
    if ([self.delegate respondsToSelector:@selector(commonPhrasesViewDidTouch:)]) {
        [self.delegate commonPhrasesViewDidTouch:commonPhrase];
    }
    self.commonPhrasesListView.hidden = YES;
    [self animationLayoutBottomBarWithStatus:KBottomBarKeyboardStatus animated:NO];
}

#pragma mark - Mentioned
//遍历@列表，根据修改字符的范围更新@信息的range
- (void)updateAllMentionedRangeInfo:(NSInteger)changedLocation length:(NSInteger)changedLength {
    for (RCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
        if (mentionedInfo.range.location >= changedLocation) {
            mentionedInfo.range = NSMakeRange(mentionedInfo.range.location + changedLength, mentionedInfo.range.length);
        }
    }
}

- (void)showChooseUserViewController:(void (^)(RCUserInfo *selectedUserInfo))selectedBlock
                              cancel:(void (^)(void))cancelBlock {
    //接口向后兼容[[++
    if ([self.delegate respondsToSelector:@selector(showChooseUserViewController:cancel:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate performSelector:@selector(showChooseUserViewController:cancel:)
                                withObject:selectedBlock
                                withObject:cancelBlock];
        });

        return;
    }
    //接口向后兼容--]]

    RCUserListViewController *userListVC = [[RCUserListViewController alloc] init];
    userListVC.selectedBlock = selectedBlock;
    userListVC.cancelBlock = cancelBlock;
    userListVC.dataSource = self;
    userListVC.navigationTitle = RCLocalizedString(@"SelectMentionedUser");
    userListVC.maxSelectedUserNumber = 1;
    UINavigationController *rootVC = [[UINavigationController alloc] initWithRootViewController:userListVC];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate presentViewController:rootVC functionTag:INPUT_MENTIONED_SELECT_TAG];
    });
}

- (BOOL)willUpdateInputTextMetionedInfo:(NSString *)text range:(NSRange)range{
    BOOL shouldUseDefaultChangeText = YES;
    if (self.isMentionedEnabled) {
        //记录变化的范围
        NSInteger changedLocation = 0;
        NSInteger changedLength = 0;

        //当长度是0 说明是删除字符
        if (text.length == 0) {
            for (RCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
                NSRange mentionedRange = mentionedInfo.range;
                //如果删除的光标在@信息的最后，删除这个@信息
                if (range.length == 1 && (mentionedRange.location + mentionedRange.length == range.location + 1)) {
                    shouldUseDefaultChangeText = NO;
                    [self.inputTextView.textStorage deleteCharactersInRange:mentionedRange];
                    range.location = range.location - mentionedRange.length + 1;
                    range.length = 0;
                    self.inputTextView.selectedRange = NSMakeRange(mentionedRange.location, 0);

                    changedLocation = mentionedInfo.range.location;
                    changedLength = -(NSInteger)mentionedInfo.range.length;

                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                } else if (mentionedRange.location <= range.location &&
                           range.location < mentionedRange.location + mentionedRange.length) {
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    //不能break，否则整块删除会遗漏
                }
            }

            if (changedLength == 0) {
                //如果删除的字符不在@信息 字符中，记录变化的位置和长度
                changedLocation = range.location + 1;
                changedLength = -(NSInteger)range.length;
            }
        } else {
            if ([text isEqualToString:@"@"]) {
                if ([self shouldTriggerMentionedChoose:self.inputTextView range:range]) {
                    __weak typeof(self) weakSelf = self;
                    [self showChooseUserViewController:^(RCUserInfo *selectedUserInfo) {
                        [weakSelf insertMentionedUser:selectedUserInfo symbolRequset:NO];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
                        });
                    }
                        cancel:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
                            });
                        }];
                }
            }

            //输入内容变化，遍历所有@信息，如果输入的字符起始位置在@信息中，移除这个@信息，否则根据变化情况更新@信息中的range
            for (RCMentionedStringRangeInfo *mentionedInfo in [self.mentionedRangeInfoList copy]) {
                NSRange strRange = mentionedInfo.range;
                if ((range.location > strRange.location) && (range.location < (strRange.location + strRange.length))) {
                    [self.mentionedRangeInfoList removeObject:mentionedInfo];
                    break;
                }
            }
            changedLocation = range.location;
            changedLength = text.length - range.length;
        }

        [self updateAllMentionedRangeInfo:changedLocation length:changedLength];
    }
    return shouldUseDefaultChangeText;
}

- (BOOL)shouldTriggerMentionedChoose:(UITextView *)textView range:(NSRange)range {
    if (range.location == 0) {
        return YES;
    } else if (!isalnum([textView.text characterAtIndex:range.location - 1])) {
        //@前是数字和字母才不弹出
        return YES;
    }
    return NO;
}

- (void)insertMentionedUser:(RCUserInfo *)userInfo symbolRequset:(BOOL)symbolRequset {
    if (!self.isMentionedEnabled || userInfo.userId == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        //获取光标位置
        NSUInteger cursorPosition = self.inputTextView.selectedRange.location;
        if (cursorPosition > self.inputTextView.textStorage.length) {
            cursorPosition = self.inputTextView.textStorage.length;
        }
        //@位置
        NSUInteger mentionedPosition;

        //@的内容
        NSString *insertContent = nil;
        NSInteger changeRangeLength;
        if (symbolRequset) {
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"@%@ ", userInfo.userId];
            }
            mentionedPosition = cursorPosition;
            changeRangeLength = [insertContent length];
        } else {
            if (userInfo.name.length > 0) {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.name];
            } else {
                insertContent = [NSString stringWithFormat:@"%@ ", userInfo.userId];
            }
            mentionedPosition = (cursorPosition >= 1) ? (cursorPosition - 1) : 0;
            changeRangeLength = [insertContent length] + 1;
        }

        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:insertContent];
        [attStr addAttribute:NSFontAttributeName
                       value:self.inputTextView.font
                       range:NSMakeRange(0, insertContent.length)];
        [attStr addAttribute:NSForegroundColorAttributeName
                       value:RCDYCOLOR(0x000000, 0x999999)
                       range:NSMakeRange(0, insertContent.length)];
        [self.inputTextView.textStorage insertAttributedString:attStr atIndex:cursorPosition];
        self.inputTextView.selectedRange = NSMakeRange(cursorPosition + insertContent.length, 0);
        [self updateAllMentionedRangeInfo:cursorPosition length:insertContent.length];

        RCMentionedStringRangeInfo *mentionedStrInfo = [[RCMentionedStringRangeInfo alloc] init];
        mentionedStrInfo.content = insertContent;
        mentionedStrInfo.userId = userInfo.userId;
        mentionedStrInfo.range = NSMakeRange(mentionedPosition, changeRangeLength);
        [self.mentionedRangeInfoList addObject:mentionedStrInfo];

        if ([self.inputTextView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            [self.inputTextView.delegate textView:self.inputTextView shouldChangeTextInRange: self.inputTextView.selectedRange replacementText:insertContent];
        }
    });
}

#pragma mark - Target Action
- (void)pubSwitchValueChanged {
    if (self.menuContainerView.hidden) {
        self.menuContainerView.hidden = NO;
        self.inputContainerView.hidden = YES;
        self.inputTextView.text = @"";
    } else {
        self.menuContainerView.hidden = YES;
        self.inputContainerView.hidden = NO;
    }

    [self.pubSwitchButton setImage:RCResourceImage(self.menuContainerView.hidden ? @"pub_menu" : @"inputbar_keyboard")
                          forState:UIControlStateNormal];
    [self didTouchPubSwitchButton:_inputContainerView.hidden];
    [self dismissPublicServiceMenuPopupView];
}

- (void)commonPhrasesButtonAction:(UIButton *)button {
    [self didTouchCommonPhrasesButton:button];
    [self.commonPhrasesListView reloadCommonPhrasesList];
}

- (float)getBoardViewBottomOriginY {
    float gap = (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    gap += [self getSafeAreaExtraBottomHeight];
    return IS_HOTSPOT_CONNECTED ? [UIScreen mainScreen].bounds.size.height - gap - 20
                                : [UIScreen mainScreen].bounds.size.height - gap;
}

- (float)getSafeAreaExtraBottomHeight {
    return [RCKitUtility getWindowSafeAreaInsets].bottom;
}

- (void)openDestructAlbum {
    [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Camera"), RCLocalizedString(@"Photos")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
        if (index == 0) {
            [self openSystemCamera];
        }else{
            [self openSystemAlbum];
        }
    } cancelBlock:^{
            
    }];
}

- (BOOL)checkAndAlertCameraAccessRight {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted) {
        [self showAlertController:RCLocalizedString(@"AccessRightTitle")
                          message:RCLocalizedString(@"cameraAccessRight")
                      cancelTitle:RCLocalizedString(@"OK")];
        return NO;
    }
    return YES;
}


- (void)resetInputContainerView {
    [self setInputBarType:self.currentControlType style:self.currentControlStyle];
}

- (void)animationLayoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus animated:(BOOL)animated {
    [self.pluginBoardView.extensionView setHidden:YES];
    if (animated == YES) {
        [UIView beginAnimations:@"Move_bar" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.25f];
        [UIView setAnimationDelegate:self];
        [self layoutBottomBarWithStatus:bottomBarStatus];
        [UIView commitAnimations];
    } else {
        [self layoutBottomBarWithStatus:bottomBarStatus];
    }
}

- (void)layoutBottomBarWithStatus:(KBottomBarStatus)bottomBarStatus {
    [self.inputContainerView setBottomBarWithStatus:bottomBarStatus];
    CGRect chatInputBarRect = self.frame;
    float bottomY = [self getBoardViewBottomOriginY];
    switch (bottomBarStatus) {
        case KBottomBarDefaultStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES commonPhrasesListView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
        } break;
        case KBottomBarKeyboardStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES commonPhrasesListView:YES];
            //bottomY里面已经去掉了屏幕底部安全距离
            if (self.keyboardFrame.size.height > 0) {
                //手机系统键盘弹起时，键盘的高度也包含了屏幕底部安全距离，相当于减掉了两次屏幕底部安全距离，需要再加回去
                chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.keyboardFrame.size.height + [self getSafeAreaExtraBottomHeight];
            }else{
               //使用外接键盘时手机系统键盘并未弹起
                chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
            }
        } break;
        case KBottomBarPluginStatus: {
            [self pluginBoardView];
            [self hiddenEmojiBoardView:YES pluginBoardView:NO commonPhrasesListView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.pluginBoardView.bounds.size.height;
        } break;
        case KBottomBarEmojiStatus: {
            [self emojiBoardView];
            [self hiddenEmojiBoardView:NO pluginBoardView:YES commonPhrasesListView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.emojiBoardView.bounds.size.height;
        } break;
        case KBottomBarRecordStatus: {
            [self hiddenEmojiBoardView:YES pluginBoardView:YES commonPhrasesListView:YES];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height;
        } break;
            
        case KBottomBarCommonPhrasesStatus: {
            if (self.commonPhrasesSource.count <= 0 || (self.conversationType != ConversationType_PRIVATE && self.conversationType != ConversationType_GROUP)) {
                RCLogI(@"Common Phrases Donot Support");
                return;
            }
            [self commonPhrasesListView];
            [self hiddenEmojiBoardView:YES pluginBoardView:YES commonPhrasesListView:NO];
            chatInputBarRect.origin.y = bottomY - self.bounds.size.height - self.commonPhrasesListView.bounds.size.height;
        } break;
        default:
            break;
    }
    [self setFrame:chatInputBarRect];
    
    [[RCExtensionService sharedService] inputBarStatusDidChange:bottomBarStatus inInputBar:self];
}

- (void)hiddenEmojiBoardView:(BOOL)hiddenEmojiBoardView
             pluginBoardView:(BOOL)hiddenPluginBoardView
       commonPhrasesListView:(BOOL)hiddenCommonPhrasesListView{
        if (self.emojiBoardView) {
        [self.emojiBoardView setHidden:hiddenEmojiBoardView];
        if (!hiddenEmojiBoardView) {
            self.emojiBoardView.frame = CGRectMake(0, [self getBoardViewBottomOriginY] - Height_EmojBoardView, self.containerView.bounds.size.width, Height_EmojBoardView);
        }
    }
    if (self.commonPhrasesListView) {
        [self.commonPhrasesListView setHidden:hiddenCommonPhrasesListView];
        if (!hiddenCommonPhrasesListView) {
            self.commonPhrasesListView.frame = CGRectMake(0, [self getBoardViewBottomOriginY] - Height_CommonPhrasesView,
                                                          self.containerView.bounds.size.width, Height_CommonPhrasesView);
        }
    }
    if (self.pluginBoardView) {
        [self.pluginBoardView setHidden:hiddenPluginBoardView];
        if (!hiddenPluginBoardView) {
            self.pluginBoardView.frame = CGRectMake(0, [self getBoardViewBottomOriginY] - Height_PluginBoardView,
                                                    self.containerView.bounds.size.width, Height_PluginBoardView);
        }
    }

}

- (void)didTouchPubSwitchButton:(BOOL)switched {
    if (self.currentBottomBarStatus != KBottomBarDefaultStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    }
}

- (void)didTouchCommonPhrasesButton:(UIButton *)button {
    if (self.currentBottomBarStatus == KBottomBarCommonPhrasesStatus) {
        [self animationLayoutBottomBarWithStatus:KBottomBarDefaultStatus animated:YES];
    } else {
        [self animationLayoutBottomBarWithStatus:KBottomBarCommonPhrasesStatus animated:YES];
    }
}

#pragma mark - Private Methods
- (void)didTouchRecordButtonEvent:(UIControlEvents)event {
    switch (event) {
    case UIControlEventTouchDown: {
        [self.voiceRecordControl onBeginRecordEvent];
    } break;
    case UIControlEventTouchUpInside: {
        [self.voiceRecordControl onEndRecordEvent];
    } break;
    case UIControlEventTouchDragExit: {
        [self.voiceRecordControl dragExitRecordEvent];
    } break;
    case UIControlEventTouchUpOutside: {
        [self.voiceRecordControl onCancelRecordEvent];

    } break;
    case UIControlEventTouchDragEnter: {
        [self.voiceRecordControl dragEnterRecordEvent];
    } break;
    case UIControlEventTouchCancel: {
        [self.voiceRecordControl onEndRecordEvent];
    } break;
    default:
        break;
    }
}

- (void)enableEmojiBoardViewSendButton{
    if (self.inputTextView.text && self.inputTextView.text.length > 0) {
           [self.emojiBoardView enableSendButton:YES];
       } else {
           [self.emojiBoardView enableSendButton:NO];
       }
}

- (void)updateSubviewsLayout{
    CGRect containerViewFrame;
    if (self.commonPhrasesSource.count > 0 && (self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP)) {
        containerViewFrame = CGRectMake(0, RC_CommonPhrasesView_Height, self.bounds.size.width,
                                        self.bounds.size.height - RC_CommonPhrasesView_Height);
    } else {
        containerViewFrame = self.bounds;
    }
    if (RCChatSessionInputBarControlDefaultType == self.currentControlType) {
        self.inputContainerView.frame = containerViewFrame;
    } else if (self.currentControlType == RCChatSessionInputBarControlPubType) {
        containerViewFrame.size.width = containerViewFrame.size.width - SwitchButtonWidth;
        containerViewFrame.origin.x = SwitchButtonWidth;
        self.inputContainerView.frame = containerViewFrame;
        self.menuContainerView.frame = containerViewFrame;
    } else if (self.currentControlType == RCChatSessionInputBarControlCSRobotType) {
        containerViewFrame.size.width = containerViewFrame.size.width - SwitchButtonWidth;
        containerViewFrame.origin.x = SwitchButtonWidth;
        self.inputContainerView.frame = containerViewFrame;
    } else if (self.currentControlType == RCChatSessionInputBarControlNoAvailableType) {
        self.inputContainerView.frame = containerViewFrame;
    }
    [self.inputContainerView setInputBarStyle:self.currentControlStyle];
    if (!self.menuContainerView.hidden) {
        [self.menuContainerView setPublicServiceMenu:self.publicServiceMenu];
    }
}

- (void)resetInputBar {
    if (self.pubSwitchButton) {
        [self.pubSwitchButton removeFromSuperview];
        self.pubSwitchButton = nil;
    }

    if (self.robotSwitchButton) {
        [self.robotSwitchButton removeFromSuperview];
        self.robotSwitchButton = nil;
    }

    if (self.inputContainerView) {
        NSString *text = self.inputTextView.text;
        [self.inputContainerView removeFromSuperview];
        self.inputContainerView = nil;
        self.inputTextView.text = text;
    }
    if (self.menuContainerView) {
        [self.menuContainerView removeFromSuperview];
        self.menuContainerView = nil;
    }
}

- (void)onSubMenuPushed:(id)sender {
}

- (void)changeTextViewHeight:(NSString *)text {
    if (self.menuContainerView == nil || self.menuContainerView.hidden == YES) {
        if (text.length != 0) {
            [self animationLayoutBottomBarWithStatus:(KBottomBarKeyboardStatus) animated:YES];
        }
    }
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:nil];
    });
}

#pragma mark - Getters and Setters

- (RCInputContainerView *)inputContainerView {
    if (!_inputContainerView) {
        _inputContainerView = [[RCInputContainerView alloc] initWithFrame:self.bounds];
        _inputContainerView.delegate = self;
    }
    return _inputContainerView;
}

- (RCButton *)switchButton {
    return self.inputContainerView.switchButton;
}

- (RCTextView *)inputTextView {
    return self.inputContainerView.inputTextView;
}

- (RCButton *)recordButton {
    return self.inputContainerView.recordButton;
}

- (RCButton *)emojiButton {
    return self.inputContainerView.emojiButton;
}

- (RCButton *)additionalButton {
    return self.inputContainerView.additionalButton;
}

- (UIView *)newLine {
    UIView *line = [UIView new];
    line.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xe3e5e6) darkColor:HEXCOLOR(0x2f2f2f)];
    return line;
}

- (NSMutableDictionary *)pluginTapBlockDic {
    if (!_pluginTapBlockDic) {
        _pluginTapBlockDic = [[NSMutableDictionary alloc] init];
    }
    return _pluginTapBlockDic;
}

- (RCEmojiBoardView *)emojiBoardView {
    if (!_emojiBoardView) {
        _emojiBoardView = [[RCEmojiBoardView alloc]
            initWithFrame:CGRectMake(0, [self getBoardViewBottomOriginY], self.frame.size.width, Height_EmojBoardView)
                 delegate:self];
        for (id<RCEmoticonTabSource> source in
             [[RCExtensionService sharedService] getEmoticonTabList:self.conversationType targetId:self.targetId]) {
            [_emojiBoardView addExtensionEmojiTab:source];
        };
        _emojiBoardView.hidden = YES;
        _emojiBoardView.delegate = self;
        _emojiBoardView.conversationType = self.conversationType;
        _emojiBoardView.targetId = self.targetId;
        [self.containerView addSubview:_emojiBoardView];
    }
    return _emojiBoardView;
}

- (RCPluginBoardView *)pluginBoardView {
    if (!_pluginBoardView) {
        _pluginBoardView = [[RCPluginBoardView alloc]
            initWithFrame:CGRectMake(0, [self getBoardViewBottomOriginY], self.containerView.bounds.size.width,
                                     Height_PluginBoardView)];

        //添加底部多功能栏功能，可以根据需求自定义
        [_pluginBoardView insertItem:RCResourceImage(@"plugin_item_picture")
                    highlightedImage:RCResourceImage(@"plugin_item_picture_highlighted")
                               title:RCLocalizedString(@"Photos")
                             atIndex:0
                                 tag:PLUGIN_BOARD_ITEM_ALBUM_TAG];
        
        [_pluginBoardView insertItem:RCResourceImage(@"plugin_item_camera")
                    highlightedImage:RCResourceImage(@"plugin_item_camera_highlighted")
                               title:RCLocalizedString(@"Camera")
                             atIndex:1
                                 tag:PLUGIN_BOARD_ITEM_CAMERA_TAG];
        
        [_pluginBoardView insertItem:RCResourceImage(@"plugin_item_location")
                    highlightedImage:RCResourceImage(@"plugin_item_location_highlighted")
                               title:RCLocalizedString(@"Location")
                             atIndex:2
                                 tag:PLUGIN_BOARD_ITEM_LOCATION_TAG];
        if (self.conversationType == ConversationType_PRIVATE) {
            [_pluginBoardView insertItem:RCResourceImage(@"plugin_item_burn")
                        highlightedImage:RCResourceImage(@"plugin_item_burn_highlighted")
                                   title:RCLocalizedString(@"Burn_After_Read")
                                 atIndex:3
                                     tag:PLUGIN_BOARD_ITEM_DESTRUCT_TAG];
        }

        NSInteger index = 100;
        NSArray *pluginItemInfoList =
            [[RCExtensionService sharedService] getPluginBoardItemInfoList:self.conversationType
                                                                  targetId:self.targetId];
        for (RCExtensionPluginItemInfo *itemInfo in pluginItemInfoList) {
            NSInteger tag;
            if (itemInfo.tag > 0) {
                tag = itemInfo.tag;
            } else {
                tag = PLUGIN_BOARD_ITEM_RED_PACKET_TAG;
            }
            [self.pluginBoardView insertItem:itemInfo.normalImage highlightedImage:itemInfo.highlightedImage title:itemInfo.title atIndex:index tag:tag];
            [self.pluginTapBlockDic setObject:itemInfo.tapBlock forKey:@(tag)];
            index++;
        }
        RCLogF(@"pluginItemInfoList count:==============> %ld", (long)pluginItemInfoList.count);
        _pluginBoardView.hidden = YES;
        _pluginBoardView.pluginBoardDelegate = self;
        [self.containerView addSubview:_pluginBoardView];
    }
    return _pluginBoardView;
}

- (NSMutableArray *)mentionedRangeInfoList {
    if (!_mentionedRangeInfoList) {
        _mentionedRangeInfoList = [[NSMutableArray alloc] init];
    }
    return _mentionedRangeInfoList;
}

- (void)setDraft:(NSString *)draft {
    if (draft && draft.length > 0) {
        __autoreleasing NSError *error = nil;
        NSData *draftData = [draft dataUsingEncoding:NSUTF8StringEncoding];
        if (draftData) {
            NSDictionary *draftDict =
                [NSJSONSerialization JSONObjectWithData:draftData options:kNilOptions error:&error];
            if (!error && [draftDict count] > 0) {
                if ([draftDict.allKeys containsObject:@"draftContent"]) {
                    draft = [draftDict objectForKey:@"draftContent"];
                }
                NSArray *mentionedRangeInfoList = [draftDict objectForKey:@"mentionedRangeInfoList"];
                for (NSString *mentionedInfoString in mentionedRangeInfoList) {
                    RCMentionedStringRangeInfo *mentionedInfo =
                        [[RCMentionedStringRangeInfo alloc] initWithDecodeString:mentionedInfoString];
                    if (mentionedInfo) {
                        [self.mentionedRangeInfoList addObject:mentionedInfo];
                    }
                }
            }
        }

        self.inputTextView.text = draft;
    }
}

- (NSString *)draft {
    NSString *draft = self.inputTextView.text;
    if (draft.length > 0) {
        NSMutableDictionary *dataDict = [NSMutableDictionary new];
        [dataDict setObject:draft forKey:@"draftContent"];

        NSMutableArray *mentionedRangeInfoList = [NSMutableArray new];
        for (RCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
            NSString *mentionedInfoString = [mentionedInfo encodeToString];
            if (mentionedInfoString) {
                [mentionedRangeInfoList addObject:mentionedInfoString];
            }
        }

        //存储@用户列表
        if (mentionedRangeInfoList.count > 0) {
            [dataDict setObject:mentionedRangeInfoList forKey:@"mentionedRangeInfoList"];
        }
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
        draft = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return draft;
    }
    return draft;
}

- (RCMentionedInfo *)mentionedInfo {
    if (self.mentionedRangeInfoList.count > 0) {
        NSMutableArray *mentionedUserIdList = [[NSMutableArray alloc] init];
        for (RCMentionedStringRangeInfo *mentionedInfo in self.mentionedRangeInfoList) {
            [mentionedUserIdList addObject:mentionedInfo.userId];
        }
        RCMentionedInfo *mentionedInfo = [[RCMentionedInfo alloc] initWithMentionedType:RC_Mentioned_Users
                                                                             userIdList:mentionedUserIdList
                                                                       mentionedContent:nil];
        //    [self.mentionedRangeInfoList removeAllObjects];
        return mentionedInfo;
    }
    return nil;
}

- (CGFloat)inputBarHeight {
    if ((self.conversationType == ConversationType_PRIVATE || self.conversationType == ConversationType_GROUP)  && self.commonPhrasesSource.count > 0) {
        return RC_ChatSessionInputBar_Height + RC_CommonPhrasesView_Height;
    } else {
        return RC_ChatSessionInputBar_Height;
    }
}

- (RCVoiceRecordControl *)voiceRecordControl {
    if (!_voiceRecordControl) {
        _voiceRecordControl = [[RCVoiceRecordControl alloc] initWithConversationType:self.conversationType];
        _voiceRecordControl.delegate = self;
    }
    return _voiceRecordControl;
}

- (RCButton *)pubSwitchButton {
    if (!_pubSwitchButton) {
        _pubSwitchButton = [[RCButton alloc] initWithFrame:CGRectZero];
        [_pubSwitchButton setFrame:CGRectMake(0, 0, SwitchButtonWidth, self.inputBarHeight)];
        [_pubSwitchButton setImage:RCResourceImage(@"inputbar_keyboard") forState:UIControlStateNormal];
        _pubSwitchButton.contentEdgeInsets = UIEdgeInsetsMake(8, 5, 8, 5);
        [_pubSwitchButton addTarget:self
                             action:@selector(pubSwitchValueChanged)
                   forControlEvents:UIControlEventTouchUpInside];
        [_pubSwitchButton setExclusiveTouch:YES];
        UIView *lineRight = [self newLine];
        lineRight.frame =
            CGRectMake(_pubSwitchButton.frame.size.width - 0.5, 0, 0.3, _pubSwitchButton.frame.size.height);
        [_pubSwitchButton addSubview:lineRight];
    }
    return _pubSwitchButton;
}

- (RCButton *)robotSwitchButton {
    if (!_robotSwitchButton) {
        _robotSwitchButton = [[RCButton alloc] initWithFrame:CGRectZero];
        [_robotSwitchButton setFrame:CGRectMake(0, 0, SwitchButtonWidth, self.inputBarHeight)];
        [_robotSwitchButton setImage:RCResourceImage(@"custom_service_switch_to_admin")
                            forState:UIControlStateNormal];
        [_robotSwitchButton addTarget:self
                               action:@selector(onRobotSwitch:)
                     forControlEvents:UIControlEventTouchUpInside];
        [_robotSwitchButton setExclusiveTouch:YES];
    }
    return _robotSwitchButton;
}

- (RCMenuContainerView *)menuContainerView {
    if (!_menuContainerView) {
        _menuContainerView = [[RCMenuContainerView alloc] initWithFrame:CGRectZero containerView:self.containerView];
        _menuContainerView.delegate = self;
        _menuContainerView.hidden = YES;
    }
    return _menuContainerView;
}

- (void)addBottomAreaView {
    CGFloat bottom = [RCKitUtility getWindowSafeAreaInsets].bottom;
    if (bottom > 0) {
        UIView * bottomAreaView= [[UIView alloc] initWithFrame:CGRectMake(0, self.containerView.bounds.size.height - bottom,
                                                                          self.containerView.bounds.size.width, bottom)];
        bottomAreaView.backgroundColor = RCDYCOLOR(0xF8F8F8, 0x0b0b0c);
        [self.containerView addSubview:bottomAreaView];
    }
}

- (RCPublicServiceMenu *)publicServiceMenu {
    return self.menuContainerView.publicServiceMenu;
}

- (BOOL)destructMessageMode {
    return self.inputContainerView.destructMessageMode;
}

- (void)setCurrentBottomBarStatus:(KBottomBarStatus)currentBottomBarStatus {
    self.inputContainerView.currentBottomBarStatus = currentBottomBarStatus;
}

- (KBottomBarStatus)currentBottomBarStatus {
    return self.inputContainerView.currentBottomBarStatus;
}

- (NSInteger)maxInputLines {
    return self.inputContainerView.maxInputLines;
}
@end
