//
//  RCBubbleCell.m
//  RongCloudOpenSource
//
//  Created by jory on 2023/4/19.
//

#import "RCBubbleCell.h"

@interface RCBubbleCell()

@property (nonatomic,strong) UIImageView *bubbleBgView;
@property (nonatomic,strong) SVGAImageView *topLeftView;
@property (nonatomic,strong) SVGAImageView *topRightView;
@property (nonatomic,strong) SVGAImageView *bottomLeftView;
@property (nonatomic,strong) SVGAImageView *bottomRightView;

@property (nonatomic,assign) CGSize contentSize;
@property (nonatomic,assign) CGSize svgaSize;

@end

@implementation RCBubbleCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        [self createSubViews];
    }
    return self;
}

- (void)createSubViews{
    //新气泡
    _bubbleBgView = [[UIImageView alloc]initWithFrame:CGRectZero];
    _bubbleBgView.backgroundColor = [UIColor clearColor];
    [self addSubview:_bubbleBgView];
    
    _topLeftView = [[SVGAImageView alloc]initWithFrame:CGRectZero];
    _topLeftView.autoPlay = true;
    _topLeftView.clearsAfterStop = true;
    _topLeftView.sizeDelegate = self;
    [_bubbleBgView addSubview:_topLeftView];
    
    _topRightView = [[SVGAImageView alloc]initWithFrame:CGRectZero];
    _topRightView.autoPlay = true;
    _topRightView.clearsAfterStop = true;
    _topRightView.sizeDelegate = self;
    [_bubbleBgView addSubview:_topRightView];
    
    _bottomLeftView = [[SVGAImageView alloc]initWithFrame:CGRectZero];
    _bottomLeftView.autoPlay = true;
    _bottomLeftView.clearsAfterStop = true;
    _bottomLeftView.sizeDelegate = self;
    [_bubbleBgView addSubview:_bottomLeftView];
    
    _bottomRightView = [[SVGAImageView alloc]initWithFrame:CGRectZero];
    _bottomRightView.autoPlay = true;
    _bottomRightView.clearsAfterStop = true;
    _bottomRightView.sizeDelegate = self;
    [_bubbleBgView addSubview:_bottomRightView];
}

- (BOOL)updateBubble:(NSDictionary *)dict {
    NSString *bg = @"";
    NSString *lt = @"";
    NSString *lb = @"";
    NSString *rt = @"";
    NSString *rb = @"";
    if ([dict.allKeys containsObject:@"bg"]){
        bg = dict[@"bg"];
    }
    if ([dict.allKeys containsObject:@"lt"]){
        lt = dict[@"lt"];
    }
    if ([dict.allKeys containsObject:@"lb"]){
        lb = dict[@"lb"];
    }
    if ([dict.allKeys containsObject:@"rt"]){
        rt = dict[@"rt"];
    }
    if ([dict.allKeys containsObject:@"rb"]){
        rb = dict[@"rb"];
    }
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0];
    
    NSString *bgPath = [NSString stringWithFormat:@"%@/VIP/svga/%@",document,bg];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:bgPath];
    if (image != nil){
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(40, 100, 40, 100) resizingMode:UIImageResizingModeStretch];
    }
    _bubbleBgView.image = image;
    
    NSString *ltPath = [NSString stringWithFormat:@"%@/VIP/svga/%@",document,lt];
    if (lt.length == 0){
        [_topLeftView setHidden:true];
    }else{
        [_topLeftView setHidden:false];
        _topLeftView.imageName = ltPath;
    }
    
    NSString *lbPath = [NSString stringWithFormat:@"%@/VIP/svga/%@",document,lb];
    if (lb.length == 0){
        [_bottomLeftView setHidden:true];
    }else{
        [_bottomLeftView setHidden:false];
        _bottomLeftView.imageName = lbPath;
    }
    
    NSString *rtPath = [NSString stringWithFormat:@"%@/VIP/svga/%@",document,rt];
    if (rt.length == 0){
        [_topRightView setHidden:true];
    }else{
        [_topRightView setHidden:false];
        _topRightView.imageName = rtPath;
    }
    
    NSString *rbPath = [NSString stringWithFormat:@"%@/VIP/svga/%@",document,rb];
    if (rb.length == 0){
        [_bottomRightView setHidden:true];
    }else{
        [_bottomRightView setHidden:false];
        _bottomRightView.imageName = rbPath;
    }
    return _topLeftView.isHidden && _topRightView.isHidden && _bottomLeftView.isHidden && _bottomRightView.isHidden && (image == nil);
}

-(void)updateSize:(CGSize)size{
    _contentSize = size;
    self.bubbleBgView.frame = CGRectMake(0, 0, _contentSize.width, _contentSize.height);
    self.topLeftView.frame = CGRectMake(0, 0, _svgaSize.width, _svgaSize.height);
    self.bottomLeftView.frame = CGRectMake(0, _contentSize.height-_svgaSize.height, _svgaSize.width, _svgaSize.height);
    self.topRightView.frame = CGRectMake(_contentSize.width-_svgaSize.width, 0, _svgaSize.width, _svgaSize.height);
    self.bottomRightView.frame = CGRectMake(_contentSize.width-_svgaSize.width, _contentSize.height-_svgaSize.height, _svgaSize.width, _svgaSize.height);
}

-(void)stopAllAnimation{
    [_topLeftView stopAnimation];
    [_bottomLeftView stopAnimation];
    [_topRightView stopAnimation];
    [_bottomRightView stopAnimation];
}

-(void)didSvgaImageViewFinishLoad:(CGSize)size player:(SVGAPlayer *)player{
    _svgaSize = size;
    if (_topLeftView == player){
        self.topLeftView.frame = CGRectMake(0, 0, _svgaSize.width, _svgaSize.height);
    }
    if (_bottomLeftView == player){
        self.bottomLeftView.frame = CGRectMake(0, _contentSize.height-_svgaSize.height, _svgaSize.width, _svgaSize.height);
    }
    if (_topRightView == player){
        self.topRightView.frame = CGRectMake(_contentSize.width-_svgaSize.width, 0, _svgaSize.width, _svgaSize.height);
    }
    if (_bottomRightView == player){
        self.bottomRightView.frame = CGRectMake(_contentSize.width-_svgaSize.width, _contentSize.height-_svgaSize.height, _svgaSize.width, _svgaSize.height);
    }
}

@end

