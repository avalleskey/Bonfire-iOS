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
#import <UITextView+Placeholder.h>
#import "Launcher.h"
#import "SimpleNavigationController.h"
#import "SearchResultCell.h"
#import <UIImageView+WebCache.h>

#define composeToolbarHeight 56

@interface ComposeViewController () {
    NSInteger maxLength;
    NSInteger maxImages;
}

@end

@implementation ComposeViewController {
    NSString *defaultPlaceholder;
    NSString *mediaPlaceholder;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor bonfireBrand];
    self.view.tintColor = [UIColor bonfireBrand];
    
    maxLength = [Session sharedInstance].defaults.post.maxLength;
    
    [self setupContent];
    [self setupTitleView];
    [self setupToolbar];
    
    [self checkRequirements];
    
    [(SimpleNavigationController *)self.navigationController setShadowVisibility:false withAnimation:NO];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.navigationItem.rightBarButtonItem.tag != 1) {
        self.navigationItem.rightBarButtonItem.tag = 1;
        [self.navigationItem.rightBarButtonItem.customView bk_removeAllBlockObservers];
        [self.navigationItem.rightBarButtonItem.customView bk_whenTapped:^{
            [self postMessage];
        }];
    }
    if (self.navigationItem.rightBarButtonItem.tag != 1) {
        self.navigationItem.rightBarButtonItem.tag = 1;
        [self.navigationItem.rightBarButtonItem.customView bk_removeAllBlockObservers];
        [self.navigationItem.rightBarButtonItem.customView bk_whenTapped:^{
            if (self.textView.text.length > 0 || self.media.count > 0) {
                // confirm discard changes
                UIAlertController *confirmActionSheet = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure you want to discard your post?" preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Discard Post" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [confirmActionSheet dismissViewControllerAnimated:YES completion:nil];
                    
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }];
                [confirmActionSheet addAction:confirmAction];
                
                UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [confirmActionSheet addAction:cancelActionSheet];
                
                [self.navigationController presentViewController:confirmActionSheet animated:YES completion:nil];
            }
            else {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
    
    maxImages = (self.replyingTo == nil ? 4 : 1);
    if (self.replyingTo) {
        self.navigationItem.titleView = nil;
        self.title = @"Reply";
        [self updatePlaceholder];
    }
    else if (self.postingIn) {
        [self updateTitleText:self.postingIn.attributes.details.title];
        self.titleLabel.alpha = 1;
        [self updatePlaceholder];
        self.titleAvatar.room = self.postingIn;
    }
    else {
        [self updateTitleText:@"Select a Camp"];
        self.titleLabel.alpha = 0.75;
        self.titleAvatar.room = nil;
    }
    
    [self checkRequirements];
    
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.textView resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupContent {
    self.contentScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.contentScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.contentScrollView.contentInset = UIEdgeInsetsMake(0, 0, composeToolbarHeight, 0);
    self.contentScrollView.userInteractionEnabled = true;
    self.contentScrollView.layer.masksToBounds = false;
    [self.contentScrollView bk_whenTapped:^{
        if (![self.textView isFirstResponder]) {
            [self.textView becomeFirstResponder];
        }
    }];
    self.contentScrollView.delegate = self;
    [self.view addSubview:self.contentScrollView];
    
    // add profile picture
    self.contentAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 12, 44, 44)];
    User *user = [Session sharedInstance].currentUser;
    self.contentAvatar.user = user;
    self.contentAvatar.userInteractionEnabled = true;
    [self.contentAvatar bk_whenTapped:^{
        [self openPrivacySelector];
    }];
    [self.contentScrollView addSubview:self.contentAvatar];
    
    CGFloat textViewX = self.contentAvatar.frame.origin.x + self.contentAvatar.frame.size.width + 14;
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(textViewX, 22, self.view.frame.size.width - textViewX - 16, 26)];
    self.textView.scrollEnabled = false;
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightRegular];
    self.textView.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.contentInset = UIEdgeInsetsZero;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.text = self.prefillMessage;
    self.textView.tintColor = self.view.tintColor;
    [self updatePlaceholder];
    [self.contentScrollView addSubview:self.textView];
    [self.textView becomeFirstResponder];
    
    self.mediaScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y, self.contentScrollView.frame.size.width, 140 - 16)];
    self.mediaScrollView.hidden = true;
    self.mediaScrollView.contentInset = UIEdgeInsetsMake(0, self.textView.frame.origin.x, 0, 16);
    self.mediaScrollView.showsHorizontalScrollIndicator = false;
    self.mediaScrollView.showsVerticalScrollIndicator = false;
    [self.contentScrollView addSubview:self.mediaScrollView];
    
    // Stack View
    self.media = [[NSMutableArray alloc] init];
    self.mediaContainerView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.mediaScrollView.frame.size.width, self.mediaScrollView.frame.size.height)];
    self.mediaContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    self.mediaContainerView.axis = UILayoutConstraintAxisHorizontal;
    self.mediaContainerView.distribution = UIStackViewDistributionFill;
    self.mediaContainerView.alignment = UIStackViewAlignmentFill;
    self.mediaContainerView.spacing = 6;
    
    self.mediaContainerView.translatesAutoresizingMaskIntoConstraints = false;
    [self.mediaScrollView addSubview:self.mediaContainerView];
    
    [self.mediaContainerView.leadingAnchor constraintEqualToAnchor:_mediaScrollView.leadingAnchor].active = true;
    [self.mediaContainerView.trailingAnchor constraintEqualToAnchor:_mediaScrollView.trailingAnchor].active = true;
    [self.mediaContainerView.bottomAnchor constraintEqualToAnchor:_mediaScrollView.bottomAnchor].active = true;
    [self.mediaContainerView.topAnchor constraintEqualToAnchor:_mediaScrollView.topAnchor].active = true;
    [self.mediaContainerView.heightAnchor constraintEqualToAnchor:_mediaScrollView.heightAnchor].active = true;
    
    [self resizeTextView];
}
- (void)setupTitleView {
    self.titleView = [[TappableView alloc] initWithFrame:CGRectMake(0, 0, 102, 40)];
    self.titleView.userInteractionEnabled = true;
    [self.titleView bk_whenTapped:^{
        [self openPrivacySelector];
    }];
    
    self.titleAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.titleView.frame.size.width / 2 - 12, 0, 24, 24)];
    self.titleAvatar.user = [Session sharedInstance].currentUser;
    [self.titleView addSubview:self.titleAvatar];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, 102, 13)];
    self.titleLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightMedium];
    [self.titleView addSubview:self.titleLabel];

    self.titleCaret = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.titleLabel.frame.origin.y + 1, 7, 12)];
    self.titleCaret.image = [UIImage imageNamed:@"navCaretIcon"];
    self.titleCaret.contentMode = UIViewContentModeCenter;
    [self.titleView addSubview:self.titleCaret];
    
    self.navigationItem.titleView = self.titleView;
}
- (void)updateTitleText:(NSString *)newTitleText {
    if (!self.replyingTo) {
        self.title = @"";
        self.titleLabel.text = newTitleText;
        
        CGSize titleSize = [newTitleText boundingRectWithSize:CGSizeMake(self.view.frame.size.width - (86 * 2) - 11, self.titleLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.titleLabel.font} context:nil].size;
        self.titleLabel.frame = CGRectMake(0, self.titleLabel.frame.origin.y, titleSize.width, self.titleLabel.frame.size.height);
        self.titleCaret.frame = CGRectMake(self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width + 4, self.titleCaret.frame.origin.y, self.titleCaret.frame.size.width, self.titleCaret.frame.size.height);
        
        self.titleView.frame = CGRectMake(0, 0, self.titleLabel.frame.origin.x + self.titleLabel.frame.size.width + 4, self.titleView.frame.size.height); // add the 6 at the end to visually balance the weight
        self.navigationItem.titleView = nil;
        self.navigationItem.titleView = self.titleView;
        self.titleAvatar.center = CGPointMake(self.titleView.frame.size.width / 2, self.titleAvatar.center.y);
    }
}
- (void)privacySelectionDidChange:(Room * _Nullable)selection {
    self.postingIn = selection;
    
    if (self.postingIn) {
        [self updateTitleText:self.postingIn.attributes.details.title];
        self.titleLabel.alpha = 1;
        self.titleAvatar.room = self.postingIn;
    }
    else {
        [self updateTitleText:@"Select a Camp"];
        self.titleLabel.alpha = 0.75;
        self.titleAvatar.room = nil;
    }
    [self updatePlaceholder];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"contentOffset.y: %f", scrollView.contentOffset.y);
    
    if (scrollView == self.contentScrollView) {
        if (scrollView.contentOffset.y > -1 * self.contentScrollView.safeAreaInsets.top) {
            [(SimpleNavigationController *)self.navigationController setShadowVisibility:TRUE withAnimation:TRUE];
        }
        else {
            [(SimpleNavigationController *)self.navigationController setShadowVisibility:FALSE withAnimation:TRUE];
        }
    }
}

