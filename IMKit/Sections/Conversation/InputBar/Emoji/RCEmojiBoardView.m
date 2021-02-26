//
//  RCEmojiBoardView.m
//  RongExtensionKit
//
//  Created by Heq.Shinoda on 14-5-29.
//  Copyright (c) 2014年 RongCloud. All rights reserved.
//

#import "RCEmojiBoardView.h"
#import "RCPageControl.h"
#import "RCEmoticonPackage.h"
#import "RCKitCommonDefine.h"
#import "RCExtensionModule.h"
#import "RCExtensionService.h"
#import "RCKitConfig.h"
#import "RCEmojiTabView.h"
#define RC_EMOJI_WIDTH 30
#define RC_EMOTIONTAB_SIZE_HEIGHT 42
#define RC_EMOTIONTAB_SIZE_WIDTH 42
#define RC_EMOTIONTAB_ICON_SIZE 25
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

NSString *const RCKitExtensionEmoticonTabNeedReloadNotification = @"RCKitExtensionEmoticonTabNeedReloadNotification";
@interface RCEmojiBoardView ()<RCEmojiTabViewDelegate>
@property (nonatomic, assign) int emojiTotal;
@property (nonatomic, assign) int emojiTotalPage;
@property (nonatomic, assign) int emojiColumn;
@property (nonatomic, assign) int emojiMaxCountPerPage;
@property (nonatomic, assign) CGFloat emojiMariginHorizontalMin;
@property (nonatomic, strong) NSArray *faceEmojiArray;
@property (nonatomic, assign) int emojiLoadedPage;
@property (nonatomic, strong) RCEmojiTabView *tabbarView;
@property (nonatomic, assign) CGSize emojiContentSize; //默认的emoji 的contentSize
@property (nonatomic, assign) int preSelectEmoticonPackageIndex;

/*!
 自定义表情的 Model 数组
 */
@property (nonatomic, strong) NSMutableArray *emojiModelList;

/*!
 app 通过调用 addEmojiTab 方法添加的自定义表情的 Model 数组
 */
@property (nonatomic, strong) NSMutableArray *appAddEmojiModelList;

@end

