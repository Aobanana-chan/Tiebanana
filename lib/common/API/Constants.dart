import 'package:tiebanana/Json_Model/json.dart';

const String ChromeUA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36";
const String BAIDU_URL = "https://www.baidu.com"; //百度首页
const String LOGIN_GET_URL = "https://passport.baidu.com/v2/?login";
const String LOGIN_POST_URL =
    "https://passport.baidu.com/v2/api/?login"; //登陆API
const String TOKEN_GET_URL =
    "https://passport.baidu.com/v2/api/?getapi"; //获取TOKEN
const String PUB_KEY_URL = "https://passport.baidu.com/v2/getpublickey";
const String TIEBA_URL = "https://tieba.baidu.com"; //贴吧首页
const String TBS_URL = "http://tieba.baidu.com/dc/common/tbs/"; //tbs 获取随机参数
const String IMGTBS_URL = "https://tieba.baidu.com/dc/common/imgtbs"; //获取传图 tbs
const String USER_INFO_GET_URL =
    "http://tieba.baidu.com/f/user/json_userinfo"; //获取用户json信息
const String MY_LIKE_URL = "http://tieba.baidu.com/f/like/mylike"; //我喜欢的贴吧
const String CAPTCHA_IMG =
    "https://passport.baidu.com/cgi-bin/genimage"; //验证码图片地址
const String REPLY_POST_URL =
    "http://c.tieba.baidu.com/c/c/post/add"; //贴吧回帖post url
const String THREAD_ADD_URL =
    "http://c.tieba.baidu.com/c/c/thread/add"; //贴吧发帖post url
const String DEL_POST_URL =
    "http://c.tieba.baidu.com/c/c/bawu/delthread"; //删帖post url
const String BAWU_POST_URL =
    "http://c.tieba.baidu.com/c/u/bawu/listreason"; //获取封禁列表
const String PRISION_POST_URL =
    "http://c.tieba.baidu.com/c/c/bawu/commitprison"; //封禁用户
const String INFO_GET_URL = "https://www.baidu.com/p"; //百度个人资料（获取贴吧头像）
const String HEAD_GET_URL =
    "http://himg.bdimg.com/sys/portrait/item"; //（获取贴吧头像地址）
const String BAIDUTIME_GET_URL =
    "http://open.baidu.com/special/time/"; //获取百度服务器时间
const String TBAT_POST_URL = "http://c.tieba.baidu.com/c/u/feed/"; //贴吧@、回复
const String FLOOR_POST_URL = "http://c.tieba.baidu.com/c/f/pb/floor"; //楼层
const String PASSPORT_AUTH_URL =
    "https://passport.baidu.com/v3/login/api/auth/"; //授权url
const String NEW_HEAD_URL = "http://tieba.baidu.com/home/main"; //用户首页
const String USER_PROFILE =
    "http://c.tieba.baidu.com/c/u/user/profile"; //贴吧用户信息查询
const String FOLLOW = "http://c.tieba.baidu.com/c/c/user/follow"; //关注某人
const String UNFOLLOW = "http://c.tieba.baidu.com/c/c/user/unfollow"; //取消关注某人
const String F_PAGE = "http://c.tieba.baidu.com/c/f/pb/page"; //帖子信息
const String SEARCH_FRIEND =
    "http://c.tieba.baidu.com/c/r/friend/searchFriend"; //获取用户信息
const String GET_USER_TIEBA =
    "http://c.tieba.baidu.com/c/f/forum/like"; //获取用户关注的贴吧
const String LIKE_TIEBA_URL =
    "http://c.tieba.baidu.com/c/c/forum/like"; //关注一个贴吧（客户端接口）
const String UNFAVO_TIEBA_URL =
    "http://c.tieba.baidu.com/c/c/forum/unfavo"; //取消关注一个贴吧(客户端接口)
const String UNFAVO_TIEBA_URL_NEW =
    "http://c.tieba.baidu.com/c/c/forum/unfavolike"; //取消关注一个贴吧(新客户端接口)
const String ADD_TIEBA =
    "https://tieba.baidu.com/f/like/commit/add"; //关注一个贴吧（网页接口）
const String DELETE_TIEBA =
    "https://tieba.baidu.com/f/like/commit/delete"; //取消关注一个贴吧（网页接口）
const String TIEBA_FID =
    "http://tieba.baidu.com/f/commit/share/fnameShareApi"; //获取贴吧fid
const String FLOR_PID = "http://c.tieba.baidu.com/c/f/pb/floor"; //获取楼层pid
const String GET_QRCODE_SIGN =
    "https://passport.baidu.com/v2/api/getqrcode"; //获取登录二维码sign
