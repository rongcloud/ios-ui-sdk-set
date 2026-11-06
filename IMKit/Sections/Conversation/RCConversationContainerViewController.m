#import "RCConversationContainerViewController+Internal.h"
#import "RCConversationListViewController.h"
#import "RCConversationViewController.h"
#import "RCConversationModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@interface RCConversationContainerViewController () <UISplitViewControllerDelegate>
@property (nonatomic, strong, readwrite) RCConversationListViewController *conversationListViewController;
@property (nonatomic, strong) UINavigationController *listNavigationController;
@property (nonatomic, strong) UINavigationController *detailNavigationController;
@property (nonatomic, strong) UISplitViewController *conversationSplitViewController;
@property (nonatomic, strong, readwrite) RCConversationViewController *currentConversationViewController;
@property (nonatomic, assign, readwrite, getter=isExpanded) BOOL expanded;
@property (nonatomic, assign) BOOL applyingLayout;
@property (nonatomic, assign) BOOL compactOverrideApplied;
@property (nonatomic, weak) UIImageView *placeholderImageView;
@property (nonatomic, weak) UILabel *placeholderLabel;
@end

@implementation RCConversationContainerViewController

- (instancetype)initWithConversationListViewController:(RCConversationListViewController *)listViewController {
    NSParameterAssert(listViewController);
    NSAssert([NSThread isMainThread], @"Conversation containers must be configured on the main thread.");
    if (!listViewController || listViewController.parentViewController) {
        [NSException raise:NSInvalidArgumentException format:@"The conversation list must not belong to another controller."];
    }
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _conversationListViewController = listViewController;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.listNavigationController = [self createNavigationControllerWithRoot:self.conversationListViewController];
    self.view.backgroundColor = self.conversationListViewController.view.backgroundColor;
    if (@available(iOS 14.0, *)) {
        UISplitViewController *split = [[UISplitViewController alloc] initWithStyle:UISplitViewControllerStyleDoubleColumn];
        self.conversationSplitViewController = split;
        split.delegate = self;
        split.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        split.preferredSplitBehavior = UISplitViewControllerSplitBehaviorTile;
        split.presentsWithGesture = NO;
        self.detailNavigationController = [self createNavigationControllerWithRoot:[self detailPlaceholder]];
        [split setViewController:self.listNavigationController forColumn:UISplitViewControllerColumnPrimary];
        [split setViewController:self.detailNavigationController forColumn:UISplitViewControllerColumnSecondary];
        [self addContentController:split];
        [self updateAdaptiveLayout];
    } else {
        [self addContentController:self.listNavigationController];
    }
}

- (UINavigationController *)createNavigationControllerWithRoot:(UIViewController *)root {
    UINavigationController *navigation = self.navigationControllerFactory ? self.navigationControllerFactory(root) : [[UINavigationController alloc] initWithRootViewController:root];
    if (!navigation || navigation.parentViewController || navigation.viewControllers.firstObject != root) {
        [NSException raise:NSInvalidArgumentException format:@"The navigation factory must return an unowned navigation controller with the supplied root."];
    }
    return navigation;
}

- (void)addContentController:(UIViewController *)controller {
    [self addChildViewController:controller];
    controller.view.frame = self.view.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (UIViewController *)detailPlaceholder {
    if (!self.placeholderViewController) {
        UIViewController *placeholder = [[UIViewController alloc] init];
        placeholder.view.backgroundColor = self.view.backgroundColor;
        if (@available(iOS 13.0, *)) {
            // 空白页顶部与内容使用相同背景，外观限定在当前页面，避免影响会话导航栏。
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithOpaqueBackground];
            appearance.backgroundColor = placeholder.view.backgroundColor;
            appearance.shadowColor = UIColor.clearColor;
            placeholder.navigationItem.standardAppearance = appearance;
            placeholder.navigationItem.scrollEdgeAppearance = appearance;
            placeholder.navigationItem.compactAppearance = appearance;
            if (@available(iOS 15.0, *)) {
                placeholder.navigationItem.compactScrollEdgeAppearance = appearance;
            }
        }
        self.placeholderViewController = placeholder;
        [self setupEmptyContentInView:placeholder.view];
    }
    return self.placeholderViewController;
}

