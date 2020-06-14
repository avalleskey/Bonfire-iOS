//
//  BFAlertController.m
//  Pulse
//
//  Created by Austin Valleskey on 4/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAlertController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import "ButtonCell.h"
#import "SpacerCell.h"
#import "Launcher.h"
#import "UIResponder+FirstResponder.h"

@interface BFAlertAction ()

@property (readwrite, assign) BFAlertActionStyle style;

@end

@implementation BFAlertAction

@synthesize style = _style;

- (id)init {
    if (self = [super init]) {
        self.enabled = true;
    }
    return self;
}

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(BFAlertActionStyle)style handler:(void (^ __nullable)(void))actionHandler {
    return [self actionWithTitle:title iconName:nil style:style handler:actionHandler];
}

+ (instancetype)actionWithTitle:(nullable NSString *)title iconName:(nullable NSString *)iconName style:(BFAlertActionStyle)style handler:(void (^ __nullable)(void))actionHandler {
    BFAlertAction *action = [[self alloc] init];
    action.title = title;
    action.style = style;
    
    // set icon
    if (!iconName || iconName.length == 0) {
        // check if it matches any automatic icon detection
        NSString *lowerCaseTitle = [title lowercaseString];
        if ([lowerCaseTitle isEqualToString:@"take photo"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconCamera];
        }
        else if ([lowerCaseTitle isEqualToString:@"choose from library"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconPhotoLibrary];
        }
        else if ([lowerCaseTitle isEqualToString:@"twitter"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconTwitter];
        }
        else if ([lowerCaseTitle isEqualToString:@"facebook"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconFacebook];
        }
        else if ([lowerCaseTitle isEqualToString:@"snapchat"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconSnapchat];
        }
        else if ([lowerCaseTitle isEqualToString:@"instagram stories"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconInstagramStories];
        }
        else if ([lowerCaseTitle isEqualToString:@"imessage"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconImessage];
        }
        else if ([lowerCaseTitle isEqualToString:@"bonfire"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconBonfire];
        }
        else if ([lowerCaseTitle isEqualToString:@"copy link"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconCopyLink];
        }
//        else if ([lowerCaseTitle isEqualToString:@"copy link to post"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconCopyLink];
//        }
//        else if ([lowerCaseTitle isEqualToString:@"open camp"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconCamp];
//        }
//        else if ([lowerCaseTitle isEqualToString:@"quote post"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconQuote];
//        }
//        else if ([lowerCaseTitle isEqualToString:@"report"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconReport];
//        }
//        else if ([lowerCaseTitle isEqualToString:@"mute conversation"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconMute];
//        }
//        else if ([lowerCaseTitle isEqualToString:@"unmute conversation"]) {
//            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconUnMute];
//        }
        else if ([lowerCaseTitle isEqualToString:@"other"] || [lowerCaseTitle isEqualToString:@"more options"]) {
            iconName = [BFAlertActionIcon iconNameWithTitle:BFAlertActionIconOther];
        }
    }
    if (iconName.length > 0 && [UIImage imageNamed:iconName]) {
        action.icon = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    if (actionHandler) {
        action.actionHandler = actionHandler;
    }
        
    return action;
}

/*
@property (nullable, nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BFAlertActionStyle style;
@property (nonatomic, getter=isEnabled) BOOL enabled;*/
- (BOOL)isEnabled {
    return self.enabled;
}

#pragma mark - NSCopying
-(instancetype)copyWithZone:(NSZone *)zone
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:
            [NSKeyedArchiver archivedDataWithRootObject:self]
            ];
}

@end

@implementation BFAlertActionIcon

NSString * const BFAlertActionIconCamera = @"camera";
NSString * const BFAlertActionIconPhotoLibrary = @"photo_library";
NSString * const BFAlertActionIconTwitter = @"twitter";
NSString * const BFAlertActionIconFacebook = @"facebook";
NSString * const BFAlertActionIconSnapchat = @"snapchat";
NSString * const BFAlertActionIconInstagramStories = @"ig_stories";
NSString * const BFAlertActionIconImessage = @"imessage";
NSString * const BFAlertActionIconBonfire = @"bonfire";
NSString * const BFAlertActionIconCopyLink = @"link";
NSString * const BFAlertActionIconCamp = @"camp";
NSString * const BFAlertActionIconQuote = @"quote";
NSString * const BFAlertActionIconReport = @"report";
NSString * const BFAlertActionIconMute = @"mute";
NSString * const BFAlertActionIconUnMute = @"unmute";
NSString * const BFAlertActionIconOther = @"other";

