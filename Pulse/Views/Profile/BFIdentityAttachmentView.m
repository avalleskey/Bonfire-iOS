//
//  BFUserAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFIdentityAttachmentView.h"
#import "BFStyles.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "NSString+Validation.h"

#define USER_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(24, 24, 24, 24)

// avatar macros
#define USER_ATTACHMENT_AVATAR_SIZE 72
#define USER_ATTACHMENT_AVATAR_BOTTOM_PADDING 10
// display name macros
#define USER_ATTACHMENT_DISPLAY_NAME_FONT [UIFont systemFontOfSize:20.f weight:UIFontWeightHeavy]
#define USER_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING 3
// username macros
#define USER_ATTACHMENT_USERNAME_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightBold]
#define USER_ATTACHMENT_USERNAME_BOTTOM_PADDING 8
// bio macros
#define USER_ATTACHMENT_BIO_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium]
#define USER_ATTACHMENT_BIO_BOTTOM_PADDING 12
// details macros
#define USER_ATTACHMENT_DETAILS_EDGE_INSETS UIEdgeInsetsMake(12, 24, 10, 24)

@implementation BFIdentityAttachmentView

- (instancetype)initWithIdentity:(Identity *)identity frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.identity = identity;
    }
    
    return self;
}

- (void)setup {
    [super setup];
    
    self.headerBackdrop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, USER_ATTACHMENT_EDGE_INSETS.top + USER_ATTACHMENT_AVATAR_SIZE * .6)];
    self.headerBackdrop.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.headerBackdrop];
    
    self.avatarContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - USER_ATTACHMENT_AVATAR_SIZE / 2 - 4, USER_ATTACHMENT_EDGE_INSETS.top - 4, USER_ATTACHMENT_AVATAR_SIZE + 8, USER_ATTACHMENT_AVATAR_SIZE + 8)];
    self.avatarContainerView.backgroundColor = [UIColor contentBackgroundColor];
    self.avatarContainerView.layer.cornerRadius = self.avatarContainerView.frame.size.width / 2;
    self.avatarContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.avatarContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    self.avatarContainerView.layer.shadowRadius = 1.f;
    self.avatarContainerView.layer.shadowOpacity = 0.12;
    [self.contentView addSubview:self.avatarContainerView];
    
    self.avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, USER_ATTACHMENT_AVATAR_SIZE, USER_ATTACHMENT_AVATAR_SIZE)];
    self.avatarView.userInteractionEnabled = false;
    [self.avatarContainerView addSubview:self.avatarView];
    
    // display name
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.font = USER_ATTACHMENT_DISPLAY_NAME_FONT;
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.textLabel];
    
    // username
    self.detailTextLabel = [[UILabel alloc] init];
    self.detailTextLabel.font = [UIFont systemFontOfSize:USER_ATTACHMENT_USERNAME_FONT.pointSize weight:UIFontWeightHeavy];
    self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
    self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
    self.detailTextLabel.numberOfLines = 0;
    self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.detailTextLabel];
    
    // bio
    self.bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48, 18)];
    self.bioLabel.font = USER_ATTACHMENT_BIO_FONT;
    self.bioLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.textColor = [UIColor bonfirePrimaryColor];
    self.bioLabel.numberOfLines = 0;
    self.bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.contentView addSubview:self.bioLabel];
    
    self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - USER_ATTACHMENT_EDGE_INSETS.left - USER_ATTACHMENT_EDGE_INSETS.right, 16)];
    self.detailsCollectionView.tintColor = [UIColor bonfirePrimaryColor];
    self.detailsCollectionView.userInteractionEnabled = false;
    [self.contentView addSubview:self.detailsCollectionView];
    
    [self bk_whenTapped:^{
        [Launcher openIdentity:self.identity];
    }];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    }
    
    self.showBio = true;
    self.showDetails = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomY = 0;
    CGFloat maxWidth = self.frame.size.width - (USER_ATTACHMENT_EDGE_INSETS.left + USER_ATTACHMENT_EDGE_INSETS.right);
    
    self.headerBackdrop.frame = CGRectMake(0, 0, self.frame.size.width, self.headerBackdrop.frame.size.height);
    
    self.avatarContainerView.frame = CGRectMake(self.frame.size.width / 2 - self.avatarContainerView.frame.size.width / 2, self.avatarContainerView.frame.origin.y, self.avatarContainerView.frame.size.width, self.avatarContainerView.frame.size.height);
    bottomY = self.avatarContainerView.frame.origin.y + self.avatarContainerView.frame.size.height - 4; // subtract the white border
    
    // text label
    if (self.textLabel.attributedText.length > 0) {
        CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
            self.textLabel.frame = CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, bottomY + USER_ATTACHMENT_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(textLabelRect.size.height));
            bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    }
    
    // detail text label
    if (self.detailTextLabel.text.length > 0) {
        CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
        self.detailTextLabel.frame = CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, bottomY + USER_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    }
    
    BOOL hasBio = self.bioLabel.attributedText.length > 0;
    self.bioLabel.hidden = !self.showBio || !hasBio;
    if (hasBio) {
        CGRect bioLabelRect = [self.bioLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.bioLabel.frame = CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, bottomY + USER_ATTACHMENT_USERNAME_BOTTOM_PADDING, maxWidth, ceilf(bioLabelRect.size.height));
        bottomY = self.bioLabel.frame.origin.y + self.bioLabel.frame.size.height;
    }
    
    BOOL hasDetails = self.detailsCollectionView.details.count > 0;
    self.detailsCollectionView.hidden = !self.showDetails || !hasDetails;
    if (hasDetails) {
        self.detailsCollectionView.frame = CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, bottomY + (hasBio ? USER_ATTACHMENT_BIO_BOTTOM_PADDING : USER_ATTACHMENT_USERNAME_BOTTOM_PADDING), self.frame.size.width - (USER_ATTACHMENT_EDGE_INSETS.left + USER_ATTACHMENT_EDGE_INSETS.right), self.detailsCollectionView.collectionViewLayout.collectionViewContentSize.height);
        // bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
}

