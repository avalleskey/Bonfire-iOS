//
//  ComposeInputView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/25/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ComposeInputView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView+WebCache.h>
#import <Photos/Photos.h>

#import "PostViewController.h"
#import "CampViewController.h"
#import "ProfileViewController.h"
#import <HapticHelper/HapticHelper.h>
#import "NSString+Validation.h"
#import "SearchResultCell.h"
#import "BFAlertController.h"
#import "NSString+Validation.h"
#import "BFCameraViewController.h"

#define headerHeight 58
#define postButtonShrinkScale 0.9

#define COMPOSE_TEXT_VIEW_INSET UIEdgeInsetsMake(12, 12, 12, 12)
#define COMPOSE_TEXT_VIEW_INSET_WITH_IMAGE UIEdgeInsetsMake(COMPOSE_TEXT_VIEW_INSET.top, 49, COMPOSE_TEXT_VIEW_INSET.bottom, 98)
#define COMPOSE_TEXT_VIEW_INSET_WITH_GIF UIEdgeInsetsMake(COMPOSE_TEXT_VIEW_INSET.top, COMPOSE_TEXT_VIEW_INSET_WITH_IMAGE.left, COMPOSE_TEXT_VIEW_INSET.bottom, 136)

@interface ComposeInputView () <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, BFCameraViewControllerDelegate, GIFCollectionViewControllerDelegate> {
    NSInteger maxLength;
    CGFloat textViewMaxHeight;
}

@property (nonatomic, strong) NSMutableArray *tagSuggestions;

@property (nonatomic) NSAttributedString *activeAttributedString;
@property (nonatomic) NSRange activeTagRange;
@property (nonatomic) NSMutableArray *autoCompleteResults;

@end

@implementation ComposeInputView {
    NSString *mediaPlaceholder;
}

static NSString * const searchResultCellIdentifier = @"SearchResultCell";
static NSString * const blankCellIdentifier = @"BlankCell";

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.post = [[Post alloc] init];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    self.frame = CGRectMake(0, self.frame.origin.y, screenWidth, self.frame.size.height);
    
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
    [self addSubview:self.contentView];
    
    self.layer.masksToBounds = false;
    
    // text view
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(6, 4, self.frame.size.width - 6 * 2, 44)];
    _textView.delegate = self;
    _textView.editable = true;
    _textView.scrollEnabled = true;
    if (@available(iOS 11.1, *)) {
        _textView.verticalScrollIndicatorInsets = UIEdgeInsetsMake(6, 0, 52, 6);
    }
    _textView.showsHorizontalScrollIndicator = false;
    _textView.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightRegular];
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.contentInset = UIEdgeInsetsZero;
    _textView.textContainerInset = UIEdgeInsetsMake(11, 12, 11, 44);
    _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _textView.textColor = [UIColor bonfirePrimaryColor];
    _textView.layer.cornerRadius = 22.f;
    _textView.backgroundColor = [UIColor colorNamed:@"ComposeTextViewBackgroundColor"];
    _textView.layer.borderWidth = HALF_PIXEL;
    _textView.placeholder = self.defaultPlaceholder;
    _textView.placeholderColor = [UIColor bonfireSecondaryColor];