+ (NSString *)iconNameWithTitle:(NSString *)title {
    if (title) {
        NSString *iconName = [NSString stringWithFormat:@"alert_action_icon_%@", title];
        if ([UIImage imageNamed:iconName]) {
            return iconName;
        }
    }
        
    return @"";
}

@end

@interface BFAlertController () <UITableViewDelegate, UITableViewDataSource>

@property (readwrite, assign) BFAlertControllerStyle preferredStyle;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *pullTabIndicatorView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) id previousFirstResponder;

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFAlertController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const buttonCellIdentifier = @"ButtonCell";
static NSString * const spacerCellIdentifier = @"SpacerCell";
#define headerEdgeInsets UIEdgeInsetsMake(24, 32, 24, 32)

- (id)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.transitioningDelegate = nil;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.previousFirstResponder = [UIResponder currentFirstResponder];
        
        if (self.previousFirstResponder && [self.previousFirstResponder respondsToSelector:@selector(resignFirstResponder)] && ([self.previousFirstResponder isKindOfClass:[UITextField class]] || [self.previousFirstResponder isKindOfClass:[UITextView class]]) && ((UIView *)self.previousFirstResponder).superview != nil) {
            DLog(@"previous first responder: %@", self.previousFirstResponder);
            if ([self.previousFirstResponder isKindOfClass:[UITextField class]] ||
                [self.previousFirstResponder isKindOfClass:[UITextView class]]) {
                
                if (((UIView *)self.previousFirstResponder).superview) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"inside dispatch async block main thread from main thread");
                        [self.previousFirstResponder resignFirstResponder];
                    });
                }
                else {
                    NSLog(@"hehehe avoided catastrophe");
                }
            }
        }
    }
    return self;
}

+ (instancetype)alertControllerWithPreferredStyle:(BFAlertControllerStyle)preferredStyle {
    BFAlertController *alertController = [[self alloc] init];
    alertController.preferredStyle = preferredStyle;
        
    return alertController;
}

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle {
    BFAlertController *alertController = [self alertControllerWithPreferredStyle:preferredStyle];
    alertController.title = title;
    alertController.message = message;
        
    return alertController;
}

+ (instancetype)alertControllerWithIcon:(nullable UIImage *)icon title:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle {
    BFAlertController *alertController = [self alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
    if (icon) {
        alertController.icon = icon;
    }
        
    return alertController;
}

- (void)show {
    self.presenter = [[AlertViewControllerPresenter alloc] init];
    self.presenter.view.backgroundColor = UIColor.clearColor;
    
    UIWindow *win = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.presenter.win = win;
    win.rootViewController = self.presenter;
    win.windowLevel = UIWindowLevelAlert;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [win makeKeyAndVisible];
        [self.presenter presentViewController:self animated:NO completion:nil];
    });
}
- (void)dismissWithCompletion:(void (^ _Nullable)(void))completion {
    [self dismissWithAnimation:true completion:completion];
}
- (void)dismissWithAnimation:(BOOL)animation completion:(void (^ _Nullable)(void))completion {
    self.view.userInteractionEnabled = false;
    
    BOOL isAlert = (self.preferredStyle == BFAlertControllerStyleAlert);
    [UIView animateWithDuration:animation?(isAlert?0.25f:0.35f):0 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        if (isAlert) {
            self.contentView.transform = CGAffineTransformMakeScale(0.94, 0.94);
            self.contentView.alpha = 0;
        }
        else {
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
        }
    } completion:^(BOOL finished) {
        [self.presenter dismissViewControllerAnimated:false completion:^{
            if (completion) {
                completion();
            }
            
            if (self.previousFirstResponder) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.previousFirstResponder respondsToSelector:@selector(becomeFirstResponder)]) {
                        [self.previousFirstResponder becomeFirstResponder];
                    }
                });
            }
        }];
    }];
}

- (id)currentFirstResponder
{
    self.previousFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return self.previousFirstResponder;
}

-(void)findFirstResponder:(id)sender {
   self.previousFirstResponder = self;
}

- (void)setPreferredStyle:(BFAlertControllerStyle)preferredStyle {
    if (preferredStyle != _preferredStyle) {
        _preferredStyle = preferredStyle;
    }
}

- (void)setTextField:(UITextField *)textField {
    if (textField != _textField) {
        _textField = textField;
        
        [self addListeners];
        [self.tableView reloadData];
        [self resize];
    }
}

- (void)addAction:(BFAlertAction *)action {
    if (!self.actions) {
        self.actions = [NSMutableArray new];
    }
    [self.actions addObject:action];

    [self.tableView reloadData];
    [self resize];
}