- (void)setupToolbar {
    CGFloat toolbarHeight = composeToolbarHeight + [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    
    self.toolbarView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.toolbarView.frame = CGRectMake(0, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width, toolbarHeight);
    self.toolbarView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    [self.view addSubview:self.toolbarView];
    
    self.takePictureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.takePictureButton setImage:[UIImage imageNamed:@"composeToolbarTakePicture"] forState:UIControlStateNormal];
    self.takePictureButton.frame = CGRectMake(8, 0, 60, composeToolbarHeight);
    self.takePictureButton.contentMode = UIViewContentModeCenter;
    self.takePictureButton.tintColor = [UIColor bonfireGrayWithLevel:700];
    [self.takePictureButton bk_whenTapped:^{
        [self takePicture:nil];
    }];
    [self.toolbarView.contentView addSubview:self.takePictureButton];
    
    self.choosePictureButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.choosePictureButton setImage:[UIImage imageNamed:@"composeToolbarChoosePicture"] forState:UIControlStateNormal];
    self.choosePictureButton.frame = CGRectMake(self.takePictureButton.frame.origin.x + self.takePictureButton.frame.size.width, 0, 58, composeToolbarHeight);
    self.choosePictureButton.contentMode = UIViewContentModeCenter;
    self.choosePictureButton.tintColor = [UIColor bonfireGrayWithLevel:700];
    [self.choosePictureButton bk_whenTapped:^{
        [self chooseFromLibrary:nil];
    }];
    [self.toolbarView.contentView addSubview:self.choosePictureButton];
    
    self.characterCountdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 50 - 16, 0, 50, self.takePictureButton.frame.size.height)];
    self.characterCountdownLabel.textAlignment = NSTextAlignmentRight;
    self.characterCountdownLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightRegular];
    self.characterCountdownLabel.textColor = [UIColor bonfireGray];
    self.characterCountdownLabel.text = [NSString stringWithFormat:@"%ld", maxLength];
    [self.toolbarView.contentView addSubview:self.characterCountdownLabel];
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.textView]) {
        [self resizeTextView];
        
        [self checkRequirements];
        
        // update countdown
        NSInteger charactersLeft = maxLength - self.textView.text.length;
        self.characterCountdownLabel.text = [NSString stringWithFormat:@"%ld", charactersLeft];
        
        if (charactersLeft <= 20) {
            self.characterCountdownLabel.textColor = [UIColor bonfireRed];
        }
        else {
            self.characterCountdownLabel.textColor = [UIColor bonfireGray];
        }
    }
}
- (void)checkRequirements {
    if ((self.textView.text.length > 0 || self.media.count > 0) && !self.navigationItem.rightBarButtonItem.enabled) {
        // enable share button
        self.navigationItem.rightBarButtonItem.enabled = true;
    }
    else if (self.textView.text.length == 0 && self.media.count == 0 && self.navigationItem.rightBarButtonItem.enabled) {
        // disable share button
        self.navigationItem.rightBarButtonItem.enabled = false;
    }
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return textView.text.length + (text.length - range.length) <= maxLength;
}
- (void)resizeTextView {
    NSString *text = self.textView.text.length > 0 ? self.textView.text : self.textView.placeholder;
    CGSize textViewSize = [text boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textView.font} context:nil].size;
    
    CGRect textViewFrame = self.textView.frame;
    textViewFrame.size.height = textViewSize.height;
    self.textView.frame = textViewFrame;
    
    [self updateAttachmentPositions];
    [self updateContentSize];
}
- (void)updateAttachmentPositions {
    // media scroll view
    CGRect mediaScrollViewFrame = self.mediaScrollView.frame;
    mediaScrollViewFrame.origin.y = self.textView.frame.origin.y + self.textView.frame.size.height + 16;
    self.mediaScrollView.frame = mediaScrollViewFrame;
}
- (void)updateContentSize {
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
}
- (void)updatePlaceholder {
    NSString *publicPostPlaceholder = @"Share with everyone...";
    
    // TODO: Add support for replies
    
    defaultPlaceholder = @"";
    if (self.replyingTo != nil) {
        defaultPlaceholder = @"Add a reply...";
    }
    else if (self.postingIn == nil) {
        defaultPlaceholder = publicPostPlaceholder;
    }
    else if (self.postingIn != nil) {
        if (self.postingIn.attributes.details.title == nil) {
            defaultPlaceholder = @"Share something...";
        }
        else {
            defaultPlaceholder = [[Session sharedInstance].defaults.post.composePrompt stringByReplacingOccurrencesOfString:@"{group_name}" withString:self.postingIn.attributes.details.title];
        }
    }
    mediaPlaceholder = @"Add caption or Post";
    
    if (self.media.count == 0) {
        self.textView.placeholder = defaultPlaceholder;
    }
    else {
        self.textView.placeholder = mediaPlaceholder;
    }
    
    if (self.textView.text.length == 0) {
        [self resizeTextView];
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
    
    CGFloat newToolbarY = self.contentScrollView.frame.size.height - self.currentKeyboardHeight - self.toolbarView.frame.size.height + bottomPadding - (self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
    
    self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, newToolbarY, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
    
    CGFloat contentInset = (self.contentScrollView.frame.size.height - self.toolbarView.frame.origin.y) - bottomPadding;
    self.contentScrollView.contentInset = UIEdgeInsetsMake(0, 0, contentInset, 0);
    self.contentScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, contentInset, 0);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.toolbarView.frame = CGRectMake(self.toolbarView.frame.origin.x, self.contentScrollView.frame.size.height - self.toolbarView.frame.size.height, self.toolbarView.frame.size.width, self.toolbarView.frame.size.height);
        
        self.contentScrollView.contentInset = UIEdgeInsetsMake(0, 0, self.toolbarView.frame.size.height, 0);
        self.contentScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.toolbarView.frame.size.height, 0);
    } completion:nil];
}