//    _textView.keyboardAppearance = UIKeyboardAppearanceLight;
    _textView.keyboardType = UIKeyboardTypeTwitter;
    _textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    [self.contentView addSubview:_textView];
    textViewMaxHeight = roundf([UIScreen mainScreen].bounds.size.height * 0.3);
    
    _mediaScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 8, _textView.frame.size.width, 140 - 16)];
    _mediaScrollView.hidden = true;
    _mediaScrollView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    _mediaScrollView.showsHorizontalScrollIndicator = false;
    _mediaScrollView.showsVerticalScrollIndicator = false;
    [self.textView addSubview:_mediaScrollView];
    
    self.mediaLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, _mediaScrollView.frame.origin.y +  _mediaScrollView.frame.size.height + 6 + HALF_PIXEL, _mediaScrollView.frame.size.width, HALF_PIXEL)];
    self.mediaLineSeparator.backgroundColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.75];
    self.mediaLineSeparator.hidden = true;
    [self.textView addSubview:self.mediaLineSeparator];
    
    // Stack View
    self.media = [[BFMedia alloc] init];
    self.media.delegate = self;
    _mediaContainerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, _mediaScrollView.frame.size.width, _mediaScrollView.frame.size.height)];
    _mediaContainerView.backgroundColor = [UIColor contentBackgroundColor];
    _mediaContainerView.axis = UILayoutConstraintAxisHorizontal;
    _mediaContainerView.distribution = UIStackViewDistributionFill;
    _mediaContainerView.alignment = UIStackViewAlignmentFill;
    _mediaContainerView.spacing = 6;
    
    _mediaContainerView.translatesAutoresizingMaskIntoConstraints = false;
    [_mediaScrollView addSubview:_mediaContainerView];
    
    [_mediaContainerView.leadingAnchor constraintEqualToAnchor:_mediaScrollView.leadingAnchor].active = true;
    [_mediaContainerView.trailingAnchor constraintEqualToAnchor:_mediaScrollView.trailingAnchor].active = true;
    [_mediaContainerView.bottomAnchor constraintEqualToAnchor:_mediaScrollView.bottomAnchor].active = true;
    [_mediaContainerView.topAnchor constraintEqualToAnchor:_mediaScrollView.topAnchor].active = true;
    [_mediaContainerView.heightAnchor constraintEqualToAnchor:_mediaScrollView.heightAnchor].active = true;
    
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.takePictureButton.frame = CGRectMake(10, 6, 36, 36);
    [self.takePictureButton setImage:[[UIImage imageNamed:@"composeAddPicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.takePictureButton.tintColor = [UIColor whiteColor];
    [self.takePictureButton setImageEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    self.takePictureButton.backgroundColor = [UIColor bonfireBrand];
    self.takePictureButton.layer.masksToBounds = true;
    self.takePictureButton.layer.cornerRadius = self.takePictureButton.frame.size.height / 2;
    self.takePictureButton.imageView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.16f].CGColor;
    self.takePictureButton.imageView.layer.masksToBounds = false;
    self.takePictureButton.imageView.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.takePictureButton.imageView.layer.shadowRadius = 1;
    self.takePictureButton.imageView.layer.shadowOpacity = 1;
    self.takePictureButton.contentMode = UIViewContentModeScaleAspectFill;
    self.takePictureButton.adjustsImageWhenHighlighted = false;
    [self.takePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.takePictureButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.takePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.takePictureButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.takePictureButton bk_whenTapped:^{        
        [self takePhotoToAttach:nil];
    }];
    [self.contentView addSubview:self.takePictureButton];
    
    self.expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.expandButton.adjustsImageWhenHighlighted = false;
    self.expandButton.frame = CGRectMake(self.frame.size.width - 36 - 14, _textView.frame.origin.y, 36, 40);
    self.expandButton.contentMode = UIViewContentModeCenter;
    [self.expandButton setImage:[[UIImage imageNamed:@"expandComposeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.expandButton.tintColor = [UIColor bonfireSecondaryColor];
    [self.expandButton setImage:[UIImage new] forState:UIControlStateDisabled];
    self.expandButton.userInteractionEnabled = true;
    [self.expandButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.expandButton.alpha = 0.8;
            self.expandButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.expandButton bk_addEventHandler:^(id sender) {
        if (self.textView.text.length == 0 && self.media.objects.count == 0) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.expandButton.alpha = 1;
                self.expandButton.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        }
    } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.contentView addSubview:self.expandButton];
    
    self.choosePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.choosePictureButton.frame = CGRectMake(self.expandButton.frame.origin.x - 36 - 4, 10, 36, 36);
    [self.choosePictureButton setImage:[[UIImage imageNamed:@"quickComposeChoosePicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.choosePictureButton.tintColor = [UIColor bonfireSecondaryColor];
    self.choosePictureButton.layer.masksToBounds = true;
    self.choosePictureButton.layer.cornerRadius = self.takePictureButton.frame.size.height / 2;
    self.choosePictureButton.contentMode = UIViewContentModeScaleAspectFill;
    self.choosePictureButton.adjustsImageWhenHighlighted = false;
    [self.choosePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.choosePictureButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.choosePictureButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.choosePictureButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.choosePictureButton bk_whenTapped:^{
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [self.contentView addSubview:self.choosePictureButton];
    
    self.chooseGIFButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.chooseGIFButton.frame = CGRectMake(self.choosePictureButton.frame.origin.x - 36 - 4, 10, 36, 36);
    [self.chooseGIFButton setImage:[[UIImage imageNamed:@"quickComposeGif"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.chooseGIFButton.tintColor = [UIColor bonfireSecondaryColor];
    self.chooseGIFButton.layer.masksToBounds = true;
    self.chooseGIFButton.layer.cornerRadius = self.chooseGIFButton.frame.size.height / 2;
    self.chooseGIFButton.contentMode = UIViewContentModeScaleAspectFill;
    self.chooseGIFButton.adjustsImageWhenHighlighted = false;
    [self.chooseGIFButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.chooseGIFButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.chooseGIFButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.chooseGIFButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.chooseGIFButton bk_whenTapped:^{
        [Launcher openGIFSearch:self];
    }];
    [self.contentView addSubview:self.chooseGIFButton];
    
    self.postButton = [TappableButton buttonWithType:UIButtonTypeCustom];
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:self.textView.font.pointSize+1 weight:UIFontWeightBold];
    self.postButton.padding = UIEdgeInsetsMake(5, 5, 5, 5);
    self.postButton.adjustsImageWhenHighlighted = false;
    self.postTitle = @"Share"; // default
    self.postButton.contentMode = UIViewContentModeCenter;
//    [self.postButton setImage:[[UIImage imageNamed:@"sendButtonIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.postButton.userInteractionEnabled = false;
    self.postButton.alpha = 0;
    self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
    [self.postButton bk_addEventHandler:^(id sender) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postButton.alpha = 0.8;
            self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.postButton bk_addEventHandler:^(id sender) {
        NSLog(@"cancel or drag exit");
        if (self.textView.text.length > 0 || self.media.objects.count > 0) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.postButton.alpha = 1;
                self.postButton.transform = CGAffineTransformMakeScale(1, 1);
            } completion:nil];
        }
    } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.contentView addSubview:self.postButton];
    
    self.charRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 12 - 32 - 4, self.postButton.frame.origin.y - self.postButton.frame.size.height, 32, 20)];
    self.charRemainingLabel.hidden = true;
    self.charRemainingLabel.textColor = [UIColor bonfireSecondaryColor];
    self.charRemainingLabel.textAlignment = NSTextAlignmentCenter;
    self.charRemainingLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightRegular];
//    [self.contentView addSubview:self.charRemainingLabel];
    
    self.replyingToLabel = [UIButton buttonWithType:UIButtonTypeCustom];
    self.replyingToLabel.hidden = true;
    self.replyingToLabel.frame = CGRectMake(0, 0, self.frame.size.width, 40);
    self.replyingToLabel.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.95];
    self.replyingToLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.replyingToLabel.contentEdgeInsets = UIEdgeInsetsMake(0, 37, 0, 12);
    self.replyingToLabel.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
    [self.replyingToLabel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self insertSubview:self.replyingToLabel belowSubview:self.contentView];
    
    UIImageView *closeIcon = [[UIImageView alloc] init];
    closeIcon.contentMode = UIViewContentModeCenter;
    closeIcon.image = [[UIImage imageNamed:@"cancelReplyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    closeIcon.frame = CGRectMake(self.replyingToLabel.frame.size.width - closeIcon.image.size.width - 12 - 12, self.replyingToLabel.frame.size.height / 2 - closeIcon.image.size.height / 2 - 12, closeIcon.image.size.width + 24, closeIcon.image.size.height + 24);
    closeIcon.tintColor = [UIColor whiteColor];
    closeIcon.userInteractionEnabled = true;
    [closeIcon bk_whenTapped:^{
        [self setReplyingTo:nil];
    }];
    [self.replyingToLabel addSubview:closeIcon];
    
    UIImageView *replyIcon = [[UIImageView alloc] initWithFrame:CGRectMake(12, self.replyingToLabel.frame.size.height / 2 - 7.5, 18, 14)];
    replyIcon.image = [[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    replyIcon.tintColor = [UIColor whiteColor];
    replyIcon.contentMode = UIViewContentModeScaleAspectFill;
    [self.replyingToLabel addSubview:replyIcon];
    
    self.autoCompleteTableViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0)];
    self.autoCompleteTableViewContainer.layer.masksToBounds = false;
    [self addSubview:self.autoCompleteTableViewContainer];
    
    self.autoCompleteTableView = [[UITableView alloc] initWithFrame:self.autoCompleteTableViewContainer.bounds style:UITableViewStyleGrouped];
    self.autoCompleteTableView.delegate = self;
    self.autoCompleteTableView.dataSource = self;
    self.autoCompleteTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.autoCompleteTableView.backgroundColor = [UIColor contentBackgroundColor];
    self.autoCompleteTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.autoCompleteTableView.estimatedRowHeight = 68;
    self.autoCompleteTableView.layer.cornerRadius = self.autoCompleteTableViewContainer.layer.cornerRadius;
    self.autoCompleteTableView.showsVerticalScrollIndicator = false;
    
    [self.autoCompleteTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    [self.autoCompleteTableView registerClass:[SearchResultCell class] forCellReuseIdentifier:searchResultCellIdentifier];
    
    [self.autoCompleteTableViewContainer addSubview:self.autoCompleteTableView];
    
    // auto complete hairline
    UIView *autoCompleteLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, -HALF_PIXEL, self.autoCompleteTableViewContainer.frame.size.width, HALF_PIXEL)];
    autoCompleteLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
//    [self.autoCompleteTableViewContainer addSubview:autoCompleteLineSeparator];
    
    // compose box hairline
    self.topSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, -HALF_PIXEL, screenWidth, HALF_PIXEL)];
    self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self addSubview:self.topSeparator];
    
    maxLength = [Session sharedInstance].defaults.post.maxLength;
    
    self.theme = [UIColor bonfireBrand]; // default
    
    [self setMediaTypes:@[BFMediaTypeText, BFMediaTypeImage, BFMediaTypeGIF]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.defaultPlaceholder == nil || mediaPlaceholder == nil) {
        [self updatePlaceholders];
    }
    
    self.replyingToLabel.frame = CGRectMake(0, self.replyingToLabel.frame.origin.y, self.frame.size.width, 40);
    
    // style
    // -- text view
    [self resize:false];
    
    // added in layoutSubviews for Dark Mode support
    _textView.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
}

- (void)setMediaTypes:(NSArray *)mediaTypes {
    if (mediaTypes != _mediaTypes) {
        _mediaTypes = mediaTypes;
        
        [self updateMediaAvailability];
    }
}

- (void)updatePlaceholders {
    NSString *publicPostPlaceholder = @"Share something...";
    
    if (self.defaultPlaceholder == nil) {
        if (self.replyingTo != nil) {
            if ([self.replyingTo.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                self.defaultPlaceholder = @"Add a reply...";
            }
            else {
                NSString *creatorIdentifier = self.replyingTo.attributes.creator.attributes.identifier;
                self.defaultPlaceholder = creatorIdentifier ? [NSString stringWithFormat:@"Reply to @%@...", creatorIdentifier] : @"Add a reply...";
            }
        }
        else {
            self.defaultPlaceholder = publicPostPlaceholder;
        }
        self.defaultPlaceholder = [self stringByDeletingWordsFromString:self.defaultPlaceholder toFit:CGRectMake(0, 0, self.textView.frame.size.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right - 86, self.textView.frame.size.height - self.textView.contentInset.top - self.textView.contentInset.bottom) withInset:0 usingFont:self.textView.font];
    }
    else if (mediaPlaceholder == nil) {
        mediaPlaceholder = @"Add a caption...";
    }
    
    if (self.media.objects.count == 0) {
        self.textView.placeholder = self.defaultPlaceholder;
    }
    else {
        self.textView.placeholder = mediaPlaceholder;
    }
}

- (NSString *)stringByDeletingWordsFromString:(NSString *)string
                                        toFit:(CGRect)rect
                                    withInset:(CGFloat)inset
                                    usingFont:(UIFont *)font
{
    NSString *result = [[string copy] stringByReplacingOccurrencesOfString:@"..." withString:@""];
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

    if ([result isEqualToString:@"Share in"]) {
        result = @"Share with the Camp...";
    }
    else if (result.length < string.length) {
        result = [result stringByAppendingString:@"..."];
    }
    
    return result;
}

- (void)reset {
    self.textView.text = @"";
    [self hidePostButton];
    [self.media flush];
    [self hideMediaTray];
    [self setReplyingTo:nil];
    [self updateMediaAvailability];
    self.tagSuggestions = [NSMutableArray new];
    [self.autoCompleteTableView reloadData];
    [self hideAutoCompleteView:true];
}

- (void)setActive:(BOOL)isActive {
    //CGRect screenRect = [[UIScreen mainScreen] bounds];
    //CGFloat screenWidth = screenRect.size.width;
    _active = isActive;
    // NSLog(@"active has been set to %@", (isActive ? @"TRUE" : @"FALSE"));
    if (isActive) {
        [self.textView becomeFirstResponder];
    }
    else {
        [self.textView resignFirstResponder];
    }
}

- (BOOL)active {
    return _active;
}
- (BOOL)isActive {
    return _active;
}

- (void)resize:(BOOL)animated {
    CGFloat upcomingTextViewWidth = self.frame.size.width - (self.textView.frame.origin.x * 2);
    
    CGRect textViewRect = [self.textView.text.length == 0 ? @"Bonfire" : self.textView.text boundingRectWithSize:CGSizeMake(upcomingTextViewWidth - self.textView.textContainerInset.left - self.textView.textContainerInset.right, 800) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil];
    
    CGFloat textHeight = MIN(ceil(textViewRect.size.height) + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom, textViewMaxHeight);
        
    CGFloat textViewPadding = self.textView.frame.origin.y;
    
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat barHeight = textViewPadding + textHeight + textViewPadding + bottomPadding;
    
    CGRect frame = self.frame;
    CGFloat bottomY = frame.origin.y + frame.size.height;
    
    [UIView animateWithDuration:animated?0.3:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.frame = CGRectMake(frame.origin.x, bottomY - barHeight, frame.size.width, barHeight);
        self.contentView.frame = self.bounds;
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, upcomingTextViewWidth, textHeight);
        
        self.postButton.center = CGPointMake(self.textView.frame.origin.x + upcomingTextViewWidth - self.postButton.frame.size.width / 2 - 12, self.textView.frame.origin.y + self.textView.frame.size.height - 23);
        self.charRemainingLabel.center = CGPointMake(self.takePictureButton.center.x, self.postButton.frame.origin.y - self.charRemainingLabel.frame.size.height / 2);
        self.charRemainingLabel.hidden = (self.charRemainingLabel.frame.origin.y < self.textView.frame.origin.y + (![self.mediaScrollView isHidden] ? self.mediaLineSeparator.frame.origin.y : 0));
        self.expandButton.center = CGPointMake(self.expandButton.center.x, self.textView.frame.origin.y + self.textView.frame.size.height - 20 - ((45 - 40) / 2));
        
        self.takePictureButton.center = CGPointMake(self.takePictureButton.center.x, self.expandButton.center.y);
        self.choosePictureButton.center = CGPointMake(self.choosePictureButton.center.x, self.expandButton.center.y);
        self.chooseGIFButton.center = CGPointMake(self.chooseGIFButton.center.x, self.expandButton.center.y);
    } completion:nil];
}

- (void)showPostButton {
    self.postButton.userInteractionEnabled = true;
    self.expandButton.userInteractionEnabled = false;
    
    if (self.postButton.alpha == 0) {
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
    }
    
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.expandButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.expandButton.alpha = 0;
        
        self.choosePictureButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.choosePictureButton.alpha = 0;
        
        self.chooseGIFButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.chooseGIFButton.alpha = 0;
    } completion:nil];
    
    [UIView animateWithDuration:0.3f delay:0.2f usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(1, 1);
        self.postButton.alpha = 1;
    } completion:nil];
}
- (void)hidePostButton {
    self.postButton.userInteractionEnabled = false;
    self.expandButton.userInteractionEnabled = true;
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        self.postButton.alpha = 0;
        
        self.expandButton.transform = CGAffineTransformMakeScale(1, 1);
        self.expandButton.alpha = 1;
        
        if ([self.media canAddImage]) {
            self.choosePictureButton.transform = CGAffineTransformMakeScale(1, 1);
            self.choosePictureButton.alpha = 1;
        }
        
        if ([self.media canAddGIF]) {
            self.chooseGIFButton.transform = CGAffineTransformMakeScale(1, 1);
            self.chooseGIFButton.alpha = 1;
        }
    } completion:nil];
}

