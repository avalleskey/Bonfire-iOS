//
//  ComposeViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/14/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ComposeViewController.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import "SimpleNavigationController.h"
#import "SearchResultCell.h"
#import "StreamPostCell.h"
#import "NSString+Validation.h"
#import <HapticHelper/HapticHelper.h>
#import "HAWebService.h"
@import Firebase;
#import <Photos/Photos.h>
#import "GTMNSString+HTML.h"
#import "BFAlertController.h"

#import "BFPostAttachmentView.h"
#import "BFIdentityAttachmentView.h"
#import "BFBotAttachmentView.h"
#import "BFCampAttachmentView.h"
#import "BFLinkAttachmentView.h"
#import "BFSmartLinkAttachmentView.h"

#define composeToolbarHeight 56

@interface ComposeViewController () {
    NSInteger maxLength;
}

@property (nonatomic) NSAttributedString *activeAttributedString;
@property (nonatomic) NSRange activeTagRange;
@property (nonatomic) NSMutableArray *autoCompleteResults;

@property (nonatomic) BFAttachmentView *quotedAttachmentView;
@property (nonatomic) ComposeTextViewCell *textViewCell;
@property (nonatomic) BOOL isScrolling;

@end

@implementation ComposeViewController {
    NSString *defaultPlaceholder;
    NSString *mediaPlaceholder;
}