- (void)addSpacer {
    if (!self.actions) {
        self.actions = [NSMutableArray new];
    }
    [self.actions addObject:[BFAlertAction actionWithTitle:nil style:BFAlertActionStyleSpacer handler:nil]];

    [self.tableView reloadData];
    [self resize];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initViews];
    [self initDefaults];
    
    [self resize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [[Launcher activeViewController] setEditing:false animated:YES];
        
        [UIView animateWithDuration:0.2f animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        
        [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        } completion:nil];
        
        if (self.preferredStyle == BFAlertControllerStyleAlert) {
            self.contentView.center = self.view.center;
            self.contentView.transform = CGAffineTransformMakeScale(1.06, 1.06);
            self.contentView.alpha = 0;
            
            [UIView animateWithDuration:0.2f delay:0.15f usingSpringWithDamping:0.82f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.transform = CGAffineTransformMakeScale(1, 1);
                self.contentView.alpha = 1;
            } completion:nil];
        }
        else {
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
            
            [UIView animateWithDuration:0.4f+(0.0006 * self.contentView.frame.size.height) delay:0.15f usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height - self.contentView.frame.size.height + (HAS_ROUNDED_CORNERS ? -[UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom : 64), self.contentView.frame.size.width, self.contentView.frame.size.height);
            } completion:nil];
        }
    }
    
    if (self.textField) {
        [self addListeners];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:true];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)initViews {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    [self initContentView];
    [self initTableView];
}

- (void)initDefaults {

}

- (void)initTapToDismiss {
    UIView *tapToDismissView = [[UIView alloc] initWithFrame:self.view.bounds];
    [tapToDismissView bk_whenTapped:^{
        [self dismissWithCompletion:nil];
    }];
    [self.view insertSubview:tapToDismissView atIndex:0];
}
- (void)removeTapToDismiss {
    for (UITapGestureRecognizer *tapRecognizer in self.view.gestureRecognizers) {
        [self.view removeGestureRecognizer:tapRecognizer];
    }
}

- (void)initContentView {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(8, self.view.frame.size.height, self.view.frame.size.width - 16, 0)];
    self.contentView.backgroundColor = [UIColor cardBackgroundColor];
    [self.view addSubview:self.contentView];
    
    if (self.preferredStyle == BFAlertControllerStyleActionSheet) {
        [self initTapToDismiss];
        [self initDragToDismiss];
        [self initPullTabIndicatorView];
    }
}

- (void)initPullTabIndicatorView {
    self.pullTabIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width / 2 - 35 / 2, 8, 35, 6)];
    self.pullTabIndicatorView.backgroundColor = [UIColor tableViewSeparatorColor];
    self.pullTabIndicatorView.layer.cornerRadius = self.pullTabIndicatorView.frame.size.height / 2;
    [self.contentView addSubview:self.pullTabIndicatorView];
}

#pragma mark - Table View
- (void)initTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, 100) style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.scrollEnabled = false;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.contentView addSubview:self.tableView];
    
    // register classes
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellIdentifier];
    [self.tableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellIdentifier];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.headerView) {
        return self.headerView;
    }
    else if (self.icon || self.title.length > 0 || self.message.length > 0 || self.textField) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        
        CGFloat bottomY = headerEdgeInsets.top;
        CGFloat bottomPadding = 0;
        if (self.icon) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(header.frame.size.width / 2 - self.icon.size.width / 2, bottomY, self.icon.size.width, self.icon.size.height)];
            imageView.image = self.icon;
            [header addSubview:imageView];
            
            bottomY  = imageView.frame.origin.y + imageView.frame.size.height;
            bottomPadding = roundf(imageView.frame.size.height * 0.25);
        }
        
        if (self.title.length > 0) {
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerEdgeInsets.left, bottomY + bottomPadding, header.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), 0)];
            titleLabel.text = self.title;
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.textColor = [UIColor bonfirePrimaryColor];
            titleLabel.numberOfLines = 0;
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
            CGFloat height = ceilf([titleLabel.text boundingRectWithSize:CGSizeMake(titleLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: titleLabel.font} context:nil].size.height);
            SetHeight(titleLabel, height);
            [header addSubview:titleLabel];
            
            bottomY = titleLabel.frame.origin.y + titleLabel.frame.size.height;
            bottomPadding = 6;
        }
        
        if (self.message.length > 0) {
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerEdgeInsets.left, bottomY + bottomPadding, header.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), 0)];
            messageLabel.text = self.message;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.textColor = [UIColor bonfireSecondaryColor];
            messageLabel.numberOfLines = 0;
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
            CGFloat height = ceilf([messageLabel.text boundingRectWithSize:CGSizeMake(messageLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: messageLabel.font} context:nil].size.height);
            SetHeight(messageLabel, height);
            [header addSubview:messageLabel];
            
            bottomY = messageLabel.frame.origin.y + messageLabel.frame.size.height;
            bottomPadding = 6;
        }
        
        if (self.textField) {
            self.textField.frame = CGRectMake(headerEdgeInsets.left, bottomY + (bottomPadding > 0 ? 16 : 0), header.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), 44);
