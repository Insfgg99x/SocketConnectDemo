//
//  Message.m
//  Socket_Demo
//
//  Created by 夏桂峰 on 15/11/8.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import "Message.h"

@implementation Message

+(instancetype)messageWithMsg:(NSString *)msg andType:(MessageType)messageType
{
    Message *message=[[Message alloc]init];
    message.msg=msg;
    message.messageType=messageType;
    return message;
}

@end
