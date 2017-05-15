//
//  CaptureViewController.m
//  音视频采集
//
//  Created by renren on 2017/5/11.
//  Copyright © 2017年 renyanping. All rights reserved.
//

#import "CaptureViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface CaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureConnection * connection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput * currentVideoDeviceInput;
@property (nonatomic, strong) UIImageView * focusCursorImageView;

@property (nonatomic,strong) UIButton *leftBtn;

@end

@implementation CaptureViewController
@synthesize leftBtn;

- (UIImageView *)focusCursorImageView
{
    if (_focusCursorImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focus"]];
        _focusCursorImageView = imageView;
        [self.view addSubview:_focusCursorImageView];
    }
    return _focusCursorImageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createUI];
    [self setupCaptureVideo];
}

- (void)createUI{
    leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame = CGRectMake(6, 20, 44, 44);
    leftBtn.backgroundColor = [UIColor blackColor];
    [leftBtn setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    [leftBtn addTarget:self action:@selector(changeCamora:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftBtn];
}

//切换摄像头
- (void)changeCamora:(UIButton *)btn{
    //获取当前的设备方向
    AVCaptureDevicePosition curPosotion = _currentVideoDeviceInput.device.position;
    
    //获取要改变的方向
    AVCaptureDevicePosition changePosition = curPosotion == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack:AVCaptureDevicePositionFront;
    
    //获取改变的摄像头设备
    AVCaptureDevice * changeDevice = [self getVideoDevice:changePosition];
    
    //获取改变的摄像头的输入设备
    AVCaptureDeviceInput * changeDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:changeDevice error:nil];
    
    //移除之前的摄像头输入设备
    [_captureSession removeInput:_currentVideoDeviceInput];
    
    //添加新的输入设备
    [_captureSession addInput:changeDeviceInput];
    
    //记录当前的输入设备
    _currentVideoDeviceInput = changeDeviceInput;
    
}

//聚焦光标
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //获取点击位置
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    //将当前位置转换成摄像头点上的位置
    CGPoint cameraPoint = [_previewLayer captureDevicePointOfInterestForPoint:point];
    
    //设置聚焦点光标位置
    [self setFocusCursorWithPoint:point];
    
    //设置聚焦
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

- (void)setFocusCursorWithPoint:(CGPoint)point{
    
    self.focusCursorImageView.center = point;
    self.focusCursorImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursorImageView.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursorImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursorImageView.alpha = 0;
    }];
    
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    
    AVCaptureDevice * captureDevice = _currentVideoDeviceInput.device;
    
    //锁定配置
    [captureDevice lockForConfiguration:nil];
    
    //设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    //设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:point];
    }
    
    //解锁配置
    [captureDevice unlockForConfiguration];
    
}

- (void)setupCaptureVideo{
    //1.创建捕获会话  强引用 否则会释放
    AVCaptureSession * captureSession = [[AVCaptureSession alloc]init];
    _captureSession = captureSession;
    
    //2.获取视频设备  默认后摄像头
    AVCaptureDevice * videoDevice = [self getVideoDevice:AVCaptureDevicePositionFront];
    
    //3.获取音频设备
    AVCaptureDevice * audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //4.视频设备输入对象
    AVCaptureDeviceInput * videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    _currentVideoDeviceInput = videoDeviceInput;
    
    //5.音频设备输入对象
    AVCaptureDeviceInput * audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    //6.添加到会话
    if ([captureSession canAddInput:videoDeviceInput]) {
        [captureSession addInput:videoDeviceInput];
    }
    if ([captureSession canAddInput:audioDeviceInput]) {
        [captureSession addInput:audioDeviceInput];
    }
    
    //7.获取视频数据输出设备
    AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    //7.1设置代理 捕获视频样品数据
    //注：队列必须串行队列 才可获取到数据  且不能为空
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    if ([captureSession canAddOutput:videoOutput]) {
        [captureSession addOutput:videoOutput];
    }
    
    //8.获取音频数据输出设备
    AVCaptureAudioDataOutput * audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
    if ([captureSession canAddOutput:audioOutput]) {
        [captureSession addOutput:audioOutput];
    }
    
    //9.获取视频输入与输出 用于分辨音视频数据
    _connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //10.添加视频预览图层
    AVCaptureVideoPreviewLayer * previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer insertSublayer:previewLayer atIndex:0];
    _previewLayer = previewLayer;
    
    //11.启动会话
    [captureSession stopRunning];
    
}

- (AVCaptureDevice *)getVideoDevice:(AVCaptureDevicePosition)position{
    
    //    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //
    //    if (device.position == position) {
    //        return device;
    //    }
    //    return nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];//此方法已废弃
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (_connection == connection) {
        NSLog(@"采集到视频数据");
    }else{
        NSLog(@"采集到音频数据");
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
