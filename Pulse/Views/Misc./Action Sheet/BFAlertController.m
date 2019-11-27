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
#import "Launcher.h"

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
    BFAlertAction *action = [[self alloc] init];
    action.title = title;
    action.style = style;
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

@interface BFAlertController () <UITableViewDelegate, UITableViewDataSource>

@property (readwrite, assign) BFAlertControllerStyle preferredStyle;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *pullTabIndicatorView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFAlertController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const buttonCellIdentifier = @"ButtonCell";
#define headerEdgeInsets UIEdgeInsetsMake(24, 32, 24, 32)

- (id)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.transitioningDelegate = nil;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle {
    BFAlertController *alertController = [[self alloc] init];
    alertController.title = title;
    alertController.message = message;
    alertController.preferredStyle = preferredStyle;
        
    return alertController;
}

- (void)setPreferredStyle:(BFAlertControllerStyle)preferredStyle {
    if (preferredStyle != _preferredStyle) {
        _preferredStyle = preferredStyle;
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
        
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        } completion:nil];
        
        if (self.preferredStyle == BFAlertControllerStyleAlert) {
            self.contentView.center = self.view.center;
            self.contentView.transform = CGAffineTransformMakeScale(1.06, 1.06);
            self.contentView.alpha = 0;
            
            [UIView animateWithDuration:0.3f delay:0.1f usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.transform = CGAffineTransformMakeScale(1, 1);
                self.contentView.alpha = 1;
            } completion:nil];
        }
        else {
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
            
            [UIView animateWithDuration:0.5f delay:0.1f usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height - self.contentView.frame.size.height - (HAS_ROUNDED_CORNERS ? 0 : 8) - [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom, self.contentView.frame.size.width, self.contentView.frame.size.height);
            } completion:nil];
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.presentingViewController.preferredStatusBarStyle;
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
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
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
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.headerView) {
        return self.headerView;
    }
    else if (self.title.length > 0 || self.message.length > 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0)];
        
        CGFloat bottomY = headerEdgeInsets.top;
        if (self.title.length > 0) {
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerEdgeInsets.left, bottomY, header.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), 0)];
            titleLabel.text = self.title;
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.textColor = [UIColor bonfirePrimaryColor];
            titleLabel.numberOfLines = 0;
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
            CGFloat height = ceilf([titleLabel.text boundingRectWithSize:CGSizeMake(titleLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: titleLabel.font} context:nil].size.height);
            SetHeight(titleLabel, height);
            [header addSubview:titleLabel];
            
            bottomY += titleLabel.frame.size.height;
        }
        
        if (self.message.length > 0) {
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerEdgeInsets.left, bottomY + (self.title.length > 0 ? 6 : 0), header.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), 0)];
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
    else if (self.title.length > 0 || self.message.length > 0) {
        CGFloat height = headerEdgeInsets.top;
        
        if (self.title.length > 0) {
            CGFloat titleHeight = ceilf([self.title boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold]} context:nil].size.height);
            height += titleHeight;
        }
        
        if (self.message.length > 0) {
            CGFloat messageHeight = ceilf([self.message boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - (headerEdgeInsets.left + headerEdgeInsets.right), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular]} context:nil].size.height);
            height += (self.title.length > 0 ? 6 : 0) + messageHeight;
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
        
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellIdentifier];
        }
                
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
        else {
            cell.buttonLabel.textColor = cell.kButtonColorDefault;
        }
        
        if (action == self.preferredAction || (!self.preferredAction && action.style == BFAlertActionStyleCancel)) {
            cell.buttonLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightSemibold];
        }
        else {
            cell.buttonLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightRegular];
        }
        
        return cell;
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
    return 56;
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
    CGFloat height = 0;
    
    UIEdgeInsets edgeInsets;
    if (self.preferredStyle == BFAlertControllerStyleAlert) {
        edgeInsets = UIEdgeInsetsMake(0, 32, 0, 32);
    }
    else {
        edgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    }
    
    self.contentView.frame = CGRectMake(edgeInsets.left, self.contentView.frame.origin.y, self.view.frame.size.width - (edgeInsets.left + edgeInsets.right), 0);
    
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
    
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.view.frame.size.width - (self.contentView.frame.origin.x * 2), height);
    [self continuityRadiusForView:self.contentView withRadius:HAS_ROUNDED_CORNERS?24:6];
}

- (void)dismissWithCompletion:(void (^ _Nullable)(void))handler {
    self.view.userInteractionEnabled = false;
    
    BOOL isAlert = (self.preferredStyle == BFAlertControllerStyleAlert);
    [UIView animateWithDuration:isAlert?0.25f:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        if (isAlert) {
            self.contentView.transform = CGAffineTransformMakeScale(0.94, 0.94);
            self.contentView.alpha = 0;
        }
        else {
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
        }
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:false completion:^{
            if (handler) {
                handler();
            }
        }];
    }];
}

#pragma mark - Misc. methods

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
