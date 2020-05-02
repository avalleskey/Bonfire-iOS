//
//  JKRichTextView.m
//  Pods
//
//  Created by Jackie CHEUNG on 14-6-2.
//
//

#import "JKRichTextView.h"
#import "JKRegularExpressionParser.h"
#import "JKDelegateProxy.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <SafariServices/SafariServices.h>

NSString * const JKRichTextViewDetectedDataHandlerAttributeName = @"JKRichTextViewDetectedDataHandlerAttributeName";

static CGSize const JKRichTextViewInvalidedIntrinsicContentSize = (CGSize){-1, -1};

@class JKRichTextViewDelegateHandler;
@interface JKRichTextView () <UIContextMenuInteractionDelegate>
@property (nonatomic, strong) NSMutableArray *dataDetectionHandlers;
@property (nonatomic, strong) JKDelegateProxy *delegateProxy;
@property (nonatomic, strong) JKRichTextViewDelegateHandler *delegateHandler;

@property (nonatomic) CGSize intrinsicContentSize;

@property (nonatomic, strong) NSMutableDictionary *defaultTypingAttributes;
@end

@interface JKRichTextViewDelegateHandler : NSObject<UITextViewDelegate>
@property (nonatomic, weak) JKRichTextView *textView;
@end

@implementation JKRichTextView
#pragma mark - Init
- (id)init {
    self = [super init];
    if(self) {
        [self _setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self _setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if(self) {
        [self _setup];
    }
    return self;
}

- (UITextRange *)selectedTextRange {
    if (self.selectable) {
        [super selectedTextRange];
    }
    
    return nil;
}

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text {
    return false;
}

- (void)_setup {
    [super setDelegate:(id <UITextViewDelegate>)self.delegateProxy];
    self.shouldPassthoughUntouchableText = true;
    self.shouldAutoDetectDataWhileEditing = NO;
    self.backgroundColor = [UIColor clearColor];
    self.selectable = true;
    self.editable = false;
    self.clipsToBounds = false;
    self.userInteractionEnabled = true;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.tintColor = [UIColor linkColor];
    self.inputView = [[UIView alloc] initWithFrame:CGRectZero];
    [self setDataDetectorTypes:UIDataDetectorTypeNone];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (sender.state == UIGestureRecognizerStateEnded) {
            NSURL *linkAtPoint = [self linkAtPoint:location];
            
            if (!linkAtPoint) return;
                        
            if ([Configuration isBonfireURL:linkAtPoint]) {
                [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] openURL:linkAtPoint options:@{}];
            }
            else {
                [Launcher openURL:linkAtPoint.absoluteString];
            }
        }
    }];
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - UIGestureRecognizerDelegate
- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    NSURL *link = [self linkAtPoint:location];
    
    UIContextMenuConfiguration *configuration;
    if (link) {
        id linkObject = [Configuration objectFromBonfireURL:link];
        
        if (linkObject) {
            if ([linkObject isKindOfClass:[User class]]) {
                User *user = (User *)linkObject;
                
                UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
                
                ProfileViewController *profileVC = [Launcher profileViewControllerForUser:user];
                profileVC.isPreview = true;
                
                configuration = [UIContextMenuConfiguration configurationWithIdentifier:link previewProvider:^(){return profileVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            }
            else if ([linkObject isKindOfClass:[Camp class]]) {
                Camp *camp = (Camp *)linkObject;
                
                UIAction *shareViaAction = [UIAction actionWithTitle:@"Share Camp via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                    [Launcher shareCamp:camp];
                }];
                
                UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[shareViaAction]];
                
                CampViewController *campVC = [Launcher campViewControllerForCamp:camp];
                campVC.isPreview = true;
                
                configuration = [UIContextMenuConfiguration configurationWithIdentifier:link previewProvider:^(){
                    return campVC;
                } actionProvider:^(NSArray* suggestedAction){
                    return menu;
                }];
            }
            else if ([linkObject isKindOfClass:[Post class]]) {
                Post *post = (Post *)linkObject;
                
                NSMutableArray *actions = [NSMutableArray new];
                if ([post.attributes.context.post.permissions canReply]) {
                    NSMutableArray *actions = [NSMutableArray new];
                    UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                        wait(0, ^{
                            [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                        });
                    }];
                    [actions addObject:replyAction];
                }
                
                if (post.attributes.postedIn) {
                    UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                        wait(0, ^{
                            Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                            
                            [Launcher openCamp:camp];
                        });
                    }];
                    [actions addObject:openCamp];
                }
                
                UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                    [Launcher sharePost:post];
                }];
                [actions addObject:shareViaAction];
                
                UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
                
                PostViewController *postVC = [Launcher postViewControllerForPost:post];
                postVC.isPreview = true;
                
                configuration = [UIContextMenuConfiguration configurationWithIdentifier:link previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            }
        }
        else {
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];

            SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:link];
            safariVC.preferredBarTintColor = [UIColor contentBackgroundColor];
            safariVC.preferredControlTintColor = [UIColor bonfirePrimaryColor];

            configuration = [UIContextMenuConfiguration configurationWithIdentifier:link previewProvider:^(){
                return safariVC;
            } actionProvider:^(NSArray* suggestedAction){
                return menu;
            }];
        }
        
        if (configuration) {
            return configuration;
        }
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            NSURL *link = (NSURL *)configuration.identifier;
            if (link) {
                if ([Configuration isBonfireURL:link]) {
                    [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication] openURL:link options:@{}];
                }
                else {
                    [Launcher openURL:link.absoluteString];
                }
            }
        });
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    NSRange range = [self rangeOfLinkAtPoint:[touch locationInView:self]];
//    if (range.length > 0) {
//        CAShapeLayer *shapeView = [[CAShapeLayer alloc] init];
//        shapeView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
//        UIBezierPath *path = [self pathForRange:range];
//        NSLog(@"path: %@", path);
//        path.lineJoinStyle = kCGLineJoinRound;
//        [path fill];
//        [path stroke];
//        [shapeView setPath:path.CGPath];
//        [[self layer] addSublayer:shapeView];
//    }
    
    return (range.location == 0 && range.length > 0);
}
- (BOOL)containslinkAtPoint:(CGPoint)point {
    return [self linkAtPoint:point] != nil;
}
- (NSURL *)linkAtPoint:(CGPoint)point {
    // Stop quickly if none of the points to be tested are in the bounds.
    if (!CGRectContainsPoint(CGRectInset(self.bounds, -5.f, -5.f), point)) {
        return nil;
    }
    
    NSURL *result = [self linkAtCharacterIndex:[self characterIndexAtPoint:point]];
    
    return result;
}

