//
//  ViewController.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/19.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "ViewController.h"
#import "YWFMDB.h"
#import <YWExcel/YWExcelView.h>
#import "YWPerson.h"


@interface ViewController ()
<YWExcelViewDelegate,YWExcelViewDataSource>
{
    UIButton *_currentBtn;
    NSMutableArray *_names;
    NSMutableArray *_phones;
    NSMutableArray *_menus;
    NSMutableArray *_emails;
    NSMutableArray *_qqs;
    NSMutableArray *_weights;
    NSMutableArray *_heights;
    NSMutableArray *_ages;
    NSMutableArray *_dbList;
    UITextField *_tf;
    UITextField *_qf;
}
@property (weak, nonatomic) IBOutlet UIButton *insertBtn;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) YWExcelView *dbExcelView;
@property (nonatomic, strong) UILabel *queryLabel;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self insertAction:self.insertBtn];
    _dbList = @[].mutableCopy;
    [self setupView];
    
    NSString *path = [NSString stringWithFormat:@"%@/Library/Caches/YWSqlite.db",NSHomeDirectory()];
    //创建数据库,并连接
    [YWFMDB connectionDB:path];
 
    [self initData];

    [self reloadList];
}

- (IBAction)insertAction:(id)sender {
    [_tf endEditing:YES];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, self.view.frame.size.width, 200) animated:YES];
    [self setSelect:sender];
}
- (IBAction)updateAction:(id)sender {
    [_tf endEditing:YES];
    [self.scrollView scrollRectToVisible:CGRectMake(CGRectGetWidth(self.view.frame), 0, CGRectGetWidth(self.view.frame), 200) animated:YES];
    [self setSelect:sender];
}
- (IBAction)deleteAction:(id)sender {
    [_tf endEditing:YES];
    [self.scrollView scrollRectToVisible:CGRectMake(CGRectGetWidth(self.view.frame) * 2, 0, CGRectGetWidth(self.view.frame), 200) animated:YES];
    [self setSelect:sender];
}
- (IBAction)queryAction:(id)sender {
    [_tf endEditing:YES];
    [self.scrollView scrollRectToVisible:CGRectMake(CGRectGetWidth(self.view.frame) * 3, 0, CGRectGetWidth(self.view.frame), 200) animated:YES];
    [self setSelect:sender];
}