- (void)takePhotoToAttach:(id)sender {
    CGPoint localPoint = [self.takePictureButton bounds].origin;
    CGPoint basePoint = [self.takePictureButton convertPoint:localPoint toView:nil];
    
    CGPoint launchPoint = CGPointMake(basePoint.x + self.takePictureButton.frame.size.width / 2, basePoint.y + self.takePictureButton.frame.size.height / 2);
    
    if ([self.textView isFirstResponder]) {
        launchPoint = CGPointZero;
        [self.textView resignFirstResponder];
    }
    
    [Launcher openComposeCameraFromCenterPoint:launchPoint sender:self];
}

- (void)chooseFromLibraryForProfilePicture:(id)sender {
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
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSLog(@"didFinishPickingMediaWithInfo");
    // determine file type
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    if (asset) {
        NSLog(@"asset:D");
        [self.media addAsset:asset];
    }
    else {
        NSLog(@"image:D");
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [self.media addImage:chosenImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [_textView becomeFirstResponder];
}
- (void)mediaObjectAdded:(BFMediaObject *)object {
    NSLog(@"media object added:: %@", object);
    [self showMediaTray];
    
    NSData *data = object.data;
    
    SDAnimatedImageView *view = [[SDAnimatedImageView alloc] init];
    view.userInteractionEnabled = true;
    view.backgroundColor = [UIColor contentBackgroundColor];
    view.layer.cornerRadius = 14.f;
    view.layer.masksToBounds = true;
    view.contentMode = UIViewContentModeScaleAspectFill;
    if ([object.MIME isEqualToString:BFMediaObjectMIME_GIF]) {
        SDAnimatedImage *animatedImage = [SDAnimatedImage imageWithData:data];
        view.image = animatedImage;
        
        UIImage *image = [UIImage imageWithData:data];
        [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(image.size.width/image.size.height)].active = true;
    }
    else {
        view.image = [UIImage imageWithData:data];
        [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(view.image ? (view.image.size.width/view.image.size.height) : 1)].active = true;
    }
    [view.heightAnchor constraintEqualToConstant:100].active = true;
    view.layer.borderWidth = 1.f;
    view.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06].CGColor;
    [self removeSelectImageViewFromMediaTray];
    
    [_mediaContainerView addArrangedSubview:view];
    
    UIButton *removeImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [removeImageButton setImage:[UIImage imageNamed:@"composeRemoveImageIcon"] forState:UIControlStateNormal];
    removeImageButton.layer.cornerRadius = 15.f;
    removeImageButton.layer.shadowOffset = CGSizeMake(0, 0.5);
    removeImageButton.layer.shadowRadius = 1.f;
    removeImageButton.layer.shadowColor = [UIColor blackColor].CGColor;
    removeImageButton.layer.shadowOpacity = 0.1f;
    removeImageButton.adjustsImageWhenHighlighted = false;
    [view addSubview:removeImageButton];
    // 1
    removeImageButton.translatesAutoresizingMaskIntoConstraints = false;
    [removeImageButton.topAnchor constraintEqualToAnchor:view.topAnchor constant:5].active = true;
    [removeImageButton.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:-5].active = true;
    [removeImageButton.widthAnchor constraintEqualToConstant:30].active = true;
    [removeImageButton.heightAnchor constraintEqualToConstant:30].active = true;
    
    [removeImageButton bk_whenTapped:^{
        [self removeImageAtIndex:[self.mediaContainerView.subviews indexOfObject:view]];
    }];
    [removeImageButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            removeImageButton.alpha = 0.8;
            removeImageButton.transform = CGAffineTransformMakeScale(0.6, 0.6);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [removeImageButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            removeImageButton.alpha = 1;
            removeImageButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self updateMediaAvailability];
    
    [self showPostButton];
    
    if (self.media.objects.count < self.media.maxImages && self.media.GIFs.count == 0) {
        [self addSelectImageViewToMediaTray];
    }
    else if (self.media.objects.count == self.media.maxImages) {
        [self removeSelectImageViewFromMediaTray];
    }
    else {
        [self.mediaScrollView setContentOffset:CGPointMake(MAX(-self.mediaScrollView.contentInset.left, self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width + self.mediaScrollView.contentInset.left), 0) animated:true];
    }
    
    wait(0.3f, ^{
        if (self.textView && [self.textView canBecomeFirstResponder]) {
            [self.textView becomeFirstResponder];
        }
    });
}

- (void)addSelectImageViewToMediaTray {
    // add the add button !
    UIView *addView = [[UIView alloc] init];
    addView.tag = 10; // add view unique tag
    addView.userInteractionEnabled = true;
    addView.layer.cornerRadius = 14.f;
    addView.layer.masksToBounds = true;
    addView.backgroundColor = [UIColor clearColor];
//    addView.layer.borderWidth = 1.f;
//    addView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06].CGColor;
    [addView.widthAnchor constraintEqualToConstant:75].active = true;
    [addView.heightAnchor constraintEqualToConstant:100].active = true;
    addView.transform = CGAffineTransformMakeScale(0.6, 0.6);
    addView.alpha = 0.01;
    [addView bk_whenTapped:^{
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [_mediaContainerView insertArrangedSubview:addView atIndex:_mediaContainerView.arrangedSubviews.count];
    
    UIButton *selectImage = [UIButton buttonWithType:UIButtonTypeCustom];
    selectImage.contentMode = UIViewContentModeCenter;
    selectImage.userInteractionEnabled = false;
    [selectImage setImage:[[UIImage imageNamed:@"composeAddPictureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    selectImage.imageEdgeInsets = UIEdgeInsetsMake(-4, 0, 0, -4);
    selectImage.tintColor = [UIColor bonfirePrimaryColor];
    selectImage.backgroundColor = [UIColor bonfireDetailColor];
    selectImage.layer.cornerRadius = 26;
    [addView addSubview:selectImage];
    
    selectImage.translatesAutoresizingMaskIntoConstraints = false;
    [selectImage.centerXAnchor constraintEqualToAnchor:addView.centerXAnchor constant:0].active = true;
    [selectImage.centerYAnchor constraintEqualToAnchor:addView.centerYAnchor constant:0].active = true;
    [selectImage.widthAnchor constraintEqualToConstant:52].active = true;
    [selectImage.heightAnchor constraintEqualToConstant:52].active = true;
    
    [UIView animateWithDuration:0.4f delay:0.15 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        addView.transform = CGAffineTransformMakeScale(1, 1);
        addView.alpha = 1;
    } completion:^(BOOL finished) {
        [self.mediaScrollView setContentOffset:CGPointMake(MAX(-self.mediaScrollView.contentInset.left, self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width + self.mediaScrollView.contentInset.left), 0) animated:true];
    }];
}
- (void)removeSelectImageViewFromMediaTray {
    if (_mediaContainerView.arrangedSubviews.count == 0) return;
    
    UIView *selectImageView;
    for (UIView *view in _mediaContainerView.arrangedSubviews) {
        if (view.tag == 10) {
            selectImageView = view;
        }
    }
    
    if (!selectImageView) return;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        selectImageView.transform = CGAffineTransformMakeScale(0.6, 0.6);
        selectImageView.alpha = 0.01;
    } completion:^(BOOL finished) {
    }];
    [UIView animateWithDuration:0.4f delay:0.15 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        selectImageView.hidden = true;
    } completion:^(BOOL finished) {
        [selectImageView removeFromSuperview];
        
        [self.mediaScrollView setContentOffset:CGPointMake(MAX(-self.mediaScrollView.contentInset.left, self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width + self.mediaScrollView.contentInset.left), 0) animated:true];
    }];
}

- (void)removeImageAtIndex:(NSInteger)index {
    if (self.media.objects.count > index) {
        BFMediaObject *object = [self.media.objects objectAtIndex:index];
        
        [self.media removeObject:object];
    }
    
    if (self.mediaContainerView.subviews.count > index) {
        UIView *view = [self.mediaContainerView.subviews objectAtIndex:index];
    
        view.userInteractionEnabled = false;
        
        [self updateMediaAvailability];
        if (self.media.objects.count == 0) {
            // no items left
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self removeSelectImageViewFromMediaTray];
                [self hideMediaTray];
            });
        }
        else if (self.media.objects.count == self.media.maxImages - 1) {
            [self addSelectImageViewToMediaTray];
        }
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.transform = CGAffineTransformMakeScale(0.6, 0.6);
            view.alpha = 0.01;
        } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:0.4f delay:0.15 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            view.hidden = true;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    }
}