const String GET_QRCODE_IMG =
    "https://passport.baidu.com/v2/api/qrcode"; //获取登录二维码图片
const String GET_FOLLOW_LIST =
    "http://c.tieba.baidu.com/c/u/follow/followList"; //获取关注列表
const String GET_FANS_LIST = "http://c.tieba.baidu.com/c/u/fans/page"; //获取粉丝列表
const String REMOVE_FANS =
    "http://c.tieba.baidu.com/c/c/user/removeFans"; //移除粉丝
const String TOOUSU_CHECK =
    "http://tieba.baidu.com/complaint/checkjubao"; //1. 举报提交
const String TOOUSU_SUBMIT = "http://help.baidu.com/tousu/submit"; //2. 举报提交
const String ZHIDAO_USER_CENTER =
    "https://zhidao.baidu.com/usercenter"; //知道用户中心，用于查询完整用户名
const String GET_FORUM_SUPPORT =
    "http://tieba.baidu.com/celebrity/submit/getForumSupport"; //1.名人堂助攻
const String FORUM_SUPPORT =
    "http://tieba.baidu.com/celebrity/submit/support"; //2。名人堂助攻
const String LEBO_API = "http://leboapi.baidu.com/leboapi/user"; //BDUSS查询用户信息
const String SIGN_DEL = "http://tieba.baidu.com/f/user/cm/sign_del"; //删除签名档
const String SIGN_QUERY = "http://tieba.baidu.com/f/user/sign"; //获取签名档
const String UK_UN = "https://pan.baidu.com/pcloud/user/getinfo"; //根据uk查询un
const String QRCODE_LOGIN_STATUS =
    "https://passport.baidu.com/channel/unicast"; //根据uk查询un
const String UPLOAD_PHOTOS =
    "https://uploadphotos.baidu.com/upload/pic"; //传图 url
const String VIEW_LOG_URL =
    "https://passport.baidu.com/viewlog"; //用户操作记录提交&旋转验证码提交
const String GETSTYLE_URL =
    "https://passport.baidu.com/viewlog/getstyle"; //用于获取验证码图片地址
const String AUTH_VERIFY_URL =
    "https://passport.baidu.com/v2/sapi/authwidgetverify"; //强制安全验证
const String WAP_URL = "https://wappass.baidu.com/"; //wap端入口
const String WAP_LOGIN_URL =
    "https://wappass.baidu.com/wp/api/login"; //wap端登陆入口
const String ONE_KEY_SIGN_IN =
    "https://tieba.baidu.com/tbmall/onekeySignin1"; //贴吧一键签到入口，使用POST方法，只会签到7级以上的贴吧，功能有限，但效率最高
const String GET_FORUM_HOME =
    "https://tieba.baidu.com/mg/o/getForumHome"; //获取贴吧主页信息(手机web端)
const String GET_FORUM_RECOMMEND =
    "http://c.tieba.baidu.com/c/f/forum/forumrecommend"; //可以获取关注的吧信息，可以用GET或者是POST方法
const String FORUM_SIGN_IN = "http://c.tieba.baidu.com/c/c/forum/sign"; //单个吧签到

