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

#define headerHeight 58
#define postButtonShrinkScale 0.9

#define TEXT_VIEW_WITH_IMAGE_X 50
#define TEXT_VIEW_WITHOUT_IMAGE_X 12

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@interface ComposeInputView () <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource>

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
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(TEXT_VIEW_WITH_IMAGE_X, 6, self.frame.size.width - TEXT_VIEW_WITH_IMAGE_X - 12, 40)];
    _textView.delegate = self;
    _textView.editable = true;
    _textView.scrollEnabled = false;
    _textView.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular];
    _textView.textContainer.lineFragmentPadding = 0;
    _textView.contentInset = UIEdgeInsetsZero;
    _textView.textContainerInset = UIEdgeInsetsMake(9, 12, 9, 44);
    _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _textView.textColor = [UIColor bonfirePrimaryColor];
    _textView.layer.cornerRadius = 20.f;
    _textView.backgroundColor = [[UIColor fromHex:@"9FA6AD"] colorWithAlphaComponent:0.1];
    _textView.layer.borderWidth = HALF_PIXEL;
    _textView.placeholder = self.defaultPlaceholder;
    _textView.placeholderColor = [UIColor bonfireSecondaryColor];
//    _textView.keyboardAppearance = UIKeyboardAppearanceLight;
    _textView.keyboardType = UIKeyboardTypeTwitter;
    [self.contentView addSubview:_textView];
    
    _mediaScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 8, _textView.frame.size.width, 140 - 16)];
    _mediaScrollView.hidden = true;
    _mediaScrollView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    _mediaScrollView.showsHorizontalScrollIndicator = false;
    _mediaScrollView.showsVerticalScrollIndicator = false;
    [self.textView addSubview:_mediaScrollView];
    
    self.mediaLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, _mediaScrollView.frame.origin.y +  _mediaScrollView.frame.size.height + 7, _mediaScrollView.frame.size.width, 1)];
    self.mediaLineSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
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
    
    // profile picture
    self.addMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addMediaButton.frame = CGRectMake(12, 12, 30, 30);
    [self.addMediaButton setImage:[[UIImage imageNamed:@"composeAddPicture"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.addMediaButton.layer.masksToBounds = true;
    self.addMediaButton.layer.cornerRadius = self.addMediaButton.frame.size.height / 2;
    self.addMediaButton.tintColor = [UIColor whiteColor];
    self.addMediaButton.backgroundColor = [UIColor bonfireSecondaryColor];
    self.addMediaButton.contentMode = UIViewContentModeScaleAspectFill;
    self.addMediaButton.adjustsImageWhenHighlighted = false;
    [self.addMediaButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.addMediaButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.addMediaButton bk_whenTapped:^{
        [self showImagePicker];
    }];
    [self.contentView addSubview:self.addMediaButton];
    
    self.postButton = [TappableButton buttonWithType:UIButtonTypeCustom];
    self.postButton.padding = UIEdgeInsetsMake(5, 5, 5, 5);
    self.postButton.adjustsImageWhenHighlighted = false;
    self.postButton.frame = CGRectMake(self.frame.size.width - 12 - 32 - 4, _textView.frame.origin.y + 4, 32, 32);
    self.postButton.contentMode = UIViewContentModeCenter;
    [self.postButton setImage:[UIImage imageNamed:@"sendButtonIcon"] forState:UIControlStateNormal];
    [self.postButton setImage:[UIImage new] forState:UIControlStateDisabled];
    self.postButton.userInteractionEnabled = false;
    self.postButton.alpha = 0;
    self.postButton.layer.cornerRadius = 16.f;
    self.postButton.layer.shadowOpacity = 0.1f;
    self.postButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.postButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.postButton.layer.shadowRadius = 3.f;
    self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale, postButtonShrinkScale);
    [self.postButton bk_addEventHandler:^(id sender) {
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
    
    self.expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.expandButton.adjustsImageWhenHighlighted = false;
    self.expandButton.frame = CGRectMake(self.frame.size.width - 12 - 40, _textView.frame.origin.y, 40, 40);
    self.expandButton.contentMode = UIViewContentModeCenter;
    [self.expandButton setImage:[[UIImage imageNamed:@"expandComposeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.expandButton.tintColor = [UIColor bonfirePrimaryColor];
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
    
    [self.contentView insertSubview:self.expandButton belowSubview:self.postButton];
    
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
    self.topSeparator.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f];
    [self addSubview:self.topSeparator];
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
    _textView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06].CGColor;
}

- (void)setMediaTypes:(NSArray *)mediaTypes {
    if (mediaTypes != _mediaTypes) {
        _mediaTypes = mediaTypes;
        
        [self updateMediaAvailability];
    }
}

- (void)updatePlaceholders {
    NSString *publicPostPlaceholder = @"Share with everyone...";
    
    if (self.defaultPlaceholder == nil) {
        UIViewController *parentController = UIViewParentController(self);
        if (self.replyingTo != nil) {
            if ([self.replyingTo.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                self.defaultPlaceholder = @"Add a reply...";
            }
            else {
                NSString *creatorIdentifier = self.replyingTo.attributes.creator.attributes.identifier;
                self.defaultPlaceholder = creatorIdentifier ? [NSString stringWithFormat:@"Reply to @%@...", creatorIdentifier] : @"Add a reply...";
            }
        }
        else if ([parentController isKindOfClass:[ProfileViewController class]]) {
            ProfileViewController *parentProfile = (ProfileViewController *)parentController;
            if ([parentProfile.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] || [self.textView isFirstResponder]) {
                // me
                self.defaultPlaceholder = publicPostPlaceholder;
            }
            else {
                self.defaultPlaceholder = [NSString stringWithFormat:@"Share with @%@", parentProfile.user.attributes.identifier];
            }
        }
        else if ([parentController isKindOfClass:[CampViewController class]]) {
            CampViewController *parentCamp = (CampViewController *)parentController;
            if (parentCamp.camp == nil) {
                self.defaultPlaceholder = publicPostPlaceholder;
            }
            else {
                if (parentCamp.camp.attributes.title == nil) {
                    self.defaultPlaceholder = @"Share something...";
                }
                else {
                    self.defaultPlaceholder = [NSString stringWithFormat:@"Share in %@...", parentCamp.camp.attributes.title];
                }
            }
        }
        else {
            self.defaultPlaceholder = @"Add a reply...";
        }
        self.defaultPlaceholder = [self stringByDeletingWordsFromString:self.defaultPlaceholder toFit:CGRectMake(0, 0, self.textView.frame.size.width - 44 - 14 - 14, self.textView.frame.size.height - self.textView.contentInset.top - self.textView.contentInset.bottom) withInset:0 usingFont:self.textView.font];
    }
    else if (mediaPlaceholder == nil) {
        mediaPlaceholder = @"Add caption or Share";
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

    if (result.length < string.length) {
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
    CGRect textViewRect = [self.textView.text.length == 0 ? @"Quintessential" : self.textView.text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width - self.textView.textContainerInset.left - self.textView.textContainerInset.right, 800) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil];
    
    CGFloat textHeight = ceil(textViewRect.size.height) + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    
    CGFloat textViewPadding = self.textView.frame.origin.y;
    
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat barHeight = textViewPadding + textHeight + textViewPadding + bottomPadding;
    
    CGRect frame = self.frame;
    CGFloat bottomY = frame.origin.y + frame.size.height;
    
    [UIView animateWithDuration:animated?0.6:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.frame = CGRectMake(frame.origin.x, bottomY - barHeight, frame.size.width, barHeight);
        self.contentView.frame = self.bounds;
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, textHeight);
        
        self.postButton.center = CGPointMake(self.textView.frame.origin.x + self.textView.frame.size.width - 20, self.textView.frame.origin.y + self.textView.frame.size.height - 20);
        self.expandButton.center = self.postButton.center;
        
        self.addMediaButton.frame = CGRectMake(self.addMediaButton.frame.origin.x, self.frame.size.height - self.addMediaButton.frame.size.height - (self.textView.frame.origin.y + ((40 - self.addMediaButton.frame.size.height) / 2)) - bottomPadding, self.addMediaButton.frame.size.width, self.addMediaButton.frame.size.height);
    } completion:nil];
}

- (void)showPostButton {
    self.postButton.userInteractionEnabled = true;
    self.expandButton.userInteractionEnabled = false;
    
    if (self.postButton.alpha == 0) {
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
    }
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(1, 1);
        self.postButton.alpha = 1;
        
        self.expandButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.expandButton.alpha = 0;
    } completion:nil];
}
- (void)hidePostButton {
    self.postButton.userInteractionEnabled = false;
    self.expandButton.userInteractionEnabled = true;
    
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.postButton.transform = CGAffineTransformMakeScale(postButtonShrinkScale / 2, postButtonShrinkScale / 2);
        self.postButton.alpha = 0;
        
        self.expandButton.transform = CGAffineTransformMakeScale(1, 1);
        self.expandButton.alpha = 1;
    } completion:nil];
}
    