- (void)setupEmptyContentInView:(UIView *)view {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    UIStackView *contentView = [[UIStackView alloc] initWithArrangedSubviews:@[imageView, label]];
    contentView.axis = UILayoutConstraintAxisVertical;
    contentView.alignment = UIStackViewAlignmentCenter;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:contentView];
    UILayoutGuide *safeArea = view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [contentView.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [contentView.centerYAnchor constraintEqualToAnchor:safeArea.centerYAnchor],
        [contentView.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor],
        [contentView.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor],
        [contentView.topAnchor constraintGreaterThanOrEqualToAnchor:safeArea.topAnchor],
        [contentView.bottomAnchor constraintLessThanOrEqualToAnchor:safeArea.bottomAnchor],
        [imageView.widthAnchor constraintLessThanOrEqualToAnchor:contentView.widthAnchor]
    ]];
    self.placeholderImageView = imageView;
    self.placeholderLabel = label;
    [self updatePlaceholderAppearance];
}

- (void)updatePlaceholderAppearance {
    if (!self.placeholderImageView) {
        return;
    }
    self.placeholderImageView.image = RCDynamicImage(@"conversation-list_no_message_img", @"no_message_img");
    self.placeholderLabel.text = RCLocalizedString(@"no_message");
    self.placeholderLabel.font = [[RCKitConfig defaultConfig].font fontOfFourthLevel];
    self.placeholderLabel.textColor = RCDynamicColor(@"text_primary_color", @"0xD3D3D3", @"0xD3D3D3");
}

- (void)setNavigationControllerFactory:(UINavigationController * _Nonnull (^ _Nullable)(UIViewController *rootViewController))navigationControllerFactory {
    NSAssert([NSThread isMainThread], @"Conversation containers must be configured on the main thread.");
    if (self.isViewLoaded) {
        [NSException raise:NSInternalInconsistencyException format:@"Set the navigation factory before loading the container view."];
    }
    _navigationControllerFactory = [navigationControllerFactory copy];
}

- (void)setPlaceholderViewController:(UIViewController *)placeholderViewController {
    NSAssert([NSThread isMainThread], @"Conversation containers must be configured on the main thread.");
    if (placeholderViewController == _placeholderViewController) {
        return;
    }
    if (placeholderViewController.parentViewController) {
        [NSException raise:NSInvalidArgumentException format:@"The placeholder must not belong to another controller."];
    }
    self.placeholderImageView = nil;
    self.placeholderLabel = nil;
    _placeholderViewController = placeholderViewController;
    if (self.detailNavigationController && !self.currentConversationViewController) {
        [self.detailNavigationController setViewControllers:@[[self detailPlaceholder]] animated:NO];
    }
}

- (void)setConversationViewControllerFactory:(RCConversationViewController * _Nullable (^ _Nullable)(RCConversationModel *model))conversationViewControllerFactory {
    NSAssert([NSThread isMainThread], @"Conversation containers must be configured on the main thread.");
    _conversationViewControllerFactory = [conversationViewControllerFactory copy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateAdaptiveLayout];
    [self synchronizeListSelection];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self.view setNeedsLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updatePlaceholderAppearance];
    [self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePlaceholderAppearance];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (void)updateAdaptiveLayout {
    if (!self.conversationSplitViewController || self.applyingLayout) {
        return;
    }
    if (@available(iOS 14.0, *)) {
        self.applyingLayout = YES;
        UIEdgeInsets insets = self.view.safeAreaInsets;
        CGSize size = self.view.bounds.size;
        CGFloat availableWidth = size.width - insets.left - insets.right;
        BOOL eligible = YES;
        if ([self.delegate respondsToSelector:@selector(conversationContainer:shouldExpandForSize:)]) {
            eligible = [self.delegate conversationContainer:self shouldExpandForSize:size];
        }
        // List actions and message/input controls each need readable content width.
        BOOL accessibilitySize = NO;
        if (@available(iOS 11.0, *)) {
            accessibilitySize = UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
        }
        CGFloat minimumWidth = accessibilitySize ? 1000.0 : 700.0;
        BOOL shouldOverride = !eligible || availableWidth < minimumWidth;
        if (shouldOverride != self.compactOverrideApplied) {
            self.compactOverrideApplied = shouldOverride;
            UITraitCollection *traits = shouldOverride ? [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact] : nil;
            [self setOverrideTraitCollection:traits forChildViewController:self.conversationSplitViewController];
        }
        [self updateExpandedState];
        self.applyingLayout = NO;
    }
}