- (void)takePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}
- (void)chooseFromLibrary:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // output image
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    [self addImageToMediaTray:chosenImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self.textView becomeFirstResponder];
}

- (void)addImageToMediaTray:(UIImage *)image {
    if (self.media.count == 0) {
        [self showMediaTray];
    }
    //View 1
    UIImageView *view = [[UIImageView alloc] init];
    view.userInteractionEnabled = true;
    view.backgroundColor = [UIColor blueColor];
    view.layer.cornerRadius = 14.f;
    view.layer.masksToBounds = true;
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.image = image;
    view.layer.borderWidth = 1.f;
    view.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    [view.heightAnchor constraintEqualToConstant:100].active = true;
    [view.widthAnchor constraintEqualToAnchor:view.heightAnchor multiplier:(image.size.width/image.size.height)].active = true;
    [_mediaContainerView addArrangedSubview:view];
    
    UIButton *removeImageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    removeImageButton.backgroundColor = [UIColor whiteColor];
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
    
    [self.media addObject:@{@"image": image, @"view": view}];
    [self updateToolbarAvailability];
    
    [self.mediaScrollView setContentOffset:CGPointMake(self.mediaScrollView.contentSize.width - self.mediaScrollView.frame.size.width, 0)];
}
- (void)removeImageAtIndex:(NSInteger)index {
    NSDictionary *item = [self.media objectAtIndex:index];
    
    UIView *view = item[@"view"];
    view.userInteractionEnabled = false;
    
    [self.media removeObject:item];
    [self updateToolbarAvailability];
    if (self.media.count == 0) {
        // no items left
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideMediaTray];
        });
    }
    [UIView animateWithDuration:(self.media.count == 0 ? 0 : 0.2f) delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        view.transform = CGAffineTransformMakeScale(0.6, 0.6);
        view.alpha = 0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
}

