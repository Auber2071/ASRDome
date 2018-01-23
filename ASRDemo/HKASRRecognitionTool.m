//
//  HKASRRecognitionTool.m
//  ASRDemo
//
//  Created by hankai on 2017/12/19.
//  Copyright © 2017年 Vencent. All rights reserved.
//

#import "HKASRRecognitionTool.h"

//只需要使用识别功能，只需要引入如下头文件
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"


//#error "请在官网新建应用，配置包名，并在此填写应用的 api key, secret key, appid(即appcode)"
const NSString* HK_API_KEY = @"l8GabTO8iPSFYVQvPAvKHZ1f";
const NSString* HK_SECRET_KEY = @"X47TYD5zUHjjgsqnHysZS3Or6qpHjRVT";
const NSString* HK_APP_ID = @"10281890";

@interface HKASRRecognitionTool ()<BDSClientASRDelegate>

//语音识别
@property (nonatomic, strong) BDSEventManager *asrEventManager;

@end


@implementation HKASRRecognitionTool

-(instancetype)init{
    self = [super init];
    if (self) {
        [self configurationOnLineASR];
    }
    return self;
}

 ///开始识别
- (void)startRecognition{

#if !TARGET_IPHONE_SIMULATOR
    //4.发送指令：启动识别
    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
#endif
}

 ///结束识别
- (void)finishRecognition{
#if !TARGET_IPHONE_SIMULATOR

    //4.发送指令：结束识别
    [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
#endif

}

 ///取消识别
- (void)cancelRecognition{

#if !TARGET_IPHONE_SIMULATOR
    //4.发送指令：取消识别
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
    [self.asrEventManager setParameter:@[HK_API_KEY, HK_SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    //3.2参数配置：设置 APPID
    [self.asrEventManager setParameter:HK_APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];

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


#pragma mark - BDSClientdelegate
// 语音识别状态、录音数据等回调均在此代理中发生，具体事件请参考Demo工程中对不同workStatus的处理流程。
- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
#if !TARGET_IPHONE_SIMULATOR

    switch (workStatus) {//workStatus:TBDVoiceRecognitionClientWorkStatus
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            NSDictionary *logDic = [self p_parseLogToDic:aObj];
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: start vr, log: %@\n", logDic]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: {
            [self p_printLog:@"CALLBACK: detect voice start point.\n"];
            if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionWithRecognitionState:param:)]) {
                [self.delegate recognitionWithRecognitionState:RecognitionStart param:@""];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
            [self p_printLog:@"CALLBACK: detect voice end point.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: partial result - %@.\n\n", [self p_getDescriptionForDic:aObj]]];
            if (aObj) {
                NSArray *tempArray = aObj[@"results_recognition"];
                NSString *resultStr = tempArray.count>0?tempArray[0]:@"";
                DLog(@"正在识别：%@",resultStr);
                if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionWithRecognitionState:param:)]) {
                    [self.delegate recognitionWithRecognitionState:Recognitioning param:resultStr];
                }
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: final result - %@.\n\n", [self p_getDescriptionForDic:aObj]]];

            if (aObj) {
                NSArray *tempArray = aObj[@"results_recognition"];
                NSString *resultStr = tempArray.count>0?tempArray[0]:@"";
                DLog(@"识别结束：%@",resultStr);

                if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionWithRecognitionState:param:)]) {
                    [self.delegate recognitionWithRecognitionState:RecognitionEnd param:resultStr];
                }
            }
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            [self p_printLog:@"CALLBACK: user press cancel.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionWithRecognitionState:param:)]) {
                [self.delegate recognitionWithRecognitionState:RecognitionError param:[aObj localizedDescription]];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusLoaded: {
            [self p_printLog:@"CALLBACK: offline engine loaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            [self p_printLog:@"CALLBACK: offline engine unLoaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: Chunk 3-party data length: %lu\n", (unsigned long)[(NSData *)aObj length]]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: Chunk NLU data: %@\n", nlu]];
            if (aObj) {
                NSDictionary *tempDict = [NSJSONSerialization JSONObjectWithData:aObj options:NSJSONReadingMutableContainers error:nil];
                NSString *resultStr = tempDict[@"merged_res"][@"semantic_form"][@"raw_text"];
                if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionWithRecognitionState:param:)]) {
                    [self.delegate recognitionWithRecognitionState:RecognitionSemantization param:resultStr];
                }
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK: Chunk end, sn: %@.\n", aObj]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFeedback: {
            NSDictionary *logDic = [self p_parseLogToDic:aObj];
            [self p_printLog:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            [self p_printLog:@"CALLBACK: recorder closed.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            [self p_printLog:@"CALLBACK: Long Speech end.\n"];
            break;
        }
        default:
            break;
    }
#endif
}




#pragma mark - Private Methods
- (void)p_printLog:(NSString *)logString{
    NSLog(@"%@",logString);
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
