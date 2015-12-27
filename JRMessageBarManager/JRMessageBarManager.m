//
//  JRMessageBarManager.m
//  JRMessageBarManager
//
//  Created by wxiao on 15/12/27.
//  Copyright © 2015年 wxiao. All rights reserved.
//

#import "JRMessageBarManager.h"
#import <QuartzCore/QuartzCore.h>

// ====================================================================== Numerics (TWMessageBarStyleSheet)
CGFloat const kTWMessageBarStyleSheetMessageBarAlpha = 0.96f;

// ====================================================================== Numerics (TWMessageView)
CGFloat const kTWMessageViewBarPadding			= 10.0f;
CGFloat const kTWMessageViewIconSize			= 36.0f;
CGFloat const kTWMessageViewTextOffset			= 2.0f;
NSUInteger const kTWMessageViewiOS7Identifier	= 7;

// ====================================================================== Numerics (TWMessageBarManager)
CGFloat const kTWMessageBarManagerDisplayDelay				= 3.0f;
CGFloat const kTWMessageBarManagerDismissAnimationDuration	= 0.25f;
CGFloat const kTWMessageBarManagerPanVelocity				= 0.2f;
CGFloat const kTWMessageBarManagerPanAnimationDuration		= 0.0002f;

// ====================================================================== Fonts (TWMessageView)
static UIFont *kTWMessageViewTitleFont			= nil;
static UIFont *kTWMessageViewDescriptionFont	= nil;

// ====================================================================== Colors (TWMessageView)
static UIColor *kTWMessageViewTitleColor		= nil;
static UIColor *kTWMessageViewDescriptionColor	= nil;

// ====================================================================== Strings (TWMessageBarStyleSheet)
NSString * const kTWMessageBarStyleSheetImageIconError		= @"icon-error.png";
NSString * const kTWMessageBarStyleSheetImageIconSuccess	= @"icon-success.png";
NSString * const kTWMessageBarStyleSheetImageIconInfo		= @"icon-info.png";

// ====================================================================== Colors (TWDefaultMessageBarStyleSheet)
static UIColor *kTWDefaultMessageBarStyleSheetErrorBackgroundColor		= nil;
static UIColor *kTWDefaultMessageBarStyleSheetSuccessBackgroundColor	= nil;
static UIColor *kTWDefaultMessageBarStyleSheetInfoBackgroundColor		= nil;
static UIColor *kTWDefaultMessageBarStyleSheetErrorStrokeColor			= nil;
static UIColor *kTWDefaultMessageBarStyleSheetSuccessStrokeColor		= nil;
static UIColor *kTWDefaultMessageBarStyleSheetInfoStrokeColor			= nil;

// ====================================================================== Protocol JRMessageViewDelegate
@class JRMessageView;
@protocol JRMessageViewDelegate <NSObject>
- (NSObject<JRMessageBarStyleSheet> *)styleSheetForMessageView:(JRMessageView *)messageView;
@end

/*******************************************************************************
							Class Interface
 *******************************************************************************/
//============================================================================== TWMessageView Class
@interface JRMessageView : UIView

@property (nonatomic, copy)		NSString					*titleString;
@property (nonatomic, copy)		NSString					*descriptionString;
@property (nonatomic, assign)	JRMessageBarMessageType		messageType;
@property (nonatomic, assign)	BOOL						hasCallback;
@property (nonatomic, strong)	NSArray						*callbacks;
@property (nonatomic, assign,	getter = isHit) BOOL		hit;
@property (nonatomic, assign)	CGFloat						duration;
@property (nonatomic, assign)	UIStatusBarStyle			statusBarStyle;
@property (nonatomic, assign)	BOOL						statusBarHidden;
@property (nonatomic, weak)		id<JRMessageViewDelegate>	delegate;

// Initializers
- (id)initWithTitle:(NSString *)title description:(NSString *)description type:(JRMessageBarMessageType)type;

// Getters
- (CGFloat)height;
- (CGFloat)width;
- (CGFloat)statusBarOffset;
- (CGFloat)availableWidth;
- (CGSize)titleSize;
- (CGSize)descriptionSize;
- (CGRect)statusBarFrame;
- (UIFont *)titleFont;
- (UIFont *)descriptionFont;
- (UIColor *)titleColor;
- (UIColor *)descriptionColor;