- (void)updateMediaAvailability {
    DLog(@"self.media canAddImages? %@", [self.media canAddImage] ? @"YES" : @"NO");
    DLog(@"self.media canAddGIFs? %@", [self.media canAddGIF] ? @"YES" : @"NO");
    DLog(@"self.media canAddMedia? %@", [self.media canAddMedia] ? @"YES" : @"NO");
    
    self.takePictureButton.enabled = [self.media canAddMedia];
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.takePictureButton.alpha = (self.takePictureButton.enabled ? 1 : 0);
    } completion:nil];
    
    self.takePictureButton.hidden = (self.mediaTypes.count == 0 || (self.mediaTypes.count == 1 && [self.mediaTypes containsObject:BFMediaTypeText]));
    [self updateTextContainerInset];
    [self updatePlaceholders];
    
    [self resize:false];
}
- (void)updateTextContainerInset {
    if ([self.media canAddGIF]) {
        _textView.textContainerInset = UIEdgeInsetsMake(_textView.textContainerInset.top, COMPOSE_TEXT_VIEW_INSET_WITH_GIF.left, COMPOSE_TEXT_VIEW_INSET_WITH_GIF.bottom, [self.postButton isEnabled] ? self.postButton.frame.size.width + 28 :  COMPOSE_TEXT_VIEW_INSET_WITH_GIF.right);
    }
    else if ([self.media canAddImage]) {
        _textView.textContainerInset = UIEdgeInsetsMake(_textView.textContainerInset.top, COMPOSE_TEXT_VIEW_INSET_WITH_IMAGE.left, COMPOSE_TEXT_VIEW_INSET_WITH_IMAGE.bottom, [self.postButton isEnabled] ? self.postButton.frame.size.width + 28 :  COMPOSE_TEXT_VIEW_INSET_WITH_IMAGE.right);
    }
    else {
        // only text
        _textView.textContainerInset = UIEdgeInsetsMake(_textView.textContainerInset.top, COMPOSE_TEXT_VIEW_INSET.left, COMPOSE_TEXT_VIEW_INSET.bottom, [self.postButton isEnabled] ? self.postButton.frame.size.width + 28 :  COMPOSE_TEXT_VIEW_INSET.right);
    }
}
    