static NSString * const composeTextViewCellReuseIdentifier = @"ComposeTextViewCell";
static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const searchResultCellIdentifier = @"SearchResultCell";
static NSString * const blankCellIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.navigationController.navigationBar.tintColor = [UIColor bonfirePrimaryColor];
    
    maxLength = [Session sharedInstance].defaults.post.maxLength;
    
    if (self.replyingTo) {
        [FIRAnalytics setScreenName:@"Reply" screenClass:nil];
    }
    else if (self.quotedObject) {
        [FIRAnalytics setScreenName:@"Quote" screenClass:nil];
    }
    else {
        [FIRAnalytics setScreenName:@"Compose" screenClass:nil];
    }
    
    [self setupTableView];
    [self setupTitleView];
    [self setupToolbar];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.tableView.contentOffset.y <= 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [(SimpleNavigationController *)self.navigationController hideBottomHairline];
        });
    }
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [((SimpleNavigationController *)self.navigationController).leftActionView bk_removeAllBlockObservers];
        [((SimpleNavigationController *)self.navigationController).leftActionView bk_whenTapped:^{
            if (self.textViewCell.textView.text.length > 0 || self.textViewCell.media.objects.count > 0) {
                // confirm discard changes
                BFAlertController *confirmActionSheet = [BFAlertController alertControllerWithTitle:nil message:@"Are you sure you want to discard your post?" preferredStyle:BFAlertControllerStyleActionSheet];
                
                BFAlertAction *confirmAction = [BFAlertAction actionWithTitle:@"Discard Post" style:BFAlertActionStyleDestructive handler:^{
                    [confirmActionSheet dismissViewControllerAnimated:YES completion:nil];
                    
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }];
                [confirmActionSheet addAction:confirmAction];
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                [confirmActionSheet addAction:cancelActionSheet];
                
                [self.navigationController presentViewController:confirmActionSheet animated:true completion:nil];
            }
            else {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        
        [self updatePlaceholder];
        if (self.replyingTo && !self.replyingToIcebreaker) {
            self.navigationItem.titleView = nil;
            self.title = @"Reply";
            self.postingIn = self.replyingTo.attributes.postedIn;
            
            [self.navigationController.navigationBar setTitleTextAttributes:
                            @{NSForegroundColorAttributeName:[UIColor bonfirePrimaryColor],
                                         NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
        }
        else if (self.postingIn) {
            self.titleAvatar.camp = self.postingIn;
            [self updateTitleText:self.postingIn.attributes.title];
        }
        else if (self.postToProfile) {
            self.titleAvatar.user = [Session sharedInstance].currentUser;
            [self updateTitleText:@"My Profile"];
        }
        else {
            self.titleAvatar.camp = nil;
            [self updateTitleText:@"Select a Camp"];
        }
        
        [self updateTintColor];
        [self checkRequirements];
    }
    
    if (![self.textViewCell.textView isFirstResponder]) {
        [self.textViewCell.textView becomeFirstResponder];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.textViewCell.textView resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    [self.tableView registerClass:[ComposeTextViewCell class] forCellReuseIdentifier:composeTextViewCellReuseIdentifier];
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    
    [self.view addSubview:self.tableView];
}
- (void)setupTitleView {
    self.titleView = [[TappableView alloc] initWithFrame:CGRectMake(0, 0, 102, 40)];
    self.titleView.userInteractionEnabled = true;
    self.titleView.shrink = true;
    [self.titleView bk_whenTapped:^{
        [self openPrivacySelector:false];
    }];
    
    self.titleAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.titleView.frame.size.width / 2 - 12, 0, 24, 24)];
    [self.titleView.contentView addSubview:self.titleAvatar];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, 102, 13)];
    self.titleLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.titleView.contentView addSubview:self.titleLabel];

    UIImage *caretImage = [[UIImage imageNamed:@"navCaretIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleCaret = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.titleLabel.frame.origin.y + (self.titleLabel.frame.size.height / 2) - (caretImage.size.height / 2) + 1, caretImage.size.width, caretImage.size.height)];
    self.titleCaret.image = caretImage;
    self.titleCaret.tintColor = [UIColor bonfirePrimaryColor];
    self.titleCaret.contentMode = UIViewContentModeCenter;
    [self.titleView.contentView addSubview:self.titleCaret];
    
    self.navigationItem.titleView = self.titleView;
}
- (void)updateTitleText:(NSString *)newTitleText {
    if (!self.replyingTo || self.replyingToIcebreaker) {
        self.title = @"";
        self.titleLabel.text = newTitleText;
        
        self.titleCaret.hidden = self.replyingToIcebreaker;
        if (self.replyingToIcebreaker) {
            SetWidth(self.titleCaret, 0);
            self.titleView.userInteractionEnabled = false;
        }
        
        CGSize titleSize = [newTitleText boundingRectWithSize:CGSizeMake(self.view.frame.size.width - (86 * 2) - 11, self.titleLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.titleLabel.font} context:nil].size;
        self.titleLabel.frame = CGRectMake(0, self.titleLabel.frame.origin.y, titleSize.width, self.titleLabel.frame.size.height);
        self.titleCaret.frame = CGRectMake(self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width + 4, self.titleCaret.frame.origin.y, self.titleCaret.frame.size.width, self.titleCaret.frame.size.height);
        
        self.titleView.frame = CGRectMake(0, 0, self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width + (self.titleCaret.frame.size.width / 2), self.titleView.frame.size.height); // add the 4 at the end to visually balance the weight
        self.navigationItem.titleView = nil;
        self.navigationItem.titleView = self.titleView;
        self.titleAvatar.center = CGPointMake(self.titleView.frame.size.width / 2, self.titleAvatar.center.y);
    }
}
- (void)privacySelectionDidChange:(Camp * _Nullable)selection {
    self.postingIn = selection;
    
    if (!self.postingIn) {
        self.postToProfile = true;
        [self updateTitleText:@"My Profile"];
        self.titleAvatar.user = [[Session sharedInstance] currentUser];
        
        [self updatePlaceholder];
        [self updateToolbarAvailability];
        [self updateTintColor];
    }
}
- (void)privacySelectionDidSelectToPost:(Camp *)selection {
    self.postingIn = selection;
    
    if (!self.postingIn) {
        self.postToProfile = true;
    }
    
    [self postMessage];
    
    self.view.userInteractionEnabled = false;
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}
- (void)updateTintColor {
    Camp *camp;
    Identity *identity;
    if (self.replyingTo) {
        if (self.replyingTo.attributes.postedIn) {
            camp = self.replyingTo.attributes.postedIn;
        }
        else {
            identity = self.replyingTo.attributes.creator;
        }
    }
    else {
        if (self.postingIn) {
            camp = self.postingIn;
        }
        else  if (self.postToProfile) {
            identity = [Session sharedInstance].currentUser;
        }
    }
    
    if (camp) {
        self.view.tintColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
    }
    else if (identity) {
        self.view.tintColor = [UIColor fromHex:identity.attributes.color adjustForOptimalContrast:true];
    }
    else {
        self.view.tintColor = [UIColor bonfireSecondaryColor];
    }
    self.postButton.backgroundColor = self.view.tintColor;
    [self.postButton setTitleColor:[UIColor highContrastForegroundForBackground:self.postButton.backgroundColor] forState:UIControlStateNormal];
    
    if (self.textViewCell) {
        [self textViewDidChange:self.textViewCell.textView];
        self.textViewCell.textView.tintColor = self.view.tintColor;
        // hack to update caret color
        [self.textViewCell.textView resignFirstResponder];
        [self.textViewCell.textView becomeFirstResponder];
    }
    
    if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        SimpleNavigationController *simpleNavVC = (SimpleNavigationController *)self.navigationController;
        
        simpleNavVC.leftActionView.tintColor = self.view.tintColor;
        simpleNavVC.rightActionView.tintColor = self.view.tintColor;
        
        if ([simpleNavVC.leftActionView isKindOfClass:[UIButton class]]) {
            [(UIButton *)simpleNavVC.leftActionView setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        }
        if ([simpleNavVC.rightActionView isKindOfClass:[UIButton class]]) {
            [(UIButton *)simpleNavVC.rightActionView setTitleColor:self.view.tintColor forState:UIControlStateNormal];
            [(UIButton *)simpleNavVC.rightActionView setTitleColor:[UIColor bonfireDisabledColor] forState:UIControlStateDisabled];
        }
    }
        
    self.takePictureButton.tintColor = self.view.tintColor;
    self.choosePictureButton.tintColor = self.view.tintColor;
}

- (void)setupToolbar {
    CGFloat toolbarHeight = composeToolbarHeight + [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat newToolbarY = self.tableView.frame.size.height - self.currentKeyboardHeight - toolbarHeight;
    
    self.toolbarView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.toolbarView.frame = CGRectMake(0, newToolbarY, self.view.frame.size.width, toolbarHeight);
    self.toolbarView.backgroundColor = [[UIColor contentBackgroundColor] colorWithAlphaComponent:0.95];
    self.toolbarView.layer.masksToBounds = true;
    [self roundCornersOnView:self.toolbarView onTopLeft:true topRight:true bottomLeft:false bottomRight:false radius:10.f];
    [self.view addSubview:self.toolbarView];
    
    self.toolbarButtonsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, toolbarHeight)];
    [self.toolbarView.contentView addSubview:self.toolbarButtonsContainer];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.toolbarView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    //[self.toolbarView.contentView addSubview:lineSeparator];
    
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.takePictureButton setImage:[[UIImage imageNamed:@"composeToolbarTakePicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.takePictureButton.frame = CGRectMake(8, (composeToolbarHeight - 40) / 2, 40, 40);
    self.takePictureButton.contentMode = UIViewContentModeCenter;
    self.takePictureButton.tintColor = [UIColor bonfirePrimaryColor];
    self.takePictureButton.backgroundColor = [UIColor bonfireDetailColor];
    self.takePictureButton.layer.cornerRadius = self.takePictureButton.frame.size.height / 2;
    [self.takePictureButton bk_whenTapped:^{
        [self takePicture:self];
    }];
    [self.toolbarButtonsContainer addSubview:self.takePictureButton];
    
    self.choosePictureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.choosePictureButton setImage:[[UIImage imageNamed:@"composeToolbarChoosePicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.choosePictureButton.frame = CGRectMake(self.takePictureButton.frame.origin.x + self.takePictureButton.frame.size.width + 12, self.takePictureButton.frame.origin.y, 40, 40);
    self.choosePictureButton.contentMode = UIViewContentModeCenter;
    self.choosePictureButton.tintColor = [UIColor bonfirePrimaryColor];
    self.choosePictureButton.backgroundColor = [UIColor bonfireDetailColor];
    self.choosePictureButton.layer.cornerRadius = self.choosePictureButton.frame.size.height / 2;
    [self.choosePictureButton bk_whenTapped:^{
        [self chooseFromLibrary:nil];
    }];
    [self.toolbarButtonsContainer addSubview:self.choosePictureButton];
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.postButton.frame = CGRectMake(self.toolbarButtonsContainer.frame.size.width - 67 - 12, composeToolbarHeight / 2 - 36 / 2, 67, 36);
    self.postButton.layer.cornerRadius = self.postButton.frame.size.height / 2;
    self.postButton.layer.masksToBounds = true;
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightBold];
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:[UIColor contentBackgroundColor] forState:UIControlStateDisabled];
    [self.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    [self.postButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postButton.alpha = 0.8;
            self.postButton.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.postButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postButton.alpha = 1;
            self.postButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.toolbarButtonsContainer addSubview:self.postButton];
    
    self.characterCountdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.postButton.frame.origin.x - 50 - 16, 0, 50, composeToolbarHeight)];
    self.characterCountdownLabel.textAlignment = NSTextAlignmentRight;
    self.characterCountdownLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightMedium];
    self.characterCountdownLabel.textColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.75];
    self.characterCountdownLabel.text = [NSString stringWithFormat:@"%ld", maxLength];
    [self.toolbarButtonsContainer addSubview:self.characterCountdownLabel];
    
    self.autoCompleteTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.toolbarView.frame.size.width, ceilf(self.tableView.frame.size.height / 4)) style:UITableViewStyleGrouped];
    self.autoCompleteTableView.delegate = self;
    self.autoCompleteTableView.dataSource = self;
    self.autoCompleteTableView.backgroundColor = [UIColor clearColor];
    self.autoCompleteTableView.transform = CGAffineTransformMakeTranslation(0, -self.toolbarButtonsContainer.frame.size.height);
    self.autoCompleteTableView.alpha = 0;
    self.autoCompleteTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.autoCompleteTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    [self.autoCompleteTableView registerClass:[SearchResultCell class] forCellReuseIdentifier:searchResultCellIdentifier];
    
    [self.toolbarView.contentView addSubview:self.autoCompleteTableView];
    
    [self updateToolbarAvailability];
}