// Helpers
- (CGRect)orientFrame:(CGRect)frame;

// Notifications
- (void)didChangeDeviceOrientation:(NSNotification *)notification;

@end

//============================================================================== JRDefaultMessageBarStyleSheet Class
@interface JRDefaultMessageBarStyleSheet : NSObject <JRMessageBarStyleSheet>

+ (JRDefaultMessageBarStyleSheet *)styleSheet;

@end

//============================================================================== JRMessageWindow Class
@interface JRMessageWindow : UIWindow

@end

//============================================================================== JRMessageBarViewController Class
@interface JRMessageBarViewController : UIViewController

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, assign) BOOL statusBarHidden;

@end

//============================================================================== JRMessageBarManager Class
@interface JRMessageBarManager () <JRMessageViewDelegate>

@property (nonatomic, strong) NSMutableArray					*messageBarQueue;
@property (nonatomic, assign, getter = isMessageVisible) BOOL	messageVisible;
@property (nonatomic, strong) JRMessageWindow					*messageWindow;
@property (nonatomic, readwrite) NSArray						*accessibleElements; // accessibility

// Static
+ (CGFloat)durationForMessageType:(JRMessageBarMessageType)messageType;

// Helpers
- (void)showNextMessage;
- (void)generateAccessibleElementWithTitle:(NSString *)title description:(NSString *)description;

// Gestures
- (void)itemSelected:(UITapGestureRecognizer *)recognizer;

// Getters
- (UIView *)messageWindowView;
- (JRMessageBarViewController *)messageBarViewController;

// Master presetation
- (void)showMessageWithTitle:(NSString *)title
				 description:(NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			 statusBarHidden:(BOOL)statusBarHidden
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(void (^)())callback;

@end


/*******************************************************************************
							Class implementation
 *******************************************************************************/
//==============================================================================
//								JRMessageBarManager
//==============================================================================
@implementation JRMessageBarManager

#pragma mark -
+ (instancetype)sharedManager {
	static JRMessageBarManager *instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[JRMessageBarManager alloc] init];
	});
	return instance;
}

#pragma mark - Static
+ (CGFloat)defaultDuration {
	return kTWMessageBarManagerDisplayDelay;
}

+ (CGFloat)durationForMessageType:(JRMessageBarMessageType)messageType {
	return kTWMessageBarManagerDisplayDelay;
}

- (instancetype)init {
	if (self = [super init]) {
		_messageBarQueue = [[NSMutableArray alloc] init];
		_messageVisible = NO;
		_styleSheet = [JRDefaultMessageBarStyleSheet styleSheet];
		_managerSupportedOrientationsMask = UIInterfaceOrientationMaskAll;
	}
	return self;
}

#pragma mark - Public

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:[JRMessageBarManager durationForMessageType:type]
					  callback:nil];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:[JRMessageBarManager durationForMessageType:type]
					  callback:callback];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:duration
					  callback:nil];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:duration
				statusBarStyle:UIStatusBarStyleDefault
					  callback:callback];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:kTWMessageBarManagerDisplayDelay
				statusBarStyle:statusBarStyle
					  callback:callback];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:duration
			   statusBarHidden:NO
				statusBarStyle:statusBarStyle
					  callback:callback];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
			 statusBarHidden:(BOOL)statusBarHidden
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:[JRMessageBarManager durationForMessageType:type]
			   statusBarHidden:statusBarHidden
				statusBarStyle:UIStatusBarStyleDefault
					  callback:callback];
}

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			 statusBarHidden:(BOOL)statusBarHidden
					callback:(nullable void (^)())callback {
	[self showMessageWithTitle:title
				   description:description
						  type:type
					  duration:duration
			   statusBarHidden:statusBarHidden
				statusBarStyle:UIStatusBarStyleDefault
					  callback:callback];
}


