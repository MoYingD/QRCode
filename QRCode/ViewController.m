//
//  ViewController.m
//  QRCode
//
//  Created by 黄利强 on 16/8/12.
//  Copyright © 2016年 黄利强. All rights reserved.
//

#import "ViewController.h"
#import "QRScanViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadAllSubview];
}

- (void)loadAllSubview
{
    CGRect frame = CGRectMake(120, 200, 100, 40);
    UIButton *btn  = [self customeButtonTitle:@"open"
                                       action:@selector(openQRVC)
                                        frame:frame];
}

// 自定义生成button
- (UIButton *)customeButtonTitle:(NSString *)title
                          action:(SEL)action
                           frame:(CGRect)frame
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.frame = frame;
    [self.view addSubview:button];
    return button;
}

- (void)openQRVC
{
    QRScanViewController *vc = [[QRScanViewController alloc] init];
    [self presentPostPage:vc];
}

- (void)presentPostPage:(UIViewController *)postPage
{
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:postPage];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