- (UIView *)roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(float)radius {

    if (tl || tr || bl || br) {
        UIRectCorner corner = 0;
        if (tl) {corner = corner | UIRectCornerTopLeft;}
        if (tr) {corner = corner | UIRectCornerTopRight;}
        if (bl) {corner = corner | UIRectCornerBottomLeft;}
        if (br) {corner = corner | UIRectCornerBottomRight;}

        UIView *roundedView = view;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:roundedView.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = roundedView.bounds;
        maskLayer.path = maskPath.CGPath;
        roundedView.layer.mask = maskLayer;
        return roundedView;
    }
    return view;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self checkRequirements];
    
    self.activeAttributedString = textView.attributedText;
    
    // update countdown
    NSInteger charactersLeft = [self charactersRemainingWithStirng:self.activeAttributedString.string];
    self.characterCountdownLabel.text = [NSString stringWithFormat:@"%ld", charactersLeft];
    
    if (charactersLeft <= 20) {
        self.characterCountdownLabel.textColor = [UIColor bonfireRed];
    }
    else {
        self.characterCountdownLabel.textColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.75];
    }
    
    /* MAKE YOUR CHANGES TO THE FIELD CONTENTS AS NEEDED HERE */
    CGFloat textViewHeightBefore = textView.frame.size.height;
    [self detectEntities];
    CGFloat textViewHeightAfter = textView.frame.size.height;
    
    // update height of the cell
    [self.textViewCell resizeTextView];
    
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    
    if (diff(textViewHeightBefore, textViewHeightAfter)) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:false];
        [self scrollViewDidScroll:self.tableView];
    }
}
- (NSInteger)charactersRemainingWithStirng:(NSString *)string {
    NSInteger length = string.length;
    
    for (NSValue *value in [string rangesForLinkMatches]) {
        NSRange range = [value rangeValue];
        
        // links take up, at max, 25 decoded characters
        if (range.length > 25) {
            length -= (range.length - 25);
        }
    }
    
    return maxLength - length;
}

