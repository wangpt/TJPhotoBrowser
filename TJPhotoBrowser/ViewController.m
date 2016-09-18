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
@property (nonatomic,strong) MWPhotoBrowser *webphotoBrowser;
@property (nonatomic, strong) NSArray *imageUrls;

@end


@implementation ViewController
-(MWPhotoBrowser *)webphotoBrowser{
    if (!_webphotoBrowser) {
        _webphotoBrowser= [[MWPhotoBrowser alloc] initWithDelegate:self];
        _webphotoBrowser.displayNavArrows = YES;
        _webphotoBrowser.enableSwipeToDismiss = YES;
    }
    return _webphotoBrowser;
    
}
#pragma mark - customlize method

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


#pragma mark - UIWebViewDelegate method

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    //预览图片
    if ([request.URL.scheme isEqualToString:@"image-preview"]) {
        NSString* path = [request.URL.absoluteString substringFromIndex:[@"image-preview:" length]];
        path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self showWithPath:path];
        
        return NO;
    }
    return YES;
    
}
- (void)showWithPath:(NSString *)path{
    __block NSInteger index = 0;
    if ([self.imageUrls containsObject:path]) {
        [self.imageUrls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *url =obj;
            if ([url isEqualToString:path]) {
                index=idx;
                *stop = YES;
                
            }
        }];
    }
    [self.webphotoBrowser setCurrentPhotoIndex:index];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.webphotoBrowser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nc animated:YES completion:nil];
    
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    //注入js
    static  NSString * const jsGetImages =
    @"function getImages(){\
    var objs = document.getElementsByTagName(\"img\");\
    var imgScr = '';\
    for(var i=0;i<objs.length;i++){\
    imgScr = imgScr + objs[i].src + '+';\
    };\
    return imgScr;\
    };";
    [webView stringByEvaluatingJavaScriptFromString:jsGetImages];//注入js方法
    NSString *urlResurlt = [webView stringByEvaluatingJavaScriptFromString:@"getImages()"];
    NSMutableArray *mUrlArray = [NSMutableArray arrayWithArray:[urlResurlt componentsSeparatedByString:@"+"]];
    if (mUrlArray.count >= 2) {
        [mUrlArray removeLastObject];
    }
    self.imageUrls=mUrlArray;
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    [mUrlArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [photos addObject:[MWPhoto photoWithURL:[NSURL URLWithString:obj]]];
        
    }];
    self.photos=photos;
    //添加图片可点击js
    [webView stringByEvaluatingJavaScriptFromString:@"function registerImageClickAction(){\
     var imgs=document.getElementsByTagName('img');\
     var length=imgs.length;\
     for(var i=0;i<length;i++){\
     img=imgs[i];\
     img.onclick=function(){\
     window.location.href='image-preview:'+this.src}\
     }\
     }"];
    [webView stringByEvaluatingJavaScriptFromString:@"registerImageClickAction();"];
    
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
