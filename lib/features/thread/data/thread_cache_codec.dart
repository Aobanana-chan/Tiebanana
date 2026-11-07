import 'package:tieba_contract/tieba_contract.dart';

/// 显式、版本化的本地存储格式，与协议层对象解耦。
class ThreadCacheCodec {
  static Map<String, dynamic>? poll(TiebaPoll? p) => p == null
      ? null
      : {
          'title': p.title,
          'multiple': p.multiple,
          'participantCount': p.participantCount,
          'totalVotes': p.totalVotes,
          'optionCount': p.optionCount,
          'hasVoted': p.hasVoted,
          'selectedIds': p.selectedIds.toList(),
          'endTime': p.endTime,
          'remainingSeconds': p.remainingSeconds,
          'options': [
            for (final o in p.options) _option(o),
          ],
          'pros': _option(p.pros),
          'cons': _option(p.cons),
        };

  static Map<String, dynamic>? _option(TiebaPollOption? o) => o == null
      ? null
      : {
          'id': o.id,
          'text': o.text,
          'imageUrl': o.imageUrl,
          'votes': o.votes,
          'hasVoted': o.hasVoted,
        };

  static TiebaPollOption? _readOption(dynamic value) {
    if (value == null) return null;
    final o = Map<String, dynamic>.from(value as Map);
    return TiebaPollOption(
      id: o['id'],
      text: o['text'] ?? '',
      imageUrl: o['imageUrl'] ?? '',
      votes: o['votes'],
      hasVoted: o['hasVoted'],
    );
  }

  static TiebaPoll? readPoll(dynamic value) {
    if (value == null) return null;
    final j = Map<String, dynamic>.from(value as Map);
    return TiebaPoll(
        title: j['title'] ?? '',
        multiple: j['multiple'],
        participantCount: j['participantCount'],
        totalVotes: j['totalVotes'],
        optionCount: j['optionCount'],
        hasVoted: j['hasVoted'],
        selectedIds: Set<int>.from(j['selectedIds'] ?? const []),
        endTime: j['endTime'],
        remainingSeconds: j['remainingSeconds'],
        options: [
          for (final o in j['options'] as List? ?? [])
            TiebaPollOption(
                id: o['id'],
                text: o['text'] ?? '',
                imageUrl: o['imageUrl'] ?? '',
                votes: o['votes'],
                hasVoted: o['hasVoted'])
        ],
        pros: _readOption(j['pros']),
        cons: _readOption(j['cons']));
  }

  static Map<String, dynamic> content(TiebaPostContent c) => {
        'type': c.type.rawValue,
        'kind': switch (c) {
          TiebaImageContent() => 'TiebaImageContent',
          TiebaAtContent() => 'TiebaAtContent',
          TiebaEmojiContent() => 'TiebaEmojiContent',
          TiebaVideoContent() => 'TiebaVideoContent',
          TiebaLinkContent() => 'TiebaLinkContent',
          TiebaPhoneContent() => 'TiebaPhoneContent',
          TiebaVoiceContent() => 'TiebaVoiceContent',
          TiebaTopicContent() => 'TiebaTopicContent',
          TiebaVideoLinkContent() => 'TiebaVideoLinkContent',
          _ => 'TiebaTextContent',
        },
        if (c is TiebaTextContent) ...{'text': c.text, 'uid': c.uid},
        if (c is TiebaImageContent) ...{
          'bigCdnSrc': c.bigCdnSrc,
          'originSrc': c.originSrc,
          'bsize': c.bsize,
          'src': c.src,
          'cdnSrc': c.cdnSrc,
          'bigSrc': c.bigSrc,
          'cdnSrcActive': c.cdnSrcActive,
        },
        if (c is TiebaAtContent) ...{'text': c.text, 'uid': c.uid},
        if (c is TiebaEmojiContent) ...{
          'text': c.text,
          'c': c.c,
          'dynamicUrl': c.dynamicUrl,
          'staticUrl': c.staticUrl,
        },
        if (c is TiebaVideoContent) ...{
          'link': c.link,
          'cover': c.cover,
          'width': c.width,
          'height': c.height,
        },
        if (c is TiebaLinkContent) ...{'text': c.text, 'link': c.link},
        if (c is TiebaPhoneContent) 'text': c.text,
        if (c is TiebaVoiceContent) ...{
          'text': c.text,
          'voiceMd5': c.voiceMd5,
          'duringTime': c.duringTime,
        },
        if (c is TiebaTopicContent) ...{'text': c.text, 'link': c.link},
        if (c is TiebaVideoLinkContent) ...{'text': c.text, 'link': c.link},
      };