- (NSInteger)characterIndexAtPoint:(CGPoint)pos
{
    NSUInteger characterIndex = [self.layoutManager characterIndexForPoint:pos inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
    return characterIndex;
}

- (NSRange)rangeOfLinkAtPoint:(CGPoint)pos {
    NSInteger idx = [self characterIndexAtPoint:pos];
    
    // Do not enumerate if the index is outside of the bounds of the text.
    if (!NSLocationInRange((NSUInteger)idx, NSMakeRange(0, self.attributedText.length))) {
        return NSMakeRange(0, 0);
    }

    NSRange range;
    [self.textStorage attribute:NSLinkAttributeName atIndex:idx effectiveRange:&range];
    
    if (range.location >= 0 && range.length > 0 && range.location + range.length <= self.attributedText.string.length) {
        return range;
    }
    
    return NSMakeRange(0, 0);
}

- (NSURL *)linkAtCharacterIndex:(NSInteger)idx {
    // Do not enumerate if the index is outside of the bounds of the text.
    if (!NSLocationInRange((NSUInteger)idx, NSMakeRange(0, self.attributedText.length))) {
        return nil;
    }

    NSRange range;
        
    NSURL *url = [self.textStorage attribute:NSLinkAttributeName atIndex:idx effectiveRange:&range];
    return url;
}

#pragma mark -

- (JKRichTextViewDelegateHandler *)delegateHandler {
    if (!_delegateHandler) {
        _delegateHandler = [[JKRichTextViewDelegateHandler alloc] init];
        _delegateHandler.textView = self;
    }
    return _delegateHandler;
}

- (JKDelegateProxy *)delegateProxy {
    if (!_delegateProxy) {
        _delegateProxy = [[JKDelegateProxy alloc] initWithDelegateProxy:self.delegateHandler];
    }
    return _delegateProxy;
}

- (void)setDelegate:(id<UITextViewDelegate>)delegate {
    if(delegate == self.delegateProxy) return;
    
    [self.delegateProxy removeDelegateTarget:[self.delegateProxy allDelegateTargets].lastObject];
    if(delegate) [self.delegateProxy addDelegateTarget:delegate];
    
    [super setDelegate:(id<UITextViewDelegate>)self.delegateProxy];
}

- (BOOL)becomeFirstResponder {
    return false;
}

- (NSMutableDictionary *)defaultTypingAttributes {
    if (!_defaultTypingAttributes) {
        _defaultTypingAttributes = [NSMutableDictionary dictionary];
    }
    return _defaultTypingAttributes;
}

#pragma mark -

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    self.defaultTypingAttributes[NSFontAttributeName] = font;
}

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    self.defaultTypingAttributes[NSForegroundColorAttributeName] = textColor;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = textAlignment;
    self.defaultTypingAttributes[NSParagraphStyleAttributeName] = [paragraphStyle copy];
}

