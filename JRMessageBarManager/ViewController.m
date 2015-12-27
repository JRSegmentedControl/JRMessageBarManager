//
//  ViewController.m
//  JRMessageBarManager
//
//  Created by wxiao on 15/12/27.
//  Copyright © 2015年 wxiao. All rights reserved.
//

#import "ViewController.h"
#import "StringConstants.h"
#import "JRMessageBarManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[[JRMessageBarManager sharedManager] showMessageWithTitle:kStringMessageBarErrorTitle
												   description:kStringMessageBarErrorMessage
														  type:JRMessageBarMessageTypeError
												statusBarStyle:UIStatusBarStyleLightContent
													  callback:^{
														  NSLog(@"SUCCESS");
													  }];
}

@end