- (void)setIdentity:(Identity *)identity {
    if (identity != _identity) {
        _identity = identity;
                
        self.tintColor = [UIColor fromHex:identity.attributes.color];
        
        self.headerBackdrop.backgroundColor = self.tintColor;
        if ([identity.type isEqualToString:@"user"]) {
            self.avatarView.user = (User *)identity;
        }
        else if ([identity.type isEqualToString:@"bot"]) {
            self.avatarView.bot = (Bot *)identity;
        }
                        
        // display name
        self.textLabel.hidden = (identity.attributes.displayName.length == 0);
        if ([self.textLabel isHidden]) {
            self.textLabel.text = @"";
        }
        else {
            NSString *displayName = identity.attributes.displayName;
                        
            NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:USER_ATTACHMENT_DISPLAY_NAME_FONT}];
            if ([identity isVerified]) {
                NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
                [spacer addAttribute:NSFontAttributeName value:USER_ATTACHMENT_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
                [displayNameAttributedString appendAttributedString:spacer];
                
                // verified icon ☑️
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
                [attachment setBounds:CGRectMake(0, roundf(USER_ATTACHMENT_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
                
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                [displayNameAttributedString appendAttributedString:attachmentString];
            }
            self.textLabel.attributedText = displayNameAttributedString;
        }

        
        // username
        self.detailTextLabel.textColor = [UIColor fromHex:identity.attributes.color adjustForOptimalContrast:true];
        self.detailTextLabel.hidden = (identity.attributes.identifier.length == 0);
        if ([self.detailTextLabel isHidden]) {
            self.detailTextLabel.text = @"";
        }
        else {
            self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", identity.attributes.identifier];
        }
        
        // bio
        self.bioLabel.hidden = !self.showBio || (identity.attributes.bio.length == 0);
        if ([self.bioLabel isHidden]) {
            self.bioLabel.text = @"";
        }
        else {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:identity.attributes.bio];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:USER_ATTACHMENT_BIO_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.bioLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.bioLabel.attributedText = attrString;
        }
        
        self.detailsCollectionView.hidden = !self.showDetails;
        if (![self.detailsCollectionView isHidden]) {
            self.detailsCollectionView.details = [BFIdentityAttachmentView detailsForIdentity:self.identity];
        }
    }
}

- (CGFloat)height {
    return [BFIdentityAttachmentView heightForIdentity:self.identity width:self.frame.size.width];
}

+ (NSArray<BFDetailItem *> *)detailsForIdentity:(Identity *)identity {
    NSMutableArray *details = [[NSMutableArray alloc] init];
    if (identity.attributes.location.displayText.length > 0) {
        BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeLocation value:identity.attributes.location.displayText action:nil];
        [details addObject:item];
    }
    if (identity.attributes.website.displayUrl.length > 0) {
        BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeWebsite value:identity.attributes.website.displayUrl action:^{
            [Launcher openURL:identity.attributes.website.actionUrl];
        }];
        [details addObject:item];
    }
    
    return [details copy];
}