- (void)resetTypingAttributes {
    self.typingAttributes = [self.defaultTypingAttributes copy];
}

- (void)setText:(NSString *)text {
    if(self.defaultAttributesUnaffectable) [self resetTypingAttributes];
    [super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.intrinsicContentSize = JKRichTextViewInvalidedIntrinsicContentSize;
    [super setAttributedText:attributedText];
    [self startDataDetection];
}

- (NSMutableArray *)dataDetectionHandlers {
    if (!_dataDetectionHandlers) {
        _dataDetectionHandlers = [NSMutableArray array];
    }
    return _dataDetectionHandlers;
}

- (NSArray *)allDataDetectionHandlers {
    return [self.dataDetectionHandlers copy];
}

- (void)addDataDetectionHandler:(id<JKRichTextViewDataDetectionHandler>)handler {
    NSAssert([handler conformsToProtocol:@protocol(JKRichTextViewDataDetectionHandler)], @"[ERROR] handler MUST confirm to 'JKRichTextViewDataDetectionHandler' Protocol.");
    
    if([handler conformsToProtocol:@protocol(JKRichTextViewDataDetectionHandler)] && ![self.dataDetectionHandlers containsObject:handler])
        [self.dataDetectionHandlers addObject:handler];
}

- (void)removeDataDetectionHandler:(id<JKRichTextViewDataDetectionHandler>)handler {
    [self.dataDetectionHandlers removeObject:handler];
}

- (void)startDataDetection {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    for (id<JKRichTextViewDataDetectionHandler>handler in self.allDataDetectionHandlers) {
        if([handler respondsToSelector:@selector(detectionAsynchronized)] && handler.detectionAsynchronized)
            [self performSelector:@selector(startDataDetectionWithHandler:) withObject:handler afterDelay:0];
        else
            [self startDataDetectionWithHandler:handler];
    }
}

- (void)startDataDetectionWithHandler:(id<JKRichTextViewDataDetectionHandler>) handler{
    if(!handler.regularExpression) return;
    
    __weak __typeof(&*self)weakSelf = self;
    [JKRegularExpressionParser enumerateMatchesInString:self.text
                                   withRegularExpressions:@[handler.regularExpression]
                                     options:NSMatchingReportCompletion
                                       range:NSMakeRange(0, self.text.length)
                                  usingBlock:^(JKRegularExpressionResult *result, NSMatchingFlags flags, BOOL *stop) {
                                      
                                      [handler textView:weakSelf didDetectData:result];
                                      
                                      [weakSelf.textStorage beginEditing];
                                      [weakSelf.textStorage addAttribute:JKRichTextViewDetectedDataHandlerAttributeName
                                                            value:NSStringFromClass([handler class])
                                                            range:result.range];
                                      [weakSelf.textStorage endEditing];
                                      
                                      if([handler respondsToSelector:@selector(textView:shouldStopDetectingData:)])
                                          *stop = [handler textView:weakSelf shouldStopDetectingData:result];
                                  }];
    
}

- (void)invalidateIntrinsicContentSize {
    [super invalidateIntrinsicContentSize];
    _intrinsicContentSize = JKRichTextViewInvalidedIntrinsicContentSize;
}

- (CGSize)intrinsicContentSize {
    if(CGSizeEqualToSize(_intrinsicContentSize, JKRichTextViewInvalidedIntrinsicContentSize)) {
        CGSize intrinsicContentSize = [self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
        _intrinsicContentSize = intrinsicContentSize;
    }
    return _intrinsicContentSize;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = [super pointInside:point withEvent:event];
    
    if(!self.shouldPassthoughUntouchableText || !pointInside) return pointInside;
    
    CGFloat fraction = 0;
    NSUInteger characterIndex = [self.layoutManager characterIndexForPoint:point inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:&fraction];
    
    NSURL *linkURL;
    if (characterIndex < self.attributedText.length) {
        linkURL = [self.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:NULL];
    }
    else {
        return NO;
    }
    
    pointInside = linkURL && fraction != 1 ? YES : NO;
    
    return pointInside;
}

@end


@implementation JKRichTextView (Formation)

- (void)setCustomLink:(NSURL *)url forTextAtRange:(NSRange)textRange {
    NSParameterAssert(url);
    
    if(self.text.length < NSMaxRange(textRange)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"[ERROR] JKRichTextView Cannot set custom link because text range(%@) is out of range.", NSStringFromRange(textRange)]}];
        return;
    }
    