//MARK: --- 插入
- (void)insertOne:(UIButton *)btn{
    if (btn.tag == 100) {
        int index = [self arcrandom];
        YWPerson *p = [YWPerson new];
        p.name = _names[index];
        p.age = [_ages[index] integerValue];
        p.phone = _phones[index];
        p.weight = [_weights[index] floatValue];
        p.height = [_heights[index] floatValue];
        p.menu = _menus[index];
        p.email = _emails[index];
        p.qq = _qqs[index];
        p.weChat = _qqs[index];
        [YWFMDB storageModel:p checkTableStructure:NO];
    }else{
        NSMutableArray *marr = @[].mutableCopy;
        for (int i = 0; i < 5; i ++) {
            int index = [self arcrandom];
            YWPerson *p = [YWPerson new];
            p.name = _names[index];
            p.age = [_ages[index] integerValue];
            p.phone = _phones[index];
            p.weight = [_weights[index] floatValue];
            p.height = [_heights[index] floatValue];
            p.menu = _menus[index];
            p.email = _emails[index];
            p.qq = _qqs[index];
            p.weChat = _qqs[index];
            [marr addObject:p];
        }
        [YWFMDB storageModels:marr checkTableStructure:NO];
    }
    [self reloadList];
}
//MARK: --- 更新
- (void)updateOne:(UIButton *)btn{
    if (btn.tag == 102) {
        [YWFMDB updateWithModel:[YWPerson class] specifiedValue:@{@"age":@"21"} checkTableStructure:NO where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"yw"]]];
    }else{
        int index = [self arcrandom];
        YWPerson *p = [YWPerson new];
        p.name = @"lpl";
        p.age = [_ages[index] integerValue];
        p.phone = _phones[index];
        p.weight = [_weights[index] floatValue];
        p.height = [_heights[index] floatValue];
        p.menu = _menus[index];
        p.email = _emails[index];
        p.qq = _qqs[index];
        p.weChat = _qqs[index];
        [YWFMDB updateWithModel:p checkTableStructure:NO where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"lpl"]]];
    }
    [self reloadList];
}
//MARK: --- 删除
- (void)deleteOne:(UIButton *)btn{
    [_tf endEditing:YES];
    if (btn.tag == 104) {
        [YWFMDB deleteTableWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:_tf.text]]];
    }else{
        [YWFMDB deleteTableWithModel:[YWPerson class]];
    }
    [self reloadList];
}
//MARK: --- 查询
- (void)queryOne:(UIButton *)btn{
    [_tf endEditing:YES];
    [_qf endEditing:YES];

    NSArray *list = @[];
    if (btn.tag == 106) {
        list = [YWFMDB queryWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:_qf.text]]];
    }else if (btn.tag == 107){
        NSString *likeString = [NSString stringWithFormat:@"%@%@%@",@"%",_qf.text,@"%"];
       list = [YWFMDB queryWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:like value:likeString]] order:@[[YWFieldOrder fieldOrderWithField:@"age" direction:desc]]];
    }else if (btn.tag == 108){
        //第零页，每次只返回3个
       list = [YWFMDB queryWithModel:[YWPerson class] limit:[YWPageable pageablePage:0 row:3]];
    }
    NSMutableString *me = [[NSMutableString alloc] initWithString:@""];
    for (YWPerson *p in list) {
        [me appendFormat:@"name=%@,age=%zi,phone=%@\n",p.name,p.age,p.phone];
    }
    if (me.length<=0) {
        [me appendString:@"查询不多相应的数据"];
    }
    _queryLabel.text = me.copy;
}
- (void)reloadList{
   NSArray *list = [YWFMDB queryWithModel:[YWPerson class]];
    [_dbList removeAllObjects];
    [_dbList addObjectsFromArray:list];
    [self.dbExcelView reloadData];
}
//MARK: --- YWExcelViewDataSource
//多少行
- (NSInteger)excelView:(YWExcelView *)excelView numberOfRowsInSection:(NSInteger)section{
    return _dbList.count;
}
//多少列
- (NSInteger)itemOfRow:(YWExcelView *)excelView{
    return 9;
}
- (void)excelView:(YWExcelView *)excelView label:(UILabel *)label textAtIndexPath:(YWIndexPath *)indexPath{
    if ( indexPath.row < _dbList.count) {
        YWPerson *p = _dbList[indexPath.row];
//        mode.headTexts = @[@"name",@"age",@"phone",@"weight",@"height",@"menu",@"email",@"qq",@"weChat"];
        switch (indexPath.item) {
            case 0:
                label.text = p.name;
                break;
            case 1:
                label.text = [NSString stringWithFormat:@"%zi",p.age];
                break;
            case 2:
                label.text = p.phone;
                break;
            case 3:
                label.text = [NSString stringWithFormat:@"%.2f",p.weight];
                break;
            case 4:
                label.text = [NSString stringWithFormat:@"%.2f",p.height];
                break;
            case 5:
                label.text = p.menu;
                break;
            case 6:
                label.text = p.email;
                break;
            case 7:
                label.text = p.qq;
                break;
            case 8:
                label.text = p.weChat;
                break;
            default:
                break;
        }
    }
}
//MARK: --- YWExcelViewDelegate
//自定义每列的宽度/默认每列的宽度为80
- (NSArray *)widthForItemOnExcelView:(YWExcelView *)excelView{
    return @[@(80),@(40),@(100),@(60),@(60),@(120),@(130),@(120),@(120)];
}
- (void)setupView{
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 340)];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 4, 340);
    [self.view addSubview:self.scrollView];
    
    [self setInsertView];
    
    [self setUpdateView];
    
    [self setDeleteView];
    
    [self setQueryView];

    UILabel *la = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scrollView.frame), CGRectGetWidth(self.view.frame),20)];
    la.text = @"模拟显示数据库中的Person表";
    la.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:la];

    YWExcelViewMode *mode = [[YWExcelViewMode alloc] init];
    mode.style = YWExcelViewStyleDefalut;
    mode.headTexts = @[@"name",@"age",@"phone",@"weight",@"height",@"menu",@"email",@"qq",@"weChat"];
    mode.defalutHeight = 30;
    CGFloat hei = CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.scrollView.frame) - 20;
    self.dbExcelView = [[YWExcelView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scrollView.frame)+20, CGRectGetWidth(self.view.frame),hei) mode:mode];
    self.dbExcelView.showBorder = YES;
    self.dbExcelView.showBorderColor = [UIColor grayColor];
    self.dbExcelView.delegate = self;
    self.dbExcelView.dataSource = self;
    [self.view addSubview:self.dbExcelView];
}
- (void)setInsertView{
    
    UIButton *btn1 = [self createTitle:@"插入一条数据" action:@selector(insertOne:)];
    btn1.tag = 100;
    btn1.frame = CGRectMake(20, 10, CGRectGetWidth(self.view.frame) -40, 30);
    UIButton *btn2 = [self createTitle:@"插入一组数据" action:@selector(insertOne:)];
    btn2.frame = CGRectMake(20, CGRectGetMaxY(btn1.frame)+10, CGRectGetWidth(self.view.frame) -40, 30);
    btn2.tag = 101;
    
    
}
- (void)setUpdateView{
    
    UIButton *btn1 = [self createTitle:@"更新name=yw,age改为21" action:@selector(updateOne:)];
    btn1.tag = 102;
    btn1.frame = CGRectMake(CGRectGetWidth(self.view.frame) + 20, 10, CGRectGetWidth(self.view.frame) - 40, 30);
    UIButton *btn2 = [self createTitle:@"更新name=lpl,所有的信息" action:@selector(updateOne:)];
    btn2.frame = CGRectMake(CGRectGetWidth(self.view.frame) + 20, CGRectGetMaxY(btn1.frame)+10, CGRectGetWidth(self.view.frame) -40, 30);
    btn2.tag = 103;
    
    
}
- (void)setDeleteView{
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)*2 + 20, 10, CGRectGetWidth(self.view.frame) - 40, 30)];
    tf.text = @"test";
    tf.borderStyle = UITextBorderStyleRoundedRect;
    _tf = tf;
    [self.scrollView addSubview:tf];
    
    UIButton *btn1 = [self createTitle:@"删除name=输入框的值" action:@selector(deleteOne:)];
    btn1.tag = 104;
    btn1.frame = CGRectMake(CGRectGetWidth(self.view.frame)*2 + 20, CGRectGetMaxY(tf.frame) + 10, CGRectGetWidth(self.view.frame) - 40, 30);
    UIButton *btn2 = [self createTitle:@"删除表中所有的数据" action:@selector(deleteOne:)];
    btn2.frame = CGRectMake(CGRectGetWidth(self.view.frame)*2 + 20, CGRectGetMaxY(btn1.frame)+10, CGRectGetWidth(self.view.frame) -40, 30);
    btn2.tag = 105;
    
    
}
- (void)setQueryView{
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)*3 + 20, 10, CGRectGetWidth(self.view.frame) - 40, 30)];
    tf.text = @"yw";
    tf.borderStyle = UITextBorderStyleRoundedRect;
    _qf = tf;
    [self.scrollView addSubview:tf];
    
    
    UIButton *btn1 = [self createTitle:@"查询name=输入框" action:@selector(queryOne:)];
    btn1.tag = 106;
    btn1.frame = CGRectMake(CGRectGetWidth(self.view.frame)*3 + 20, CGRectGetMaxY(tf.frame)+10, CGRectGetWidth(self.view.frame) - 40, 30);
    UIButton *btn2 = [self createTitle:@"查询name like '%输入框%',并按age desc 排序" action:@selector(queryOne:)];
    btn2.frame = CGRectMake(CGRectGetWidth(self.view.frame)*3 + 20, CGRectGetMaxY(btn1.frame)+10, CGRectGetWidth(self.view.frame) -40, 30);
    btn2.tag = 107;
    
    UIButton *btn3 = [self createTitle:@"查询name like '%输入框%',并分页显示" action:@selector(queryOne:)];
    btn3.frame = CGRectMake(CGRectGetWidth(self.view.frame)*3 + 20, CGRectGetMaxY(btn2.frame)+10, CGRectGetWidth(self.view.frame) -40, 30);
    btn3.tag = 108;
    
    _queryLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)*3 + 20, CGRectGetMaxY(btn3.frame)+10, CGRectGetWidth(self.view.frame)-40, CGRectGetHeight(self.scrollView.frame) - CGRectGetMaxY(btn1.frame)+10)];
    _queryLabel.numberOfLines = 0;
    _queryLabel.font = [UIFont systemFontOfSize:13];
    _queryLabel.textColor = [UIColor redColor];
    [self.scrollView addSubview:_queryLabel];
    
}


