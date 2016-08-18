//
//  QRScanViewController.m
//  QRCode
//
//  Created by 黄利强 on 16/8/18.
//  Copyright © 2016年 黄利强. All rights reserved.
//

#import "QRScanViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "Const.h"

@interface QRScanViewController() <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>

@property (strong,nonatomic) AVCaptureSession *session;
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UILabel *infoLabel;
@property (nonatomic, strong) UIImageView *scanLineImageView;
@property (nonatomic, strong) NSTimer *scanLineTimer;

@property (nonatomic, strong) UIView *bottomBackground;
@property (nonatomic, strong) UIImageView *articleImageView;
@property (nonatomic, strong) UILabel *websiteLabel;

@end

@implementation QRScanViewController
{
    BOOL isShowStatus;
    NSString *_QRCode;
}

- (void)initViewAndSubViews
{
    
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    self.view.frame = mainBounds;
    
    CGRect readerFrame = self.view.frame;
    CGSize viewFinderSize = CGSizeMake(readerFrame.size.width - 80, readerFrame.size.width - 80);
    CGRect scanCrop =
    CGRectMake((readerFrame.size.width - viewFinderSize.width)/2,
               (readerFrame.size.height - viewFinderSize.height)/2,
               viewFinderSize.width,
               viewFinderSize.height);
    
    
    /**********************************摄像头开始**********************************/
    // 1 实例化摄像头设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2 设置输入,把摄像头作为输入设备
    // 因为模拟器是没有摄像头的，因此在此最好做个判断
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error)
    {
        MDLog(@"没有摄像头%@", error.localizedDescription);
        // 用户拒绝授权
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"无法打开相机"
                                                        message:[NSString stringWithFormat:@"请在设置-隐私-相机中，允许APP访问相机"]
                                                       delegate:self
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:@"去更改", nil];
        [alert show];
        self.session = [[AVCaptureSession alloc]init];
    }
    else
    {
        
        // 3 设置输出(Metadata元数据)
        AVCaptureMetadataOutput *outPut = [[AVCaptureMetadataOutput alloc] init];
        
        outPut.rectOfInterest =
        CGRectMake(scanCrop.origin.y/readerFrame.size.height,
                   scanCrop.origin.x/readerFrame.size.width,
                   scanCrop.size.height/readerFrame.size.height,
                   scanCrop.size.width/readerFrame.size.width
                   );
        
        // 3.1 设置输出的代理
        // 使用主线程队列，相应比较同步，使用其他队列，相应不同步，容易让用户产生不好的体验。
        [outPut setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        // 4 拍摄会话
        self.session = [[AVCaptureSession alloc]init];
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
        // 添加session的输入和输出
        [self.session addInput:input];
        [self.session addOutput:outPut];
        // 4.1 设置输出的格式
        [outPut setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        
    }
    
    // 5 设置预览图层(用来让用户能够看到扫描情况)
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    // AVCaptureVideoPreviewLayer -- to show the user what a camera is recording
    // 5.1 设置preview图层的属性
    [preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    // 5.2设置preview图层的大小
    [preview setFrame:self.view.bounds];
    //5.3将图层添加到视图的图层
    [self.view.layer insertSublayer:preview atIndex:0];
    self.previewLayer = preview;
    
    /**********************************摄像头结束**********************************/
    
    /* 画一个取景框开始 */
    // 正方形取景框的边长
    CGFloat edgeLength = 20.0;
    
    // 四个边角
    UIImageView *topLeft =
    [[UIImageView alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2,
                                                  (readerFrame.size.height - viewFinderSize.height)/2,
                                                  edgeLength, edgeLength)];
    topLeft.image = [UIImage imageNamed:@"qr_top_left.png"];
    [self.view addSubview:topLeft];
    
    UIImageView *topRight =
    [[UIImageView alloc] initWithFrame:CGRectMake((readerFrame.size.width + viewFinderSize.width)/2 - edgeLength,
                                                  (readerFrame.size.height - viewFinderSize.height)/2,
                                                  edgeLength, edgeLength)];
    topRight.image = [UIImage imageNamed:@"qr_top_right.png"];
    [self.view addSubview:topRight];
    
    UIImageView *bottomLeft =
    [[UIImageView alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2,
                                                  (readerFrame.size.height + viewFinderSize.height)/2 - edgeLength,
                                                  edgeLength, edgeLength)];
    bottomLeft.image = [UIImage imageNamed:@"qr_bottom_left"];
    [self.view addSubview:bottomLeft];
    
    UIImageView *bottomRight =
    [[UIImageView alloc] initWithFrame:CGRectMake((readerFrame.size.width + viewFinderSize.width)/2 - edgeLength,
                                                  (readerFrame.size.height + viewFinderSize.height)/2 - edgeLength,
                                                  edgeLength, edgeLength)];
    bottomRight.image = [UIImage imageNamed:@"qr_bottom_right"];
    [self.view addSubview:bottomRight];
    
    // 四条线
    UIView *topLine =
    [[UIView alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2-1,
                                             (readerFrame.size.height - viewFinderSize.height)/2-1,
                                             viewFinderSize.width+2, 1)];
    topLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self.view addSubview:topLine];
    
    UIView *bottomLine =
    [[UIView alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2-1,
                                             (readerFrame.size.height + viewFinderSize.height)/2,
                                             viewFinderSize.width+2, 1)];
    bottomLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self.view addSubview:bottomLine];
    
    UIView *leftLine =
    [[UIView alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2-1,
                                             (readerFrame.size.height - viewFinderSize.height)/2-1,
                                             1, viewFinderSize.height+2)];
    leftLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self.view addSubview:leftLine];
    
    UIView *rightLine =
    [[UIView alloc] initWithFrame:CGRectMake((readerFrame.size.width + viewFinderSize.width)/2,
                                             (readerFrame.size.height - viewFinderSize.height)/2-1,
                                             1, viewFinderSize.height+2)];
    rightLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self.view addSubview:rightLine];
    
    // 中间扫描线
    self.scanLineImageView =
    [[UIImageView alloc] initWithFrame:CGRectMake((readerFrame.size.width - 230)/2,
                                                  (readerFrame.size.height - viewFinderSize.height)/2,
                                                  230, 10)];
    self.scanLineImageView.image = [UIImage imageNamed:@"qr_scan_line"];
    
    [self.view addSubview:self.scanLineImageView];
    
    /* 画一个取景框结束 */
    
    /* 配置取景框之外颜色开始 */
    // scanCrop
    UIView *viewTopScan =
    [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainBounds.size.width, scanCrop.origin.y)];
    
    UIView *viewBottomScan =
    [[UIView alloc] initWithFrame:CGRectMake(0, scanCrop.origin.y+scanCrop.size.height,
                                             mainBounds.size.width,
                                             mainBounds.size.height - scanCrop.size.height - scanCrop.origin.y)];
    
    UIView *viewLeftScan =
    [[UIView alloc] initWithFrame:CGRectMake(0, scanCrop.origin.y, scanCrop.origin.x, scanCrop.size.height)];
    
    UIView *viewRightScan =
    [[UIView alloc] initWithFrame:CGRectMake(scanCrop.origin.x + scanCrop.size.width,
                                             scanCrop.origin.y,
                                             mainBounds.size.width - scanCrop.origin.x - scanCrop.size.width,
                                             scanCrop.size.height)];
    viewTopScan.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    viewBottomScan.backgroundColor = viewTopScan.backgroundColor;
    viewLeftScan.backgroundColor = viewTopScan.backgroundColor;
    viewRightScan.backgroundColor = viewTopScan.backgroundColor;
    [self.view addSubview:viewTopScan];
    [self.view addSubview:viewBottomScan];
    [self.view addSubview:viewLeftScan];
    [self.view addSubview:viewRightScan];
    
    /* 配置取景框之外颜色结束 */
    
    // 返回键
    UIButton *goBackButton = ({
        UIButton *button =
        [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 36, 36)];
        [button setImage:[UIImage imageNamed:@"qr_vc_left"] forState:UIControlStateNormal];
        button.layer.cornerRadius = 18.0;
        button.layer.backgroundColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
        [button addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchDown];
        button;
    });
    [self.view addSubview:goBackButton];
    
    // 控制散光灯
    UIButton *torchSwitch = ({
        UIButton *button =
        [[UIButton alloc] initWithFrame:CGRectMake(mainBounds.size.width-44-20, 30, 36, 36)];
        [button setImage:[UIImage imageNamed:@"qr_vc_right"] forState:UIControlStateNormal];
        button.layer.cornerRadius = 18.0;
        button.layer.backgroundColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
        [button addTarget:self action:@selector(torchSwitch:) forControlEvents:UIControlEventTouchDown];
        button;
    });
    [self.view addSubview:torchSwitch];
    
    
    self.infoLabel =
    [[UILabel alloc] initWithFrame:CGRectMake((readerFrame.size.width - viewFinderSize.width)/2,
                                              (readerFrame.size.height + viewFinderSize.height)/2 + 20,
                                              viewFinderSize.width, 30)];
    self.infoLabel.text = @"将方框对准二维码进行扫描";
    self.infoLabel.font = [UIFont systemFontOfSize:13.0];
    self.infoLabel.layer.cornerRadius = self.infoLabel.frame.size.height / 2;
    self.infoLabel.layer.backgroundColor = [UIColor clearColor].CGColor; //[[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] CGColor];
    self.infoLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.infoLabel];
    
    
    self.bottomBackground = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 72, CGRectGetWidth(self.view.frame), 72)];
    self.bottomBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:self.bottomBackground];
    
    NSString *websitePrefix = @"在电脑浏览器打开，请访问网址并扫码\n";
    NSString *websiteSuffix = @"https://github.com/MoYingD";
    NSString *websiteText = [NSString stringWithFormat:@"%@%@", websitePrefix, websiteSuffix];
    NSMutableAttributedString *websiteAttributedText = [[NSMutableAttributedString alloc] initWithString:websiteText];
    [websiteAttributedText addAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName : FONT_WITH_SIZE(16)}
                                   range:NSMakeRange(0, [websitePrefix length])];
    [websiteAttributedText addAttributes:@{NSForegroundColorAttributeName : UICOLOR_RGB(0xffd400), NSFontAttributeName : FONT_WITH_SIZE(20)}
                                   range:NSMakeRange([websitePrefix length], [websiteSuffix length])];
    
    self.websiteLabel = [[UILabel alloc] initWithFrame:self.bottomBackground.frame];
    self.websiteLabel.center = self.bottomBackground.center;
    self.websiteLabel.attributedText = websiteAttributedText;
    self.websiteLabel.numberOfLines = 3;
    self.websiteLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.websiteLabel];
    
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    MDLog(@"viewDidLoad");
    [super viewDidLoad];
    
    isShowStatus = NO;
    
    [self initViewAndSubViews];
    MDLog(@"viewDidLoad finish");
    
    [self hideTheStatusBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    MDLog(@"viewWillAppear");
    [super viewWillAppear:animated];
    // 隐藏状态栏
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    //6.启动会话
    [self.session startRunning];
    
    // 开始扫描
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        MDLog(@"没有摄像头%@", error.localizedDescription);
        input = nil;
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if (self.scanLineTimer == nil)
    {
        [self moveUpAndDownLine];
        [self createTimer];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 消失时设置导航栏 状态栏状态为显示
    self.navigationController.navigationBar.hidden = NO;
    [self showTheStatusBar];
    [super viewWillDisappear:animated];
}

-(void)showTheStatusBar
{
    isShowStatus = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

//And to hide the status bar:
-(void)hideTheStatusBar
{
    isShowStatus = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden {
    return !isShowStatus;
}

// 返回
- (void)goBack:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

// 控制散光灯
- (void)torchSwitch:(id)sender
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    if (device.hasTorch) {
        // 判断设备是否有散光灯
        BOOL b = [device lockForConfiguration:&error];
        if (!b)
        {
            if (error)
            {
                MDLog(@"lock torch configuration error:%@", error.localizedDescription);
            }
            return;
        }
        device.torchMode =
        (device.torchMode == AVCaptureTorchModeOff ? AVCaptureTorchModeOn : AVCaptureTorchModeOff);
        [device unlockForConfiguration];
    }
}

#define LINE_SCAN_TIME  3.0     // 扫描线从上到下扫描所历时间（s）

- (void)createTimer {
    self.scanLineTimer =
    [NSTimer scheduledTimerWithTimeInterval:LINE_SCAN_TIME
                                     target:self
                                   selector:@selector(moveUpAndDownLine)
                                   userInfo:nil
                                    repeats:YES];
}

// 扫描条上下滚动
- (void)moveUpAndDownLine
{
    CGRect readerFrame = self.view.frame;
    CGSize viewFinderSize = CGSizeMake(self.view.frame.size.width - 80, self.view.frame.size.width - 80);
    
    CGRect scanLineframe = self.scanLineImageView.frame;
    scanLineframe.origin.y =
    (readerFrame.size.height - viewFinderSize.height)/2;
    self.scanLineImageView.frame = scanLineframe;
    self.scanLineImageView.hidden = NO;
    
    __weak __typeof(self) weakSelf = self;
    
    [UIView animateWithDuration:LINE_SCAN_TIME - 0.05
                     animations:^{
                         CGRect scanLineframe = weakSelf.scanLineImageView.frame;
                         scanLineframe.origin.y =
                         (readerFrame.size.height + viewFinderSize.height)/2 -
                         weakSelf.scanLineImageView.frame.size.height;
                         
                         weakSelf.scanLineImageView.frame = scanLineframe;
                     }
                     completion:^(BOOL finished) {
                         weakSelf.scanLineImageView.hidden = YES;
                     }];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
//此方法是在识别到QRCode并且完成转换，如果QRCode的内容越大，转换需要的时间就越长。
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 会频繁的扫描，调用代理方法
    // 1如果扫描完成，停止会话
    [self.session stopRunning];
    //2删除预览图层
    //    [self.previewLayer removeFromSuperlayer];
    //设置界面显示扫描结果
    if (metadataObjects.count > 0)
    {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        MDLog(@"code:%@", obj.stringValue);
        
        _QRCode = obj.stringValue;
        
        [self sendScanQRCodeRequest:_QRCode];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        // 授权拒绝, 停留在本界面
        //        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    
}

// 处理识别出的二维码内容
- (void)sendScanQRCodeRequest:(NSString *)qrCode
{
    MDLog(@"code is %@", qrCode);
}


@end
