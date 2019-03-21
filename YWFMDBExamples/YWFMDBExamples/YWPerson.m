//
//  YWPerson.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/20.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWPerson.h"

@implementation YWPerson

- (NSNumber *)sql_version{
    return @2.1;
}

- (NSSet<NSString *> *)sql_CustomClassAsField{
    return [NSSet setWithObjects:@"YWUser", nil];
}

@end


@implementation YWUser

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self.userId = [aDecoder decodeObjectForKey:@"userId"];
    self.userName = [aDecoder decodeObjectForKey:@"userName"];
    return self;
}

@end
