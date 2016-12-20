//
//  ViewController.m
//  NetWorkRequest
//
//  Created by mibo02 on 16/12/20.
//  Copyright © 2016年 mibo02. All rights reserved.
//

#import "ViewController.h"
#import <PPNetworkHelper.h>

static NSString *const dataUrl = @"http://192.168.1.151/hmis/index";
static NSString *const downloadUrl = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *onetextview;

@property (weak, nonatomic) IBOutlet UITextView *twotextview;

@property (weak, nonatomic) IBOutlet UILabel *status;


@property (weak, nonatomic) IBOutlet UISwitch *swith;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;

//是否开启缓存
@property (nonatomic, assign, getter=isCache) BOOL cache;
//是否开始下载
@property (nonatomic, assign, getter=isDownload)BOOL download;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"网络缓存大小cache = %fMB",[PPNetworkCache getAllHttpCacheSize]/1024/1024.f);
    //实时监测网络状态
    [PPNetworkHelper networkStatusWithBlock:^(PPNetworkStatus status) {
        switch (status) {
            case PPNetworkStatusUnknown:
               
            case PPNetworkStatusNotReachable:
            {
                self.status.text = @"没有网络";
                [self getData:YES url:dataUrl];
                 NSLog(@"无网络,加载缓存数据");
            }
                break;
            case PPNetworkStatusReachableViaWWAN:
          
            case PPNetworkStatusReachableViaWiFi:
            {
                [self getData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:dataUrl];
            }
                break;
                
            default:
                break;
        }
    }];
    
    //一次性获取当前网络状态
    [self currentNetworkStatus];
    
    
}
- (void)currentNetworkStatus
{
    if (kIsNetwork) {
        NSLog(@"有网络");
        if (kIsWiFiNetwork)
            {
                NSLog(@"WiFi");
            }
        else if(kIsWWANNetwork)
            {
                NSLog(@"手机网络");
            }
        }
    
}



#pragma mark - get request
- (void)getData:(BOOL)isOn url:(NSString *)url
{
    if (isOn) {
        self.status.text = @"缓存打开";
        self.swith.on = YES;
        [PPNetworkHelper GET:url parameters:@{} responseCache:^(id responseCache) {
            self.twotextview.text = [self jsonToString:responseCache];
        } success:^(id responseObject) {
            self.onetextview.text = [self jsonToString:responseObject];
        } failure:^(NSError *error) {
            
        }];
        //无缓存
    } else {
        self.status.text = @"缓存关闭";
        self.swith.on = NO;
        self.twotextview.text = @"";
        //无缓存请求数据
        [PPNetworkHelper GET:url parameters:nil success:^(id responseObject) {
            self.onetextview.text = [self jsonToString:responseObject];
        } failure:^(NSError *error) {
            
        }];
    }
}
- (IBAction)downloadBtn:(id)sender
{
    static NSURLSessionTask *task = nil;
    //开始下载
    if (!self.isDownload) {
        self.download = YES;
        [self.downBtn setTitle:@"取消下载" forState:(UIControlStateNormal)];
        //下载至沙盒中的制定文件夹
        task = [PPNetworkHelper downloadWithURL:downloadUrl fileDir:@"Download" progress:^(NSProgress *progress) {
            CGFloat stauts = 100.f * progress.completedUnitCount / progress.totalUnitCount;
             NSLog(@"下载进度 :%.2f%%,,%@",stauts,[NSThread currentThread]);
        } success:^(NSString *filePath) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"下载完成" message:[NSString stringWithFormat:@"文件路径:%@",filePath] preferredStyle:(UIAlertControllerStyleActionSheet)];
            UIAlertAction *firstaction  = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil];
            [alert addAction:firstaction];
            [self presentViewController:alert animated:YES completion:nil];
            
            [self.downBtn setTitle:@"重新下载" forState:(UIControlStateNormal)];
        } failure:^(NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载失败"
                                                                message:[NSString stringWithFormat:@"%@",error]
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
            NSLog(@"error = %@",error);
        }];
    }
    //暂停下载
    else
    {
        self.download = NO;
        [task suspend];
        self.progress.progress = 0;
        [self.downBtn setTitle:@"开始下载" forState:(UIControlStateNormal)];
    }
}
//开关
- (IBAction)switchAction:(UISwitch *)sender
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];
    [self getData:sender.isOn url:dataUrl];
}

//json格式转字符串
- (NSString *)jsonToString:(NSDictionary *)dic
{
    if (!dic) {
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
