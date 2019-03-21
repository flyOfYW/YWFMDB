//
//  YWPerson.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/20.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YWSqlModelProtocol.h"

@class YWUser;
NS_ASSUME_NONNULL_BEGIN

@interface YWPerson : NSObject <YWSqlModelProtocol>

@property (nonatomic,  copy) NSString *name;

@property (nonatomic, assign) NSInteger age;

@property (nonatomic, copy) NSString *phone;

@property (nonatomic, assign) CGFloat weight;

@property (nonatomic, assign) CGFloat height;

@property (nonatomic,   copy) NSString *menu;

@property (nonatomic,   copy) NSString *email;

@property (nonatomic,   copy) NSString *qq;

@property (nonatomic,   copy) NSString *weChat;

@property (nonatomic,   strong) NSArray <YWUser *>*list;

@property (nonatomic,   strong) NSDictionary *dict;

@property (nonatomic,   assign) BOOL setelec;

@property (nonatomic,   strong) YWUser *user;


@end

@interface YWUser : NSObject <NSCoding>

@property (nonatomic, strong) NSNumber *userId;

@property (nonatomic,   copy) NSString *userName;

@end


NS_ASSUME_NONNULL_END