- (void)detectEntities {
    NSRange s_range = self.textViewCell.textView.selectedRange;
    NSUInteger s_loc = s_range.location;
    
    BOOL insideUsername = false;
    BOOL insideCampTag = false;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.textViewCell.textView.text attributes:@{NSFontAttributeName: self.textViewCell.textView.font, NSForegroundColorAttributeName:[UIColor colorNamed:@"FullContrastColor"]}];
    NSArray *usernameRanges = [self.textViewCell.textView.text rangesForUsernameMatches];
    NSArray *campTagRanges = [self.textViewCell.textView.text rangesForCampTagMatches];
    NSArray *urlRanges = [self.textViewCell.textView.text rangesForLinkMatches];
    if (usernameRanges.count > 0) {
        for (NSValue *value in usernameRanges) {
            NSRange range = [value rangeValue];
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.view.tintColor range:range];
            
            // NSLog(@"USERNAME. (%lu > %lu && %lu <= %lu + %lu)", s_loc, range.location, s_loc, range.location, range.length);
            if (s_loc > range.location && s_loc <= range.location + range.length) {
                insideUsername = true;
                self.activeTagRange = range;
                break;
            }
        }
    }
    if (campTagRanges.count > 0) {
        NSLog(@"campTagRanges: %@", campTagRanges);
        for (NSValue *value in campTagRanges) {
            NSRange range = [value rangeValue];
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.view.tintColor range:range];
            
            // NSLog(@"CAMP TAG. (%lu > %lu && %lu <= %lu + %lu)", s_loc, range.location, s_loc, range.location, range.length);
            if (s_loc > range.location && s_loc <= range.location + range.length) {
                insideCampTag = true;
                self.activeTagRange = range;
                break;
            }
        }
    }
    
    if (urlRanges.count > 0) {
        NSLog(@"urlRanges: %@", urlRanges);
        for (NSValue *value in urlRanges) {
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.view.tintColor range:[value rangeValue]];
        }
    }
    
    NSInteger remainingCharacters = [self charactersRemainingWithStirng:self.textViewCell.textView.text];
    if (remainingCharacters < 0) {
        NSInteger length = labs(remainingCharacters);
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireRed] range:NSMakeRange(MIN(self.textViewCell.textView.text.length - length, self.textViewCell.textView.text.length), length)];
        [attributedText addAttribute:NSBackgroundColorAttributeName value:[[UIColor bonfireRed] colorWithAlphaComponent:0.1] range:NSMakeRange(MIN(self.textViewCell.textView.text.length -  length, self.textViewCell.textView.text.length), length)];
    }
    
    self.activeAttributedString = attributedText;
    self.textViewCell.textView.attributedText = self.activeAttributedString;
    
    // environment issue
    // -> set selected range using the range before updating the attributed text
    [self.textViewCell.textView setSelectedRange:s_range];
    
    if (insideUsername || insideCampTag) {
        [self getAutoCompleteResults:[self.textViewCell.textView.text substringWithRange:self.activeTagRange]];
    }
    else {
        self.activeTagRange = NSMakeRange(NSNotFound, 0);
        [self hideAutoCompleteView];
    }
}
- (void)checkRequirements {
    if (!self.textViewCell) return;
    
    if ((![self textViewIsEmpty] && [self charactersRemainingWithStirng:self.textViewCell.textView.text] >= 0) || self.textViewCell.media.objects.count > 0 || self.quotedAttachmentView != nil) {
        // enable share button
        ((SimpleNavigationController *)self.navigationController).rightActionView.userInteractionEnabled = true;
        ((SimpleNavigationController *)self.navigationController).rightActionView.alpha = 1;
        
        if (![self.postButton isEnabled]) {
            self.postButton.alpha = 1;
            self.postButton.enabled = true;
            
            self.postButton.backgroundColor = self.view.tintColor;
            [self.postButton setTitleColor:[UIColor highContrastForegroundForBackground:self.postButton.backgroundColor] forState:UIControlStateNormal];
            
            self.postButton.transform = CGAffineTransformMakeScale(1, 1);
            self.postButton.alpha = 1;
        }
    }
    else {
        // disable share button
        ((SimpleNavigationController *)self.navigationController).rightActionView.userInteractionEnabled = false;
        ((SimpleNavigationController *)self.navigationController).rightActionView.alpha = 0.5;
        self.postButton.backgroundColor = [UIColor bonfireSecondaryColor];
        self.postButton.alpha = 0.2;
        self.postButton.enabled = false;
    }
}
- (BOOL)textViewIsEmpty {
    NSString *spacelessString = [self.textViewCell.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return spacelessString.length == 0;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *proposedNewString = [[textView text] stringByReplacingCharactersInRange:range withString:text];
    BOOL shouldChange = [self charactersRemainingWithStirng:proposedNewString] >= 0;
    
    if (!shouldChange) {
        if ([self charactersRemainingWithStirng:self.textViewCell.textView.text] >= 0) {
            // only do this if it *just* went over
            [HapticHelper generateFeedback:FeedbackType_Notification_Warning];
//            [UIView animateWithDuration:0.2f delay:0 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
//                self.textViewCell.textView.alpha = 0.5;
//            } completion:^(BOOL finished) {
//                [UIView animateWithDuration:0.15f delay:0 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
//                    self.textViewCell.textView.alpha = 1;
//                } completion:nil];
//            }];
        }
    }
    else if (_textViewCell.textView.alpha != 1) {
//        [_textViewCell.textView.layer removeAllAnimations];
//        _textViewCell.textView.alpha = 1;
    }
    
    return true;
}
- (void)updateContentSize {
    /*
    // start from the bottom most views
    UIView *bottomMostView;
    if (!self.mediaScrollView.isHidden) {
        bottomMostView = self.mediaScrollView;
    }
    else if (!self.textView.isHidden) {
        bottomMostView = self.textView;
    }
    
    if (bottomMostView) {
        CGFloat bottomInset = 24;
        self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, self.mediaScrollView.frame.origin.y + self.mediaScrollView.frame.size.height + bottomInset);
    }
     */
}
- (void)updatePlaceholder {
    if (!self.textViewCell) return;
    
    NSString *publicPostPlaceholder = @"Share with everyone...";
    
    defaultPlaceholder = @"";
    if (self.replyingTo != nil) {
        if ([self.replyingTo.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            defaultPlaceholder = @"Add a reply...";
        }
        else {
            NSString *creatorIdentifier = self.replyingTo.attributes.creator.attributes.identifier;
            defaultPlaceholder = creatorIdentifier ? [NSString stringWithFormat:@"Reply to @%@...", creatorIdentifier] : @"Add a reply...";
        }
    }
    else if (self.postingIn) {
        if (self.postingIn.attributes.title) {
            defaultPlaceholder = [NSString stringWithFormat:@"Share in %@...", self.postingIn.attributes.title];
        }
        else {
            defaultPlaceholder = @"Share with the Camp...";
        }
    }
    else if (self.postToProfile) {
        defaultPlaceholder = publicPostPlaceholder;
    }
    else {
        defaultPlaceholder = @"Share something...";
    }
    mediaPlaceholder = @"Add caption or Share";
    
    if (self.textViewCell.media.objects.count > 0) {
        self.textViewCell.textView.placeholder = mediaPlaceholder;
    }
    else {
        self.textViewCell.textView.placeholder = defaultPlaceholder;
    }
}
- (NSString *)stringByDeletingWordsFromString:(NSString *)string
                                        toFit:(CGRect)rect
                                    withInset:(CGFloat)inset
                                    usingFont:(UIFont *)font {
    NSString *result = [string copy];
    CGSize maxSize = CGSizeMake(rect.size.width  - (inset * 2), FLT_MAX);
    if (!font) font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGRect boundingRect = [result boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font, } context:nil];
    CGSize size = boundingRect.size;
    NSRange range;
    
    if (rect.size.height < size.height) {
        while (rect.size.height < size.height) {
            
            range = [result rangeOfString:@" "
                                  options:NSBackwardsSearch];
            
            if (range.location != NSNotFound && range.location > 0 ) {
                result = [result substringToIndex:range.location];
            } else {
                result = [result substringToIndex:result.length - 1];
            }
            
            if (!font) font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            CGRect boundingRect = [result boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font, } context:nil];
            size = boundingRect.size;
        }
    }
    if (result.length < string.length) {
        result = [result stringByAppendingString:@"..."];
    }
    
    return result;
}