  static TiebaPostContent readContent(Map<String, dynamic> j) {
    final type = TiebaContentType.fromRaw(j['type']);
    switch (j['kind']) {
      case 'TiebaImageContent':
        return TiebaImageContent(
            bigCdnSrc: j['bigCdnSrc'],
            originSrc: j['originSrc'],
            bsize: j['bsize'],
            src: j['src'],
            cdnSrc: j['cdnSrc'],
            bigSrc: j['bigSrc'],
            cdnSrcActive: j['cdnSrcActive'],
            type: type);
      case 'TiebaAtContent':
        return TiebaAtContent(text: j['text'], uid: j['uid']);
      case 'TiebaEmojiContent':
        return TiebaEmojiContent(
            c: j['c'],
            text: j['text'],
            dynamicUrl: j['dynamicUrl'],
            staticUrl: j['staticUrl'],
            type: type);
      case 'TiebaVideoContent':
        return TiebaVideoContent(
            link: j['link'],
            cover: j['cover'],
            width: j['width'],
            height: j['height']);
      case 'TiebaLinkContent':
        return TiebaLinkContent(text: j['text'], link: j['link'], type: type);
      case 'TiebaPhoneContent':
        return TiebaPhoneContent(text: j['text']);
      case 'TiebaVoiceContent':
        return TiebaVoiceContent(
            text: j['text'],
            voiceMd5: j['voiceMd5'],
            duringTime: j['duringTime']);
      case 'TiebaTopicContent':
        return TiebaTopicContent(text: j['text'], link: j['link'], type: type);
      case 'TiebaVideoLinkContent':
        return TiebaVideoLinkContent(text: j['text'], link: j['link']);
      default:
        return TiebaTextContent(
            text: j['text'] ?? '', uid: j['uid'], type: type);
    }
  }

  static Map<String, dynamic> author(TiebaAuthor a) => {
        'icons': a.icons,
        'levelID': a.levelID,
        'forumRole': a.forumRole?.name,
        'nameShow': a.nameShow,
        'portrait': a.portrait,
        'uid': a.uid,
        'username': a.username,
      };
  static TiebaAuthor readAuthor(Map<String, dynamic> j) => TiebaAuthor(
      icons: List<String>.from(j['icons']),
      levelID: j['levelID'],
      forumRole: switch (j['forumRole']) {
        'assistant' => TiebaForumRole.assistant,
        'manager' => TiebaForumRole.manager,
        _ => null,
      },
      nameShow: j['nameShow'],
      portrait: j['portrait'],
      uid: j['uid'],
      username: j['username']);
  static Map<String, dynamic> post(TiebaPost p) => {
        'id': p.id,
        'title': p.title,
        'createTime': p.createTime,
        'content': p.content.map(content).toList(),
        'isFirstFloor': p.isFirstFloor,
        'isInnerFloor': p.isInnerFloor,
        'isDeleted': p.isDeleted,
        'agreeNum': p.agreeNum,
        'disagreeNum': p.disagreeNum,
        'hasAgree': p.hasAgree,
        'agreeType': p.agreeType,
        'portrait': p.portrait,
        'uid': p.uid,
        'nameShow': p.nameShow,
        'username': p.username,
        if (p is TiebaThreadPagePost) ...{
          'floor': p.floor,
          'lbsInfo': p.lbsInfo,
          'ipLocation': p.ipLocation,
          'poll': poll(p.poll),
          'hasPoll': p.hasPoll,
          'subPostList': p.subPostList.map(post).toList(),
          'subPostNumber': p.subPostNumber,
        },
        if (p is TiebaSubPost) 'isVoice': p.isVoice,
      };
  static TiebaPost readPost(Map<String, dynamic> j) {
    final List<TiebaPostContent> contents = (j['content'] as List)
        .map((e) => readContent(Map<String, dynamic>.from(e)))
        .toList();
    final TiebaPost p;
    if (j.containsKey('floor')) {
      p = TiebaThreadPagePost(
          id: j['id'],
          title: j['title'],
          floor: j['floor'],
          lbsInfo: j['lbsInfo'],
          ipLocation: j['ipLocation'] ?? '',
          poll: readPoll(j['poll']),
          hasPoll: j['hasPoll'] ?? false,
          subPostList: (j['subPostList'] as List)
              .map(
                  (e) => readPost(Map<String, dynamic>.from(e)) as TiebaSubPost)
              .toList(),
          subPostNumber: j['subPostNumber'],
          content: contents,
          createTime: j['createTime'],
          isFirstFloor: j['isFirstFloor'],
          isInnerFloor: j['isInnerFloor'],
          portrait: j['portrait'],
          uid: j['uid'],
          nameShow: j['nameShow'],
          username: j['username']);
    } else {
      p = TiebaSubPost(
          id: j['id'],
          title: j['title'],
          isVoice: j['isVoice'] ?? false,
          content: contents,
          createTime: j['createTime'],
          isFirstFloor: j['isFirstFloor'],
          isInnerFloor: j['isInnerFloor'],
          portrait: j['portrait'],
          uid: j['uid'],
          nameShow: j['nameShow'],
          username: j['username']);
    }
    return p
      ..isDeleted = j['isDeleted'] ?? false
      ..agreeNum = j['agreeNum']
      ..disagreeNum = j['disagreeNum']
      ..hasAgree = j['hasAgree']
      ..agreeType = j['agreeType'];
  }