- (void)updateToolbarAvailability {
    self.takePictureButton.enabled = (self.media.count < maxImages);
    self.choosePictureButton.enabled = (self.media.count < maxImages);
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.takePictureButton.alpha = (self.takePictureButton.enabled ? 1 : 0.25);
        self.choosePictureButton.alpha = (self.choosePictureButton.enabled ? 1 : 0.25);
    } completion:nil];
}

- (void)showMediaTray {
    _textView.placeholder = mediaPlaceholder;
    
    self.mediaScrollView.alpha = 1;
    self.mediaScrollView.hidden = false;
    self.mediaScrollView.userInteractionEnabled = true;
    
    [self checkRequirements];
    [self updateContentSize];
}
- (void)hideMediaTray {
    _textView.placeholder = defaultPlaceholder;
    
    self.mediaScrollView.userInteractionEnabled = false;
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.mediaScrollView.alpha = 0;
    } completion:^(BOOL finished) {
        self.mediaScrollView.hidden = true;
        [self updateContentSize];
    }];
    
    if (self.textView.text.length == 0) {
        [self checkRequirements];
    }
    
    // remove all media views
    for (NSDictionary *dictionary in self.media) {
        UIView *view = dictionary[@"view"];
        [view removeFromSuperview];
    }
}

- (void)postMessage {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.textView.text;
    if (message.length > 0) {
        [params setObject:message forKey:@"message"];
    }
    if (self.media.count > 0) {
        [params setObject:self.media forKey:@"images"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"images"]) {
        // meets min. requirements
        [[Session sharedInstance] createPost:params postingIn:self.postingIn replyingTo:self.replyingTo];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)openPrivacySelector {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.currentSelection = self.postingIn;
    sitvc.delegate = self;
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:sitvc];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    [self.navigationController presentViewController:simpleNav animated:YES completion:nil];
}

@end