static int rc_currentSelectIndexPackage;
static int rc_currentSelectIndexPage;
@implementation RCEmojiBoardView {
    /*!
     PageControl
     */
    RCPageControl *pageCtrl;

    /*!
     当前所在页的索引值
     */
    //  NSInteger currentIndex;

    CGFloat lastFrameWith;
}
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<RCEmojiViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        rc_currentSelectIndexPage = 0;
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString *bundlePath = [resourcePath stringByAppendingPathComponent:@"Emoji.plist"];
        DebugLog(@"Emoji.plist > %@", bundlePath);
        self.faceEmojiArray = [[NSArray alloc] initWithContentsOfFile:bundlePath];
        self.emojiLoadedPage = 0;

        [self generateDefaultLayoutParameters];
        lastFrameWith = self.frame.size.width;
        self.emojiBackgroundView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 186)];
        self.emojiBackgroundView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
        self.emojiBackgroundView.pagingEnabled = YES;
        self.emojiBackgroundView.contentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);
        self.emojiBackgroundView.showsHorizontalScrollIndicator = NO;
        self.emojiBackgroundView.showsVerticalScrollIndicator = NO;
        self.emojiBackgroundView.delegate = self;
        if ([RCKitUtility isRTL]) {
            [self.emojiBackgroundView setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
        self.delegate = delegate;
        [self addSubview:self.emojiBackgroundView];
        [self loadLabelView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(needReloadEmoticonTabSource:)
                                                 name:RCKitExtensionEmoticonTabNeedReloadNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Super Methods

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (fabs(frame.size.width - lastFrameWith) >= 4) {
        lastFrameWith = frame.size.width;
    } else {
        return; //防止页面过度刷新
    }
    // 配置本页视图动态变化 ========================= 开始//
    if (_tabbarView) {
        CGRect tabbarViewFrame = _tabbarView.frame;
        tabbarViewFrame.size.width = frame.size.width;
        self.tabbarView.frame = tabbarViewFrame;
    }
    
    // 配置本页视图动态变化 ========================= 结束//

    [self generateDefaultLayoutParameters];
    // 调整现实布局
    for (UIView *subView in self.emojiBackgroundView.subviews) {
        // 先把表情类视图移除
        if (![subView isKindOfClass:[UIScrollView class]]) {
            [subView removeFromSuperview];
        }
    }

    self.emojiLoadedPage = 0;
    [self.emojiBackgroundView setContentOffset:CGPointMake(0, 0) animated:YES];
    // 能不能不重新初始化视图
    //[self loadEmojiViewPartly];
    self.emojiContentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);

    for (NSInteger i = 0; i < _emojiModelList.count; i++) {
        RCEmoticonPackage *model = _emojiModelList[i];
        int offsetX = self.frame.size.width * i;
        CGRect frame = CGRectMake(self.emojiContentSize.width + offsetX, 0, self.frame.size.width,
                                  self.emojiBackgroundView.contentSize.height);
        model.emotionContainerView.frame = frame;
        [model setNeedLayout];
    }
    CGSize size = self.emojiContentSize;
    size.width = self.emojiContentSize.width + self.frame.size.width * _emojiModelList.count;
    self.emojiBackgroundView.contentSize = size;
    [self loadEmotionTab:rc_currentSelectIndexPackage];
}

//用于动画效果
- (void)setHidden:(BOOL)hidden {
    CGRect viewRect = self.frame;
    if (hidden) {
        viewRect.origin.y = [self getBoardViewBottonOriginY];
    } else {
        viewRect.origin.y = [self getBoardViewBottonOriginY] - self.frame.size.height;
    }
    [self setFrame:viewRect];
    [super setHidden:hidden];
}

#pragma mark - Public Methods
- (void)loadLabelView {
    [self loadEmojiViewPartly];
    if (pageCtrl) {
        [pageCtrl removeFromSuperview];
        pageCtrl = nil;
    }
    pageCtrl = [[RCPageControl alloc] initWithFrame:CGRectMake(0, 175, self.frame.size.width, 5)];
    pageCtrl.numberOfPages = self.emojiTotalPage; //总的图片页数
    pageCtrl.currentPage = 0;                     //当前页
    [pageCtrl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:pageCtrl];
    [self addSubview:self.tabbarView];
    BOOL isAddButtonEnabled = [[RCExtensionService sharedService]
        isEmoticonAddButtonEnabled:(RCChatSessionInputBarControl *)self.delegate];
    BOOL isSettingButtonEnabled = [[RCExtensionService sharedService]
        isEmoticonSettingButtonEnabled:(RCChatSessionInputBarControl *)self.delegate];
    [self.tabbarView showAddButton:isAddButtonEnabled showSettingButton:isSettingButtonEnabled];
    [self loadCustomerEmoticonPackage];
}

- (void)enableSendButton:(BOOL)enableSend {
    UIButton *sendButton = (UIButton *)[self viewWithTag:333];
    if (enableSend) {
        sendButton.userInteractionEnabled = YES;
        sendButton.backgroundColor = RCDYCOLOR(0x0099ff, 0x007Acc);
        [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        sendButton.userInteractionEnabled = NO;
        sendButton.backgroundColor = RCDYCOLOR(0xfafafa, 0x0b0b0c);
        [sendButton setTitleColor:RCDYCOLOR(0x999999, 0x505050) forState:UIControlStateNormal];
    }
}

- (void)addEmojiTab:(id<RCEmoticonTabSource>)viewDataSource {
    RCEmoticonPackage *model = [[RCEmoticonPackage alloc] initEmoticonPackage:[viewDataSource image]
                                                               withTotalCount:[viewDataSource pageCount]];
    model.tabSource = viewDataSource;
    model.identify = [viewDataSource identify];
    model.emojBoardView = self;
    if (!_emojiModelList) {
        _emojiModelList = [NSMutableArray new];
    }
    if (!_appAddEmojiModelList) {
        _appAddEmojiModelList = [NSMutableArray new];
    }
    [_appAddEmojiModelList addObject:model];
    [_emojiModelList addObject:model];
    [self loadCustomerEmoticonPackage];
}

- (void)addExtensionEmojiTab:(id<RCEmoticonTabSource>)viewDataSource {
    RCEmoticonPackage *model = [[RCEmoticonPackage alloc] initEmoticonPackage:[viewDataSource image]
                                                               withTotalCount:[viewDataSource pageCount]];
    model.tabSource = viewDataSource;
    model.identify = [viewDataSource identify];
    model.emojBoardView = self;
    if (!_emojiModelList) {
        _emojiModelList = [NSMutableArray new];
    }
    [_emojiModelList addObject:model];
    [self loadCustomerEmoticonPackage];
}

- (void)setCurrentIndex:(int)index withTotalPages:(int)totalPageNum {
    pageCtrl.numberOfPages = totalPageNum;
    rc_currentSelectIndexPage = index;
    [pageCtrl setCurrentPage:index];
}

- (void)reloadExtensionEmoticonTabSource {
    NSString *identify = nil;
    if (rc_currentSelectIndexPackage < _emojiModelList.count) {
        RCEmoticonPackage *model = _emojiModelList[rc_currentSelectIndexPackage];
        identify = model.identify;
    } else {
        rc_currentSelectIndexPackage = 0;
        rc_currentSelectIndexPage = 0;
    }

    if (_emojiModelList && _emojiModelList.count > 0) {
        [_emojiModelList removeAllObjects];
    }
    if (self.emojiBackgroundView) {
        [self.emojiBackgroundView removeFromSuperview];
        self.emojiBackgroundView = nil;
    }
    self.emojiBackgroundView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 186)];
    self.emojiBackgroundView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
    self.emojiBackgroundView.pagingEnabled = YES;
    self.emojiBackgroundView.contentSize = CGSizeMake(self.emojiTotalPage * self.frame.size.width, 186);
    self.emojiBackgroundView.showsHorizontalScrollIndicator = NO;
    self.emojiBackgroundView.showsVerticalScrollIndicator = NO;
    self.emojiBackgroundView.delegate = self;
    [self addSubview:self.emojiBackgroundView];
    self.emojiLoadedPage = 0;
    [self loadLabelView];
    for (int i = 0; i < _appAddEmojiModelList.count; i++) {
        [_emojiModelList addObject:_appAddEmojiModelList[i]];
    }
    NSArray<id<RCEmoticonTabSource>> *emoticonTabSourceList =
        [[RCExtensionService sharedService] getEmoticonTabList:self.conversationType targetId:self.targetId];
    for (id<RCEmoticonTabSource> source in emoticonTabSourceList) {
        RCEmoticonPackage *model =
            [[RCEmoticonPackage alloc] initEmoticonPackage:[source image] withTotalCount:[source pageCount]];
        model.tabSource = source;
        model.identify = [source identify];
        model.emojBoardView = self;
        [_emojiModelList addObject:model];
    };
    if (identify) {
        BOOL hasFoundPackage = NO;
        for (int i = 0; i < _emojiModelList.count; i++) {
            RCEmoticonPackage *model = _emojiModelList[i];
            if ([model.identify isEqualToString:identify]) {
                hasFoundPackage = YES;
                rc_currentSelectIndexPackage = i;
                [self showEmoticonPackage:i];
                CGSize viewSize = self.emojiBackgroundView.frame.size;
                CGRect rect =
                    CGRectMake(rc_currentSelectIndexPage * viewSize.width, 0, viewSize.width, viewSize.height);
                [model.emotionContainerView scrollRectToVisible:rect animated:NO];
                break;
            }
        }
        if (!hasFoundPackage) {
            rc_currentSelectIndexPage = 0;
            rc_currentSelectIndexPackage = 0;
        }
    } else {
        rc_currentSelectIndexPackage = (int)(_emojiModelList.count);
        [self showEmoticonPackage:rc_currentSelectIndexPackage];
    }
    [self loadCustomerEmoticonPackage];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self loadEmojiViewPartly];
}