  static Map<String, dynamic> pageInfo(TiebaPageInfo p) => {
        'currentPage': p.currentPage,
        'hasMore': p.hasMore,
        'hasPrev': p.hasPrev,
      };
  static TiebaPageInfo readPageInfo(Map<String, dynamic> j) => TiebaPageInfo(
      currentPage: j['currentPage'],
      hasMore: j['hasMore'],
      hasPrev: j['hasPrev']);
  static Map<String, dynamic> page(TiebaThreadPage p) => {
        'posts': p.posts.map(post).toList(),
        'page': pageInfo(p.page),
        'agreeType': p.thread.agreeType,
        'storeCount': p.thread.storeCount,
        'threadAuthorUid': p.thread.authorUid,
        'poll': poll(p.thread.poll),
        'hasPoll': p.thread.hasPoll,
        'authors': p.userListSet.map((k, v) => MapEntry(k, author(v))),
        'videoUrl': p.videoInfo?.videoUrl,
        'thumbnailUrl': p.videoInfo?.thumbnailUrl,
        'videoWidth': p.videoInfo?.width,
        'videoHeight': p.videoInfo?.height,
        'isStored': p.isStored,
        'tid': p.tid,
        'title': p.title,
        'fid': p.fid,
        'forumName': p.forumName,
        'avatar': p.avatar,
        'hasMore': p.hasMore,
        'hasPrev': p.hasPrev,
        'pages': p.postPage.map((k, v) => MapEntry('$k', v.map(post).toList())),
      };
  static TiebaThreadPage readPage(Map<String, dynamic> j) {
    final p = TiebaThreadPage(
        posts: (j['posts'] as List)
            .map((e) =>
                readPost(Map<String, dynamic>.from(e)) as TiebaThreadPagePost)
            .toList(),
        page: readPageInfo(j['page']),
        thread: TiebaThreadData(
            agreeType: j['agreeType'],
            poll: readPoll(j['poll']),
            hasPoll: j['hasPoll'] ?? false,
            storeCount: j['storeCount'],
            authorUid: j['threadAuthorUid'] ?? ''),
        userListSet: (j['authors'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, readAuthor(v))),
        videoInfo: j['thumbnailUrl'] == null
            ? null
            : TiebaVideoInfo(
                videoUrl: j['videoUrl'],
                thumbnailUrl: j['thumbnailUrl'],
                width: j['videoWidth'],
                height: j['videoHeight']),
        isStored: j['isStored'],
        tid: j['tid'],
        title: j['title'],
        fid: j['fid'],
        forumName: j['forumName'],
        avatar: j['avatar'],
        hasMore: j['hasMore'] ?? false,
        hasPrev: j['hasPrev'] ?? false);
    (j['pages'] as Map<String, dynamic>).forEach((k, v) {
      p.postPage[int.parse(k)] = (v as List)
          .map((e) =>
              readPost(Map<String, dynamic>.from(e)) as TiebaThreadPagePost)
          .toList();
    });
    return p;
  }

  static Map<String, dynamic> inner(InnerFloor f) => {
        'post': post(f.post),
        'subposts': f.subposts.map(post).toList(),
        'page': pageInfo(f.page),
        'agreeType': f.thread.agreeType,
        'storeCount': f.thread.storeCount,
        'threadAuthorUid': f.thread.authorUid,
        'authors': f.authors.map((k, v) => MapEntry(k, author(v))),
      };
  static InnerFloor readInner(Map<String, dynamic> j) => InnerFloor(
      post: readPost(j['post']) as TiebaThreadPagePost,
      subposts: (j['subposts'] as List)
          .map((e) => readPost(Map<String, dynamic>.from(e)) as TiebaSubPost)
          .toList(),
      page: readPageInfo(j['page']),
      thread: TiebaThreadData(
          agreeType: j['agreeType'],
          storeCount: j['storeCount'],
          authorUid: j['threadAuthorUid'] ?? ''),
      authors: (j['authors'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, readAuthor(v))));
}