#pragma mark -
- (void)showMessageWithTitle:(NSString *)title
				 description:(NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			 statusBarHidden:(BOOL)statusBarHidden
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(void (^)())callback {
	JRMessageView *messageView = [[JRMessageView alloc] initWithTitle:title description:description type:type];
	messageView.delegate = self;
	
	messageView.callbacks = callback ? [NSArray arrayWithObject:callback] : [NSArray array];
	messageView.hasCallback = callback ? YES : NO;
	
	messageView.duration = duration;
	messageView.hidden = YES;
	
	messageView.statusBarStyle = statusBarStyle;
	messageView.statusBarHidden = statusBarHidden;
	
	[[self messageWindowView] addSubview:messageView];
	[[self messageWindowView] bringSubviewToFront:messageView];
	
	[self.messageBarQueue addObject:messageView];
	
	if (!self.messageVisible)
	{
		[self showNextMessage];
	}
}

- (void)hideAllAnimated:(BOOL)animated {
	for (UIView *subview in [[self messageWindowView] subviews])
	{
		if ([subview isKindOfClass:[JRMessageView class]])
		{
			JRMessageView *currentMessageView = (JRMessageView *)subview;
			if (animated)
			{
				[UIView animateWithDuration:kTWMessageBarManagerDismissAnimationDuration animations:^{
					currentMessageView.frame = CGRectMake(currentMessageView.frame.origin.x, -currentMessageView.frame.size.height, currentMessageView.frame.size.width, currentMessageView.frame.size.height);
				} completion:^(BOOL finished) {
					[currentMessageView removeFromSuperview];
				}];
			}
			else
			{
				[currentMessageView removeFromSuperview];
			}
		}
	}
	
	self.messageVisible = NO;
	[self.messageBarQueue removeAllObjects];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.messageWindow.hidden = YES;
	self.messageWindow = nil;
}

- (void)hideAll {
	[self hideAllAnimated:NO];
}

#pragma mark - Helpers
- (void)showNextMessage {
	if ([self.messageBarQueue count] > 0)
	{
		self.messageVisible = YES;
		
		JRMessageView *messageView = [self.messageBarQueue objectAtIndex:0];
		[self messageBarViewController].statusBarHidden = messageView.statusBarHidden; // important to do this prior to hiding
		messageView.frame = CGRectMake(0, -[messageView height], [messageView width], [messageView height]);
		messageView.hidden = NO;
		[messageView setNeedsDisplay];
		
		UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemSelected:)];
		[messageView addGestureRecognizer:gest];
		
		if (messageView)
		{
			[self.messageBarQueue removeObject:messageView];
			
			[self messageBarViewController].statusBarStyle = messageView.statusBarStyle;
			
			[UIView animateWithDuration:kTWMessageBarManagerDismissAnimationDuration animations:^{
				[messageView setFrame:CGRectMake(messageView.frame.origin.x, messageView.frame.origin.y + [messageView height], [messageView width], [messageView height])]; // slide down
			}];
			[self performSelector:@selector(itemSelected:) withObject:messageView afterDelay:messageView.duration];
			
			[self generateAccessibleElementWithTitle:messageView.titleString description:messageView.descriptionString];
		}
	}
}

- (void)generateAccessibleElementWithTitle:(NSString *)title description:(NSString *)description {
	UIAccessibilityElement *textElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
	textElement.accessibilityLabel = [NSString stringWithFormat:@"%@\n%@", title, description];
	textElement.accessibilityTraits = UIAccessibilityTraitStaticText;
	self.accessibleElements = @[textElement];
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self); // notify the accessibility framework to read the message
}

#pragma mark - Gestures
- (void)itemSelected:(id)sender {
	JRMessageView *messageView = nil;
	BOOL itemHit = NO;
	if ([sender isKindOfClass:[UIGestureRecognizer class]])
	{
		messageView = (JRMessageView *)((UIGestureRecognizer *)sender).view;
		itemHit = YES;
	}
	else if ([sender isKindOfClass:[JRMessageView class]])
	{
		messageView = (JRMessageView *)sender;
	}
	
	if (messageView && ![messageView isHit])
	{
		messageView.hit = YES;
		
		[UIView animateWithDuration:kTWMessageBarManagerDismissAnimationDuration animations:^{
			[messageView setFrame:CGRectMake(messageView.frame.origin.x, messageView.frame.origin.y - [messageView height], [messageView width], [messageView height])]; // slide back up
		} completion:^(BOOL finished) {
			if (itemHit)
			{
				if ([messageView.callbacks count] > 0)
				{
					id obj = [messageView.callbacks objectAtIndex:0];
					if (![obj isEqual:[NSNull null]])
					{
						((void (^)())obj)();
					}
				}
			}
			
			self.messageVisible = NO;
			[messageView removeFromSuperview];
			
			if([self.messageBarQueue count] > 0)
			{
				[self showNextMessage];
			}
			else
			{
				self.messageWindow.hidden = YES;
				self.messageWindow = nil;
			}
		}];
	}
}