- (void)showMediaTray {
    _textView.textContainerInset = UIEdgeInsetsMake(9 + 140, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
    _textView.placeholder = @"Add a caption...";
    
    [self resize:false];
    [self showPostButton];
    
    self.mediaScrollView.alpha = 1;
    self.mediaLineSeparator.alpha = 1;
    self.mediaScrollView.hidden = false;
    self.mediaLineSeparator.hidden = false;
    self.mediaScrollView.userInteractionEnabled = true;
    self.mediaLineSeparator.userInteractionEnabled = true;
}
- (void)hideMediaTray {
    _textView.textContainerInset = UIEdgeInsetsMake(COMPOSE_TEXT_VIEW_INSET.top, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
    _textView.placeholder = self.defaultPlaceholder;
    
    [self resize:true];
    if (self.textView.text.length == 0) {
        [self hidePostButton];
    }
    
    self.mediaScrollView.userInteractionEnabled = false;
    self.mediaLineSeparator.userInteractionEnabled = false;
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.mediaScrollView.alpha = 0;
        self.mediaLineSeparator.alpha = 0;
    } completion:^(BOOL finished) {
        self.mediaScrollView.hidden = true;
        self.mediaLineSeparator.hidden = true;
    }];
    
    // remove all media views
    for (UIView *subview in self.mediaContainerView.subviews) {
        [subview removeFromSuperview];
    }
}

