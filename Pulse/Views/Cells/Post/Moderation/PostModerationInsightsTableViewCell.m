//
//  PostModerationInsightsTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostModerationInsightsTableViewCell.h"
#import "Session.h"
#import "Launcher.h"

#import "UIColor+Palette.h"
#import "InsightTableViewCell.h"

#define padding 24

@interface PostModerationInsightsTableViewCell () <BFComponentProtocol>

@end

@implementation PostModerationInsightsTableViewCell

static NSString * const insightCellReuseIdentifier = @"InsightCell";

static NSString * const blankCellIdentifier = @"BlankCell";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clipsToBounds = false;
    self.contentView.clipsToBounds = false;
    self.backgroundColor = [UIColor clearColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _tableView = [[UITableView alloc] initWithFrame:self.frame style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [_tableView registerClass:[InsightTableViewCell class] forCellReuseIdentifier:insightCellReuseIdentifier];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.clipsToBounds = false;
    _tableView.scrollEnabled = false;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.contentView addSubview:_tableView];
    
    self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
    self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self addSubview:self.lineSeparator];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.insights count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [InsightTableViewCell height];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // add reply upsell cell
    InsightTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:insightCellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[InsightTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:insightCellReuseIdentifier];
    }
    
    if (self.insights.count > indexPath.row) {
        NSDictionary *insight = self.insights[indexPath.row];
        
        // text
        cell.textLabel.text = insight[@"text"];
        
        // image (optional)
        if (insight[@"image"]) {
            cell.imageView.image = [[UIImage imageNamed:insight[@"image"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imageView.tintColor = [UIColor bonfireSecondaryColor];
        }
        else {
            cell.imageView.image = nil;
        }
        
        // detail (optional)
        if (insight[@"detail"]) {
            cell.detailTextLabel.text = insight[@"dtail"];
        }
        
        cell.lineSeparator.hidden = indexPath.row == self.insights.count-1;
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.tableView.frame = CGRectMake(0, 0, self.frame.size.width, self.tableView.contentSize.height);
    [self.tableView reloadData];
    
    if (![self.lineSeparator isHidden]) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        self.insights = [PostModerationInsightsTableViewCell insightsFromPost:post];
    }
}

+ (NSArray *)insightsFromPost:(Post *)post {
    NSMutableArray *i = [NSMutableArray new];
    
    // time ago
    NSDictionary *timeAgo = @{
        @"text": @"Posted 2 hours ago",
        @"detail": @"24 views",
        @"image": @"moderationInsightTimeAgo"
    };
    [i addObject:timeAgo];
    
    // report count
    NSDictionary *reportCount = @{
        @"text": @"Reported by {x} campers",
        @"image": @"moderationInsightReported"
    };
    [i addObject:reportCount];
    
    // explicit?
    BOOL explicit = true;
    if (explicit) {
        NSDictionary *explicitLanguage = @{
            @"text": @"Contains explicit language",
            @"image": @"moderationInsightExplicit"
        };
        [i addObject:explicitLanguage];
    }
    
    // mature reference?
    BOOL matureReference = true;
    if (matureReference) {
        NSDictionary *mature = @{
            @"text": @"References drugs, alcohol, or sex",
            @"image": @"moderationInsightMatureReference"
        };
        [i addObject:mature];
    }
    
    return i;
}
- (void)setInsights:(NSArray *)insights {
    if (insights != _insights) {
        _insights = insights;
        
        [self.tableView reloadData];
        [self layoutSubviews];
    }
}

+ (CGFloat)heightForPost:(Post *)post {
    NSArray *insights = [self insightsFromPost:post];
    
    return insights.count * [InsightTableViewCell height];
}

@end
