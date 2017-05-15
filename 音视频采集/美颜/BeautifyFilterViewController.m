//
//  BeautifyFilterViewController.m
//  音视频采集
//
//  Created by renren on 2017/5/12.
//  Copyright © 2017年 renyanping. All rights reserved.
//

#import "BeautifyFilterViewController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"

@interface BeautifyFilterViewController ()

@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
@property (nonatomic, strong) GPUImageView * captureVideoPreview;


@property (nonatomic, strong) UISwitch * filterSwitch;
@end

@implementation BeautifyFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createUI];
    [self setupGPUImage];
}

- (void)setupGPUImage{
    //创建视频
    GPUImageVideoCamera * videoCamera = [[GPUImageVideoCamera alloc]initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    //创刊最终预览view
    GPUImageView * captureVideoPreview = [[GPUImageView alloc]initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];
    _captureVideoPreview = captureVideoPreview;
    
    //设置处理链
    [_videoCamera addTarget:captureVideoPreview];
    
    // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
    // 开始采集视频
    [_videoCamera startCameraCapture];
    
}

- (void)createUI{
    _filterSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(6, 20, 44, 44)];
    _filterSwitch.on = NO;
    [_filterSwitch addTarget:self action:@selector(isAddFilter:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_filterSwitch];
    
    
}

- (void)isAddFilter:(UISwitch *)sender{
    //切换美颜原理  移除之前的处理链 重新设置处理链
    if (sender.on) {
        //美颜
        [_videoCamera removeAllTargets];
        
        //创建美颜滤镜
        GPUImageBeautifyFilter * beautifuFilter = [[GPUImageBeautifyFilter alloc]init];
        
        //设置处理链  数据源--》滤镜——》展示
        [_videoCamera addTarget:beautifuFilter];
        [beautifuFilter addTarget:_captureVideoPreview];
        
    }else{
        //非美颜
        //移除之前的所有处理链
        [_videoCamera removeAllTargets];
        [_videoCamera addTarget:_captureVideoPreview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
