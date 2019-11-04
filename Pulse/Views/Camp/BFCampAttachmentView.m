//
//  BFCampAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFCampAttachmentView.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "Launcher.h"

#define CAMP_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(24, 24, 16, 24)

// avatar macros
#define CAMP_ATTACHMENT_AVATAR_SIZE 72
#define CAMP_ATTACHMENT_AVATAR_BOTTOM_PADDING 10
// display name macros
#define CAMP_ATTACHMENT_DISPLAY_NAME_FONT [UIFont systemFontOfSize:20.f weight:UIFontWeightHeavy]
#define CAMP_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING 3
// username macros
#define CAMP_ATTACHMENT_USERNAME_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightBold]
#define CAMP_ATTACHMENT_USERNAME_BOTTOM_PADDING 8
// bio macros
#define CAMP_ATTACHMENT_DESCRIPTION_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium]
#define CAMP_ATTACHMENT_DESCRIPTION_BOTTOM_PADDING 12
#define CAMP_ATTACHMENT_DESCRIPTION_MAX_LENGTH 64
// details macros
#define CAMP_ATTACHMENT_DETAILS_EDGE_INSETS UIEdgeInsetsMake(12, 24, 10, 24)

@implementation BFCampAttachmentView

- (instancetype)initWithCamp:(Camp *)camp frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.camp = camp;
    }
    
    return self;
}

- (void)setup {
    [super setup];
    
    self.headerBackdrop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, CAMP_ATTACHMENT_EDGE_INSETS.top + CAMP_ATTACHMENT_AVATAR_SIZE / 2)];
    self.headerBackdrop.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.headerBackdrop];
    
    self.avatarContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - CAMP_ATTACHMENT_AVATAR_SIZE / 2 - 4, CAMP_ATTACHMENT_EDGE_INSETS.top - 4, CAMP_ATTACHMENT_AVATAR_SIZE + 8, CAMP_ATTACHMENT_AVATAR_SIZE + 8)];
    self.avatarContainerView.backgroundColor = [UIColor contentBackgroundColor];
    self.avatarContainerView.layer.cornerRadius = self.avatarContainerView.frame.size.width / 2;
    self.avatarContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.avatarContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    self.avatarContainerView.layer.shadowRadius = 1.f;
    self.avatarContainerView.layer.shadowOpacity = 0.12;
    [self.contentView addSubview:self.avatarContainerView];
        
    self.avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, CAMP_ATTACHMENT_AVATAR_SIZE, CAMP_ATTACHMENT_AVATAR_SIZE)];
    self.avatarView.userInteractionEnabled = false;
    [self.avatarContainerView addSubview:self.avatarView];
    
    // display name
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.font = CAMP_ATTACHMENT_DISPLAY_NAME_FONT;
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.textLabel];
    
    // username
    self.detailTextLabel = [[UILabel alloc] init];
    self.detailTextLabel.font = [UIFont systemFontOfSize:CAMP_ATTACHMENT_USERNAME_FONT.pointSize weight:UIFontWeightHeavy];
    self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
    self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
    self.detailTextLabel.numberOfLines = 0;
    self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.detailTextLabel];
    
    // bio
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48, 18)];
    self.descriptionLabel.font = CAMP_ATTACHMENT_DESCRIPTION_FONT;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.textColor = [UIColor bonfirePrimaryColor];
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.contentView addSubview:self.descriptionLabel];
    
    self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_ATTACHMENT_EDGE_INSETS.left - CAMP_ATTACHMENT_EDGE_INSETS.right, 16)];
    self.detailsCollectionView.tintColor = [UIColor bonfirePrimaryColor];
    self.detailsCollectionView.userInteractionEnabled = false;
    [self.contentView addSubview:self.detailsCollectionView];
    
    [self bk_whenTapped:^{
        [Launcher openCamp:self.camp];
    }];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    } else {
        // Fallback on earlier versions
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resizeHeight];
    
    CGFloat bottomY = 0;
    CGFloat maxWidth = self.frame.size.width - (CAMP_ATTACHMENT_EDGE_INSETS.left + CAMP_ATTACHMENT_EDGE_INSETS.right);
    
    self.headerBackdrop.frame = CGRectMake(0, 0, self.frame.size.width, self.headerBackdrop.frame.size.height);
    
    self.avatarContainerView.frame = CGRectMake(self.frame.size.width / 2 - self.avatarContainerView.frame.size.width / 2, self.avatarContainerView.frame.origin.y, self.avatarContainerView.frame.size.width, self.avatarContainerView.frame.size.height);
    bottomY = self.avatarContainerView.frame.origin.y + self.avatarContainerView.frame.size.height - 4;
    
    // text label
    if (self.textLabel.attributedText.length > 0) {
        CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
            self.textLabel.frame = CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, bottomY + CAMP_ATTACHMENT_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(textLabelRect.size.height));
            bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    }
    
    // detail text label
    if (self.detailTextLabel.text.length > 0) {
        CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
        self.detailTextLabel.frame = CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, bottomY + CAMP_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    }
    
    BOOL hasBio = self.descriptionLabel.attributedText.length > 0;
    self.descriptionLabel.hidden = !hasBio;
    if (hasBio) {
        CGRect bioLabelRect = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.descriptionLabel.frame = CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, bottomY + CAMP_ATTACHMENT_USERNAME_BOTTOM_PADDING, maxWidth, ceilf(bioLabelRect.size.height));
        bottomY = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    }
    
    BOOL hasDetails = self.detailsCollectionView.details.count > 0;
    self.detailsCollectionView.hidden = !hasDetails;
    if (hasDetails) {
        self.detailsCollectionView.frame = CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, bottomY + (hasBio ? CAMP_ATTACHMENT_DESCRIPTION_BOTTOM_PADDING : CAMP_ATTACHMENT_USERNAME_BOTTOM_PADDING), self.frame.size.width - (CAMP_ATTACHMENT_EDGE_INSETS.left + CAMP_ATTACHMENT_EDGE_INSETS.right), self.detailsCollectionView.collectionViewLayout.collectionViewContentSize.height);
        // bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
}

