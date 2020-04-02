//
//  BFPostAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFPostAttachmentView.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "Launcher.h"
#import "NSURL+WebsiteTypeValidation.h"
#import <SafariServices/SafariServices.h>
#import "PostCell.h"

#define POST_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(12, 12, 12, 12)
#define POST_ATTACHMENT_HEADER_HEIGHT 24
#define POST_ATTACHMENT_MESSAGE_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular]
#define POST_ATTACHMENT_MESSAGE_TRUNCATION_LIMIT 75

@implementation BFPostAttachmentView

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [super setup];
    
//    self.backgroundColor = [UIColor clearColor];
    
    self.avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(POST_ATTACHMENT_EDGE_INSETS.left, POST_ATTACHMENT_EDGE_INSETS.top, POST_ATTACHMENT_HEADER_HEIGHT, POST_ATTACHMENT_HEADER_HEIGHT)];
    self.avatarView.openOnTap = true;
    [self.contentView addSubview:self.avatarView];
    
    // display name
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.text = @"Link Title";
    self.textLabel.font = POST_ATTACHMENT_MESSAGE_FONT;
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.textLabel];
    
    // username
    self.creatorLabel = [[UILabel alloc] init];
    self.creatorLabel.text = @"Link detail";
    self.creatorLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.creatorLabel.textAlignment = NSTextAlignmentLeft;
    self.creatorLabel.textColor = [UIColor bonfireSecondaryColor];
    self.creatorLabel.numberOfLines = 1;
    self.creatorLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.creatorLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.creatorLabel];
    
    // username
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.text = @"";
    self.dateLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.dateLabel.textAlignment = NSTextAlignmentLeft;
    self.dateLabel.textColor = [UIColor bonfireSecondaryColor];
    self.dateLabel.numberOfLines = 1;
    self.dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.dateLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.dateLabel];
    
    self.imagesView = [[PostImagesView alloc] init];
    [self.contentView addSubview:self.imagesView];
    
    [self bk_whenTapped:^{
        [Launcher openPost:self.post withKeyboard:false];
    }];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets offset = POST_ATTACHMENT_EDGE_INSETS;
    
    CGFloat yBottom = offset.top;
    
    CGSize dateLabelSize = [self.dateLabel.text boundingRectWithSize:CGSizeMake(100, self.avatarView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.dateLabel.font} context:nil].size;
    self.dateLabel.frame = CGRectMake(self.frame.size.width - offset.right - ceilf(dateLabelSize.width), yBottom, ceilf(dateLabelSize.width), self.avatarView.frame.size.height);
    self.creatorLabel.frame = CGRectMake(self.avatarView.frame.origin.x + self.avatarView.frame.size.width + 8, yBottom, (self.dateLabel.frame.origin.x - 8) - (self.avatarView.frame.origin.x + self.avatarView.frame.size.width + 8), self.avatarView.frame.size.height);
    yBottom = self.creatorLabel.frame.origin.y + self.creatorLabel.frame.size.height + 8;
    
    if (self.textLabel.text.length > 0) {
        CGFloat textLabelHeight = ceilf([self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - offset.left - offset.right, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.textLabel.font} context:nil].size.height);
        self.textLabel.frame = CGRectMake(offset.left, yBottom, self.frame.size.width - offset.left - offset.right, textLabelHeight);
        yBottom = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 8;
    }
    
    BOOL hasImage = self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        self.imagesView.frame = CGRectMake(0, yBottom, self.frame.size.width, imageHeight);
        
//         yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    
    [self resizeHeight];
}

- (void)resizeHeight {
    CGFloat height = 0;
    if (self.post) height = [BFPostAttachmentView heightForPost:self.post width:self.frame.size.width];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    self.contentView.frame = self.bounds;
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        // set avatar
        if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn) {
            if (self.avatarView.camp != _post.attributes.postedIn) {
                self.avatarView.camp = _post.attributes.postedIn;
            }
        }
        else {
            if (self.avatarView.user != _post.attributes.creator && self.avatarView.bot != _post.attributes.creator) {
                if (_post.attributes.creatorUser) {
                    self.avatarView.user = _post.attributes.creatorUser;
                }
                else if (_post.attributes.creatorBot) {
                    self.avatarView.bot = _post.attributes.creatorBot;
                }
            }
        }
        
        // set creator label
        self.creatorLabel.attributedText = [PostCell attributedCreatorStringForPost:self.post includeTimestamp:false showCamptag:true primaryColor:nil];
        
        // set date created
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *new = [NSDate date];
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *comps = [gregorian components: NSCalendarUnitDay
                                               fromDate: [formatter dateFromString:_post.attributes.createdAt]
                                                 toDate: new
                                                options: 0];
        
        if ([comps day] < 3) {
            self.dateLabel.text = [NSDate mysqlDatetimeFormattedAsTimeAgo:_post.attributes.createdAt withForm:TimeAgoShortForm];
        }
        else {
            self.dateLabel.text = @"";
        }
        
        // set message
        self.textLabel.text = [BFPostAttachmentView attachmentMessageForPost:post];
        
        // set image attachments
        self.imagesView.containerView.layer.cornerRadius = 0;
        if (self.post.attributes.attachments.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.attachments.media];
        }
        else if (self.post.attributes.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.media];
        }
        else {
            [self.imagesView setMedia:@[]];
        }
        
        [self resizeHeight];
    }
}

