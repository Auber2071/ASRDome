//
//  HKASRRecognitionTool.h
//  ASRDemo
//
//  Created by hankai on 2017/12/19.
//  Copyright © 2017年 Vencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    ///识别开始
    RecognitionStart,
    ///识别进行中
    Recognitioning,
    ///识别结束
    RecognitionEnd,
    ///语义化结束
    RecognitionSemantization,
    ///识别有误
    RecognitionError
} HKVoiceRecognitionClientWorkStatus;

@protocol   HKASRRecognitionToolDelegate <NSObject>
//识别开始
-(void)recognitionWithRecognitionState:(HKVoiceRecognitionClientWorkStatus)state param:(NSString*)param;


@end

@interface HKASRRecognitionTool : NSObject
@property (nonatomic, assign) id<HKASRRecognitionToolDelegate> delegate;

 ///开始识别
- (void)startRecognition;

 ///结束识别
- (void)finishRecognition;

///取消识别
- (void)cancelRecognition;

@end
