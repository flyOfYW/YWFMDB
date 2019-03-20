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

要求
==============
* iOS 8.0 or later
* Xcode 8.0 or later


集成
==============
* 不需加密: pod 'YWFMDB'
* 需加密数据库: pod 'YWFMDB/SQLCipher'

注意
==============
* 在需要对数据表自定义相关信息请先查看YWSqlModelProtocol协议
- 当模型类有新增/删除属性的时候需要在模型类实现sql_version并返回相应的版本号来表明有字段更新操作，YWFMDB会根据这个VERSION变更智能检查并自动更新数据库字段，无需手动更新数据库字段
- 当模型类需要忽略属性存储字段时，请实现sql_ignoreTheField协议方法即可return要忽略属性名称集合
- 如果自定义主键时，请实现sql_mainKey协议方法即可return主键字段（默认db_id）
- 如果自定义表名时，请实现sql_tableName协议方法即可return表名（默认是存储类的类名）

```objective-c
@protocol YWSqlModelProtocol <NSObject>
@optional
/**
 自定义主键名，切勿可跟对象的属性名一样
 
 @return 主键名（默认db_id）
 */
- (NSString *)sql_mainKey;
/**
 表名（默认是model的类名）

 @return 表名
 */
- (NSString *)sql_tableName;
/**
 表的版本号（默认1.0）

 @return 表的版本号
 */
- (NSNumber *)sql_version;
/**
 忽略的存储字段

 @return 忽略的存储字段
 */
- (NSSet<NSString *>*)sql_ignoreTheField;

```