// adjust the y position of the toolbar when keyboard frame changes
- (void)keyboardWillChangeFrame:(NSNotification *)notification {    
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat newToolbarY = self.tableView.frame.size.height - self.currentKeyboardHeight - self.toolbarView.frame.size.height + bottomPadding;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, newToolbarY, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
        
        CGFloat contentInset = (self.tableView.frame.size.height - self.toolbarView.frame.origin.y) - bottomPadding;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, contentInset, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, contentInset, 0);
    } completion:nil];
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    NSLog(@"keyboardWillDismiss");
    _currentKeyboardHeight = 0;
    
    CGFloat newToolbarY = self.tableView.frame.size.height - self.currentKeyboardHeight - self.toolbarView.frame.size.height;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, newToolbarY, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.toolbarView.frame.size.height, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.toolbarView.frame.size.height, 0);
    } completion:nil];
}

- (void)takePicture:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        [self openCamera];
    } else if(authStatus == AVAuthorizationStatusDenied ||
              authStatus == AVAuthorizationStatusRestricted) {
        // denied
        [self showNoCameraAccess];
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted){
                NSLog(@"Granted access to %@", mediaType);
                [self openCamera];
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
                [self showNoCameraAccess];
            }
        }];
    }
}
- (void)openCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Launcher topMostViewController] presentViewController:picker animated:false completion:nil];
    });
}
- (void)showNoCameraAccess {
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your camera" message:@"To allow Bonfire to access your camera, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:openSettingsAction];

    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:closeAction];
    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
}
- (void)chooseFromLibrary:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"PHAuthorizationStatusAuthorized");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = self;
                    picker.allowsEditing = NO;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                NSLog(@"PHAuthorizationStatusDenied");
                // confirm action
                dispatch_async(dispatch_get_main_queue(), ^{
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

                    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
                });

                break;
            }
            case PHAuthorizationStatusRestricted: {
                NSLog(@"PHAuthorizationStatusRestricted");
                break;
            }
        }
    }];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    // determine file type
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    if (asset) {
        [self.textViewCell.media addAsset:asset];
    }
    else {
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self.textViewCell.media addImage:chosenImage];
    }
    
    [self mediaDidChange];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self.textViewCell.textView becomeFirstResponder];
}

- (void)mediaDidChange {
    [self checkRequirements];
    [self updateToolbarAvailability];
    [self updatePlaceholder];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)updateToolbarAvailability {
    if (!self.textViewCell) return;
    
    self.takePictureButton.enabled = [self.textViewCell.media canAddMedia];
    self.choosePictureButton.enabled = [self.textViewCell.media canAddMedia];
    
    BOOL mediaAllowed = true; // default: assume it's allowed
    if (self.replyingTo || self.postingIn)  {
        NSArray *mediaTypesAllowed = @[];
        
        if (self.replyingTo) {
            mediaTypesAllowed = self.replyingTo.attributes.context.post.permissions.reply;
        }
        else if (self.postingIn) {
            mediaTypesAllowed = self.postingIn.attributes.context.camp.permissions.post;
        }
        
        mediaAllowed = !(mediaTypesAllowed.count == 0 || (mediaTypesAllowed.count == 1 && [mediaTypesAllowed containsObject:BFMediaTypeText]));
    }
    
    NSLog(@"media allowed ? %@", mediaAllowed ? @"YES" : @"NO");
    
    self.takePictureButton.hidden = !mediaAllowed;
    self.choosePictureButton.hidden = !mediaAllowed;
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.takePictureButton.alpha = (self.takePictureButton.enabled ? 1 : 0.25);
        self.choosePictureButton.alpha = (self.choosePictureButton.enabled ? 1 : 0.25);
    } completion:nil];
}

- (void)postMessage {
    if (!self.textViewCell) return;
    
    if (!self.replyingTo && !self.postToProfile && !self.postingIn) {
        [self openPrivacySelector:true];
        return;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.textViewCell.textView.text;
    if (message.length > 0) {
        [params setObject:[Post trimString:message] forKey:@"message"];
    }
    if (self.textViewCell.media.objects.count > 0) {
        [params setObject:self.textViewCell.media forKey:@"media"];
    }
    if (self.quotedObject) {
        NSDictionary *attachment;
        
        if ([self.quotedObject isKindOfClass:[Post class]]) {
            attachment = @{@"post_id": ((Post *)self.quotedObject).identifier};
        }
        else if ([self.quotedObject isKindOfClass:[Identity class]]) {
            attachment = @{@"user_id": ((Identity *)self.quotedObject).identifier};
        }
        else if ([self.quotedObject isKindOfClass:[Camp class]]) {
            attachment = @{@"camp_id": ((Camp *)self.quotedObject).identifier};
        }
        else if ([self.quotedObject isKindOfClass:[BFLink class]]) {
            attachment = @{@"link": ((BFLink *)self.quotedObject).attributes.actionUrl};
        }
        
        if (attachment) {
            [params setObject:attachment forKey:@"attachments"];
        }
    }
    
    if ([params allKeys].count > 0) {
        NSLog(@"create params:: %@", params);
        // meets min. requirements
        [BFAPI createPost:params postingIn:self.postingIn replyingTo:self.replyingTo attachments:nil];
        
        if (self.navigationController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                if (self.replyingToIcebreaker) {
                    [Launcher openPost:self.replyingTo withKeyboard:nil];
                }
            }];
        }
    }
}

