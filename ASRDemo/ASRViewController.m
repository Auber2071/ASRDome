//
//  ASRViewController.m
//  ASRDemo
//
//  Created by hankai on 2017/10/25.
//  Copyright © 2017年 Vencent. All rights reserved.
//

#import "ASRViewController.h"

//只需要使用识别功能，只需要引入如下头文件
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"


//#error "请在官网新建应用，配置包名，并在此填写应用的 api key, secret key, appid(即appcode)"
const NSString* API_KEY = @"l8GabTO8iPSFYVQvPAvKHZ1f";
const NSString* SECRET_KEY = @"X47TYD5zUHjjgsqnHysZS3Or6qpHjRVT";
const NSString* APP_ID = @"10281890";

@interface ASRViewController ()<BDSClientASRDelegate>

//语音识别
@property (nonatomic, strong) BDSEventManager *asrEventManager;

//UI 布局
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *recognitionBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;


@end

@implementation ASRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configurationOnLineASR];
}

- (IBAction)startRecognition:(id)sender {
#if !TARGET_IPHONE_SIMULATOR

    // 4.发送指令：启动识别
    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
#endif

}

- (IBAction)finishRecognition:(id)sender {
    self.finishBtn.enabled = NO;
#if !TARGET_IPHONE_SIMULATOR
    [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
#endif

}

//取消
- (IBAction)cancelRecognition:(id)sender {
    self.finishBtn.enabled = NO;
    self.cancelBtn.enabled = NO;
#if !TARGET_IPHONE_SIMULATOR
    [self.asrEventManager sendCommand:BDS_ASR_CMD_CANCEL];
#endif

}




//在线识别
-(void)configurationOnLineASR{
#if !TARGET_IPHONE_SIMULATOR

    // 1.创建语音识别对象
    self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
    // 2.设置语音识别代理
    [self.asrEventManager setDelegate:self];
    // 3.1参数配置：在线身份验证
    [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    //3.2参数配置：设置 APPID
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    //4.发送指令：启动识别
    //[self.asrEventManager sendCommand:BDS_ASR_CMD_START];
    
    /********************************************************************************/
    //3.2 离在线并行识别
    /********************************************************************************/
    /*
    //3.3长语音识别
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_NEED_CACHE_AUDIO];
    [self.asrEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    // 长语音请务必开启本地VAD
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
     */
    /********************************************************************************/
    //3.4端点检测，即自动检测音频输入的起始点和结束点，如果需要自行控制识别结束需关闭VAD，请同时关闭服务端VAD与端上VAD：
    // 关闭服务端VAD
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_EARLY_RETURN];
    // 关闭本地VAD
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
    
    /********************************************************************************/
    //3.5 语义理解
    // 开启在线语义
    [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
#endif

}


#pragma mark - BDSClientASRDelegate
// 语音识别状态、录音数据等回调均在此代理中发生，具体事件请参考Demo工程中对不同workStatus的处理流程。(TBDVoiceRecognitionClientWorkStatus)
- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
#if !TARGET_IPHONE_SIMULATOR

    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            NSDictionary *logDic = [self p_parseLogToDic:aObj];
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: start vr, log: %@\n", logDic]];
            [self p_onStartRecognition];
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: {
            [self p_printLogTextView:@"CALLBACK: detect voice start point.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
            [self p_printLogTextView:@"CALLBACK: detect voice end point.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: partial result - %@.\n\n", [self p_getDescriptionForDic:aObj]]];
            if (aObj) {
                NSArray *tempArray = aObj[@"results_recognition"];
                NSString *resultStr = tempArray.count>0?tempArray[0]:@"";
                self.resultTextView.text = resultStr;
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: final result - %@.\n\n", [self p_getDescriptionForDic:aObj]]];
            if (aObj) {
                NSArray *tempArray = aObj[@"results_recognition"];
                NSString *resultStr = tempArray.count>0?tempArray[0]:@"";
                self.resultTextView.text = resultStr;
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            [self p_printLogTextView:@"CALLBACK: user press cancel.\n"];
            [self p_onEndRecognition];
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            [self p_onEndRecognition];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLoaded: {
            [self p_printLogTextView:@"CALLBACK: offline engine loaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            [self p_printLogTextView:@"CALLBACK: offline engine unLoaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk 3-party data length: %lu\n", (unsigned long)[(NSData *)aObj length]]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk NLU data: %@\n", nlu]];
            
            if (aObj) {
                NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:aObj options:NSJSONReadingMutableContainers error:nil];
                NSString *resultStr = tempDict[@"merged_res"][@"semantic_form"][@"raw_text"];
                self.resultTextView.text = resultStr;
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk end, sn: %@.\n", aObj]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFeedback: {
            NSDictionary *logDic = [self p_parseLogToDic:aObj];
            [self p_printLogTextView:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            [self p_printLogTextView:@"CALLBACK: recorder closed.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            [self p_printLogTextView:@"CALLBACK: Long Speech end.\n"];
            [self p_onEndRecognition];
            break;
        }
        default:
            break;
    }
#endif

}




#pragma mark - Private Methods
- (void)p_printLogTextView:(NSString *)logString{
    //self.logTextView.text = [logString stringByAppendingString:_logTextView.text];
    NSLog(@"%@",logString);
    //[self.logTextView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)p_onStartRecognition{
    self.finishBtn.enabled = YES;
    self.finishBtn.enabled = YES;
    [self.recognitionBtn setTitle:@"Speaking..." forState:UIControlStateNormal];
}


- (void)p_onEndRecognition{
    self.finishBtn.enabled = NO;
    self.cancelBtn.enabled = NO;
    self.recognitionBtn.enabled = YES;
    [self.recognitionBtn setTitle:@"语音识别" forState:UIControlStateNormal];
}
- (NSString *)p_getDescriptionForDic:(NSDictionary *)dic {
    if (dic) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                              options:NSJSONWritingPrettyPrinted
                                                                                error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSDictionary *)p_parseLogToDic:(NSString *)logString{
    NSArray *tmp = NULL;
    NSMutableDictionary *logDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSArray *items = [logString componentsSeparatedByString:@"&"];
    for (NSString *item in items) {
        tmp = [item componentsSeparatedByString:@"="];
        if (tmp.count == 2) {
            [logDic setObject:tmp.lastObject forKey:tmp.firstObject];
        }
    }
    return logDic;
}

@end