//停止滚动的时候
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //更新UIPageControl的当前页
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    int selectIndex = currentIndex;
    if (currentIndex >= self.emojiTotalPage) {
        int emotionPackageIndex = currentIndex - self.emojiTotalPage;
        RCEmoticonPackage *model = self.emojiModelList[emotionPackageIndex];
        pageCtrl.numberOfPages = model.totalPage;
        selectIndex = 0;
        if (model.tabSource) {
            if (_preSelectEmoticonPackageIndex > emotionPackageIndex) {
                selectIndex = model.totalPage - 1;
                if (selectIndex < 0) {
                    selectIndex = 0;
                }
                [model showEmoticonView:selectIndex];
            } else {
                [model showEmoticonView:0];
            }
        }
        pageCtrl.numberOfPages = model.totalPage;
        rc_currentSelectIndexPackage = emotionPackageIndex + 1; //当前选择的表情包
        rc_currentSelectIndexPage = 0;
    } else {
        pageCtrl.numberOfPages = self.emojiTotalPage;
        rc_currentSelectIndexPackage = 0;
        rc_currentSelectIndexPage = currentIndex;
        if (self.emojiLoadedPage <= currentIndex) {
            [self showEmoticonView:currentIndex];
        }
    }
    [self.tabbarView showEmotion:rc_currentSelectIndexPackage];
    _preSelectEmoticonPackageIndex = rc_currentSelectIndexPackage;
    [pageCtrl setCurrentPage:selectIndex];
    DebugLog(@"%d/%d", rc_currentSelectIndexPage, rc_currentSelectIndexPackage);
}