- (void)openPrivacySelector:(BOOL)postOnSelection {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.currentSelection = self.postingIn;
    sitvc.delegate = self;
    sitvc.shareOnProfile = self.postToProfile;
    sitvc.postOnSelection = postOnSelection;
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:sitvc];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:simpleNav animated:YES completion:nil];
}

- (void)getAutoCompleteResults:(NSString *)tag {
    NSString *q = tag;
    NSLog(@"getAutoCompleteResults(%@)", q);
    BOOL isUser = [q hasPrefix:@"@"];
    BOOL isCamp = [q hasPrefix:@"#"];
    if (!isUser && !isCamp) return;
    
    if (isUser) {
        q = [q stringByReplacingOccurrencesOfString:@"@" withString:@""];
    }
    else if (isCamp) {
        q = [q stringByReplacingOccurrencesOfString:@"#" withString:@""];
    }
    
    NSString *url = @"search";
    
    if (isUser) {
        url = [url stringByAppendingString:@"/users"];
    }
    else if (isCamp) {
        url = [url stringByAppendingString:@"/camps"];
    }
    
    [[HAWebService authenticatedManager] GET:url parameters:@{@"q": q} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *currentSearchTerm = self.activeTagRange.location != NSNotFound ? [self.textViewCell.textView.text substringWithRange:self.activeTagRange] : @"";
        if ([tag isEqualToString:currentSearchTerm]) {
            NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                    
            if (isUser) {
                self.autoCompleteResults = [[NSMutableArray alloc] initWithArray:responseData[@"results"][@"users"]];
            }
            else if (isCamp) {
                self.autoCompleteResults = [[NSMutableArray alloc] initWithArray:responseData[@"results"][@"camps"]];
            }
            
            if (self.autoCompleteResults.count > 0 && self.activeTagRange.location != NSNotFound && self.autoCompleteTableView.alpha != 1) {
                [self showAutoCompleteView];
            }
            else if (self.autoCompleteResults.count == 0 && self.autoCompleteTableView.alpha != 0) {
                [self hideAutoCompleteView];
            }
            
            [self.autoCompleteTableView reloadData];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        [self hideAutoCompleteView];
    }];
}

- (void)setReplyingTo:(Post *)replyingTo {
    if (replyingTo != _replyingTo) {
        _replyingTo = replyingTo;
        
        [self updatePlaceholder];
        [self updateToolbarAvailability];
        [self updateTintColor];
    }
}
- (void)setPostingIn:(Camp *)postingIn {
    if (postingIn != _postingIn) {
        _postingIn = postingIn;
        
        if (self.postingIn) {
            [self updateTitleText:self.postingIn.attributes.title];
            self.titleAvatar.camp = self.postingIn;
        }
        
        [self updatePlaceholder];
        [self updateToolbarAvailability];
        [self updateTintColor];
    }
}
- (void)setQuotedObject:(id)quotedObject {
    if (quotedObject != _quotedObject) {
        // validate quoted object is currently supported
        NSArray *supportedTypes = @[[Post class], [User class], [Bot class], [Camp class], [BFLink class]];
        if ([supportedTypes containsObject:[quotedObject class]]) {
            _quotedObject = quotedObject;
            
            if ([quotedObject isKindOfClass:[Post class]]) {
                BFPostAttachmentView *attachmentView = [[BFPostAttachmentView alloc] init];
                attachmentView.post = quotedObject;
                self.quotedAttachmentView = attachmentView;
            }
            else if ([quotedObject isKindOfClass:[User class]]) {
                BFIdentityAttachmentView *attachmentView = [[BFIdentityAttachmentView alloc] init];
                attachmentView.identity = quotedObject;
                self.quotedAttachmentView = attachmentView;
            }
            else if ([quotedObject isKindOfClass:[Bot class]]) {
                BFBotAttachmentView *attachmentView = [[BFBotAttachmentView alloc] init];
                attachmentView.bot = quotedObject;
                self.quotedAttachmentView = attachmentView;
            }
            else if ([quotedObject isKindOfClass:[Camp class]]) {
                BFCampAttachmentView *attachmentView = [[BFCampAttachmentView alloc] init];
                attachmentView.camp = quotedObject;
                self.quotedAttachmentView = attachmentView;
            }
            else if ([quotedObject isKindOfClass:[BFLink class]]) {
                if ([(BFLink *)quotedObject isSmartLink]) {
                    BFSmartLinkAttachmentView *attachmentView = [[BFSmartLinkAttachmentView alloc] init];
                    attachmentView.shareLinkButton.hidden = true;
                    attachmentView.shareLinkButtonSeparator.hidden = true;
                    attachmentView.link = quotedObject;
                    self.quotedAttachmentView = attachmentView;
                }
                else  {
                    BFLinkAttachmentView *attachmentView = [[BFLinkAttachmentView alloc] init];
                    attachmentView.link = quotedObject;
                    self.quotedAttachmentView = attachmentView;
                }
            }
        }
        else {
            self.quotedAttachmentView = nil;
        }
        
        [self.tableView reloadData];
    }
}

//- (void)updateContentInsets {
//    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
//
//    CGFloat newComposeInputViewY = self.view.frame.size.height;
//
//    CGFloat parentPostOffset = 0;
//
//    if (self.replyingTo) {
//        BOOL requiresParentPostPadding = true;
//
//        CGFloat textViewHeight = [self.textViewCell height];
//        CGFloat replyHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//
//        parentPostOffset = (self.composeInputView.frame.origin.y - textViewHeight - replyHeight - self.tableView.adjustedContentInset.top);
//        parentPostOffset = MAX(0, parentPostOffset);
//    }
//
//    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY + parentPostOffset, 0);
//    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.view.frame.size.height - newComposeInputViewY, 0);
//}