//            self.textField.backgroundColor = [UIColor bonfireDetailColor];
            self.textField.layer.cornerRadius = 10.f;
            self.textField.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
            self.textField.layer.borderWidth = 1;
            self.textField.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
            self.textField.textColor = [UIColor bonfirePrimaryColor];
            self.textField.keyboardAppearance = UIKeyboardAppearanceDark;
            
            UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
            self.textField.leftViewMode = UITextFieldViewModeAlways;
            self.textField.rightViewMode = UITextFieldViewModeAlways;
            self.textField.leftView = paddingView;
            self.textField.rightView = paddingView;
            
            [header addSubview:self.textField];
            
            bottomY = self.textField.frame.origin.y + self.textField.frame.size.height;
        }
        
        SetHeight(header, bottomY + headerEdgeInsets.bottom);
        
        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.headerView) {
        return self.headerView.frame.size.height;
    }
    else if (self.title.length > 0 || self.message.length > 0 || self.textField) {
        CGFloat height = headerEdgeInsets.top;
        CGFloat bottomPadding = 0;
        
        if (self.icon) {
            height += self.icon.size.height;
            bottomPadding = roundf(self.icon.size.height * 0.25);
        }
        
        if (self.title.length > 0) {
            CGFloat titleHeight = ceilf([self.title boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold]} context:nil].size.height);
            height += (bottomPadding + titleHeight);
            
            bottomPadding = 6;
        }
        
        if (self.message.length > 0) {
            CGFloat messageHeight = ceilf([self.message boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular]} context:nil].size.height);
            height += (bottomPadding + messageHeight);
            
            bottomPadding = 6;
        }
        
        if (self.textField) {
            CGFloat textFieldHeight = 44;
            height += (bottomPadding > 0 ? 16 : 0) + textFieldHeight;
        }
        
        return height + headerEdgeInsets.bottom + (self.preferredStyle == BFAlertControllerStyleActionSheet ? 8 : 0);
    }
    
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.actions.count) {
        BFAlertAction *action = self.actions[indexPath.row];
        
        if (action.style == BFAlertActionStyleSpacer) {
            SpacerCell *cell = [tableView dequeueReusableCellWithIdentifier:spacerCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[SpacerCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:spacerCellIdentifier];
            }
            
            cell.bottomSeparator.hidden = true;
            
            return cell;
        }
        else {
            ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellIdentifier];
            }
            
            cell.backgroundColor = [UIColor cardBackgroundColor];
                    
            // Configure the cell...
            if (action.title) {
                cell.buttonLabel.text = action.title;
            }
            cell.buttonLabel.textAlignment = NSTextAlignmentCenter;
            
            cell.topSeparator.hidden = indexPath.row == 0 && !self.headerView && (self.title.length == 0 && self.message.length == 0);
            cell.bottomSeparator.hidden = true;
            
            CGFloat buttonFontPointSize = 18;
            if (action.style == BFAlertActionStyleCancel) {
                cell.buttonLabel.textColor = cell.kButtonColorDefault;
            }
            else if (action.style == BFAlertActionStyleDestructive) {
                cell.buttonLabel.textColor = cell.kButtonColorDestructive;
            }
            else if (action.style == BFAlertActionStyleSemiDestructive) {
                cell.buttonLabel.textColor = cell.kButtonColorSemiDestructive;
            }
            else {
                cell.buttonLabel.textColor = cell.kButtonColorDefault;
            }
            
            if (action == self.preferredAction || (!self.preferredAction && action.style == BFAlertActionStyleCancel)) {
                cell.buttonLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightSemibold];
            }
            else {
                cell.buttonLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightRegular];
            }
            
            if (action.icon) {
                cell.iconImageView.image = action.icon;
                cell.iconImageView.alpha = 0.5;
            }
            else {
                cell.iconImageView.image = nil;
                cell.iconImageView.alpha = 0;
            }
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actions.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.actions.count) {
        BFAlertAction *action = self.actions[indexPath.row];
        
        if (action.style == BFAlertActionStyleSpacer) {
            return [SpacerCell height];
        }
        else {
            return [ButtonCell height];
        }
    }
    
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.actions.count) {
        BFAlertAction *action = self.actions[indexPath.row];
        
        [self dismissWithCompletion:^{
            if (action && action.actionHandler != nil) {
                action.actionHandler();
            }
        }];
    }
}