- (void)resizeHeight {
    CGFloat height = 0;
    if (self.camp) height = [BFCampAttachmentView heightForCamp:self.camp width:self.frame.size.width];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
                
        self.tintColor = [UIColor fromHex:camp.attributes.color];
        
        self.headerBackdrop.backgroundColor = self.tintColor;
                
        self.avatarView.camp = camp;
                        
        // display name
        self.textLabel.hidden = (camp.attributes.title.length == 0);
        if ([self.textLabel isHidden]) {
            self.textLabel.text = @"";
        }
        else {
            NSString *displayName = camp.attributes.title;
                        
            NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:CAMP_ATTACHMENT_DISPLAY_NAME_FONT}];
            self.textLabel.attributedText = displayNameAttributedString;
        }

        
        // username
        self.detailTextLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        self.detailTextLabel.hidden = (camp.attributes.identifier.length == 0);
        if ([self.detailTextLabel isHidden]) {
            self.detailTextLabel.text = @"";
        }
        else {
            self.detailTextLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
        }
        
        // bio
        self.descriptionLabel.hidden = (camp.attributes.theDescription.length == 0);
        if ([self.descriptionLabel isHidden]) {
            self.descriptionLabel.text = @"";
        }
        else {
            NSString *campDescription = camp.attributes.theDescription;
            if (campDescription.length > CAMP_ATTACHMENT_DESCRIPTION_MAX_LENGTH) {
                campDescription = [[[campDescription substringToIndex:CAMP_ATTACHMENT_DESCRIPTION_MAX_LENGTH] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@"... "];
            }
            
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:campDescription];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:CAMP_ATTACHMENT_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.descriptionLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.descriptionLabel.attributedText = attrString;
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        if (camp.attributes.identifier.length > 0 || camp.identifier.length > 0) {
            if (self.camp.attributes.visibility != nil) {
                BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:(camp.attributes.visibility.isPrivate ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(camp.attributes.visibility.isPrivate ? @"Private" : @"Public") action:nil];
                visibility.selectable = false;
                [details addObject:visibility];
            }
            
            if (self.camp.attributes.summaries.counts != nil) {
                BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
                members.selectable = false;
                [details addObject:members];
            }
        }
        
        self.detailsCollectionView.hidden = (details.count == 0);
        
        if (![self.detailsCollectionView isHidden]) {
            self.detailsCollectionView.details = [details copy];
        }
        
        [self resizeHeight];
    }
}

