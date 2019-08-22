//
//  YWCommomModel.h
//  YWFMDBExamples
//
//  Created by Mr.Yao on 2019/8/22.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YWSqlModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface YWCommomModel : NSObject<YWSqlModelProtocol>
@property (nonatomic,  copy) NSString *name;
@end

NS_ASSUME_NONNULL_END
