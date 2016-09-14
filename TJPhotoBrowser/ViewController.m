//
//  ViewController.m
//  TJPhotoBrowser
//
//  Created by 王朋涛 on 16/9/12.
//  Copyright © 2016年 王朋涛. All rights reserved.
//

#import "ViewController.h"
#import "MJPhotoProgressView.h"
#define kMinProgress 0.0001
@interface ViewController ()
{
    UILabel *_failureLabel;

}
@property (nonatomic) float progress;
@property (nonatomic, strong) NSMutableArray *photos;

@end


@implementation ViewController
#pragma mark - customlize method

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    NSMutableArray *photos = [[NSMutableArray alloc] init];
    [photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://pic32.nipic.com/20130829/12906030_124355855000_2.png"]]];
    //            photo.caption = @"The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England.";

    
    self.photos=photos;
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;//显示动作按钮，允许共享，复制等（默认为是）
    browser.displayNavArrows = YES;//是否显示导航工具栏上的左、右箭头（默认为否）
    browser.displaySelectionButtons = NO;//是否选择按钮显示在每个图像（默认为NO）
    browser.alwaysShowControls = NO;//允许导航控制器一直显示（(默认为NO）
    browser.zoomPhotosToFill = YES;//图像几乎填满屏幕将初步放大填充（默认为是）
    browser.enableGrid = YES;//是否允许在网格的所有照片缩略图查看（默认为是）
    browser.startOnGrid = NO;//是否开始对缩略图网格代替第一张照片（默认为否）
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = NO;//自动播放
    [browser setCurrentPhotoIndex:0];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nc animated:YES completion:nil];

}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}


- (void)timer:(NSObject *)obj{
    MJPhotoProgressView *waiting=(MJPhotoProgressView *)obj;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block float timeout=0; //倒计时时间
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout>=1){ //倒计时结束，关闭
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
                waiting.progress = timeout;

                [self setProgress:timeout];
            });
        }else{
            float strTime = timeout;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"timeout:%f",strTime);
                
                //                self.progress=timeout;
                waiting.progress = strTime;
                [self setProgress:timeout];

            });
            timeout+=0.1;
            
        }
    });

    dispatch_resume(_timer);


}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