#pragma mark - RCEmojiTabViewDelegate

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickSendButton:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(didSendButtonEvent:sendButton:)]) {
        [self.delegate didSendButtonEvent:self sendButton:button];
    }
}

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickSettingButton:(UIButton *)button{
    if ([self.delegate isKindOfClass:[RCChatSessionInputBarControl class]]) {
        [[RCExtensionService sharedService] emoticonTab:self
                                  didTouchSettingButton:button
                                             inInputBar:(RCChatSessionInputBarControl *)self.delegate];
    } else {
        [[RCExtensionService sharedService] emoticonTab:self didTouchSettingButton:button inInputBar:nil];
    }
}

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didClickAddButton:(UIButton *)button{
    if ([self.delegate isKindOfClass:[RCChatSessionInputBarControl class]]) {
        [[RCExtensionService sharedService] emoticonTab:self
                                      didTouchAddButton:button
                                             inInputBar:(RCChatSessionInputBarControl *)self.delegate];
    } else {
        [[RCExtensionService sharedService] emoticonTab:self didTouchAddButton:button inInputBar:nil];
    }
}

- (void)emojiTabView:(RCEmojiTabView *)emojiTabView didSelectEmotion:(int)index{
    _preSelectEmoticonPackageIndex = index;
    rc_currentSelectIndexPage = 0;
    [self loadEmotionTab:index];
}

#pragma mark - Private Methods
- (void)loadEmotionTab:(int)index {
    if ([self.delegate isKindOfClass:[RCChatSessionInputBarControl class]]) {
        [[RCExtensionService sharedService] emoticonTab:self
                               didTouchEmotionIconIndex:index
                                             inInputBar:(RCChatSessionInputBarControl *)self.delegate
                                    isBlockDefaultEvent:^(BOOL isBlockDefaultEvent) {
                                        if (!isBlockDefaultEvent) {
                                            [self showEmoticonPackage:index];
                                        }
                                    }];
    } else {
        [self showEmoticonPackage:index];
    }
}