+ (CGFloat)heightForIdentity:(Identity *)identity width:(CGFloat)width showBio:(BOOL)showBio showDetails:(BOOL)showDetails {
    if (!identity) {
        return 0;
    }
    
    CGFloat maxWidth = (width - (USER_ATTACHMENT_EDGE_INSETS.left + USER_ATTACHMENT_EDGE_INSETS.right));
    
    // knock out all the required bits first
    CGFloat height = USER_ATTACHMENT_EDGE_INSETS.top + USER_ATTACHMENT_AVATAR_SIZE + USER_ATTACHMENT_AVATAR_BOTTOM_PADDING;
    
    // display name
    if (identity.attributes.displayName.length > 0) {
        NSString *displayName = identity.attributes.displayName;
        
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:USER_ATTACHMENT_DISPLAY_NAME_FONT}];
           if ([identity isVerified]) {
               NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
               [spacer addAttribute:NSFontAttributeName value:USER_ATTACHMENT_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
               [displayNameAttributedString appendAttributedString:spacer];
               
               // verified icon ☑️
               NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
               attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
               [attachment setBounds:CGRectMake(0, roundf(USER_ATTACHMENT_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
               
               NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
               [displayNameAttributedString appendAttributedString:attachmentString];
           }

           CGRect textLabelRect = [displayNameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
           CGFloat userDisplayNameHeight = ceilf(textLabelRect.size.height);
           height += userDisplayNameHeight;
    }
    
    if (identity.attributes.identifier.length > 0) {
        CGRect usernameRect = [[NSString stringWithFormat:@"@%@", identity.attributes.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:USER_ATTACHMENT_USERNAME_FONT} context:nil];
        CGFloat usernameHeight = ceilf(usernameRect.size.height);
        height += USER_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING + usernameHeight;
    }
    
    if (showBio && identity.attributes.bio.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:identity.attributes.bio];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:USER_ATTACHMENT_BIO_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect bioRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat bioHeight = ceilf(bioRect.size.height);
        height += USER_ATTACHMENT_USERNAME_BOTTOM_PADDING + bioHeight;
    }
    
    if (showDetails && identity.identifier.length > 0) {
        NSArray *details = [self detailsForIdentity:identity];
        
        if (details.count > 0) {
            [[self staticDetailsCollectionView] setDetails:details];
                        
            height += (identity.attributes.bio.length > 0 ? USER_ATTACHMENT_BIO_BOTTOM_PADDING : USER_ATTACHMENT_USERNAME_BOTTOM_PADDING) + [self staticDetailsCollectionView].frame.size.height;
        }
    }
    
    return height + USER_ATTACHMENT_EDGE_INSETS.bottom;
}

+ (BFDetailsCollectionView *)staticDetailsCollectionView {
    static BFDetailsCollectionView *_staticDetailsCollectionView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _staticDetailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(USER_ATTACHMENT_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - USER_ATTACHMENT_EDGE_INSETS.left - USER_ATTACHMENT_EDGE_INSETS.right, 16)];
        _staticDetailsCollectionView.delegate = _staticDetailsCollectionView;
        _staticDetailsCollectionView.dataSource = _staticDetailsCollectionView;
    });
        
    return _staticDetailsCollectionView;
}

+ (CGFloat)heightForIdentity:(Identity *)identity width:(CGFloat)width {
    return [self heightForIdentity:identity width:width showBio:true showDetails:true];
}

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.identity) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        if ([self.identity isKindOfClass:[User class]]) {
            ProfileViewController *profileVC = [Launcher profileViewControllerForUser:(User *)self.identity];
            profileVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"user_preview" previewProvider:^(){
                return profileVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
        else {
            ProfileViewController *profileVC = [Launcher profileViewControllerForBot:(Bot *)self.identity];
            profileVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"bot_preview" previewProvider:^(){
                return profileVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.identity) {
                [Launcher openIdentity:self.identity];
            }
        });
    }];
}

@end