- (UIButton *)createTitle:(NSString *)ti action:(SEL)action{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:ti forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor lightGrayColor];
    [self.scrollView addSubview:btn];
    return btn;
}
- (void)setSelect:(UIButton *)sender{
    _currentBtn.selected = NO;
    _currentBtn.backgroundColor = [UIColor blackColor];
    _currentBtn = sender;
    _currentBtn.selected = YES;
    _currentBtn.backgroundColor = [UIColor lightGrayColor];
}

- (void)initData{

    _names = @[@"yw",@"lpl",@"test",@"lye",@"hgw",@"bghw",@"fghj",@"wer",@"hj",@"uytrew",@"pok",@"cvb",@"wer"].mutableCopy;
    _phones = @[@"13129352342",@"13129352890",@"13125652342",@"17629352342",@"19929352302",@"15129358842",@"19129952342",@"13929678342",@"13899352342",@"13889352342",@"19882352342",@"13129324567",@"13532852342"].mutableCopy;
    
    _menus = @[@"ywfghjkgbnkhnjh",@"fghjghjiuhjuh",@"asdfdsadfdss",@"lye",@"asdfdsasfsda",@"wqerewesw",@"fdsdfdda1",@"asdfdsdfda",@"gdfsdsad",@"gsdfasdfsasdsfad",@"pok",@"cvb",@"wer"].mutableCopy;
    _emails = @[@"1498627884@qq.com",@"2903491212@qq.com",@"1234567@qq.com",@"9876543@qq.com",@"12345345455@qq.com",@"234567890@qq.com",@"87654345678@qq.com",@"23456789@qq.com",@"765323456789@qq.com",@"543212345678@qq.com",@"ut32345678987@qq.com",@"7654345th@qq.com",@"ujhvbytrertyuj@qq.com"].mutableCopy;
    _qqs = @[@"1498627884",@"2903491212",@"1234567",@"9876543",@"12345345455",@"234567890",@"87654345678",@"23456789",@"765323456789",@"543212345678",@"ut32345678987",@"7654345th",@"ujhvbytrertyuj"].mutableCopy;
    _weights = @[@"100",@"120",@"90",@"89",@"24",@"130",@"99",@"54",@"87",@"124",@"108",@"88",@"111"].mutableCopy;
    _heights = @[@"160",@"120",@"110",@"170",@"175",@"130",@"155",@"175",@"187",@"190",@"108",@"176",@"190"].mutableCopy;
    _ages = @[@"16",@"12",@"20",@"21",@"35",@"23",@"20",@"18",@"17",@"22",@"25",@"33",@"11"].mutableCopy;
    
    NSArray *list = [YWFMDB queryWithModel:[YWPerson class]];
    
    if (!list || list.count == 0 ) {
        YWPerson *p = [YWPerson new];
        p.name = @"yw";
        p.age = 23;
        p.phone = @"13557352348";
        p.weight = 130;
        p.height = 175;
        p.menu = @"ios job";
        p.email = @"1498627884@qq.com";
        p.qq = @"1498627884";
        p.weChat = @"13557352348";
        
        YWPerson *p1 = [YWPerson new];
        p1.name = @"lpl";
        p1.age = 21;
        p1.phone = @"13557352348";
        p1.weight = 130;
        p1.height = 175;
        p1.menu = @"ios job";
        p1.email = @"1498627884@qq.com";
        p1.qq = @"1498627884";
        p1.weChat = @"13557352348";
        
        YWPerson *p2 = [YWPerson new];
        p2.name = @"test";
        p2.age = 20;
        p2.phone = @"13557352348";
        p2.weight = 130;
        p2.height = 175;
        p2.menu = @"ios job";
        p2.email = @"1498627884@qq.com";
        p2.qq = @"1498627884";
        p2.weChat = @"13557352348";
        
        [YWFMDB storageModels:@[p,p1,p2] checkTableStructure:NO];
        
    }
    
  

}

- (int)arcrandom{
    return  arc4random() % (13) ;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [_tf endEditing:YES];
}
@end
