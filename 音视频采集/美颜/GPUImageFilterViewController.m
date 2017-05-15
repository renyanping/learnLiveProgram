//
//  GPUImageFilterViewController.m
//  音视频采集
//
//  Created by renren on 2017/5/12.
//  Copyright © 2017年 renyanping. All rights reserved.
//

#import "GPUImageFilterViewController.h"
#import <GPUImage/GPUImage.h>

@interface GPUImageFilterViewController ()

@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
@property (nonatomic, strong) GPUImageBilateralFilter * bilateralFilter;
@property (nonatomic, strong) GPUImageBrightnessFilter * brightnessFilter;

@end

@implementation GPUImageFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createUI];
    
    [self setupGPUFilter];
}

- (void)setupGPUFilter{
    //创建视频源
    // SessionPreset:屏幕分辨率，AVCaptureSessionPresetHigh会自适应高分辨率
    // cameraPosition:摄像头方向
    GPUImageVideoCamera * videoCamera = [[GPUImageVideoCamera alloc]initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera = videoCamera;
    
    //创建最终预览的view
    GPUImageView * captureVideoPreview = [[GPUImageView alloc]initWithFrame:self.view.bounds];
    [self.view insertSubview:captureVideoPreview atIndex:0];
    
    //创建滤镜：磨皮，美白——>组合滤镜
    GPUImageFilterGroup * groupFilter = [[GPUImageFilterGroup alloc]init];
    
    //磨皮滤镜
    GPUImageBilateralFilter * bilateralFilter = [[GPUImageBilateralFilter alloc]init];
    [groupFilter addTarget:bilateralFilter];
    _bilateralFilter = bilateralFilter;
    
    //美白滤镜
    GPUImageBrightnessFilter * brightnessFilter = [[GPUImageBrightnessFilter alloc]init];
    [groupFilter addTarget:brightnessFilter];
    _brightnessFilter = brightnessFilter;
    
    //设置滤镜组链
    [bilateralFilter addTarget:brightnessFilter];
    [groupFilter setInitialFilters:@[bilateralFilter]];
    groupFilter.terminalFilter = bilateralFilter;
    
    //设置GPUImage的响应链 从数据源videoCamera——>滤镜groupFilter——>最终界面效果captureVideoPreview
    [videoCamera addTarget:groupFilter];
    [groupFilter addTarget:captureVideoPreview];
    
    // 必须调用startCameraCapture，底层才会把采集到的视频源，渲染到GPUImageView中，就能显示了。
    //开始采集
    [videoCamera startCameraCapture];
    
}

- (void)createUI{
    UISlider * bilateralSlider = [[UISlider alloc]initWithFrame:CGRectMake(20, ScreenHeight - 100, ScreenWidth - 40, 20)];
    bilateralSlider.minimumValue = 0;
    bilateralSlider.maximumValue = 10;
    bilateralSlider.value = 5;
    bilateralSlider.minimumTrackTintColor = [UIColor blueColor];
    bilateralSlider.tag = 1;
    [bilateralSlider addTarget:self action:@selector(changeValueSlider:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:bilateralSlider];
    
    UISlider * brightnessSlider = [[UISlider alloc]initWithFrame:CGRectMake(20, ScreenHeight - 50, ScreenWidth - 40, 20)];
    brightnessSlider.minimumValue = 0;
    brightnessSlider.maximumValue = 10;
    brightnessSlider.value = 5;
    brightnessSlider.minimumTrackTintColor = [UIColor blueColor];
    brightnessSlider.tag = 2;
    [brightnessSlider addTarget:self action:@selector(changeValueSlider:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:brightnessSlider];
}

- (void)changeValueSlider:(UISlider *)slider{
    if (slider.tag == 1) {
        //磨皮  值越小，磨皮效果越好
        CGFloat macFloat = 10;
        [_bilateralFilter setDistanceNormalizationFactor:macFloat - slider.value];
    }else{
        //美白
        _brightnessFilter.brightness = slider.value;
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