- (void)updateExpandedState {
    BOOL expanded = NO;
    if (@available(iOS 14.0, *)) {
        expanded = self.conversationSplitViewController && !self.conversationSplitViewController.isCollapsed && self.conversationSplitViewController.displayMode == UISplitViewControllerDisplayModeOneBesideSecondary;
    }
    if (_expanded != expanded) {
        _expanded = expanded;
        [self.currentConversationViewController.viewIfLoaded setNeedsLayout];
        if ([self.delegate respondsToSelector:@selector(conversationContainer:didChangeExpanded:)]) {
            [self.delegate conversationContainer:self didChangeExpanded:expanded];
        }
    }
}

- (BOOL)matchesType:(RCConversationType)type targetId:(NSString *)targetId channelId:(NSString *)channelId {
    RCConversationViewController *current = self.currentConversationViewController;
    return current && current.conversationType == type && [current.targetId isEqualToString:targetId] && [(current.channelId ?: @"") isEqualToString:(channelId ?: @"")];
}

- (void)showConversationModel:(RCConversationModel *)model animated:(BOOL)animated {
    NSAssert([NSThread isMainThread], @"Present conversations on the main thread.");
    if ([self matchesType:model.conversationType targetId:model.targetId channelId:model.channelId]) {
        [self presentConversationViewController:self.currentConversationViewController animated:animated];
        return;
    }
    RCConversationViewController *conversation = self.conversationViewControllerFactory ? self.conversationViewControllerFactory(model) : [[RCConversationViewController alloc] initWithConversationType:model.conversationType targetId:model.targetId];
    if (!conversation) {
        return;
    }
    if (!self.conversationViewControllerFactory) {
        conversation.channelId = model.channelId;
        conversation.title = model.conversationTitle;
        if (model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_NORMAL) {
            conversation.unReadMessage = model.unreadMessageCount;
            conversation.enableNewComingMessageIcon = YES;
            conversation.enableUnreadMessageIcon = YES;
        }
    }
    [self presentConversationViewController:conversation animated:animated];
}

- (void)presentConversationViewController:(RCConversationViewController *)viewController animated:(BOOL)animated {
    NSAssert([NSThread isMainThread], @"Present conversations on the main thread.");
    NSParameterAssert(viewController);
    if (!viewController) {
        return;
    }
    (void)self.view;
    BOOL isCurrentViewController = viewController == self.currentConversationViewController;
    if (!isCurrentViewController && viewController.parentViewController) {
        [NSException raise:NSInvalidArgumentException format:@"The conversation must not belong to another controller."];
    }
    RCConversationViewController *conversation = viewController;
    if (@available(iOS 14.0, *)) {
        self.currentConversationViewController = conversation;
        if (isCurrentViewController && [self.detailNavigationController.viewControllers containsObject:conversation]) {
            [self.detailNavigationController popToViewController:conversation animated:animated && self.isExpanded];
        } else {
            [self.detailNavigationController setViewControllers:@[conversation] animated:NO];
        }
        if (!self.isExpanded) {
            [self.conversationSplitViewController showColumn:UISplitViewControllerColumnSecondary];
        }
    } else {
        if (isCurrentViewController) {
            [self.listNavigationController popToViewController:conversation animated:animated];
        } else {
            [self closeConversationAnimated:NO];
            self.currentConversationViewController = conversation;
            [self.listNavigationController pushViewController:conversation animated:animated];
        }
    }
    [self synchronizeListSelection];
}