- (void)setReplyingTo:(Post *)replyingTo {
    if (replyingTo != _replyingTo) {
        _replyingTo = replyingTo;
        
        if (_replyingTo) {
            if ([replyingTo.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                [_replyingToLabel setTitle:@"Replying to yourself" forState:UIControlStateNormal];
            }
            else {
                if (replyingTo.attributes.creator.attributes.identifier) {
                    [_replyingToLabel setTitle:[NSString stringWithFormat:@"Replying to @%@", replyingTo.attributes.creator.attributes.identifier] forState:UIControlStateNormal];
                }
                else {
                    [_replyingToLabel setTitle:@"Loading..." forState:UIControlStateNormal];
                }
            }
            [self showReplyingTo];
        }
        else {
            self.textView.text = @"";
            [self hideReplyingTo];
        }
        
        if ([self.delegate respondsToSelector:@selector(composeInputViewReplyingToDidChange)]) {
            [self.delegate composeInputViewReplyingToDidChange];
        }
        
        [self updatePlaceholders];
    }
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint translatedPoint = [_replyingToLabel convertPoint:point fromView:self];
    
    if (!_replyingToLabel.isHidden && CGRectContainsPoint(_replyingToLabel.bounds, translatedPoint)) {
        return [_replyingToLabel hitTest:translatedPoint withEvent:event];
    }
    
    translatedPoint = [_autoCompleteTableView convertPoint:point fromView:self];
    if (CGRectContainsPoint(_autoCompleteTableView.bounds, translatedPoint)) {
        return [_autoCompleteTableView hitTest:translatedPoint withEvent:event];
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)showReplyingTo {
    self.replyingToLabel.hidden = false;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyingToLabel.frame = CGRectMake(0, -1 * self.replyingToLabel.frame.size.height, self.frame.size.width, self.replyingToLabel.frame.size.height);
    } completion:nil];
}
- (void)hideReplyingTo {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyingToLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.replyingToLabel.frame.size.height);
    } completion:^(BOOL finished) {
        self.replyingToLabel.hidden = true;
    }];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.textView]) {
        [self resize:false];
        
        if (![self textViewIsEmpty] || self.media.objects.count > 0) {
            [self showPostButton];
            
            BOOL enableButton =  (self.media.objects.count > 0) || [self charactersRemainingWithStirng:textView.text] >= 0;
            self.postButton.enabled = enableButton;
            self.postButton.alpha = enableButton ? 1 : 0.5;
        }
        else {
            [self hidePostButton];
        }

        CGFloat textViewHeightBefore = textView.frame.size.height;
        [self detectEntities];
        CGFloat textViewHeightAfter = textView.frame.size.height;
        
        if (diff(textViewHeightBefore, textViewHeightAfter) && textView.frame.size.height == textViewMaxHeight) {
            NSRange bottom = NSMakeRange(textView.text.length -1, 1);
            [textView scrollRangeToVisible:bottom];

            [textView setScrollEnabled:NO];
            [textView setScrollEnabled:YES];
        }

        NSInteger charactersRemaining = [self charactersRemainingWithStirng:self.textView.text];
        self.charRemainingLabel.text = [NSString stringWithFormat:@"%ld", (long)charactersRemaining];
        if (charactersRemaining <= 20) {
            self.charRemainingLabel.textColor = [UIColor bonfireRed];
        }
        else {
            self.charRemainingLabel.textColor = [UIColor bonfireSecondaryColor];
        }
        
        if ([self.delegate respondsToSelector:@selector(composeInputViewMessageDidChange:)]) {
            [self.delegate composeInputViewMessageDidChange:textView];
        }
    }
}
- (BOOL)textViewIsEmpty {
    NSString *spacelessString = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return spacelessString.length == 0;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *proposedNewString = [[textView text] stringByReplacingCharactersInRange:range withString:text];
    BOOL shouldChange = [self charactersRemainingWithStirng:proposedNewString] >= 0;
    
    if (!shouldChange) {
        if ([self charactersRemainingWithStirng:self.textView.text] >= 0) {
            // only do this if it *just* went over
            [HapticHelper generateFeedback:FeedbackType_Notification_Warning];
            [UIView animateWithDuration:0.2f delay:0 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
                self.textView.alpha = 0.5;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.15f delay:0 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
                    self.textView.alpha = 1;
                } completion:nil];
            }];
        }
    }
    else if (self.textView.alpha != 1) {
        [self.textView.layer removeAllAnimations];
        self.textView.alpha = 1;
    }
    
    return true;
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
    NSRange s_range = self.textView.selectedRange;
    NSUInteger s_loc = s_range.location;
    
    BOOL insideUsername = false;
    BOOL insideCampTag = false;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:self.textView.text attributes:@{NSFontAttributeName: self.textView.font, NSForegroundColorAttributeName:[UIColor bonfirePrimaryColor]}];
    NSArray *usernameRanges = [self.textView.text rangesForUsernameMatches];
    NSArray *campTagRanges = [self.textView.text rangesForCampTagMatches];
    NSArray *urlRanges = [self.textView.text rangesForLinkMatches];
    if (usernameRanges.count > 0) {
        NSLog(@"usernameRanges: %@", usernameRanges);
        for (NSValue *value in usernameRanges) {
            NSRange range = [value rangeValue];
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.textView.tintColor range:range];
            
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
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.textView.tintColor range:range];
            
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
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.textView.tintColor range:[value rangeValue]];
        }
    }
    
    NSInteger remainingCharacters = [self charactersRemainingWithStirng:self.textView.text];
    if (remainingCharacters < 0) {
        NSInteger length = labs(remainingCharacters);
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireRed] range:NSMakeRange(MIN(self.textView.text.length - length, self.textView.text.length), length)];
        [attributedText addAttribute:NSBackgroundColorAttributeName value:[[UIColor bonfireRed] colorWithAlphaComponent:0.1] range:NSMakeRange(MIN(self.textView.text.length -  length, self.textView.text.length), length)];
    }
    
    self.activeAttributedString = attributedText;
    self.textView.attributedText = self.activeAttributedString;
    
    // environment issue
    // -> set selected range using the range before updating the attributed text
    [self.textView setSelectedRange:s_range];
    
    // update height of the cell
    [self resize:false];
    
    if (insideUsername) NSLog(@"insideUsername ==> true");
    if (insideCampTag) NSLog(@"insideCampTag ==> true");
    
    if (insideUsername || insideCampTag) {
        [self getAutoCompleteResults:[self.textView.text substringWithRange:self.activeTagRange]];
    }
    else {
        self.activeTagRange = NSMakeRange(NSNotFound, 0);
        [self hideAutoCompleteView:true];
    }
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
        NSString *currentSearchTerm = self.activeTagRange.location != NSNotFound ? [self.textView.text substringWithRange:self.activeTagRange] : @"";
        if ([tag isEqualToString:currentSearchTerm]) {
            NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                            
            if (isUser) {
                self.autoCompleteResults = [[NSMutableArray alloc] initWithArray:responseData[@"results"][@"users"]];
            }
            else if (isCamp) {
                self.autoCompleteResults = [[NSMutableArray alloc] initWithArray:responseData[@"results"][@"camps"]];
            }
                    
            if (self.autoCompleteResults.count > 0 && self.activeTagRange.location != NSNotFound) {
                [self.autoCompleteTableView reloadData];
                [self showAutoCompleteView];
            }
            else if (self.autoCompleteResults.count == 0) {
                [self hideAutoCompleteView:true];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [self hideAutoCompleteView:true];
    }];
}

