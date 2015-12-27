//
//  JRMessageBarManager.h
//  JRMessageBarManager
//
//  Created by wxiao on 15/12/27.
//  Copyright © 2015年 wxiao. All rights reserved.
//

#import <UIKit/UIKit.h>

/// MessageBar Type
typedef NS_ENUM(NSInteger, JRMessageBarMessageType) {
	JRMessageBarMessageTypeError,			// 错误
	JRMessageBarMessageTypeSuccess,			// 成功
	JRMessageBarMessageTypeInfo				// 信息
};

// ============================================================================= TWMessageBarStyleSheet
@protocol JRMessageBarStyleSheet <NSObject>
/// 返回背景色
- (nonnull UIColor *)backgroundColorForMessageType:(JRMessageBarMessageType)type;
/// 返回底线颜色
- (nonnull UIColor *)strokeColorForMessageType:(JRMessageBarMessageType)type;
/// 返回icon
- (nonnull UIImage *)iconImageForMessageType:(JRMessageBarMessageType)type;
@optional
/// 标题字体大小
- (nonnull UIFont *)titleFontForMessageType:(JRMessageBarMessageType)type;
/// 描述信息字体大小
- (nonnull UIFont *)descriptionFontForMessageType:(JRMessageBarMessageType)type;
/// 标题文字颜色
- (nonnull UIColor *)titleColorForMessageType:(JRMessageBarMessageType)type;
/// 描述信息文字颜色
- (nonnull UIColor *)descriptionColorForMessageType:(JRMessageBarMessageType)type;
@end

// ============================================================================= TWMessageBarManager
@interface JRMessageBarManager : NSObject

/// 获取单例
+ (nonnull JRMessageBarManager*)sharedManager;

/// 展示时间 默认:3s
+ (CGFloat)defaultDuration;

/// TWMessageBarStyleSheet 对象
@property (nonnull, nonatomic, strong) NSObject<JRMessageBarStyleSheet> *styleSheet;

/// 屏幕方向
@property (nonatomic, assign) UIInterfaceOrientationMask managerSupportedOrientationsMask;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					callback:(nullable void (^)())callback;


- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
					callback:(nullable void (^)())callback;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(nullable void (^)())callback;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			  statusBarStyle:(UIStatusBarStyle)statusBarStyle
					callback:(nullable void (^)())callback;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
			 statusBarHidden:(BOOL)statusBarHidden
					callback:(nullable void (^)())callback;

- (void)showMessageWithTitle:(nullable NSString *)title
				 description:(nullable NSString *)description
						type:(JRMessageBarMessageType)type
					duration:(CGFloat)duration
			 statusBarHidden:(BOOL)statusBarHidden
					callback:(nullable void (^)())callback;

- (void)hideAllAnimated:(BOOL)animated;

- (void)hideAll;

@end

// ============================================================================= UIDevice (Additions)
@interface UIDevice (Additions)

- (BOOL)tw_isRunningiOS7OrLater;

@end