- (CGFloat)height {
    return [BFPostAttachmentView heightForPost:self.post width:self.frame.size.width];
}

+ (NSString *)attachmentMessageForPost:(Post *)post {
    if (post.attributes.simpleMessage.length > 0) {
        return [post.attributes simpleMessageWithTruncationLimit:POST_ATTACHMENT_MESSAGE_TRUNCATION_LIMIT];
    }
    
    NSInteger attachments = 0;
    NSString *attachmentName = @"";
    if (post.attributes.attachments.media.count > 0) {
        attachments += post.attributes.attachments.media.count;
    }
    if (post.attributes.attachments.link > 0) {
        attachments++;
        attachmentName = @"Link";
    }
    if (post.attributes.attachments.camp > 0) {
        attachments++;
        attachmentName = @"Camp";
    }
    if (post.attributes.attachments.user > 0) {
        attachments++;
        attachmentName = @"User";
    }
    if (post.attributes.attachments.post > 0) {
        attachments++;
        attachmentName = @"Attachment";
    }
    
    if (attachments == 1 && attachmentName.length > 0) {
        NSString *detail = @"";
        if (post.attributes.attachments.link > 0) {
            detail = post.attributes.attachments.link.attributes.canonicalUrl;
        }
        else if (post.attributes.attachments.camp > 0) {
            detail = post.attributes.attachments.camp.attributes.title;
        }
        else if (post.attributes.attachments.user > 0) {
            detail = [NSString stringWithFormat:@"%@ (@%@)", post.attributes.attachments.user.attributes.displayName, post.attributes.attachments.user.attributes.identifier];
        }
        else if (post.attributes.attachments.post > 0) {
            detail = @"1 Post";
        }
        
        if (detail.length > 0) {
            attachmentName = [attachmentName stringByAppendingString:@": "];
            attachmentName = [attachmentName stringByAppendingString:detail];
        }
        
        return attachmentName;
    }
    else if (attachments > 1) {
        return [NSString stringWithFormat:@"%lu Attachments", (long)attachments];
    }
    else {
        return @"";
    }
}

+ (CGFloat)heightForPost:(Post *)post width:(CGFloat)width {
    CGFloat height = POST_ATTACHMENT_EDGE_INSETS.top;
    
    height += POST_ATTACHMENT_HEADER_HEIGHT;
    
    // message label
    NSString *message = [BFPostAttachmentView attachmentMessageForPost:post];
    if (message.length > 0) {
        CGFloat textLabelHeight = ceilf([message boundingRectWithSize:CGSizeMake(width - POST_ATTACHMENT_EDGE_INSETS.left - POST_ATTACHMENT_EDGE_INSETS.right, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: POST_ATTACHMENT_MESSAGE_FONT} context:nil].size.height);
        height += 8 + textLabelHeight;
    }

    // image
    BOOL hasImage = (post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0);
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        height += 8 + imageHeight; // 6 above if text, 8 if not
    }
    else {
        height +=  POST_ATTACHMENT_EDGE_INSETS.bottom;
    }
        
    return height;
}


- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.post) {
        NSMutableArray *actions = [NSMutableArray new];
        if ([self.post.attributes.context.post.permissions canReply]) {
            NSMutableArray *actions = [NSMutableArray new];
            UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                wait(0, ^{
                    [Launcher openComposePost:self.post.attributes.postedIn inReplyTo:self.post withMessage:nil media:nil  quotedObject:nil];
                });
            }];
            [actions addObject:replyAction];
        }
        
        if (self.post.attributes.postedIn) {
            UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                wait(0, ^{
                    Camp *camp = [[Camp alloc] initWithDictionary:[self.post.attributes.postedIn toDictionary] error:nil];
                    
                    [Launcher openCamp:camp];
                });
            }];
            [actions addObject:openCamp];
        }
        
        UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
            [Launcher sharePost:self.post];
        }];
        [actions addObject:shareViaAction];
        
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
        
        PostViewController *postVC = [Launcher postViewControllerForPost:self.post];
        postVC.isPreview = true;
        
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:self.post.identifier previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.post) {
                [Launcher openPost:self.post withKeyboard:false];
            }
        });
    }];
}

@end