+ (CGFloat)heightForCamp:(Camp *)camp  width:(CGFloat)width {
    if (!camp) {
        return 0;
    }
    
    CGFloat maxWidth = (width - (CAMP_ATTACHMENT_EDGE_INSETS.left + CAMP_ATTACHMENT_EDGE_INSETS.right));
    
    // knock out all the required bits first
    CGFloat height = CAMP_ATTACHMENT_EDGE_INSETS.top + CAMP_ATTACHMENT_AVATAR_SIZE + CAMP_ATTACHMENT_AVATAR_BOTTOM_PADDING;
    
    // display name
    if (camp.attributes.title.length > 0) {
        NSString *displayName = camp.attributes.title;
        
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:CAMP_ATTACHMENT_DISPLAY_NAME_FONT}];

        CGRect textLabelRect = [displayNameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
        CGFloat userDisplayNameHeight = ceilf(textLabelRect.size.height);
        height += userDisplayNameHeight;
    }
    
    if (camp.attributes.identifier.length > 0) {
        CGRect usernameRect = [[NSString stringWithFormat:@"#%@", camp.attributes.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:CAMP_ATTACHMENT_USERNAME_FONT} context:nil];
        CGFloat usernameHeight = ceilf(usernameRect.size.height);
        height += CAMP_ATTACHMENT_DISPLAY_NAME_BOTTOM_PADDING + usernameHeight;
    }
    
    if (camp.attributes.theDescription.length > 0) {
        NSString *campDescription = camp.attributes.theDescription;
        if (campDescription.length > CAMP_ATTACHMENT_DESCRIPTION_MAX_LENGTH) {
            campDescription = [[[campDescription substringToIndex:CAMP_ATTACHMENT_DESCRIPTION_MAX_LENGTH] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@"... "];
        }
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:campDescription];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:CAMP_ATTACHMENT_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect bioRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat bioHeight = ceilf(bioRect.size.height);
        height += CAMP_ATTACHMENT_USERNAME_BOTTOM_PADDING + bioHeight;
    }
    
    if (camp.attributes.visibility != nil || camp.attributes.summaries.counts != nil) {
        CGFloat detailsHeight = 0;
        NSMutableArray *details = [[NSMutableArray alloc] init];
        
        if (camp.attributes.visibility != nil) {
            BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:(camp.attributes.visibility.isPrivate ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(camp ? @"Private" : @"Public") action:nil];
            [details addObject:visibility];
        }
        
        if (camp.attributes.summaries.counts != nil) {
            BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
            [details addObject:members];
        }
                
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_ATTACHMENT_EDGE_INSETS.left, 0, width - CAMP_ATTACHMENT_EDGE_INSETS.left - CAMP_ATTACHMENT_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            detailsHeight = detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
            NSLog(@"details height: %f", detailsHeight);
            height = height + (camp.attributes.theDescription.length > 0 ? CAMP_ATTACHMENT_DESCRIPTION_BOTTOM_PADDING : CAMP_ATTACHMENT_USERNAME_BOTTOM_PADDING) + detailsHeight;
        }
    }
    
    NSLog(@"camp height: %f", height + CAMP_ATTACHMENT_EDGE_INSETS.bottom);
    
    return height + CAMP_ATTACHMENT_EDGE_INSETS.bottom;
}

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.camp) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        CampViewController *campVC = [Launcher campViewControllerForCamp:self.camp];
        campVC.isPreview = true;
        
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"camp_preview" previewProvider:^(){return campVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.camp) {
                [Launcher openCamp:self.camp];
            }
        });
    }];
}

@end
