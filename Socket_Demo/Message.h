//
//  Message.h
//  Socket_Demo
//
//  Created by 夏桂峰 on 15/11/8.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import <Foundation/Foundation.h>

//消息类型
typedef NS_ENUM(NSInteger, MessageType) {
    MessageTypeSend=0,//发送的消息
    MessageTypeReceive//接收的消息
};

@interface Message : NSObject
//消息
@property(nonatomic,strong)NSString *msg;
//消息类型
@property(nonatomic,assign)MessageType messageType;
//初始化方法
+(instancetype)messageWithMsg:(NSString *)msg andType:(MessageType)messageType;

@end