//延迟加载
- (void)loadEmojiViewPartly {
    //每次加载两页，防止快速移动
    int beginEmojiBtn = self.emojiLoadedPage * self.emojiMaxCountPerPage;
    int endEmojiBtn = MIN(self.emojiTotal, (self.emojiLoadedPage + 2) * self.emojiMaxCountPerPage);
    float startPos_X = 0, startPos_Y = 26.5;
    startPos_X = self.emojiMariginHorizontalMin + 6;
    for (int i = beginEmojiBtn; i < endEmojiBtn; i++) {
        int pageIndex = i / self.emojiMaxCountPerPage;
        float emojiPosX =
            startPos_X + 42 * (i % self.emojiMaxCountPerPage % self.emojiColumn) + pageIndex * self.frame.size.width;
        float emojiPosY = startPos_Y + 47 * (i % self.emojiMaxCountPerPage / self.emojiColumn);
        UIButton *emojiBtn =
            [[UIButton alloc] initWithFrame:CGRectMake(emojiPosX, emojiPosY, RC_EMOJI_WIDTH, RC_EMOJI_WIDTH)];
        emojiBtn.titleLabel.font = [[RCKitConfig defaultConfig].font fontOfSize:26];
        [emojiBtn setTitle:self.faceEmojiArray[i] forState:UIControlStateNormal];
        [emojiBtn addTarget:self action:@selector(emojiBtnHandle:) forControlEvents:UIControlEventTouchUpInside];
        [self.emojiBackgroundView addSubview:emojiBtn];
        if (((i + 1) >= self.emojiMaxCountPerPage && (i + 1) % self.emojiMaxCountPerPage == 0) ||
            i == self.emojiTotal - 1) {
            CGRect frame = emojiBtn.frame;
            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton addTarget:self
                             action:@selector(emojiBtnHandle:)
                   forControlEvents:UIControlEventTouchUpInside];
            int offset = 30;
            frame.origin.x = self.frame.size.width - startPos_X - offset + pageIndex * self.frame.size.width;
            frame.size = CGSizeMake(RC_EMOJI_WIDTH, RC_EMOJI_WIDTH);
            deleteButton.frame = frame;
            [deleteButton setImage:RCResourceImage(@"emoji_btn_delete") forState:UIControlStateNormal];
            deleteButton.contentEdgeInsets = UIEdgeInsetsMake(3, 0, 0, 0);
            [self.emojiBackgroundView addSubview:deleteButton];
        }
        if (self.emojiLoadedPage < pageIndex + 1) {
            self.emojiLoadedPage = pageIndex + 1;
        }
    }
    self.emojiContentSize = self.emojiBackgroundView.contentSize;
}

- (void)generateDefaultLayoutParameters {
    CGFloat emojiSpanHorizontal = 42;
    int emojiRow = 3;
    self.emojiMariginHorizontalMin = 6;
    if (nil == self.faceEmojiArray || [self.faceEmojiArray count] == 0) {
        self.emojiTotal = 0;
    } else {
        self.emojiTotal = (int)[self.faceEmojiArray count];
    }
    self.emojiColumn = (int)(self.frame.size.width / emojiSpanHorizontal); // 能够容纳多少列
    int left = ((int)self.frame.size.width) % 42;
    if (left < 12) {
        self.emojiColumn--;
        left = left + emojiSpanHorizontal;
    }
    self.emojiMaxCountPerPage = self.emojiColumn * emojiRow - 1;
    self.emojiMariginHorizontalMin = left / 2;
    self.emojiTotalPage =
        self.emojiTotal / self.emojiMaxCountPerPage + (self.emojiTotal % self.emojiMaxCountPerPage ? 1 : 0);
}

- (void)loadCustomerEmoticonPackage {
    NSMutableArray *emojiList = @[RCResourceImage(@"emoji_btn_normal")].mutableCopy;
    for (int i = 0; i < _emojiModelList.count; i++) {
        RCEmoticonPackage *model = _emojiModelList[i];
        int offsetX = self.frame.size.width * i;
        CGRect frame = CGRectMake(self.emojiContentSize.width + offsetX, 0, self.frame.size.width,
                                  self.emojiBackgroundView.contentSize.height);
        [model.emotionContainerView setFrame:frame];
        // 给该试图添加一个tag，方便后期移除或者重新页面布局
        [self.emojiBackgroundView addSubview:model.emotionContainerView];
        CGSize size = self.emojiContentSize;
        size.width = self.emojiContentSize.width + self.frame.size.width * _emojiModelList.count;
        self.emojiBackgroundView.contentSize = size;
        [emojiList addObject:model.tabImage];
    }
    [self.tabbarView reloadTabView:emojiList.copy];
    if (rc_currentSelectIndexPackage <= self.emojiModelList.count)
        [self showEmoticonPackage:rc_currentSelectIndexPackage];
}