- (void)showAutoCompleteView {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat toolbarHeight = self.autoCompleteTableView.frame.size.height;
    CGFloat newToolbarY = self.tableView.frame.size.height - self.currentKeyboardHeight - toolbarHeight;
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, newToolbarY, self.toolbarView.frame.size.width, toolbarHeight);
        self.toolbarView.contentView.frame = self.toolbarView.bounds;
        [self roundCornersOnView:self.toolbarView onTopLeft:true topRight:true bottomLeft:false bottomRight:false radius:10.f];
        
        CGFloat contentInset = (self.tableView.frame.size.height - self.toolbarView.frame.origin.y) - bottomPadding;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, contentInset, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, contentInset, 0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:true];
        });
        
        self.toolbarButtonsContainer.transform = CGAffineTransformMakeScale(0.95, 0.95);
        self.toolbarButtonsContainer.alpha = 0;
        
        self.autoCompleteTableView.transform = CGAffineTransformIdentity;
        self.autoCompleteTableView.alpha = 1;
    } completion:nil];
}
- (void)hideAutoCompleteView {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat toolbarHeight = composeToolbarHeight + bottomPadding;
    CGFloat newToolbarY = self.view.frame.size.height - self.currentKeyboardHeight - toolbarHeight + bottomPadding;
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, newToolbarY, self.toolbarView.frame.size.width, toolbarHeight);
        self.toolbarView.contentView.frame = self.toolbarView.bounds;
        [self roundCornersOnView:self.toolbarView onTopLeft:true topRight:true bottomLeft:false bottomRight:false radius:10.f];
        
        CGFloat contentInset = (self.tableView.frame.size.height - self.toolbarView.frame.origin.y) - bottomPadding;
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, contentInset, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, contentInset, 0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:true];
        });
        
        self.toolbarButtonsContainer.transform = CGAffineTransformIdentity;
        self.toolbarButtonsContainer.alpha = 1;
        
        self.autoCompleteTableView.transform = CGAffineTransformMakeTranslation(0, composeToolbarHeight);
        self.autoCompleteTableView.alpha = 0;
    } completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0 && indexPath.row == 0 && self.replyingTo) {
            StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
            }
            
            cell.showContext = false;
            cell.showPostedIn = true;
            cell.hideActions = true;
            
            cell.post = self.replyingTo;
            
            cell.lineSeparator.hidden = true;
            cell.selectable = false;
            cell.moreButton.hidden = true;
            cell.bottomLine.hidden = false;
            
            return cell;
        }
        else if (indexPath.section == 1 && indexPath.row == 0) {
            if (self.textViewCell) return self.textViewCell;
            
            ComposeTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:composeTextViewCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ComposeTextViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:composeTextViewCellReuseIdentifier];
            }
            
            cell.tintColor = self.view.tintColor;
            
            cell.lineSeparator.hidden = true;
            cell.topLine.hidden = !self.replyingTo;
                        
            if (cell.tag != 1) {
                cell.tag = 1;
                [cell.textView becomeFirstResponder];
                cell.textView.delegate = self;
                cell.textView.tintColor = cell.tintColor;
                cell.textView.text = _prefillMessage;
                cell.delegate = self;
                
                if (self.media && self.media.count > 0) {
                    for (NSObject *object in self.media) {
                        if ([object isKindOfClass:[PHAsset class]]) {
                            [cell.media addAsset:(PHAsset *)object];
                        }
                        else if ([object isKindOfClass:[UIImage class]]) {
                            [cell.media addImage:(UIImage *)object];
                        }
                    }
                }
            }
            else {
                cell.textView.attributedText = self.activeAttributedString;
            }
            
            cell.quotedAttachmentView = self.quotedAttachmentView;
            
            if (!self.textViewCell) {
                self.textViewCell = cell;
                [self checkRequirements];
            }
            [self updatePlaceholder];
            [self detectEntities];
            
            return cell;
        }
    }
    else if (tableView == self.autoCompleteTableView) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:searchResultCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:searchResultCellIdentifier];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        // create a line separator
        if (![cell.contentView viewWithTag:2]) {
            UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
            lineSeparator.tag = 2;
            lineSeparator.backgroundColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.06];
            [cell.contentView addSubview:lineSeparator];
        }
        
        // -- Type --
        int type = 0;
        
        NSDictionary *json;
        // mix of types
        if (indexPath.section == 0) {
            json = self.autoCompleteResults[indexPath.row];
        }
        else {
            json = self.autoCompleteResults[indexPath.row];
        }
        if (json[@"type"]) {
            if ([json[@"type"] isEqualToString:@"camp"]) {
                type = 1;
            }
            else if ([json[@"type"] isEqualToString:@"user"]) {
                type = 2;
            }
        }
        
        if (type != 0) {
            if (type == 1) {
                NSError *error;
                Camp *camp = [[Camp alloc] initWithDictionary:json error:&error];
                cell.camp = camp;
            }
            else {
                //NSError *error;
                User *user = [[User alloc] initWithDictionary:self.autoCompleteResults[indexPath.row] error:nil];
                cell.user = user;
            }
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0 && indexPath.row == 0 && self.replyingTo) {
            float height = [StreamPostCell heightForPost:self.replyingTo showContext:false showActions:false minimizeLinks:false] + 8; // removed action bar (32pt + 8pt)
            float minHeight = 48 + (postContentOffset.top + postContentOffset.bottom); // 48 = avatar height
            if (height < minHeight) {
                height = minHeight;
            }
            
            return height;
        }
        else if (indexPath.section == 1 && indexPath.row == 0) {
            if (!self.textViewCell) return CGFLOAT_MIN;
            
            return [self.textViewCell height];
        }
    }
    else if (tableView == self.autoCompleteTableView) {
        return 68;
    }
    
    return 0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) return 2;
    if (tableView == self.autoCompleteTableView) return 1;
    
    return 0;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == 0 && self.replyingTo) {
            return 1;
        }
        else if (section == 1) {
            return 1;
        }
    }
    else if (tableView == self.autoCompleteTableView) {
        return self.autoCompleteResults.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && section == 0) {
        if (self.replyingToIcebreaker) {
            return 100;
        }
//        else if (self.replyingTo) {
//            return 52;
//        }
    }
    return CGFLOAT_MIN;
}
- (UIView * _Nullable)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView && section == 0) {
        if (self.replyingToIcebreaker) {
            UIView *header = [UIView new];
            header.frame = CGRectMake(0, 0, self.view.frame.size.width, 104);
            
            UIView *replyingToView = [[UIView alloc] initWithFrame:CGRectMake(12, 8, header.frame.size.width - 12 - 12, header.frame.size.height - 12)];
            replyingToView.backgroundColor = [UIColor bonfireDetailColor];
            replyingToView.layer.cornerRadius = 8.f;
            replyingToView.layer.masksToBounds = true;
            [header addSubview:replyingToView];
            
            UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, replyingToView.frame.size.width - 24, 19)];
            welcomeLabel.textColor = [UIColor bonfirePrimaryColor];
            welcomeLabel.text = @"Welcome to the Camp! 👋";
            welcomeLabel.textAlignment = NSTextAlignmentCenter;
            welcomeLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
            [replyingToView addSubview:welcomeLabel];
            
            UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 40, replyingToView.frame.size.width - 24, 34)];
            infoLabel.textColor = [UIColor bonfireSecondaryColor];
            infoLabel.text = @"Answer the Camp Icebreaker to help\nothers get to know you better";
            infoLabel.textAlignment = NSTextAlignmentCenter;
            infoLabel.numberOfLines = 0;
            infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
            infoLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
            [replyingToView addSubview:infoLabel];
            
            return header;
        }