- (void)showAutoCompleteView {
    CGFloat height = self.autoCompleteResults.count * [self tableView:self.autoCompleteTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (height > 170) {
        height = 170; //68 * 2.5
    }
    
    if (self.autoCompleteTableViewContainer.alpha == 0) {
        self.autoCompleteTableViewContainer.transform = CGAffineTransformMakeTranslation(0, 0);
        self.autoCompleteTableViewContainer.frame = CGRectMake(0, -1 * height, self.frame.size.width, height);
        self.autoCompleteTableView.frame = CGRectMake(0, 0, self.autoCompleteTableViewContainer.frame.size.width, self.autoCompleteTableViewContainer.frame.size.height);
        
        [UIView animateWithDuration:0.45f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.autoCompleteTableViewContainer.alpha = 1;
            self.autoCompleteTableViewContainer.transform = CGAffineTransformMakeTranslation(0, 0);
            
            self.topSeparator.frame = CGRectMake(0, -1 * (self.autoCompleteTableView.frame.size.height + self.topSeparator.frame.size.height), self.topSeparator.frame.size.width, self.topSeparator.frame.size.height);
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            self.autoCompleteTableViewContainer.frame = CGRectMake(0, -1 * height, self.frame.size.width, height);
            self.autoCompleteTableView.frame = CGRectMake(0, 0, self.autoCompleteTableViewContainer.frame.size.width, self.autoCompleteTableViewContainer.frame.size.height);
            
            self.topSeparator.frame = CGRectMake(0, -1 * (self.autoCompleteTableView.frame.size.height + self.topSeparator.frame.size.height), self.topSeparator.frame.size.width, self.topSeparator.frame.size.height);
        } completion:nil];
    }
}
- (void)hideAutoCompleteView:(BOOL)animated {
    [UIView animateWithDuration:animated?0.3f:0 delay:0 usingSpringWithDamping:0.92f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.autoCompleteTableViewContainer.frame = CGRectMake(0, -(HALF_PIXEL), self.frame.size.width, 0);
        self.autoCompleteTableView.frame = CGRectMake(0, 0, self.autoCompleteTableViewContainer.frame.size.width, self.autoCompleteTableViewContainer.frame.size.height);
        self.topSeparator.frame = CGRectMake(0, -1 * HALF_PIXEL, self.topSeparator.frame.size.width, self.topSeparator.frame.size.height);
    } completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // -- Type --
    int type = 0;
    
    NSDictionary *json = self.autoCompleteResults[indexPath.row];
    if (json[@"type"]) {
        if ([json[@"type"] isEqualToString:@"camp"]) {
            type = 1;
        }
        else if ([json[@"type"] isEqualToString:@"user"]) {
            type = 2;
        }
        else if ([json[@"type"] isEqualToString:@"bot"]) {
            type = 3;
        }
    }
    
    if (type != 0) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:searchResultCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:searchResultCellIdentifier];
        }
        
        // hide the last row
        cell.lineSeparator.hidden = indexPath.row == self.autoCompleteResults.count - 1;

        if (cell.gestureRecognizers.count == 0) {
            [cell bk_whenTapped:^{
                BOOL changes = false;
                NSString *finalString = self.textView.text;
                if (cell.user || cell.bot) {
                    Identity *identity = (cell.user ? cell.user : cell.bot);
                    NSString *usernameSelected = identity.attributes.identifier;
                    
                    if (usernameSelected.length > 0) {
                        finalString = [self.textView.text stringByReplacingCharactersInRange:self.activeTagRange withString:[NSString stringWithFormat:@"@%@ ", usernameSelected]];
                        changes = true;
                    }
                }
                else if (cell.camp) {
                    NSString *campTagSelected = cell.camp.attributes.identifier;
                    
                    if (campTagSelected.length > 0) {
                        finalString = [self.textView.text stringByReplacingCharactersInRange:self.activeTagRange withString:[NSString stringWithFormat:@"#%@ ", campTagSelected]];
                        changes = true;
                    }
                }
                
                if (changes) {
                    // set it twice to avoid autocorrection from overriding our changes
                    self.textView.text = finalString;
                    self.textView.text = finalString;
                    
                    [self hideAutoCompleteView:false];
                    [self textViewDidChange:self.textView];
                    [HapticHelper generateFeedback:FeedbackType_Selection];
                }
            }];
        }
        
        if (type == 1) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:json error:&error];
            cell.camp = camp;
        }
        else if (type == 2) {
            //NSError *error;
            User *user = [[User alloc] initWithDictionary:self.autoCompleteResults[indexPath.row] error:nil];
            cell.user = user;
        }
        else if (type == 3) {
            //NSError *error;
            Bot *bot = [[Bot alloc] initWithDictionary:self.autoCompleteResults[indexPath.row] error:nil];
            cell.bot = bot;
        }
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SearchResultCell height];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.autoCompleteResults.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView * _Nullable)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView * _Nullable)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)setPostTitle:(NSString *)postTitle {
    if (![postTitle isEqualToString:_postTitle]) {
        _postTitle = postTitle;
        
        // update title
        [self.postButton setTitle:_postTitle forState:UIControlStateNormal];
        
        // update frame
        self.postButton.frame = CGRectMake(0, 0,  ceilf(self.postButton.intrinsicContentSize.width), 32);
        self.postButton.center = CGPointMake(self.textView.frame.origin.x + self.textView.frame.size.width - self.postButton.frame.size.width / 2 - 12, self.textView.frame.origin.y + self.textView.frame.size.height - 23);
        
        [self updateTextContainerInset];
    }
}

