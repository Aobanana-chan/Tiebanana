import 'package:flutter_test/flutter_test.dart';
import 'package:tieba_contract/testing.dart';
import 'package:tieba_contract/tieba_contract.dart';

void main() {
  late DemoTiebaApi api;
  late TiebaChatApi chat;

  setUp(() {
    api = DemoTiebaApi(latency: Duration.zero);
    chat = api;
  });

  test('会话列表、未读、发送、重试与已读状态机', () async {
    final List<TiebaConversation> conversations = await chat.getConversations();
    expect(conversations, isNotEmpty);
    final int totalUnread = conversations.fold<int>(
        0, (int sum, TiebaConversation item) => sum + item.unread);
    expect(await chat.getChatUnread(), totalUnread);

    final TiebaConversation first = conversations.first;
    final ChatMessagePage page = await chat.getChatMessages(first.id);
    expect(page.messages, isNotEmpty);
    expect(page.hasMore, isFalse);

    final int before = page.messages.length;
    final ChatSendResult result = await chat.sendChatMessage(
      first.id,
      const ChatDraft(text: '测试一条文字 #(滑稽)'),
    );
    expect(result.blocked, isFalse);
    expect(result.message.status, TiebaChatMessageStatus.sent);
    expect(result.message.id, isNotEmpty);
    expect(result.message.recordId, isNotEmpty);

    final ChatMessagePage after = await chat.getChatMessages(first.id);
    expect(after.messages.length, before + 1);
    expect(after.messages.last.content, '测试一条文字 #(滑稽)');

    // 同一个 recordId 重试不会追加第二条。
    final ChatSendResult retried = await chat.sendChatMessage(
      first.id,
      ChatDraft(text: '测试一条文字 #(滑稽)', recordId: result.message.recordId),
    );
    expect(retried.message.recordId, result.message.recordId);
    expect(
      (await chat.getChatMessages(first.id)).messages.length,
      before + 1,
    );

    final TiebaConversation updated = (await chat.getConversations())
        .firstWhere((TiebaConversation item) => item.id == first.id);
    expect(updated.lastMessage, '测试一条文字 #(滑稽)');
    expect(updated.lastMessageIsMine, isTrue);

    await chat.markChatRead(first.id, after.messages.last.id);
    expect(
      (await chat.getConversations())
          .firstWhere((TiebaConversation item) => item.id == first.id)
          .unread,
      0,
    );
  });

  test('首次私信从用户主页发起：没有会话时也能发', () async {
    const String peer = '20010';
    final TiebaConversation? shell = await chat.getChatPeer(peer);
    expect(shell, isNotNull);
    expect(shell!.title, isNotEmpty);

    final ChatSendResult result = await chat.sendChatMessage(
      peer,
      const ChatDraft(text: '你好'),
    );
    expect(result.message.status, TiebaChatMessageStatus.sent);
    expect(
      (await chat.getConversations())
          .any((TiebaConversation item) => item.id == peer),
      isTrue,
    );
  });

  test('免打扰是会话级设置，屏蔽只读', () async {
    final TiebaConversation first = (await chat.getConversations()).first;
    final ChatMaskSettings before = await chat.getChatMask(first.id);
    expect(before.userId, first.id);

    await chat.updateChatMask(
      before.copyWith(muteNotifications: true, blocked: true),
    );
    final ChatMaskSettings after = await chat.getChatMask(first.id);
    expect(after.muteNotifications, isTrue);
    // IM 设置不双写屏蔽；屏蔽由 TiebaBlockSettings.chat 负责。
    expect(after.blocked, isFalse);
  });

  test('未登录不能读私信', () async {
    api.logout();
    expect(
      () => chat.getConversations(),
      throwsA(isA<NetAPIError>()),
    );
  });
}