#pragma mark - Getters
- (UIView *)messageWindowView {
	return [self messageBarViewController].view;
}

- (JRMessageBarViewController *)messageBarViewController {
	if (!self.messageWindow)
	{
		self.messageWindow = [[JRMessageWindow alloc] init];
		self.messageWindow.frame = [UIApplication sharedApplication].keyWindow.frame;
		self.messageWindow.hidden = NO;
		self.messageWindow.windowLevel = UIWindowLevelNormal;
		self.messageWindow.backgroundColor = [UIColor clearColor];
		self.messageWindow.rootViewController = [[JRMessageBarViewController alloc] init];
	}
	return (JRMessageBarViewController *)self.messageWindow.rootViewController;
}

- (NSArray *)accessibleElements {
	if (_accessibleElements != nil)
	{
		return _accessibleElements;
	}
	_accessibleElements = [NSArray array];
	return _accessibleElements;
}

#pragma mark - Setters
- (void)setStyleSheet:(NSObject<JRMessageBarStyleSheet> *)styleSheet {
	if (styleSheet != nil) {
		_styleSheet = styleSheet;
	}
}

#pragma mark - TWMessageViewDelegate

- (NSObject<JRMessageBarStyleSheet> *)styleSheetForMessageView:(JRMessageView *)messageView {
	return self.styleSheet;
}

#pragma mark - UIAccessibilityContainer
- (NSInteger)accessibilityElementCount {
	return (NSInteger)[self.accessibleElements count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
	return [self.accessibleElements objectAtIndex:(NSUInteger)index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
	return (NSInteger)[self.accessibleElements indexOfObject:element];
}

- (BOOL)isAccessibilityElement {
	return NO;
}

@end


//==============================================================================
//							JRDefaultMessageBarStyleSheet
//==============================================================================
@implementation JRDefaultMessageBarStyleSheet
#pragma mark - Alloc/Init
+ (void)initialize {
	if (self == [JRDefaultMessageBarStyleSheet class]) {
		// Colors (background)
		kTWDefaultMessageBarStyleSheetErrorBackgroundColor		= [UIColor colorWithRed:1.0
																			  green:0.611
																			   blue:0.0
																			  alpha:kTWMessageBarStyleSheetMessageBarAlpha]; // orange

		kTWDefaultMessageBarStyleSheetSuccessBackgroundColor	= [UIColor colorWithRed:0.0f
																			   green:0.831f
																				blue:0.176f
																			   alpha:kTWMessageBarStyleSheetMessageBarAlpha]; // green
		kTWDefaultMessageBarStyleSheetInfoBackgroundColor		= [UIColor colorWithRed:0.0
																			green:0.482
																			 blue:1.0
																			alpha:kTWMessageBarStyleSheetMessageBarAlpha]; // blue
		
		// Colors (stroke)
		kTWDefaultMessageBarStyleSheetErrorStrokeColor		= [UIColor colorWithRed:0.949f green:0.580f blue:0.0f alpha:1.0f]; // orange
		kTWDefaultMessageBarStyleSheetSuccessStrokeColor	= [UIColor colorWithRed:0.0f green:0.772f blue:0.164f alpha:1.0f]; // green
		kTWDefaultMessageBarStyleSheetInfoStrokeColor		= [UIColor colorWithRed:0.0f green:0.415f blue:0.803f alpha:1.0f]; // blue
	}
}

+ (JRDefaultMessageBarStyleSheet *)styleSheet {
	return [[JRDefaultMessageBarStyleSheet alloc] init];
}

#pragma mark - TWMessageBarStyleSheet
- (nonnull UIColor *)backgroundColorForMessageType:(JRMessageBarMessageType)type {
	UIColor *backgroundColor = nil;
	switch (type) {
		case JRMessageBarMessageTypeError:
			backgroundColor = kTWDefaultMessageBarStyleSheetErrorBackgroundColor;
			break;
		case JRMessageBarMessageTypeSuccess:
			backgroundColor = kTWDefaultMessageBarStyleSheetSuccessBackgroundColor;
			break;
		case JRMessageBarMessageTypeInfo:
			backgroundColor = kTWDefaultMessageBarStyleSheetInfoBackgroundColor;
			break;
	}
	return backgroundColor;
}

- (nonnull UIColor *)strokeColorForMessageType:(JRMessageBarMessageType)type {
	UIColor *strokeColor = nil;
	switch (type) {
		case JRMessageBarMessageTypeError:
			strokeColor = kTWDefaultMessageBarStyleSheetErrorStrokeColor;
			break;
		case JRMessageBarMessageTypeSuccess:
			strokeColor = kTWDefaultMessageBarStyleSheetSuccessStrokeColor;
			break;
		case JRMessageBarMessageTypeInfo:
			strokeColor = kTWDefaultMessageBarStyleSheetInfoStrokeColor;
			break;
	}
	return strokeColor;
}

- (nonnull UIImage *)iconImageForMessageType:(JRMessageBarMessageType)type {
	UIImage *iconImage = nil;
	switch (type) {
		case JRMessageBarMessageTypeError:
			iconImage = [UIImage imageNamed:kTWMessageBarStyleSheetImageIconError];
			break;
		case JRMessageBarMessageTypeSuccess:
			iconImage = [UIImage imageNamed:kTWMessageBarStyleSheetImageIconSuccess];
			break;
		case JRMessageBarMessageTypeInfo:
			iconImage = [UIImage imageNamed:kTWMessageBarStyleSheetImageIconInfo];
			break;
	}
	return iconImage;
}

@end


//==============================================================================
//								TWMessageView
//==============================================================================
@implementation JRMessageView

#pragma mark - Alloc/Init
+ (void)initialize {
	if (self == [JRMessageView class]) {
		// Fonts
		kTWMessageViewTitleFont			= [UIFont boldSystemFontOfSize:16.0];
		kTWMessageViewDescriptionFont	= [UIFont systemFontOfSize:14.0];
		// Colors
		kTWMessageViewTitleColor		= [UIColor colorWithWhite:1.0 alpha:1.0];
		kTWMessageViewDescriptionColor	= [UIColor colorWithWhite:1.0 alpha:1.0];
	}
}

- (id)initWithTitle:(NSString *)title
		description:(NSString *)description
			   type:(JRMessageBarMessageType)type {

	if (self = [super initWithFrame:CGRectZero]) {
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		self.userInteractionEnabled = YES;
		
		_titleString = title;
		_descriptionString = description;
		_messageType = type;
		
		_hasCallback = NO;
		_hit = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didChangeDeviceOrientation:)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];
	}
	return self;
}