//    NSLog(@"set custom link for url (%@) at text range (%lu, %lu)", url.absoluteString, (long)textRange.location, (long)textRange.length);
    
    [self.textStorage beginEditing];
    [self.textStorage addAttribute:NSLinkAttributeName value:url range:textRange];
    [self.textStorage endEditing];
}

- (void)insertImage:(UIImage *)image size:(CGSize)size atIndex:(NSUInteger)index {
    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithData:nil ofType:nil];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, 0, size.width, size.height);
    
    [self insertTextAttachment:attachment atIndex:index baselineAjustment:YES];
}

- (void)insertTextAttachment:(NSTextAttachment *)attachment atIndex:(NSUInteger)index {
    [self insertTextAttachment:attachment atIndex:index baselineAjustment:NO];
}

- (void)insertTextAttachment:(NSTextAttachment *)attachment atIndex:(NSUInteger)index baselineAjustment:(BOOL)baselineAjustment {
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    [self insertTextAttachment:attachment forAttributedText:attributedText atIndex:index baselineAjustment:baselineAjustment];
    [super setAttributedText:attributedText];
}

- (void)insertTextAttachment:(NSTextAttachment *)attachment forAttributedText:(NSMutableAttributedString *)attributedText atIndex:(NSUInteger)index baselineAjustment:(BOOL)baselineAjustment {
    NSParameterAssert(attachment);
    
    NSAttributedString *imageAttributeString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributedText insertAttributedString:imageAttributeString atIndex:index];
    
    if(baselineAjustment && self.text.length >= index+1) {
        /** Adjust attribute text baseline offset, because attachment image will be inserted above baseline.  */
        UIFont *font = [attributedText attribute:NSFontAttributeName atIndex:index effectiveRange:NULL];
        [attributedText addAttribute:NSBaselineOffsetAttributeName value:@(font.descender) range:NSMakeRange(index, 1)];
    }
}

- (void)replaceCharacterAtRange:(NSRange)textRange withTextAttachment:(NSTextAttachment *)attachment {
    [self replaceCharacterAtRange:textRange withTextAttachment:attachment baselineAjustment:NO];
}

- (void)replaceCharacterAtRange:(NSRange)textRange withTextAttachment:(NSTextAttachment *)attachment baselineAjustment:(BOOL)baselineAjustment {
    NSParameterAssert(attachment);
    
    NSMutableString *replacementString = [NSMutableString string];
    
    NSString *attachmentReplacementString = [NSString stringWithFormat:@"%C", (unichar)NSAttachmentCharacter];
    for (NSUInteger index = 0; index < textRange.length-1; index++) [replacementString appendString:attachmentReplacementString];
    
    [self.textStorage beginEditing];
    [self.textStorage replaceCharactersInRange:textRange withString:replacementString];
    
    [self insertTextAttachment:attachment forAttributedText:self.textStorage atIndex:textRange.location baselineAjustment:baselineAjustment];
    [self.textStorage endEditing];
}

@end


@implementation JKRichTextViewDelegateHandler
#pragma mark - UITextvViewDelegate
- (BOOL)textView:(JKRichTextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return false;
    
    
    NSString *handlerClassName = [textView.attributedText attribute:JKRichTextViewDetectedDataHandlerAttributeName atIndex:characterRange.location effectiveRange:nil];
        
    if(!handlerClassName.length) return YES;
    
    for (id<JKRichTextViewDataDetectionHandler> handler in self.textView.dataDetectionHandlers) {
        if(![NSStringFromClass([handler class]) isEqualToString:handlerClassName]) continue;
        if([handler respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)])
            [handler textView:textView shouldInteractWithURL:URL inRange:characterRange];
        else
            [Launcher openURL:URL.absoluteString];
    }
    
    return NO;
}

- (BOOL)textView:(JKRichTextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return false;
}

- (void)textViewDidChange:(UITextView *)textView {
    if(self.textView.shouldAutoDetectDataWhileEditing) [self.textView startDataDetection];
}

@end