#pragma mark - BFCameraViewControllerDelegate
- (void)cameraViewController:(nonnull BFCameraViewController *)cameraView didFinishPickingImage:(nonnull UIImage *)image {
    [self.media addImage:image];
}
- (void)cameraViewController:(BFCameraViewController *)cameraView didFinishPickingAsset:(PHAsset *)asset {
    [self.media addAsset:asset];
}

- (void)setTheme:(UIColor *)theme {
    if (theme != _theme) {
        _theme = theme;
        
        UIColor *adjustedTheme = (CGColorEqualToColor(theme.CGColor, [UIColor bonfireBrand].CGColor) ? theme  : [UIColor fromHex:[UIColor toHex:theme] adjustForOptimalContrast:true]);
        self.tintColor = theme;
        self.textView.tintColor = adjustedTheme;
        [self.postButton setTitleColor:adjustedTheme forState:UIControlStateNormal];
        
        if (self.takePictureButton && self.takePictureButton.layer) {
            if (self.takePictureButton.layer.sublayers) {
                NSMutableArray *sublayers = [self.takePictureButton.layer.sublayers mutableCopy];
                NSMutableArray *deleteSublayers = [NSMutableArray new];
                for (CALayer *layer in sublayers) {
                    if ([layer.name isEqualToString:@"gradient"]) {
                        [deleteSublayers addObject:layer];
                    }
                }
                [sublayers removeObjectsInArray:deleteSublayers];
                self.takePictureButton.layer.sublayers = sublayers;
            }
            
            [self.takePictureButton.layer insertSublayer:[BFCameraViewController cameraGradientLayerWithColor:theme withSize:self.takePictureButton.frame.size] atIndex:0];
            [self.takePictureButton bringSubviewToFront:self.takePictureButton.imageView];
            self.takePictureButton.tintColor = [UIColor highContrastForegroundForBackground:theme];
        }
    }
}

- (void)GIFCollectionView:(nonnull GIFCollectionViewController *)gifCollectionViewController didSelectGIFWithData:(nonnull NSData *)data {
    [self.media addGIFData:data];
    
    wait(0.3, ^{
        [self.textView becomeFirstResponder];
    });
}

@end
