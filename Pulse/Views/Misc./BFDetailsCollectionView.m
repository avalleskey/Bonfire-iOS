//
//  BFDetailsCollectionView.m
//  Pulse
//
//  Created by Austin Valleskey on 4/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFDetailsCollectionView.h"
#import "KTCenterFlowLayout.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "BFAlertController.h"

#define BFDetail_PADDING_INSETS UIEdgeInsetsMake(10, 10, 10, 10)
#define BFDetail_FONT [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium]

@implementation BFDetailsCollectionView

- (id)init {
    self = [super initWithFrame:CGRectZero collectionViewLayout:[BFDetailsCollectionView layout]];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame collectionViewLayout:[BFDetailsCollectionView layout]];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _details = @[];
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.dataSource = self;
    self.clipsToBounds = false;
    [self registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"detailIdentifier"];
}

+ (KTCenterFlowLayout *)layout {
    KTCenterFlowLayout *detailsLayout = [[KTCenterFlowLayout alloc] init];
    detailsLayout.minimumLineSpacing = 8.f;
    detailsLayout.minimumInteritemSpacing = 8.f;
    return detailsLayout;
}

- (void)setDetails:(NSArray<BFDetailItem *> *)details {
    if (details != _details) {
        _details = details;
        
        [self reloadData];
        [self layoutSubviews];
        
        // resize to fit
        CGFloat heightDifference = self.collectionViewLayout.collectionViewContentSize.height - self.frame.size.height;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y - heightDifference, self.frame.size.width, self.collectionViewLayout.collectionViewContentSize.height);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.details.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"detailIdentifier" forIndexPath:indexPath];
    
    if (cell.tag != 1) {
        cell.tag = 1;
        cell.clipsToBounds = false;
        cell.contentView.backgroundColor = [UIColor bonfireDetailColor];
        /*cell.contentView.layer.borderColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5].CGColor;
        cell.contentView.layer.borderWidth = 1.f;*/
        cell.contentView.clipsToBounds = false;
//        [cell.contentView setElevation:1];
        cell.contentView.layer.cornerRadius = cell.frame.size.height / 2;
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(BFDetail_PADDING_INSETS.left, BFDetail_PADDING_INSETS.top, 16, 16)];
        iconView.tag = 10;
        iconView.contentMode = UIViewContentModeCenter;
        [cell.contentView addSubview:iconView];
        
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconView.frame.origin.x + iconView.frame.size.width + 6, 0, 0, cell.contentView.frame.size.height)];
        valueLabel.tag = 20;
        valueLabel.font = BFDetail_FONT;
        valueLabel.textColor = [UIColor bonfirePrimaryColor];
        [cell.contentView addSubview:valueLabel];
    }
    
    BFDetailItem *item = [self.details objectAtIndex:indexPath.item];
    
    UIImageView *iconView = [cell.contentView viewWithTag:10];
    if (item.type == BFDetailItemTypePrivacyPublic) {
        iconView.image = [[UIImage imageNamed:@"details_label_public"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypePrivacyPrivate) {
        iconView.image = [[UIImage imageNamed:@"details_label_private"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeMembers ||
             item.type == BFDetailItemTypeSubscribers) {
        iconView.image = [[UIImage imageNamed:@"details_label_members"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeLocation) {
        iconView.image = [[UIImage imageNamed:@"details_label_location"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeWebsite) {
        iconView.image = [[UIImage imageNamed:@"details_label_link"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeSourceLink ||
             item.type == BFDetailItemTypeSourceUser) {
        iconView.image = [[UIImage imageNamed:@"details_label_source"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeSourceLink_Feed ||
             item.type == BFDetailItemTypeSourceUser_Feed) {
        iconView.image = [[UIImage imageNamed:@"details_label_feed"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypePostNotificationsOn) {
        iconView.image = [[UIImage imageNamed:@"details_label_notifications--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypePostNotificationsOff) {
        iconView.image = [[UIImage imageNamed:@"details_label_notifications_off--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeEdit) {
        iconView.image = [[UIImage imageNamed:@"details_label_edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeCreatedAt ||
             item.type == BFDetailItemTypeJoinedAt) {
        iconView.image = [[UIImage imageNamed:@"details_label_calendar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.type == BFDetailItemTypeMatureContent) {
        iconView.image = [[UIImage imageNamed:@"details_label_flag"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    iconView.tintColor = [UIColor bonfireSecondaryColor];
    
    UILabel *valueLabel = [cell.contentView viewWithTag:20];
    valueLabel.text = [item prettyValue];
    CGFloat labelWidth = [valueLabel.text boundingRectWithSize:CGSizeMake(200, 36) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:BFDetail_FONT} context:nil].size.width;
    valueLabel.frame = CGRectMake(valueLabel.frame.origin.x, 0, labelWidth, cell.contentView.frame.size.height);
    
    if (item.selectable) {
        valueLabel.textColor = self.tintColor;
    }
    else {
        valueLabel.textColor = [UIColor bonfirePrimaryColor];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BFDetailItem *item = [self.details objectAtIndex:indexPath.item];
    NSString *label = [item prettyValue];
    
    CGFloat width = BFDetail_PADDING_INSETS.left + (16 + (label.length > 0 ? 6 : 0)) + BFDetail_PADDING_INSETS.right;
    
    if (label.length > 0) {
        CGFloat labelWidth = [label boundingRectWithSize:CGSizeMake(200, 36) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:BFDetail_FONT} context:nil].size.width;
        width += labelWidth;
    }
    
    return CGSizeMake(width, BFDetail_PADDING_INSETS.top + 16 + BFDetail_PADDING_INSETS.bottom);
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    BFDetailItem *item = [self.details objectAtIndex:indexPath.item];
    
    if (item.selectable) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.contentView.backgroundColor = [UIColor bonfireDetailHighlightedColor];
        } completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    BFDetailItem *item = [self.details objectAtIndex:indexPath.item];
    
    if (item.selectable) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.contentView.backgroundColor = [UIColor bonfireDetailColor];
        } completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BFDetailItem *item = [self.details objectAtIndex:indexPath.item];
    
    if (!item.selectable) return;
    
    if (item.action) {
        item.action();
    }
    else {
        if (item.type == BFDetailItemTypeWebsite ||
            item.type == BFDetailItemTypeSourceLink) {
            NSString *link = item.value;
            
            if (link.length == 0) return;
            
            [Launcher openURL:item.value];
            return;
        }
    }
}

@end

@implementation BFDetailItem

- (id)initWithType:(BFDetailItemType)type value:(NSString *)value action:(void (^_Nullable)(void))action {
    self = [self init];
    if (self) {
        _type = type;
        _value = value;
        
        if (action) {
            _action = action;
        }
        else if (type == BFDetailItemTypeMatureContent) {
            // standardized handler
            _action = ^{
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Mature Content" message:@"This Camp has an 18+ age restriction because it includes alcohol or drugs, is sexual in nature, or other age-restricted content." preferredStyle:BFAlertControllerStyleActionSheet];
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancelActionSheet];
                
                [actionSheet show];
            };
        }
        
        _selectable = (_action ||
                       _type == BFDetailItemTypeWebsite ||
                       _type == BFDetailItemTypeSourceLink);
    }
    return self;
}

- (NSNumberFormatter *)decimalStyleNumberFormatter {
    static NSNumberFormatter *_sharedDecimalStyleNumberFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDecimalStyleNumberFormatter = [NSNumberFormatter new];
        [_sharedDecimalStyleNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    });
        
    return _sharedDecimalStyleNumberFormatter;
}

- (NSString *)prettyValue {
    NSString *prettyValue = self.value;
    if (self.type == BFDetailItemTypeWebsite) {
        prettyValue = [prettyValue stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        prettyValue = [prettyValue stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        
        return prettyValue;
    }
    else if (self.type == BFDetailItemTypeMembers ||
             self.type == BFDetailItemTypeSubscribers) {
        NSInteger memberCount = [(prettyValue?prettyValue:@"0") integerValue];
        
        prettyValue = [Camp memberCountTieredRepresentationFromInteger:memberCount];
        
        if (self.type == BFDetailItemTypeMembers) {
            prettyValue = [prettyValue stringByAppendingString:[NSString stringWithFormat:@" %@", ([prettyValue isEqualToString:@"1"] ? @"camper" : @"campers")]];
        }
        else if (self.type == BFDetailItemTypeSubscribers) {
            prettyValue = [prettyValue stringByAppendingString:[NSString stringWithFormat:@" %@", ([prettyValue isEqualToString:@"1"] ? @"subscriber" : @"subscribers")]];
        }
        
        return prettyValue;
    }
    else if (self.type == BFDetailItemTypeSourceLink ||
             self.type == BFDetailItemTypeSourceLink_Feed) {
        NSURL *url = [NSURL URLWithString:prettyValue];
        prettyValue = url.host;
        
        if (url.path) {
            [prettyValue stringByAppendingString:url.path];
        }
        
        if (prettyValue.length > 4 && [[prettyValue substringToIndex:4] isEqualToString:@"www."]) {
            prettyValue = [prettyValue substringFromIndex:4];
        }
        
        prettyValue = [@"by " stringByAppendingString:prettyValue];
                
        return prettyValue;
    }
    else if (self.type == BFDetailItemTypeSourceUser ||
             self.type == BFDetailItemTypeSourceUser_Feed) {
        prettyValue = [@"by @" stringByAppendingString:prettyValue];
                
        return prettyValue;
    }
    else if (self.type == BFDetailItemTypeCreatedAt ||
             self.type == BFDetailItemTypeJoinedAt) {
        if (prettyValue.length == 0) {
            prettyValue = @"";
        }
        
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *date = [inputFormatter dateFromString:prettyValue];
        
        if (date) {
            // iMessage like date
            NSDateFormatter *outputFormatter_part1 = [[NSDateFormatter alloc] init];
            [outputFormatter_part1 setDateFormat:@"MMMM yyyy"];
            
            prettyValue = [outputFormatter_part1 stringFromDate:date];
            
            if (self.type == BFDetailItemTypeCreatedAt) {
                prettyValue = [@"Created " stringByAppendingString:prettyValue];
            }
            else if (self.type == BFDetailItemTypeJoinedAt) {
                prettyValue = [@"Joined " stringByAppendingString:prettyValue];
            }
        }
        
        return prettyValue;
    }
    else if (self.type == BFDetailItemTypeMatureContent) {
        return prettyValue ? prettyValue : @"Mature";
    }
    
    return prettyValue;
}

@end