- (void)showImagePicker {
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhotoToAttach:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    UIAlertAction *chooseFromLibrary = [UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [imagePickerOptions addAction:cancel];
    
    [UIViewParentController(self) presentViewController:imagePickerOptions animated:YES completion:nil];
}

- (void)takePhotoToAttach:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self openCamera];
    }
    else if(authStatus == AVAuthorizationStatusDenied ||
            authStatus == AVAuthorizationStatusRestricted) {
        // denied
        [self showNoCameraAccess];
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined){
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
        [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
    });
}
- (void)showNoCameraAccess {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Allow Bonfire to access your camera" message:@"To allow Bonfire to access your camera, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *openSettingsAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:openSettingsAction];

    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil];
    [actionSheet addAction:closeAction];
    [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
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
                    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction *openSettingsAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
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
        [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(view.image.size.width/view.image.size.height)].active = true;
    }
    [view.heightAnchor constraintEqualToConstant:100].active = true;
    view.layer.borderWidth = 1.f;
    view.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06].CGColor;
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
    
    [self.mediaScrollView setContentOffset:CGPointMake(self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width, 0)];
    
    [self showPostButton];
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
                [self hideMediaTray];
            });
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
//    NSLog(@"self.media canAddImages? %@", [self.media canAddImage] ? @"YES" : @"NO");
//    NSLog(@"self.media canAddGIFs? %@", [self.media canAddGIF] ? @"YES" : @"NO");
//    NSLog(@"self.media canAddMedia? %@", [self.media canAddMedia] ? @"YES" : @"NO");
    
    self.addMediaButton.hidden = false;
    self.addMediaButton.enabled = [self.media canAddMedia];
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.addMediaButton.alpha = (self.addMediaButton.enabled ? 1 : 0.25);
    } completion:nil];
    
    /*
    if ([self.mediaTypes containsObject:BFMediaTypeImage] ||
        [self.mediaTypes containsObject:BFMediaTypeGIF]) {
        // determine add media button
        self.addMediaButton.hidden = false;
        self.addMediaButton.enabled = (self.media.count < self.maxImages);
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.addMediaButton.alpha = (self.addMediaButton.enabled ? 1 : 0.25);
        } completion:nil];
        
        if ([self.mediaTypes containsObject:BFMediaTypeText]) {
            self.textView.frame = CGRectMake(TEXT_VIEW_WITH_IMAGE_X, self.textView.frame.origin.y, self.frame.size.width - TEXT_VIEW_WITH_IMAGE_X - 12, self.textView.frame.size.height);
        }
        else {
            
        }
    }
    else {
        self.addMediaButton.hidden = true;
        
        self.textView.frame = CGRectMake(TEXT_VIEW_WITHOUT_IMAGE_X, self.textView.frame.origin.y, self.frame.size.width - TEXT_VIEW_WITHOUT_IMAGE_X - 12, self.textView.frame.size.height);
    }*/
    
    [self resize:false];
}
    
