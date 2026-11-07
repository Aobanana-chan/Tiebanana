// ignore_for_file: constant_identifier_names

import 'package:tiebanana/Json_Model/json.dart';

///UA
const String ChromeUA =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36";

///百度首页
const String BAIDU_URL = "https://www.baidu.com";
/////用户首页
const String BAIDU_PASSPORT_URL = "https://passport.baidu.com";
const String LOGIN_GET_URL = "https://passport.baidu.com/v2/?login";

///登陆API
const String LOGIN_POST_URL = "https://passport.baidu.com/v2/api/?login";

///获取TOKEN
const String TOKEN_GET_URL = "https://passport.baidu.com/v2/api/?getapi";

///获取登陆rsa加密公钥
const String PUB_KEY_URL = "https://passport.baidu.com/v2/getpublickey";

///贴吧首页
const String TIEBA_URL = "https://tieba.baidu.com";

///tbs 获取随机参数
const String TBS_URL = "http://tieba.baidu.com/dc/common/tbs/";

///获取传图 tbs
const String IMGTBS_URL = "https://tieba.baidu.com/dc/common/imgtbs";

///获取用户json信息
const String USER_INFO_GET_URL = "http://tieba.baidu.com/f/user/json_userinfo";

///我喜欢的贴吧
const String MY_LIKE_URL = "http://tieba.baidu.com/f/like/mylike";

///验证码图片地址
const String CAPTCHA_IMG = "https://passport.baidu.com/cgi-bin/genimage";

///贴吧回帖post url
const String REPLY_POST_URL = "http://c.tieba.baidu.com/c/c/post/add";

///贴吧发帖post url
const String THREAD_ADD_URL = "http://c.tieba.baidu.com/c/c/thread/add";

///删帖post url
const String DEL_POST_URL = "http://c.tieba.baidu.com/c/c/bawu/delthread";

///获取封禁列表
const String BAWU_POST_URL = "http://c.tieba.baidu.com/c/u/bawu/listreason";

///封禁用户
const String PRISION_POST_URL =
    "http://c.tieba.baidu.com/c/c/bawu/commitprison";

///百度个人资料（获取贴吧头像）
const String INFO_GET_URL = "https://www.baidu.com/p";

///（获取贴吧头像地址）
const String HEAD_GET_URL = "http://himg.bdimg.com/sys/portrait/item";

///获取百度服务器时间
const String BAIDUTIME_GET_URL = "http://open.baidu.com/special/time/";

///贴吧@、回复
const String TBAT_POST_URL = "http://c.tieba.baidu.com/c/u/feed/";

///楼层
const String FLOOR_POST_URL = "http://c.tieba.baidu.com/c/f/pb/floor";

///授权url
const String PASSPORT_AUTH_URL =
    "https://passport.baidu.com/v3/login/api/auth/";

///用户首页
const String NEW_HEAD_URL = "http://tieba.baidu.com/home/main";

///贴吧用户信息查询
const String USER_PROFILE = "http://c.tieba.baidu.com/c/u/user/profile";

///关注某人
const String FOLLOW = "http://c.tieba.baidu.com/c/c/user/follow";

///取消关注某人
const String UNFOLLOW = "http://c.tieba.baidu.com/c/c/user/unfollow";

///帖子信息
const String F_PAGE = "http://c.tieba.baidu.com/c/f/pb/page";

///获取用户信息
const String SEARCH_FRIEND = "http://c.tieba.baidu.com/c/r/friend/searchFriend";

///获取用户关注的贴吧
const String GET_USER_TIEBA = "http://c.tieba.baidu.com/c/f/forum/like";

///关注一个贴吧（客户端接口）
const String LIKE_TIEBA_URL = "http://c.tieba.baidu.com/c/c/forum/like";

///取消关注一个贴吧(客户端接口)
const String UNFAVO_TIEBA_URL = "http://c.tieba.baidu.com/c/c/forum/unfavo";

///取消关注一个贴吧(新客户端接口)
const String UNFAVO_TIEBA_URL_NEW =
    "http://c.tieba.baidu.com/c/c/forum/unfavolike";

