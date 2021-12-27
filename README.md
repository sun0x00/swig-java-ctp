# swig-java-ctp
### 使用[SWIG](http://www.swig.org/)生成用于Java调用上期技术CTP-API的JNI（C++）源码

#### 简介

本仓库提供 [redtorch](https://github.com/sun0x00/redtorch) 项目的rt-gateway-ctp模块的具体代码生成方法和跨平台运行方案细节。

#### 使用方法

+ 下载[SWIG](http://www.swig.org/)软件，并将可执行文件swig.exe(Windows)所在目录加入PATH（或修改run_swig.bat使用绝对路径）
+ 分别运行各目录下的批处理文件run_swig.bat获得Java源码和JNI(C++)源码


#### 提示
+ 本仓库中提供的 **.i** 文件可跨平台使用，并且生成的JNI(C++)源代码同时适用于Linux和Windows平台
+ 本仓库中CTP相关的头文件 **.h** 分别来[上期技术官网](http://www.sfit.com.cn)提供的各对应版本的SDK压缩包
+ 自动生成的源码已经默认包含了 [libiconv](https://www.gnu.org/software/libiconv/) 编码转换方案，具体参考 **.i** 文件
+ 自动生成的JNI(C++)源码不能解决CTP结算单乱码问题。如需解决结算单乱码问题，请参考下文中提供的参考方案
+ SWIG软件具备跨平台特性，本仓库仅提供Window下的批处理文件 **.bat**，如需在Linux环境下使用SWIG自动生成源码，请参考 **.bat** 文件中的生成命令
+ 实际编译时，Windows环境下使用的 iconv 头文件和链接库来自开源项目 [libiconv-win-build](https://github.com/sun0x00/libiconv-win-build)
+ 实际编译时，Linux环境下使用的 iconv 头文件和链接库请直接使用[libiconv](https://www.gnu.org/software/libiconv/)官方压编译
+ 实际编译时，需要jni.h和jni_md.h两个头文件，这两个头文件来自Java Development Kit，请在实际使用的JDK中寻找，一般情况下这两个文件也具备跨平台特性


#### 编译

请分别参考以下两个仓库进一步了解编译相关内容

+ Windows [jctpapi-msvc](https://github.com/sun0x00/jctpapi-msvc)
+ Linux [jctpapi-liunx](https://github.com/sun0x00/jctpapi-linux)



#### 结算单乱码的解决方案
结算单乱码的主要原因是CTP对结算单的完整文本按固定长度的byte数组分段断传输，由于单个unicode字符可能多个byte的情况，因此如果JNI在传输过程中使用iconv转码会丢失数据。

已知的解决方案是修改自动生成后的C++和Java源码（必须同时修复，否则会因JNI类型不匹配而导致崩溃），对结算单相关的数据不使用iconv进行转码，在Java中接收全部的byte数组后拼接为一个完整的byte数组，然后再使用new String构建字符串并使用GB18030(兼容GBK和GB2312)重新编码，此问题便可解决。

下文中提供的方法用于透传结算单分段byte数组数据，不使用iconv转码。

在生成的JNI(C++)源码中搜索 `CThostFtdcSettlementInfoField_1Content_1get`
将返回类型改为`jbyteArray `
将函数内容替换为

    jbyteArray jresult = 0 ;
    CThostFtdcSettlementInfoField *arg1 = (CThostFtdcSettlementInfoField *) 0 ;
    char *result = 0 ;

    (void)jenv;
    (void)jcls;
    (void)jarg1_;
    arg1 = *(CThostFtdcSettlementInfoField **)&jarg1;
    result = (char *) ((arg1)->Content);
    {
    	if (result) {
    		jresult = jenv->NewByteArray( strlen(result));
    		jenv->SetByteArrayRegion(jresult, 0, strlen(result), (jbyte*)result);
    	}
    }
    return jresult;



最终结果例如：

	SWIGEXPORT jbyteArray JNICALL Java_xyz_redtorch_gateway_ctp_x64v6v3v15v_api_jctpv6v3v15x64apiJNI_CThostFtdcSettlementInfoField_1Content_1get(JNIEnv *jenv, jclass jcls, jlong jarg1, jobject jarg1_) {
		jbyteArray jresult = 0;
		CThostFtdcSettlementInfoField *arg1 = (CThostFtdcSettlementInfoField *)0;
		char *result = 0;

		(void)jenv;
		(void)jcls;
		(void)jarg1_;
		arg1 = *(CThostFtdcSettlementInfoField **)&jarg1;
		result = (char *)((arg1)->Content);
		{
			if (result) {
				jresult = jenv->NewByteArray(strlen(result));
				jenv->SetByteArrayRegion(jresult, 0, strlen(result), (jbyte*)result);
			}

		}
		return jresult;
	}

** 请不要直接复制上段函数代码，注意函数名一致性 **

手动将`CThostFtdcSettlementInfoField.java`文件中的函数 `getContent()`方法的返回类型改为`byte[]`，将其调用的其他类的方法的返回类型也改为`byte[]`直到无错为止。

在java中，在没有返回last标记之前，存储所有`byte[]`，返回标记之后拼接为一个大`byte[] `使用`new String(contentBytes,"GB18030")`，便可得到完全正确的结算单。