- (void)showMediaTray {
    _textView.textContainerInset = UIEdgeInsetsMake(9 + 140, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
    _textView.placeholder = @"Add caption or Share";
    
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
    _textView.textContainerInset = UIEdgeInsetsMake(9, _textView.textContainerInset.left, _textView.textContainerInset.bottom, _textView.textContainerInset.right);
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
                [_replyingToLabel setTitle:[NSString stringWithFormat:@"Replying to @%@", replyingTo.attributes.creator.attributes.identifier] forState:UIControlStateNormal];
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
        
        if (textView.text.length > 0 || self.media.objects.count > 0) {
            [self showPostButton];
        }
        else {
            [self hidePostButton];
        }
        
        [self detectEntities];
        
        if ([self.delegate respondsToSelector:@selector(composeInputViewMessageDidChange:)]) {
            [self.delegate composeInputViewMessageDidChange:textView];
        }
    }
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
    
    self.activeAttributedString = attributedText;
    self.textView.attributedText = self.activeAttributedString;
    
    // environment issue
    // -> set selected range using the range before updating the attributed text
    [self.textView setSelectedRange:s_range];
    
    // update height of the cell
    [self resize:true];
    
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
            if (cell.user) {
                NSString *usernameSelected = cell.user.attributes.identifier;
                
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
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
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

@end