///关注一个贴吧（网页接口）
const String ADD_TIEBA = "https://tieba.baidu.com/f/like/commit/add";

///取消关注一个贴吧（网页接口）
const String DELETE_TIEBA = "https://tieba.baidu.com/f/like/commit/delete";

///获取贴吧fid
const String TIEBA_FID = "http://tieba.baidu.com/f/commit/share/fnameShareApi";

///获取楼层pid
const String FLOR_PID = "http://c.tieba.baidu.com/c/f/pb/floor";

///获取登录二维码sign
const String GET_QRCODE_SIGN = "https://passport.baidu.com/v2/api/getqrcode";

///获取登录二维码图片
const String GET_QRCODE_IMG = "https://passport.baidu.com/v2/api/qrcode";

///获取关注列表
const String GET_FOLLOW_LIST = "http://c.tieba.baidu.com/c/u/follow/followList";

///获取粉丝列表
const String GET_FANS_LIST = "http://c.tieba.baidu.com/c/u/fans/page";

///移除粉丝
const String REMOVE_FANS = "http://c.tieba.baidu.com/c/c/user/removeFans";

///1. 举报提交
const String TOOUSU_CHECK = "http://tieba.baidu.com/complaint/checkjubao";

///2. 举报提交
const String TOOUSU_SUBMIT = "http://help.baidu.com/tousu/submit";

///知道用户中心，用于查询完整用户名
const String ZHIDAO_USER_CENTER = "https://zhidao.baidu.com/usercenter";

///1.名人堂助攻
const String GET_FORUM_SUPPORT =
    "http://tieba.baidu.com/celebrity/submit/getForumSupport";

///2。名人堂助攻
const String FORUM_SUPPORT = "http://tieba.baidu.com/celebrity/submit/support";

///BDUSS查询用户信息
const String LEBO_API = "http://leboapi.baidu.com/leboapi/user";

///删除签名档
const String SIGN_DEL = "http://tieba.baidu.com/f/user/cm/sign_del";

///获取签名档
const String SIGN_QUERY = "http://tieba.baidu.com/f/user/sign";

///根据uk查询un
const String UK_UN = "https://pan.baidu.com/pcloud/user/getinfo";

///根据uk查询un
const String QRCODE_LOGIN_STATUS = "https://passport.baidu.com/channel/unicast";

///传图 url
const String UPLOAD_PHOTOS = "https://uploadphotos.baidu.com/upload/pic";

///用户操作记录提交&旋转验证码提交
const String VIEW_LOG_URL = "https://passport.baidu.com/viewlog";

///用于获取验证码图片地址
const String GETSTYLE_URL = "https://passport.baidu.com/viewlog/getstyle";

///强制安全验证
const String AUTH_VERIFY_URL =
    "https://passport.baidu.com/v2/sapi/authwidgetverify";

///wap端入口
const String WAP_URL = "https://wappass.baidu.com/";

///wap端登陆入口
const String WAP_LOGIN_URL = "https://wappass.baidu.com/wp/api/login";

///贴吧一键签到入口，使用POST方法，只会签到7级以上的贴吧，功能有限，但效率最高
const String ONE_KEY_SIGN_IN = "https://tieba.baidu.com/tbmall/onekeySignin1";

///获取贴吧主页信息(手机web端)
const String GET_FORUM_HOME = "https://tieba.baidu.com/mg/o/getForumHome";

///可以获取关注的吧信息，可以用GET或者是POST方法
const String GET_FORUM_RECOMMEND =
    "http://c.tieba.baidu.com/c/f/forum/forumrecommend";

///单个吧签到
const String FORUM_SIGN_IN = "http://c.tieba.baidu.com/c/c/forum/sign";

///获取动态贴
const String FORUM_DYNMANIC =
    "http://c.tieba.baidu.com/c/f/excellent/personalized";

///获取头像
const String AUTHOR_AVATAR = "http://tb.himg.baidu.com/sys/portrait/item/";