///百度err_no码 Web端口
final webErrCode = {
  "-1": {"msg": '系统错误,请您稍后再试', "field": ""},
  "0": {"msg": '登陆成功', "field": ""},
  "1": {"msg": "您输入的帐号格式不正确", "field": "userName"},
  "2": {"msg": '用户名或密码有误，请重新输入或找回密码', "field": "userName"},
  "3": {"msg": "验证码不存在或已过期,请重新输入", "field": ""},
  "4": {"msg": "帐号或密码错误，请重新输入或者找回密码", "field": "password"},
  "5": {"msg": "", "field": ""},
  "6": {"msg": "您输入的验证码有误", "field": "verifyCode"},
  "7": {"msg": "用户名或密码有误，请重新输入或找回密码", "field": "password"},
  "16": {"msg": '您的帐号因安全问题已被限制登录,帮助中心', "field": ""},
  "257": {"msg": "请输入验证码", "field": "verifyCode"},
  "100027": {"msg": "百度正在进行系统升级，暂时不能提供服务，敬请谅解", "field": ""},
  "120016": {"msg": "", "field": ""},
  "18": {"msg": "", "field": ""},
  "19": {"msg": "", "field": ""},
  "20": {"msg": "", "field": ""},
  "21": {"msg": "没有登录权限", "field": ""},
  "22": {"msg": "", "field": ""},
  "23": {"msg": "", "field": ""},
  "24": {"msg": "百度正在进行系统升级，暂时不能提供服务，敬请谅解", "field": ""},
  "400031": {"msg": "请在弹出的窗口操作,或重新登录", "field": ""},
  "400032": {"msg": "", "field": ""},
  "400034": {"msg": "", "field": ""},
  "401007": {"msg": "您的手机号关联了其他帐号，请选择登录", "field": ""},
  "120021": {"msg": "登录失败,请在弹出的窗口操作,或重新登录", "field": ""}, //需要手机短信验证
  "500010": {"msg": "登录过于频繁,请24小时后再试", "field": ""},
  "200010": {"msg": "验证码不存在或已过期", "field": ""},
  "100005": {"msg": "系统错误,请您稍后再试", "field": ""},
  "120019": {"msg": "请在弹出的窗口操作,或重新登录", "field": "userName"},
  "110024": {"msg": "此帐号暂未激活s", "field": ""},
  "100023": {"msg": "系统升级中，为了您的帐号安全，您可以使用二维码登录或者更换其他浏览器继续登录", "field": ""},
  "17": {"msg": '您的帐号已锁定,请解锁后登录', "field": "userName"},
  "400401": {"msg": "", "field": ""},
  "400037": {"msg": "", "field": ""},
  "50023": {"msg": "1个手机号30日内最多换绑3个账号", "field": ""},
  "50024": {"msg": "注册过于频繁，请稍候再试", "field": ""},
  "50025": {"msg": "注册过于频繁，请稍候再试；也可以通过上行短信的方式进行注册", "field": ""},
  "50028": {"msg": '帐号或密码多次输错，请3个小时之后再试或找回密码', "field": ""},
  "50029": {"msg": '帐号或密码多次输错，请3个小时之后再试或找回密码', "field": ""},
  "400714": {"msg": '系统检测你的帐号疑似被盗，存在安全风险请重置密码', "field": ""},
  "50030": {"msg": "抱歉，该手机号的申请次数已达当日上限，请更换手机号", "field": ""},
  "50031": {"msg": "抱歉，该手机号的申请次数已达当月上限，请更换手机号", "field": ""},
  "50032": {"msg": "抱歉，该手机号的申请次数已达本季度上限，请更换手机号", "field": ""},
  "50035": {"msg": "系统错误,请您稍后再试(50035)", "field": ""},
  "400413": {"msg": "", "field": ""},
  "400414": {"msg": "", "field": ""},
  "400415": {"msg": "帐号存在风险，为了您的帐号安全，请到百度钱包/理财/地图任一APP登录并完成验证，谢谢", "field": ""},
  "400500": {"msg": "您登录的帐号已注销，请登录其他帐号或重新注册", "field": ""},
  "72200": {"msg": "您的帐号因冻结暂时无法登录，请前往冻结时的手机APP，在登录页点击遇到问题进行解冻", "field": ""},
  "96001": {"msg": "您的帐号因违反百度用户协议被限制登录", "field": ""},
  "100060": {"msg": "因系统升级暂不支持注册，预计6月7日恢复服务", "field": ""},
  "400702": {"msg": "该帐号已关闭手机号登录，请使用帐号密码登录", "field": ""},
  "400704": {"msg": "", "field": ""},
  "400706": {"msg": "", "field": ""},
  "50043": {"msg": "当前浏览器版本过低，请升级或更换浏览器后重试", "field": ""},
  "923002": {"msg": "当前身份证无法识别", "field": ""},
  "97101": {"msg": "系统繁忙，请稍候再试", "field": ""},
  "400703": {
    "msg": "手机号已被运营商二次放号，请前往https://passport.baidu.com/v2/?reg注册新帐号",
    "field": ""
  },
  "50045": {"msg": "您的手机因安全问题已被限制"},
  "50046": {"msg": "您的ip因安全问题已被限制"},
  "50044": {"msg": "您的网络环境存在安全风险，请切换网络重试"},
  "50047": {"msg": "暂不支持海外及港澳台地区注册"},
  "50048": {"msg": "您当前的操作存在安全风险，请稍后再试"},
  "26": {"msg": "暂不支持海外及港澳台地区注册"},
  "100073": {"msg": "网盘帐号系统正在升级，现暂停新帐号注册，将于2月28日恢复开放，对此给您带来不便深表歉意！"},
  "400012": {"msg": '您的帐号因违反百度用户协议被限制登录'},
  "400044": {"msg": '您的帐号因违反百度用户协议被限制登录'}
};

class BaiduErroNo {
  static LoginErrCode parse(String code) {
    LoginErrCode ret = LoginErrCode();
    ret.errcode = code;
    ret.msg = webErrCode[code]!["msg"];
    return ret;
  }
}