#pragma mark - Memory Management
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if ([self.delegate respondsToSelector:@selector(styleSheetForMessageView:)]) {
		id<JRMessageBarStyleSheet> styleSheet = [self.delegate styleSheetForMessageView:self];
		
		// background fill
		CGContextSaveGState(context);
		{
			if ([styleSheet respondsToSelector:@selector(backgroundColorForMessageType:)])
			{
				[[styleSheet backgroundColorForMessageType:self.messageType] set];			//========???
				CGContextFillRect(context, rect);
			}
		}
		CGContextRestoreGState(context);
		
		// bottom stroke
		CGContextSaveGState(context);
		{
			if ([styleSheet respondsToSelector:@selector(strokeColorForMessageType:)])
			{
				CGContextBeginPath(context);
				CGContextMoveToPoint(context, 0, rect.size.height);
				CGContextSetStrokeColorWithColor(context, [styleSheet strokeColorForMessageType:self.messageType].CGColor);
				CGContextSetLineWidth(context, 1.0);
				CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
				CGContextStrokePath(context);
			}
		}
		CGContextRestoreGState(context);
		
		CGFloat xOffset = kTWMessageViewBarPadding;
		CGFloat yOffset = kTWMessageViewBarPadding + [self statusBarOffset];
		
		// icon
		CGContextSaveGState(context);
		{
			if ([styleSheet respondsToSelector:@selector(iconImageForMessageType:)])
			{
				[[styleSheet iconImageForMessageType:self.messageType] drawInRect:CGRectMake(xOffset, yOffset, kTWMessageViewIconSize, kTWMessageViewIconSize)];
			}
		}
		CGContextRestoreGState(context);
		
		yOffset -= kTWMessageViewTextOffset;
		xOffset += kTWMessageViewIconSize + kTWMessageViewBarPadding;
		
		CGSize titleLabelSize = [self titleSize];
		CGSize descriptionLabelSize = [self descriptionSize];
		
		if (self.titleString && !self.descriptionString)
		{
			yOffset = ceil(rect.size.height * 0.5) - ceil(titleLabelSize.height * 0.5) - kTWMessageViewTextOffset;
		}
	
		if ([[UIDevice currentDevice] tw_isRunningiOS7OrLater])
		{
			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			paragraphStyle.alignment = NSTextAlignmentLeft;
			
			[[self titleColor] set];
			[self.titleString drawWithRect:CGRectMake(xOffset, yOffset, titleLabelSize.width, titleLabelSize.height)
								   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
								attributes:@{NSFontAttributeName:[self titleFont], NSForegroundColorAttributeName:[self titleColor], NSParagraphStyleAttributeName:paragraphStyle}
								   context:nil];
			
			yOffset += titleLabelSize.height;
			
			[[self descriptionColor] set];
			[self.descriptionString drawWithRect:CGRectMake(xOffset, yOffset, descriptionLabelSize.width, descriptionLabelSize.height)
										 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
									  attributes:@{NSFontAttributeName:[self descriptionFont], NSForegroundColorAttributeName:[self descriptionColor], NSParagraphStyleAttributeName:paragraphStyle}
										 context:nil];
		}
		else
		{
			[[self titleColor] set];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[self.titleString drawInRect:CGRectMake(xOffset, yOffset, titleLabelSize.width, titleLabelSize.height) withFont:[self titleFont] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentLeft];
#pragma clang diagnostic pop
			
			yOffset += titleLabelSize.height;
			
			[[self descriptionColor] set];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[self.descriptionString drawInRect:CGRectMake(xOffset, yOffset, descriptionLabelSize.width, descriptionLabelSize.height) withFont:[self descriptionFont] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentLeft];
#pragma clang diagnostic pop
		}
	}
}