- (void)emojiBtnHandle:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTouchEmojiView:touchedEmoji:)]) {
        [self.delegate didTouchEmojiView:self touchedEmoji:sender.titleLabel.text];
    }
}

- (void)showEmoticonPackage:(int)index {
    int selectIndex = index;
    if (selectIndex > 0) {
        selectIndex = selectIndex + self.emojiTotalPage - 1;
        RCEmoticonPackage *model = self.emojiModelList[index - 1];
        pageCtrl.numberOfPages = model.totalPage;
        [model showEmoticonView:0];
        if (rc_currentSelectIndexPage > model.totalPage) {
            rc_currentSelectIndexPage = 0;
        }

    } else {
        pageCtrl.numberOfPages = self.emojiTotalPage;
    }
    CGSize viewSize = self.emojiBackgroundView.frame.size;
    CGRect rect = CGRectMake(selectIndex * viewSize.width, 0, viewSize.width, viewSize.height);
    [self.emojiBackgroundView scrollRectToVisible:rect animated:NO];
    [pageCtrl setCurrentPage:index];
    rc_currentSelectIndexPackage = index;
    _preSelectEmoticonPackageIndex = index;
    [self showEmoticonView:rc_currentSelectIndexPage];
    [self.tabbarView showEmotion:index];
}

- (void)showEmoticonView:(int)index {
    //    //令UIScrollView做出相应的滑动显示
    if (rc_currentSelectIndexPackage > 0) {
        if ((rc_currentSelectIndexPackage - 1) < _emojiModelList.count) {
            RCEmoticonPackage *model = _emojiModelList[rc_currentSelectIndexPackage - 1];
            if (rc_currentSelectIndexPage < model.totalPage) {
                [model showEmoticonView:rc_currentSelectIndexPage];
                [self setCurrentIndex:rc_currentSelectIndexPage withTotalPages:model.totalPage];
            }
        }
    } else {
        while (self.emojiLoadedPage <= index && (self.faceEmojiArray && self.faceEmojiArray.count > 0)) {
            [self loadEmojiViewPartly];
        }
        CGSize viewSize = self.emojiBackgroundView.frame.size;
        CGRect rect = CGRectMake(index * viewSize.width, 0, viewSize.width, viewSize.height);
        [self.emojiBackgroundView scrollRectToVisible:rect animated:YES];
        [pageCtrl setCurrentPage:index];
    }
}

//然后是点击UIPageControl时的响应函数pageTurn
- (void)pageTurn:(UIPageControl *)sender {
    int index = (int)sender.currentPage;
    rc_currentSelectIndexPage = 0;
    [self showEmoticonPackage:index];
}

- (float)getBoardViewBottonOriginY {
    float gap = (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    return [UIScreen mainScreen].bounds.size.height - gap;
}

- (void)needReloadEmoticonTabSource:(NSNotification *)notification {
    NSArray<RCEmoticonTabSource> *emoticonTabList = notification.object;
    if (emoticonTabList) {
        [self reloadExtensionEmoticonTabSource];
        if ([self.delegate isMemberOfClass:[RCChatSessionInputBarControl class]]) {
            RCChatSessionInputBarControl *chatSessionInputBarControl = (RCChatSessionInputBarControl *)self.delegate;
            if (chatSessionInputBarControl.inputTextView.text &&
                chatSessionInputBarControl.inputTextView.text.length > 0) {
                [self enableSendButton:YES];
            } else {
                [self enableSendButton:NO];
            }
        }
    }
}

#pragma mark - Getters and Setters
- (CGSize)contentViewSize {
    return CGSizeMake(self.frame.size.width, 186);
}

- (RCEmojiTabView *)tabbarView{
    if (!_tabbarView) {
        _tabbarView = [[RCEmojiTabView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 38, self.frame.size.width, 38)];
        _tabbarView.backgroundColor = RCDYCOLOR(0xffffff, 0x1a1a1a);
        _tabbarView.delegate = self;
    }
    return _tabbarView;
}
@end