//        else if (self.replyingTo) {
//            UIView *header = [UIView new];
//            header.frame = CGRectMake(0, 0, self.view.frame.size.width, 52);
//
//            UIView *replyingToView = [[UIView alloc] initWithFrame:CGRectMake(12, 8, header.frame.size.width - 12 - 12, header.frame.size.height - 12)];
//            replyingToView.backgroundColor = [UIColor bonfireDetailColor];
//            replyingToView.layer.cornerRadius = 8.f;
//            replyingToView.layer.masksToBounds = true;
//            [header addSubview:replyingToView];
//
//            UIImage *replyIconImage = [[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//            UIImageView *replyIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, replyingToView.frame.size.height / 2 - 7.5, replyIconImage.size.width, 15)];
//            replyIcon.image = replyIconImage;
//            replyIcon.tintColor = [UIColor bonfirePrimaryColor];
//            replyIcon.contentMode = UIViewContentModeScaleAspectFill;
//            [replyingToView addSubview:replyIcon];
//
//            CGFloat replyingToLabelX = replyIcon.frame.origin.x + replyIcon.frame.size.width + 8;
//            UILabel *replyingToLabel = [[UILabel alloc] initWithFrame:CGRectMake(replyingToLabelX, 0, replyingToView.frame.size.width - replyingToLabelX - 12, replyingToView.frame.size.height)];
//            replyingToLabel.textColor = [UIColor bonfirePrimaryColor];
//            if ([self.replyingTo.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
//                replyingToLabel.text = [NSString stringWithFormat:@"Replying to yourself"];
//            }
//            else {
//                replyingToLabel.text = [NSString stringWithFormat:@"Replying to @%@", self.replyingTo.attributes.creator.attributes.identifier];
//            }
//            replyingToLabel.textAlignment = NSTextAlignmentLeft;
//            replyingToLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
//            replyingToLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
//            [replyingToView addSubview:replyingToLabel];
//
//            UIView *lineSeparator_t = [[UIView alloc] initWithFrame:CGRectMake(0, 0, replyingToView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//            lineSeparator_t.backgroundColor = [UIColor tableViewSeparatorColor];
//            //[replyingToView addSubview:lineSeparator_t];
//
//            UIView *lineSeparator_b = [[UIView alloc] initWithFrame:CGRectMake(0, replyingToView.frame.size.height - (1 / [UIScreen mainScreen].scale), replyingToView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//            lineSeparator_b.backgroundColor = [UIColor tableViewSeparatorColor];
//            //[replyingToView addSubview:lineSeparator_b];
//
//            return header;
//        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView * _Nullable)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil; 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.autoCompleteTableView) {
        if (self.textViewCell && self.textViewCell.textView && self.activeTagRange.location != NSNotFound) {
            SearchResultCell *cell = [self.autoCompleteTableView cellForRowAtIndexPath:indexPath];
            if (self.autoCompleteResults.count > indexPath.row) {
                BOOL changes = false;
                NSString *finalString = self.textViewCell.textView.text;
                if (cell.user) {
                    NSString *usernameSelected = cell.user.attributes.identifier;
                    
                    if (usernameSelected.length > 0) {
                        finalString = [self.textViewCell.textView.text stringByReplacingCharactersInRange:self.activeTagRange withString:[NSString stringWithFormat:@"@%@ ", usernameSelected]];
                        changes = true;
                    }
                }
                else if (cell.camp) {
                    NSString *campTagSelected = cell.camp.attributes.identifier;
                    
                    if (campTagSelected.length > 0) {
                        finalString = [self.textViewCell.textView.text stringByReplacingCharactersInRange:self.activeTagRange withString:[NSString stringWithFormat:@"#%@ ", campTagSelected]];
                        changes = true;
                    }
                }
                
                if (changes) {
                    // set it twice to avoid autocorrection from overriding our changes
                    self.textViewCell.textView.text = finalString;
                    self.textViewCell.textView.text = finalString;
                    
                    [self textViewDidChange:self.textViewCell.textView];
                    [HapticHelper generateFeedback:FeedbackType_Selection];
                }
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController childTableViewDidScroll:self.tableView];
        }
        else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            [(ComplexNavigationController *)self.navigationController childTableViewDidScroll:self.tableView];
        }
    }
}

@end
