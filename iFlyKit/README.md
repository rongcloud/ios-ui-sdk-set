融云IM讯飞语音输入sdk-RongiFlykit集成说明文档

#一、
 融云的讯飞输入法插件依赖于IMKit，把讯飞语音输入 SDK 文件夹拷贝到项目文件夹下，并导入到项目工程中。注：RongiFlykit依赖于讯飞的iflyMSC.framework和资源包RongCloudiFly.bundle

#二、
 Build Settings 中 Other Linker Flags 添加 -ObjC 。

#三、
RongiFlyKit 是静态库，需要添加系统依赖库，

```
AddressBook.framework
libz.tbd
SystemConfiguration.framework
CoreTelephony.framework
CoreServices.framework
Contacts.framework
```

#四、
 如果需要修改讯飞sdk的appkey，来做一些业务统计，请在IMKit初始化之后调用下面的方法，保证IMKit加载该模块的时候，使用正确的讯飞appkey
 注意！！！：因为讯飞的appkey和sdk是绑定的，所以如果你需要更换讯飞的appkey，就必须更换成对应的iflyMSC.framework

[RCiFlyKit setiFlyAppKey:@"讯飞 appkey"];