///获取回复
const String GET_REPLY = "http://c.tieba.baidu.com/c/u/feed/replyme";

///获取@我
const String GET_ATME = "http://c.tieba.baidu.com/c/u/feed/atme";

///获取个人信息，用Get方法
const String GET_MY_USER_INFO =
    "https://tieba.baidu.com/mo/q/newmoindex?need_user=1";

/// 获取消息通知
const String GET_MESSAGE = "http://c.tieba.baidu.com/c/s/msg";

///获取吧主页信息
const String GET_FORUM_PAGE = "http://c.tieba.baidu.com/c/f/frs/page";

///点赞
const String AGREE_URL = "http://c.tieba.baidu.com/c/c/agree/opAgree";

///获取手机号码注册状态
const String GET_PHONE_NUMBER_STATUS =
    "https://passport.baidu.com/v2/?getphonestatus";

///短信登录发送短信API
const String LOGIN_SEND_PASS = "https://passport.baidu.com/v2/api/senddpass";

///文字图片验证码，后加vcodestr
const String WORD_CAPTCHA_IMAGE =
    "https://passport.baidu.com/cgi-bin/genimage?";

/// WAP端账号状态检查
const String WAP_ACCOUNT_CHECK = "https://wappass.baidu.com/v3/login/api/check";

///搜索吧API
const String SEARCH_FORUM = "https://tieba.baidu.com/mo/q/seekforum";

///搜索贴API
const String SEARCH_THREAD = "https://tieba.baidu.com/mo/q/seekcomposite";

///贴吧表情链接cdn
const String TIEBA_EMOJI =
    "https://gsp0.baidu.com/5aAHeD3nKhI2p27j8IqW0jdnxx1xbK/tb/editor/images/client/";

///贴吧熊GIF表情链接cdn
const String TIEBA_KUMA_EMOJI =
    "https://gsp0.baidu.com/5aAHeD3nKhI2p27j8IqW0jdnxx1xbK/tb/editor/images/bearchildren/";

/// WAP端回帖API
const String WAP_POST_REPLY = "http://c.tieba.baidu.com/c/c/post/add";

///WAP端传图API
const String WAP_UPLOAD_PICTURE = "http://c.tieba.baidu.com/c/s/uploadPicture";

/// WEB端搜贴API
const String WEB_SEARCH_POST = "https://tieba.baidu.com/mo/q/search/thread";

///WEB端搜索用户API
const String WEB_SEARCH_USER = "https://tieba.baidu.com/mo/q/search/user";

///WAP端获取用户post
const String WAP_USER_POST = "http://c.tieba.baidu.com/c/u/feed/userpost";

///WAP端获取用户关注贴
const String WAP_USER_FORUM_LIKE = "http://c.tieba.baidu.com/c/f/forum/like";

///获取用户收藏贴
const String USER_THREAD_STORE =
    "http://c.tieba.baidu.com/c/f/post/threadstore";

///添加到收藏贴
const String ADD_THREAD_STORE = "http://c.tieba.baidu.com/c/c/post/addstore";

///取消收藏贴
const String REMOVE_THREAD_STORE = "http://c.tieba.baidu.com/c/c/post/rmstore";

///服务中心
const String SERVICE_CENTER =
    "http://tieba.baidu.com/n/apage-runtime/page/ueg_service_center";

///获取音频
///参数:voice_md5
const String VOVICE_MESSAGE = "http://c.tieba.baidu.com/c/p/voice";

///不喜欢首页推荐贴 参数：
///
///BDUSS
///
///dislike:[{"click_time":时间戳,"dislike_ids":"","extra":"","fid":"14911","tid":"7555696416"}]
///
///dislike_from
///
///stoken
///
///sign
const String RECOMMED_DISLIKE =
    "http://c.tieba.baidu.com/c/c/excellent/submitDislike";