- (void)initDragToDismiss {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.contentView addGestureRecognizer:panRecognizer];
}
- (void)removeDragToDismiss {
    for (UIGestureRecognizer *gestureRecognizer in self.contentView.gestureRecognizers) {
        [self.contentView removeGestureRecognizer:gestureRecognizer];
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, self.centerBegin.y + (self.contentView.frame.size.height * 2));
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        if (translation.y > 0 || recognizer.view.center.y >= self.centerBegin.y) {
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 recognizer.view.center.y + translation.y);
        }
        else {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = 24;
            CGFloat percentage = diff / max;
            if (percentage > 1) {
                percentage = 1;
            }
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 10 * percentage));

            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
        }
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        if (percentage > 0) {
            //recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - 0.8) * percentage, 1.0 - (1.0 - 0.8) * percentage);
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
                
        if (velocity.y > 400) {
            [self dismissWithCompletion:nil];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
                recognizer.view.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}

- (void)resize {
    UIEdgeInsets edgeInsets;
    if (self.preferredStyle == BFAlertControllerStyleAlert) {
        edgeInsets = UIEdgeInsetsMake(0, 32, 0, 32);
    }
    else {
        edgeInsets = UIEdgeInsetsMake(0, (HAS_ROUNDED_CORNERS ? 8 : 0), 0, (HAS_ROUNDED_CORNERS ? 8 : 0));
    }
    
    CGFloat height = 0;
    CGFloat width = MIN(IPAD_CONTENT_MAX_WIDTH, self.view.frame.size.width - edgeInsets.left - edgeInsets.right);
    
    self.contentView.frame = CGRectMake(self.view.frame.size.width / 2 - width / 2, self.contentView.frame.origin.y, width, 0);
    
    if (self.pullTabIndicatorView) {
        self.pullTabIndicatorView.frame = CGRectMake(self.contentView.frame.size.width / 2 - self.pullTabIndicatorView.frame.size.width / 2, self.pullTabIndicatorView.frame.origin.y, self.pullTabIndicatorView.frame.size.width, self.pullTabIndicatorView.frame.size.height);
        height += self.pullTabIndicatorView.frame.size.height +  (self.pullTabIndicatorView.frame.origin.y * 2);
    }
    
    float sizeOfTableViewContent = 0;
    for (int s = 0; s < [self.tableView numberOfSections]; s++) {
        sizeOfTableViewContent += [self tableView:self.tableView heightForHeaderInSection:s];
        for (int r = 0; r < [self.tableView numberOfRowsInSection:s]; r++) {
            sizeOfTableViewContent += [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]];
        }
        sizeOfTableViewContent += [self tableView:self.tableView heightForFooterInSection:s];
    }
    self.tableView.frame = CGRectMake(0, height, self.contentView.frame.size.width, sizeOfTableViewContent);
    height += self.tableView.frame.size.height;
    
    if (self.preferredStyle == BFAlertControllerStyleActionSheet && !HAS_ROUNDED_CORNERS) {
        height += 64;
    }
    
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.view.frame.size.width - (self.contentView.frame.origin.x * 2), height);
    [self continuityRadiusForView:self.contentView withRadius:HAS_ROUNDED_CORNERS?24:10];
}

#pragma mark - Misc. methods

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UIEdgeInsets safeAreaInsets = window.safeAreaInsets;
    
    self.contentView.center = CGPointMake(self.view.frame.size.width / 2, (safeAreaInsets.top + (self.view.frame.size.height - _currentKeyboardHeight)) / 2);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.contentView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    } completion:nil];
}

@end

@implementation AlertViewControllerPresenter

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [_win resignKeyWindow]; //optional nilling the window works
    _win.hidden = YES; //optional nilling the window works
    _win = nil;
    [super dismissViewControllerAnimated:flag completion:^{
        if (completion) completion();
        
        [UIView animateWithDuration:0.2f animations:^{
            [[Launcher activeViewController] setNeedsStatusBarAppearanceUpdate];
        }];
    }];
    
    
}

@end
