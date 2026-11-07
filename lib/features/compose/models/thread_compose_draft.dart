import 'dart:convert';

/// 发帖编辑器的本机草稿数据。
class ComposePoll {
  const ComposePoll({
    required this.title,
    required this.options,
    this.multiple = false,
    this.days = -1,
  });

  final String title;
  final List<String> options;
  final bool multiple;
  final int days;

  static String? validate(String title, List<String> options) {
    if (title.trim().isEmpty) return '请填写投票标题';
    if (options.length < 2) return '请至少填写两个选项';
    final values = options.map((v) => v.trim()).toList();
    if (values.any((v) => v.isEmpty)) return '请填写每一个选项';
    if (values.any((v) => v.runes.length > 14)) return '每个选项最多 14 个字';
    if (values.toSet().length != values.length) return '选项不能重复';
    return null;
  }
}

class ComposeAttachment {
  const ComposeAttachment(this.assetId, this.original);
  final String assetId;
  final bool original;
}

class ComposeScoreItem {
  const ComposeScoreItem(
      {required this.assetId, required this.title, this.content = ''});
  final String assetId;
  final String title;
  final String content;
}

class ComposeScore {
  const ComposeScore({required this.items, this.levelLimit = 0});
  final List<ComposeScoreItem> items;
  final int levelLimit;

  static String? validate(List<ComposeScoreItem> items) {
    if (items.isEmpty) return '请至少添加一个打分项';
    if (items.length > 30) return '最多添加 30 个打分项';
    final names = <String>{};
    for (final item in items) {
      if (item.title.trim().isEmpty) return '请添加打分项名称';
      if (item.title.runes.length > 18) return '名称最多 18 个字';
      if (item.content.runes.length > 20) return '补充简介最多 20 个字';
      if (RegExp(
              r'[\u{1F000}-\u{1FFFF}\u2122-\u2B55\u303D\u00A9\u00AE\u3030\uFE0F\u20E3]',
              unicode: true)
          .hasMatch(item.title)) {
        return '名称仅支持中英文、符号和数字，不支持表情';
      }
      if (!names.add(item.title.replaceAll(RegExp(r'\s'), ''))) {
        return '不可提交重复的打分项名称';
      }
    }
    return null;
  }
}

class ThreadComposeDraft {
  const ThreadComposeDraft({
    this.title = '',
    this.body = '',
    this.tail = '',
    this.useTail = false,
    this.poll,
    this.attachments = const [],
    this.topicId,
    this.topicName,
    this.hideFromProfile = false,
    this.contentStatement = '',
    this.score,
  });

  final String title;
  final String body;
  final String tail;
  final bool useTail;
  final ComposePoll? poll;
  final List<ComposeAttachment> attachments;
  final String? topicId;
  final String? topicName;
  final bool hideFromProfile;
  final String contentStatement;
  final ComposeScore? score;

  bool get hasContent =>
      title.trim().isNotEmpty ||
      body.trim().isNotEmpty ||
      poll != null ||
      score != null ||
      topicId != null ||
      attachments.isNotEmpty;

  String encode() => jsonEncode({
        'version': 1,
        'title': title,
        'body': body,
        'tail': tail,
        'useTail': useTail,
        'hideFromProfile': hideFromProfile,
        'contentStatement': contentStatement,
        if (score != null)
          'score': {
            'levelLimit': score!.levelLimit,
            'items': [
              for (final item in score!.items)
                {
                  'assetId': item.assetId,
                  'title': item.title,
                  'content': item.content
                }
            ]
          },
        if (topicId != null) 'topicId': topicId,
        if (topicName != null) 'topicName': topicName,
        if (poll != null)
          'poll': {
            'title': poll!.title,
            'options': poll!.options,
            'multiple': poll!.multiple,
            'days': poll!.days,
          },
        'attachments': [
          for (final a in attachments)
            {'id': a.assetId, 'original': a.original},
        ],
      });

  /// 草稿解析失败时抛出异常，调用方显示恢复失败并保留存储内容。
  static ThreadComposeDraft decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['version'] != 1) throw const FormatException('不支持的草稿版本');
    final rawPoll = data['poll'] as Map<String, dynamic>?;
    final rawScore = data['score'] as Map<String, dynamic>?;
    final score = rawScore == null
        ? null
        : ComposeScore(levelLimit: rawScore['levelLimit'] as int, items: [
            for (final item in rawScore['items'] as List)
              ComposeScoreItem(
                  assetId: item['assetId'] as String,
                  title: item['title'] as String,
                  content: item['content'] as String)
          ]);
    if (score != null &&
        (ComposeScore.validate(score.items) != null ||
            score.levelLimit < 0 ||
            score.levelLimit > 18 ||
            rawPoll != null)) {
      throw const FormatException('打分草稿无效');
    }
    final poll = rawPoll == null
        ? null
        : ComposePoll(
            title: rawPoll['title'] as String,
            options: (rawPoll['options'] as List).cast<String>(),
            multiple: rawPoll['multiple'] as bool,
            days: rawPoll['days'] as int,
          );
    if (poll != null &&
        (ComposePoll.validate(poll.title, poll.options) != null ||
            ![-1, 1, 7, 30].contains(poll.days))) {
      throw const FormatException('投票草稿无效');
    }
    return ThreadComposeDraft(
      title: data['title'] as String,
      body: data['body'] as String,
      tail: data['tail'] as String,
      useTail: data['useTail'] as bool,
      hideFromProfile: data['hideFromProfile'] as bool? ?? false,
      contentStatement: data['contentStatement'] as String? ?? '',
      score: score,
      topicId: data['topicId'] as String?,
      topicName: data['topicName'] as String?,
      poll: poll,
      attachments: [
        for (final value in data['attachments'] as List)
          ComposeAttachment(value['id'] as String, value['original'] as bool),
      ],
    );
  }
}