///百度err_no码 Web端口
const webErrCode = {
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
  "20": {"msg": "登录过于频繁,请24小时后再试", "field": ""},
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

const Map<String, String> emojiFileMapping = {
  "image_emoticon": "呵呵",
  "image_emoticon5": "酷",
  "image_emoticon2": "哈哈",
  "image_emoticon3": "吐舌",
  "image_emoticon24": "太开心",
  "image_emoticon22": "笑眼",
  "image_emoticon20": "花心",
  "image_emoticon66": "小乖",
  "image_emoticon28": "乖",
  "image_emoticon67": "捂嘴笑",
  "image_emoticon25": "滑稽",
  "image_emoticon68": "你懂的",
  "image_emoticon12": "不高兴",
  "image_emoticon6": "怒",
  "image_emoticon8": "汗",
  "image_emoticon10": "黑线",
  "image_emoticon9": "泪",
  "image_emoticon13": "真棒",
  "image_emoticon33": "喷",
  "image_emoticon30": "惊哭",
  "image_emoticon16": "阴险",
  "image_emoticon11": "鄙视",
  "image_emoticon4": "啊",
  "image_emoticon27": "狂汗",
  "image_emoticon69": "what",
  "image_emoticon15": "疑问",
  "image_emoticon70": "酸爽",
  "image_emoticon71": "呀咩爹",
  "image_emoticon19": "委屈",
  "image_emoticon32": "惊讶",
  "image_emoticon29": "睡觉",
  "image_emoticon72": "笑尿",
  "image_emoticon73": "挖鼻",
  "image_emoticon17": "吐",
  "image_emoticon74": "犀利",
  "image_emoticon75": "小红脸",
  "image_emoticon76": "懒得理",
  "image_emoticon26": "勉强",
  "image_emoticon7": "开心",
  "image_emoticon14": "钱",
  "image_emoticon18": "咦",
  "image_emoticon21": "呼~",
  "image_emoticon23": "冷",
  "image_emoticon31": "升起",
  "image_emoticon97": "突然兴奋",
  "image_emoticon100": "黑头高兴",
  "image_emoticon95": "欢呼",
  "image_emoticon88": "嘿嘿嘿",
  "image_emoticon91": "微微一笑",
  "image_emoticon86": "吃瓜",
  "image_emoticon92": "托腮",
  "image_emoticon93": "摊手",
  "image_emoticon90": "困成狗",
  "image_emoticon85": "暗中观察",
  "image_emoticon94": "柯基暗中观察",
  "image_emoticon87": "喝酒",
  "image_emoticon89": "噗",
  "image_emoticon98": "紧张",
  "image_emoticon96": "炸药",
  "image_emoticon99": "黑头瞪眼",
  "image_emoticon128": "望远镜",
  "image_emoticon126": "不听",
  "image_emoticon127": "干饭",
  "image_emoticon130": "老虎",
  "image_emoticon131": "嗷呜",
  "image_emoticon132": "烟花",
  "image_emoticon129": "菜狗",
  "image_emoticon125": "奥特曼",
  "bearchildren_01": "熊-88",
  "bearchildren_02": "熊-HI",
  "bearchildren_03": "熊-人艰不拆",
  "bearchildren_04": "熊-啥",
  "bearchildren_05": "熊-大哭",
  "bearchildren_06": "熊-失落",
  "bearchildren_07": "熊-怒赞",
  "bearchildren_08": "熊-惊呆了",
  "bearchildren_09": "熊-李菊福",
  "bearchildren_10": "熊-来信砍",
  "bearchildren_11": "熊-欢迎入群",
  "bearchildren_12": "熊-牛闪闪",
  "bearchildren_13": "熊-生日快乐",
  "bearchildren_14": "熊-石化",
  "bearchildren_15": "熊-羞羞哒",
  "bearchildren_16": "熊-肥皂必杀",
  "bearchildren_17": "熊-谢谢你",
  "bearchildren_18": "熊-跳舞",
  "bearchildren_19": "熊-霹雳舞",
  "bearchildren_20": "熊-鼓掌",
  "image_emoticon34": "爱心",
  "image_emoticon35": "心碎",
  "image_emoticon124": "白眼",
  "image_emoticon123": "爱你的形状",
  "image_emoticon122": "来追我呀",
  "image_emoticon121": "月亮代表我的心",
  "image_emoticon120": "无聊",
  "image_emoticon119": "扎心了",
  "image_emoticon118": "我是不会骗你的",
  "image_emoticon117": "我养你",
  "image_emoticon116": "小姐姐来玩呀",
  "image_emoticon115": "小姐姐来啦",
  "image_emoticon46": "haha",
  "image_emoticon50": "OK",
  "image_emoticon77": "沙发",
  "image_emoticon78": "手纸",
  "image_emoticon79": "香蕉",
  "image_emoticon80": "便便",
  "image_emoticon81": "药丸",
  "image_emoticon82": "红领巾",
  "image_emoticon83": "蜡烛",
  "image_emoticon84": "三道杠",
  "image_emoticon114": "小姐姐在吗",
  "image_emoticon113": "小姐姐别走",
  "image_emoticon112": "宝宝不开心",
  "image_emoticon111": "好幸福",
  "image_emoticon110": "嗯嗯",
  "image_emoticon109": "哈哈哈",
  "image_emoticon108": "吓到宝宝了",
  "image_emoticon107": "单身等撩",
  "image_emoticon106": "假装看不见",
  "image_emoticon105": "你是我的人",
  "image_emoticon45": "音乐",
  "image_emoticon42": "灯泡",
  "image_emoticon101": "不跟丑人说话",
  "image_emoticon102": "么么哒",
  "image_emoticon103": "亲亲才能起来",
  "image_emoticon104": "伦家只是宝宝",
  "image_emoticon36": "玫瑰",
  "image_emoticon37": "礼物",
  "image_emoticon38": "彩虹",
  "image_emoticon40": "太阳",
  "image_emoticon39": "星星月亮",
  "image_emoticon41": "钱币",
  "image_emoticon43": "茶杯",
  "image_emoticon44": "蛋糕",
  "image_emoticon48": "大拇指",
  "image_emoticon47": "胜利"
};

const Map<String, String> emojiMapping = {
  "呵呵": "image_emoticon",
  "酷": "image_emoticon5",
  "哈哈": "image_emoticon2",
  "吐舌": "image_emoticon3",
  "太开心": "image_emoticon24",
  "笑眼": "image_emoticon22",
  "花心": "image_emoticon20",
  "小乖": "image_emoticon66",
  "乖": "image_emoticon28",
  "捂嘴笑": "image_emoticon67",
  "滑稽": "image_emoticon25",
  "你懂的": "image_emoticon68",
  "不高兴": "image_emoticon12",
  "怒": "image_emoticon6",
  "汗": "image_emoticon8",
  "黑线": "image_emoticon10",
  "泪": "image_emoticon9",
  "真棒": "image_emoticon13",
  "喷": "image_emoticon33",
  "惊哭": "image_emoticon30",
  "阴险": "image_emoticon16",
  "鄙视": "image_emoticon11",
  "啊": "image_emoticon4",
  "狂汗": "image_emoticon27",
  "what": "image_emoticon69",
  "疑问": "image_emoticon15",
  "酸爽": "image_emoticon70",
  "呀咩爹": "image_emoticon71",
  "委屈": "image_emoticon19",
  "惊讶": "image_emoticon32",
  "睡觉": "image_emoticon29",
  "笑尿": "image_emoticon72",
  "挖鼻": "image_emoticon73",
  "吐": "image_emoticon17",
  "犀利": "image_emoticon74",
  "小红脸": "image_emoticon75",
  "懒得理": "image_emoticon76",
  "勉强": "image_emoticon26",
  "开心": "image_emoticon7",
  "钱": "image_emoticon14",
  "咦": "image_emoticon18",
  "呼~": "image_emoticon21",
  "冷": "image_emoticon23",
  "升起": "image_emoticon31",
  "突然兴奋": "image_emoticon97",
  "黑头高兴": "image_emoticon100",
  "欢呼": "image_emoticon95",
  "嘿嘿嘿": "image_emoticon88",
  "微微一笑": "image_emoticon91",
  "吃瓜": "image_emoticon86",
  "托腮": "image_emoticon92",
  "摊手": "image_emoticon93",
  "困成狗": "image_emoticon90",
  "暗中观察": "image_emoticon85",
  "柯基暗中观察": "image_emoticon94",
  "喝酒": "image_emoticon87",
  "噗": "image_emoticon89",
  "紧张": "image_emoticon98",
  "炸药": "image_emoticon96",
  "黑头瞪眼": "image_emoticon99",
  "望远镜": "image_emoticon128",
  "不听": "image_emoticon126",
  "干饭": "image_emoticon127",
  "老虎": "image_emoticon130",
  "嗷呜": "image_emoticon131",
  "烟花": "image_emoticon132",
  "菜狗": "image_emoticon129",
  "奥特曼": "image_emoticon125",
  "熊-88": "bearchildren_01",
  "熊-HI": "bearchildren_02",
  "熊-人艰不拆": "bearchildren_03",
  "熊-啥": "bearchildren_04",
  "熊-大哭": "bearchildren_05",
  "熊-失落": "bearchildren_06",
  "熊-怒赞": "bearchildren_07",
  "熊-惊呆了": "bearchildren_08",
  "熊-李菊福": "bearchildren_09",
  "熊-来信砍": "bearchildren_10",
  "熊-欢迎入群": "bearchildren_11",
  "熊-牛闪闪": "bearchildren_12",
  "熊-生日快乐": "bearchildren_13",
  "熊-石化": "bearchildren_14",
  "熊-羞羞哒": "bearchildren_15",
  "熊-肥皂必杀": "bearchildren_16",
  "熊-谢谢你": "bearchildren_17",
  "熊-跳舞": "bearchildren_18",
  "熊-霹雳舞": "bearchildren_19",
  "熊-鼓掌": "bearchildren_20",
  "爱心": "image_emoticon34",
  "心碎": "image_emoticon35",
  "白眼": "image_emoticon124",
  "爱你的形状": "image_emoticon123",
  "来追我呀": "image_emoticon122",
  "月亮代表我的心": "image_emoticon121",
  "无聊": "image_emoticon120",
  "扎心了": "image_emoticon119",
  "我是不会骗你的": "image_emoticon118",
  "我养你": "image_emoticon117",
  "小姐姐来玩呀": "image_emoticon116",
  "小姐姐来啦": "image_emoticon115",
  "haha": "image_emoticon46",
  "OK": "image_emoticon50",
  "沙发": "image_emoticon77",
  "手纸": "image_emoticon78",
  "香蕉": "image_emoticon79",
  "便便": "image_emoticon80",
  "药丸": "image_emoticon81",
  "红领巾": "image_emoticon82",
  "蜡烛": "image_emoticon83",
  "三道杠": "image_emoticon84",
  "小姐姐在吗": "image_emoticon114",
  "小姐姐别走": "image_emoticon113",
  "宝宝不开心": "image_emoticon112",
  "好幸福": "image_emoticon111",
  "嗯嗯": "image_emoticon110",
  "哈哈哈": "image_emoticon109",
  "吓到宝宝了": "image_emoticon108",
  "单身等撩": "image_emoticon107",
  "假装看不见": "image_emoticon106",
  "你是我的人": "image_emoticon105",
  "音乐": "image_emoticon45",
  "灯泡": "image_emoticon42",
  "不跟丑人说话": "image_emoticon101",
  "么么哒": "image_emoticon102",
  "亲亲才能起来": "image_emoticon103",
  "伦家只是宝宝": "image_emoticon104",
  "玫瑰": "image_emoticon36",
  "礼物": "image_emoticon37",
  "彩虹": "image_emoticon38",
  "太阳": "image_emoticon40",
  "星星月亮": "image_emoticon39",
  "钱币": "image_emoticon41",
  "茶杯": "image_emoticon43",
  "蛋糕": "image_emoticon44",
  "大拇指": "image_emoticon48",
  "胜利": "image_emoticon47"
};