#pragma mark - Getters
- (CGFloat)height {
	CGSize titleLabelSize = [self titleSize];
	CGSize descriptionLabelSize = [self descriptionSize];
	return MAX((kTWMessageViewBarPadding * 2) + titleLabelSize.height + descriptionLabelSize.height + [self statusBarOffset], (kTWMessageViewBarPadding * 2) + kTWMessageViewIconSize + [self statusBarOffset]);
}

- (CGFloat)width {
	return [self statusBarFrame].size.width;
}

- (CGFloat)statusBarOffset {
	return [[UIDevice currentDevice] tw_isRunningiOS7OrLater] ? [self statusBarFrame].size.height : 0.0;
}

- (CGFloat)availableWidth {
	return ([self width] - (kTWMessageViewBarPadding * 3) - kTWMessageViewIconSize);
}

- (CGSize)titleSize {
	CGSize boundedSize = CGSizeMake([self availableWidth], CGFLOAT_MAX);
	CGSize titleLabelSize;

	if ([[UIDevice currentDevice] tw_isRunningiOS7OrLater])
	{
		NSDictionary *titleStringAttributes = [NSDictionary dictionaryWithObject:[self titleFont] forKey: NSFontAttributeName];
		titleLabelSize = [self.titleString boundingRectWithSize:boundedSize
														options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
													 attributes:titleStringAttributes
														context:nil].size;
	}
	else
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		titleLabelSize = [_titleString sizeWithFont:[self titleFont] constrainedToSize:boundedSize lineBreakMode:NSLineBreakByTruncatingTail];
#pragma clang diagnostic pop
	}
	
	return CGSizeMake(ceilf(titleLabelSize.width), ceilf(titleLabelSize.height));
}

- (CGSize)descriptionSize {
	CGSize boundedSize = CGSizeMake([self availableWidth], CGFLOAT_MAX);
	CGSize descriptionLabelSize;
	
	if ([[UIDevice currentDevice] tw_isRunningiOS7OrLater])
	{
		NSDictionary *descriptionStringAttributes = [NSDictionary dictionaryWithObject:[self descriptionFont] forKey: NSFontAttributeName];
		descriptionLabelSize = [self.descriptionString boundingRectWithSize:boundedSize
																	options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
																 attributes:descriptionStringAttributes
																	context:nil].size;
	}
	else
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		descriptionLabelSize = [_descriptionString sizeWithFont:[self descriptionFont] constrainedToSize:boundedSize lineBreakMode:NSLineBreakByTruncatingTail];
#pragma clang diagnostic pop
	}
	
	return CGSizeMake(ceilf(descriptionLabelSize.width), ceilf(descriptionLabelSize.height));
}

