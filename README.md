# YWFMDB
基于FMDB对model和字典的直接操作

简介
==============
- **架构**: 采用runtime和FMDB完美结合打造的强大数据库操作
- **安全**: 支持数据库级别加密
- **易用**: 真正实现一行代码操作数据库
- **目标**: 替代手写sql语句方式
- **支持**: (NSString,NSNumber,Int,double,float,Bool)类型
- **灵活**: 依据模型类实现的YWSqlModelProtocol协议,支持忽略模型类属性存储数据表中
- **智能**: 根据模型类实现的YWSqlModelProtocol协议返回的版本号即时更新数据库字段(动态删除/添加)