- (void)closeConversationAnimated:(BOOL)animated {
    NSAssert([NSThread isMainThread], @"Close conversations on the main thread.");
    [self.view endEditing:YES];
    RCConversationViewController *conversation = self.currentConversationViewController;
    if (!conversation) {
        return;
    }
    self.currentConversationViewController = nil;
    if (@available(iOS 14.0, *)) {
        if (self.conversationSplitViewController.isCollapsed) {
            NSArray<UIViewController *> *stack = self.listNavigationController.viewControllers;
            NSUInteger detailIndex = [stack indexOfObject:self.detailNavigationController];
            if (detailIndex != NSNotFound && detailIndex > 0) {
                // Collapsed splits append the detail navigation controller to the list stack.
                // Showing the primary column would also discard pushed aggregate lists.
                [self.listNavigationController popToViewController:stack[detailIndex - 1] animated:animated];
            } else {
                [self.conversationSplitViewController showColumn:UISplitViewControllerColumnPrimary];
            }
        }
        [self.detailNavigationController setViewControllers:@[[self detailPlaceholder]] animated:NO];
    } else {
        NSUInteger index = [self.listNavigationController.viewControllers indexOfObject:conversation];
        if (index != NSNotFound) {
            NSArray *stack = [self.listNavigationController.viewControllers subarrayWithRange:NSMakeRange(0, index)];
            [self.listNavigationController setViewControllers:stack animated:animated];
        }
    }
    [self synchronizeListSelection];
}

- (void)conversationWasDeleted:(RCConversationModel *)model {
    NSAssert([NSThread isMainThread], @"Notify conversation deletions on the main thread.");
    if ((model.conversationModelType == RC_CONVERSATION_MODEL_TYPE_COLLECTION &&
         self.currentConversationViewController.conversationType == model.conversationType) ||
        [self matchesType:model.conversationType targetId:model.targetId channelId:model.channelId]) {
        [self closeConversationAnimated:NO];
    }
}

- (void)synchronizeListSelection {
    for (UIViewController *controller in self.listNavigationController.viewControllers) {
        if (![controller isKindOfClass:[RCConversationListViewController class]] || !controller.isViewLoaded) {
            continue;
        }
        RCConversationListViewController *list = (RCConversationListViewController *)controller;
        NSIndexPath *selected = list.conversationListTableView.indexPathForSelectedRow;
        if (selected) {
            [list.conversationListTableView deselectRowAtIndexPath:selected animated:NO];
        }
        if (!self.currentConversationViewController || !self.isExpanded) {
            continue;
        }
        NSUInteger index = 0;
        for (RCConversationModel *model in list.conversationListDataSource) {
            if ([self matchesType:model.conversationType targetId:model.targetId channelId:model.channelId]) {
                NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
                if (index < [list.conversationListTableView numberOfRowsInSection:0]) {
                    [list.conversationListTableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
                break;
            }
            index++;
        }
    }
}

+ (instancetype)containerForViewController:(UIViewController *)viewController {
    for (UIViewController *controller = viewController; controller; controller = controller.parentViewController) {
        if ([controller isKindOfClass:self]) {
            return (RCConversationContainerViewController *)controller;
        }
    }
    return nil;
}

- (UISplitViewControllerColumn)splitViewController:(UISplitViewController *)svc topColumnForCollapsingToProposedTopColumn:(UISplitViewControllerColumn)proposedTopColumn API_AVAILABLE(ios(14.0)) {
    return self.currentConversationViewController ? UISplitViewControllerColumnSecondary : UISplitViewControllerColumnPrimary;
}

- (void)splitViewControllerDidCollapse:(UISplitViewController *)svc {
    [self updateExpandedState];
}

- (void)splitViewControllerDidExpand:(UISplitViewController *)svc {
    [self updateExpandedState];
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    [self.view setNeedsLayout];
}
@end