- (CGRect)statusBarFrame {
	CGRect windowFrame = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1 ? [self orientFrame:[UIApplication sharedApplication].keyWindow.frame] : [UIApplication sharedApplication].keyWindow.frame;
	CGRect statusFrame = NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1 ?  [self orientFrame:[UIApplication sharedApplication].statusBarFrame] : [UIApplication sharedApplication].statusBarFrame;
	return CGRectMake(windowFrame.origin.x, windowFrame.origin.y, windowFrame.size.width, statusFrame.size.height);
}

- (UIFont *)titleFont {
	if ([self.delegate respondsToSelector:@selector(styleSheetForMessageView:)]) {
		id<JRMessageBarStyleSheet> styleSheet = [self.delegate styleSheetForMessageView:self];
		if ([styleSheet respondsToSelector:@selector(titleFontForMessageType:)])
		{
			return [styleSheet titleFontForMessageType:self.messageType];
		}
	}
	return kTWMessageViewTitleFont;
}

- (UIFont *)descriptionFont {
	if ([self.delegate respondsToSelector:@selector(styleSheetForMessageView:)])
	{
		id<JRMessageBarStyleSheet> styleSheet = [self.delegate styleSheetForMessageView:self];
		if ([styleSheet respondsToSelector:@selector(descriptionFontForMessageType:)])
		{
			return [styleSheet descriptionFontForMessageType:self.messageType];
		}
	}
	return kTWMessageViewDescriptionFont;
}

- (UIColor *)titleColor {
	if ([self.delegate respondsToSelector:@selector(styleSheetForMessageView:)]) {
//		id<TWMessageBarStyleSheet> styleSheet = [self.delegate styleSheetForMessageView:self];
//		if ([styleSheet respondsToSelector:@selector(titleColorForMessageType:)])
//		{
//			return [styleSheet titleColorForMessageType:self.messageType];
//		}
	}
	return kTWMessageViewTitleColor;
}

- (UIColor *)descriptionColor {
	if ([self.delegate respondsToSelector:@selector(styleSheetForMessageView:)]) {

//		id<JRMessageBarStyleSheet> styleSheet = [self.delegate styleSheetForMessageView:self];
//		if ([styleSheet respondsToSelector:@selector(descriptionColorForMessageType:)])
//		{
//			return [styleSheet descriptionColorForMessageType:self.messageType];
//		}
	}
	return kTWMessageViewDescriptionColor;
}

#pragma mark - Helpers
- (CGRect)orientFrame:(CGRect)frame {
	return frame;
}

#pragma mark - Notifications
- (void)didChangeDeviceOrientation:(NSNotification *)notification {
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [self statusBarFrame].size.width, self.frame.size.height);
	[self setNeedsDisplay];
}

@end

//==============================================================================
//							JRMessageBarViewController
//==============================================================================
@implementation JRMessageBarViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return [JRMessageBarManager sharedManager].managerSupportedOrientationsMask;
}

#pragma mark - Setters
- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle {
	_statusBarStyle = statusBarStyle;
	if ([[UIDevice currentDevice] tw_isRunningiOS7OrLater]) {
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
	_statusBarHidden = statusBarHidden;
	if ([[UIDevice currentDevice] tw_isRunningiOS7OrLater]) {
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

#pragma mark - Status Bar
- (UIStatusBarStyle)preferredStatusBarStyle {
	return self.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
	return self.statusBarHidden;
}

@end

//==============================================================================
//								JRMessageWindow
//==============================================================================
@implementation JRMessageWindow
#pragma mark - Touches
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	UIView *hitView = [super hitTest:point withEvent:event];
	if ([hitView isEqual: self.rootViewController.view]) {
		hitView = nil;
	}
	return hitView;
}
@end


@implementation UIDevice (Additions)
#pragma mark - OS Helpers
- (BOOL)tw_isRunningiOS7OrLater {
	NSString *systemVersion	= self.systemVersion;
	NSUInteger systemInt	= [systemVersion intValue];
	return systemInt		>= kTWMessageViewiOS7Identifier;
}

@end






























