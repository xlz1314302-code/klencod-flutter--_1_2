import 'package:flutter/material.dart';

void main() => runApp(const AliChatApp());

const Color green = Color(0xFF27845D);
const Color greenDark = Color(0xFF176344);
const Color paleGreen = Color(0xFFEAF5EE);

class ChatMessage {
  ChatMessage(this.text, this.isMe, {String? time})
      : time = time ?? _clock();
  final String text;
  final bool isMe;
  final String time;
}

String _clock() {
  final now = DateTime.now();
  final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
  return '$h:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'م' : 'ص'}';
}

class ChatContact {
  ChatContact({required this.name, required this.color, this.online = false,
    this.unread = 0, this.group = false, List<ChatMessage>? messages})
      : messages = messages ?? <ChatMessage>[];
  final String name;
  final Color color;
  final bool online;
  final bool group;
  int unread;
  final List<ChatMessage> messages;
  String get lastText => messages.isEmpty ? 'ابدأ محادثة جديدة' : messages.last.text;
  String get lastTime => messages.isEmpty ? '' : messages.last.time;
}

class AliChatApp extends StatefulWidget {
  const AliChatApp({super.key});
  @override
  State<AliChatApp> createState() => _AliChatAppState();
}

class _AliChatAppState extends State<AliChatApp> {
  bool dark = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali Chat',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF5F8F6), foregroundColor: Color(0xFF183328), elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFFF0F5F1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true, brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101814),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101814), foregroundColor: Colors.white, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF24332B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      home: MainScreen(dark: dark, onDarkChanged: (v) => setState(() => dark = v)),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.dark, required this.onDarkChanged});
  final bool dark;
  final ValueChanged<bool> onDarkChanged;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  bool searching = false;
  String query = '';
  bool notifications = true;
  bool sounds = true;
  String profileName = 'Ali';
  String profileStatus = 'متاح للدردشة';
  final searchController = TextEditingController();
  final List<ChatContact> chats = [
    ChatContact(name: 'أحمد', color: const Color(0xFF70A9E8), online: true, unread: 2, messages: [
      ChatMessage('السلام عليكم، كيف حالك؟', false, time: '10:20 ص'),
      ChatMessage('وعليكم السلام، الحمد لله بخير 🌿', true, time: '10:23 ص'),
      ChatMessage('متى نبدأ المشروع الجديد؟', false, time: '10:30 ص'),
    ]),
    ChatContact(name: 'محمد', color: const Color(0xFFB18AE0), online: true, messages: [
      ChatMessage('التصميم جميل جداً 👏', false, time: '9:45 ص'),
      ChatMessage('تسلم يا غالي', true, time: '9:48 ص'),
    ]),
    ChatContact(name: 'فريق التصميم', color: const Color(0xFFE4A56B), group: true, unread: 5, messages: [
      ChatMessage('تم إرسال الملفات إلى المجموعة', false, time: 'أمس'),
    ]),
    ChatContact(name: 'خالد', color: const Color(0xFF65B9A0), messages: [ChatMessage('أرسل لي النسخة النهائية', false, time: 'أمس')]),
    ChatContact(name: 'سالم', color: const Color(0xFFE28C9A), online: true, messages: [ChatMessage('شكراً لك، وصلت الصورة', false, time: 'الأحد')]),
  ];
  final List<Map<String, dynamic>> calls = [
    {'name': 'أحمد', 'video': false, 'missed': false, 'time': '10:42 ص'},
    {'name': 'محمد', 'video': true, 'missed': true, 'time': 'أمس'},
    {'name': 'خالد', 'video': false, 'missed': false, 'time': 'الأحد'},
  ];

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  void snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final pages = [buildChats(), buildCalls(), buildSettings()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() { tab = v; searching = false; query = ''; searchController.clear(); }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'الدردشات'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call_rounded), label: 'المكالمات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        ],
      ),
      floatingActionButton: tab == 0 ? FloatingActionButton.extended(
        backgroundColor: green, foregroundColor: Colors.white,
        onPressed: createChat, icon: const Icon(Icons.edit_rounded), label: const Text('محادثة جديدة'),
      ) : null,
    );
  }

  Widget buildChats() {
    final filtered = chats.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 8), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مرحباً بك 👋', style: TextStyle(fontSize: 13, color: green, fontWeight: FontWeight.w700)),
          Text(profileName == 'Ali' ? 'Ali Chat' : profileName, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        ])),
        IconButton(onPressed: () => setState(() => searching = !searching), icon: Icon(searching ? Icons.close_rounded : Icons.search_rounded)),
        IconButton(onPressed: showMore, icon: const Icon(Icons.more_vert_rounded)),
      ])),
      if (searching) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: TextField(
        controller: searchController, autofocus: true, onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(hintText: 'ابحث عن محادثة...', prefixIcon: Icon(Icons.search)),
      )),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [greenDark, Color(0xFF55A77D)]), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تواصل بكل سهولة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            SizedBox(height: 5), Text('رسائلك ومحادثاتك في مكان واحد', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), shape: BoxShape.circle), child: const Icon(Icons.forum_rounded, color: Colors.white, size: 28)),
        ]),
      )),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3), child: Row(children: [
        const Expanded(child: Text('المحادثات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        Text('${filtered.length} محادثات', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ])),
      Expanded(child: filtered.isEmpty ? const Center(child: Text('لا توجد نتائج بحث')) : ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 90), itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 82),
        itemBuilder: (context, index) {
          final c = filtered[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            leading: _avatar(c),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(c.lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(c.lastTime, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 5), if (c.unread > 0) Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: green, shape: BoxShape.circle), child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            onTap: () async { c.unread = 0; await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(contact: c))); if (mounted) setState(() {}); },
            onLongPress: () => chatOptions(c),
          );
        },
      )),
    ]);
  }

  Widget _avatar(ChatContact c) => Stack(children: [
    CircleAvatar(radius: 27, backgroundColor: c.color.withOpacity(.2), child: Icon(c.group ? Icons.groups_rounded : Icons.person_rounded, color: c.color, size: 29)),
    if (c.online) Positioned(bottom: 0, right: 0, child: Container(width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF36B879), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)))),
  ]);

  void createChat() {
    final controller = TextEditingController();
    showDialog<void>(context: context, builder: (d) => AlertDialog(
      title: const Text('محادثة جديدة'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'اكتب اسم الشخص أو المجموعة')),
      actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')), FilledButton(onPressed: () {
        final name = controller.text.trim(); if (name.isEmpty) return;
        final c = ChatContact(name: name, color: Colors.teal, group: false);
        setState(() => chats.insert(0, c)); Navigator.pop(d);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(contact: c))).then((_) { if (mounted) setState(() {}); });
      }, child: const Text('إنشاء'))],
    ));
  }

  void chatOptions(ChatContact c) {
    showModalBottomSheet<void>(context: context, builder: (d) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('تثبيت المحادثة'), onTap: () { Navigator.pop(d); snack('تم تثبيت ${c.name} محلياً'); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('حذف المحادثة'), onTap: () { Navigator.pop(d); setState(() => chats.remove(c)); snack('تم حذف المحادثة'); }),
    ])));
  }

  void showMore() {
    showModalBottomSheet<void>(context: context, builder: (d) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.mark_chat_read_outlined), title: const Text('تحديد الكل كمقروء'), onTap: () { setState(() { for (final c in chats) { c.unread = 0; } }); Navigator.pop(d); snack('تم تحديد المحادثات كمقروءة'); }),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('حول Ali Chat'), onTap: () { Navigator.pop(d); about(); }),
    ])));
  }

  Widget buildCalls() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text('المكالمات', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))),
    Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [
      const CircleAvatar(backgroundColor: paleGreen, child: Icon(Icons.link_rounded, color: green)), const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('روابط المكالمات', style: TextStyle(fontWeight: FontWeight.w900)), Text('إنشاء رابط لمشاركته لاحقاً', style: TextStyle(fontSize: 11, color: Colors.grey))])),
      IconButton(onPressed: () => snack('إنشاء روابط المكالمات يحتاج خدمة اتصال وخادماً'), icon: const Icon(Icons.add_circle, color: green)),
    ])),
    const Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 8), child: Text('الأخيرة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
    Expanded(child: ListView.builder(itemCount: calls.length, itemBuilder: (context, i) {
      final call = calls[i]; final missed = call['missed'] as bool;
      return ListTile(leading: CircleAvatar(backgroundColor: paleGreen, child: Icon(call['video'] as bool ? Icons.videocam_rounded : Icons.call_rounded, color: green)),
        title: Text(call['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: missed ? Colors.red : null)),
        subtitle: Text('${missed ? 'مكالمة فائتة' : 'مكالمة صادرة'} • ${call['time']}'),
        trailing: IconButton(icon: const Icon(Icons.call_outlined, color: green), onPressed: () => snack('الاتصال الحقيقي يحتاج ربط خدمة مكالمات')),
      );
    })),
  ]);

  Widget buildSettings() => ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 25), children: [
    const Text('الإعدادات', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 15),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(22)), child: Row(children: [
      const CircleAvatar(radius: 29, backgroundColor: paleGreen, child: Text('A', style: TextStyle(color: green, fontWeight: FontWeight.w900, fontSize: 26))), const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profileName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(profileStatus, style: const TextStyle(color: green, fontSize: 12))])),
      IconButton(onPressed: editProfile, icon: const Icon(Icons.edit_outlined, color: green)),
    ])),
    const SizedBox(height: 20), const Text('التفضيلات', style: TextStyle(color: green, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    _settingsGroup([
      SwitchListTile(value: notifications, onChanged: (v) => setState(() => notifications = v), secondary: const Icon(Icons.notifications_outlined, color: green), title: const Text('الإشعارات'), subtitle: const Text('تشغيل أو إيقاف إشعارات التطبيق'), activeColor: green),
      SwitchListTile(value: sounds, onChanged: (v) => setState(() => sounds = v), secondary: const Icon(Icons.volume_up_outlined, color: green), title: const Text('الأصوات'), subtitle: const Text('أصوات الواجهة'), activeColor: green),
      SwitchListTile(value: widget.dark, onChanged: widget.onDarkChanged, secondary: const Icon(Icons.dark_mode_outlined, color: green), title: const Text('الوضع الداكن'), subtitle: const Text('تغيير مظهر التطبيق'), activeColor: green),
    ]),
    const SizedBox(height: 20), const Text('الحساب والدعم', style: TextStyle(color: green, fontWeight: FontWeight.w900)), const SizedBox(height: 8),
    _settingsGroup([
      ListTile(leading: const Icon(Icons.lock_outline, color: green), title: const Text('الخصوصية والأمان'), trailing: const Icon(Icons.chevron_left), onTap: () => info('الخصوصية', 'هذه نسخة تجريبية محلية. لا يوجد خادم أو حسابات حقيقية.')),
      ListTile(leading: const Icon(Icons.language, color: green), title: const Text('اللغة'), subtitle: const Text('العربية'), trailing: const Icon(Icons.chevron_left), onTap: () => info('اللغة', 'اللغة الحالية هي العربية.')),
      ListTile(leading: const Icon(Icons.info_outline, color: green), title: const Text('حول التطبيق'), trailing: const Icon(Icons.chevron_left), onTap: about),
      ListTile(leading: const Icon(Icons.support_agent, color: green), title: const Text('التواصل مع المطور'), subtitle: const Text('المطور علي النجار'), trailing: const Icon(Icons.chevron_left), onTap: () => info('المطور', 'علي النجار\nAli Al-Najjar for Advertising and Promotion')),
    ]),
    const SizedBox(height: 22), const Center(child: Text('ALI CHAT • VERSION 1.0', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2))),
  ]);

  Widget _settingsGroup(List<Widget> children) => Container(decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: Column(children: children));

  void editProfile() {
    final name = TextEditingController(text: profileName); final status = TextEditingController(text: profileStatus);
    showDialog<void>(context: context, builder: (d) => AlertDialog(title: const Text('تعديل الملف الشخصي'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
      const SizedBox(height: 10), TextField(controller: status, decoration: const InputDecoration(labelText: 'الحالة')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')), FilledButton(onPressed: () {
      if (name.text.trim().isEmpty) return; setState(() { profileName = name.text.trim(); profileStatus = status.text.trim().isEmpty ? 'متاح للدردشة' : status.text.trim(); }); Navigator.pop(d); snack('تم تحديث الملف الشخصي');
    }, child: const Text('حفظ'))]));
  }
  void info(String title, String message) => showDialog<void>(context: context, builder: (d) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إغلاق'))]));
  void about() => info('Ali Chat', 'تطبيق دردشة تجريبي من تصميم وتطوير علي النجار.\n\nالرسائل تعمل محلياً على هذا الجهاز.');
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contact});
  final ChatContact contact;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  bool recording = false;
  @override
  void dispose() { controller.dispose(); scrollController.dispose(); super.dispose(); }

  void send() {
    final text = controller.text.trim(); if (text.isEmpty) return;
    setState(() { widget.contact.messages.add(ChatMessage(text, true)); controller.clear(); });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (scrollController.hasClients) scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: Row(children: [
        CircleAvatar(backgroundColor: c.color.withOpacity(.2), child: Icon(c.group ? Icons.groups : Icons.person, color: c.color)), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text(c.online ? 'متصل الآن' : 'آخر ظهور مؤخراً', style: const TextStyle(fontSize: 10, color: green))])),
      ]), actions: [IconButton(onPressed: () => callInfo(false), icon: const Icon(Icons.call_outlined)), IconButton(onPressed: () => callInfo(true), icon: const Icon(Icons.videocam_outlined)), PopupMenuButton<String>(onSelected: (v) { if (v == 'clear') setState(() => c.messages.clear()); if (v == 'search') showSearchDialog(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'search', child: Text('البحث في المحادثة')), PopupMenuItem(value: 'clear', child: Text('مسح الرسائل'))])]),
      body: Column(children: [
        Expanded(child: c.messages.isEmpty ? const Center(child: Text('لا توجد رسائل بعد. ابدأ المحادثة 👋')) : ListView.builder(
          controller: scrollController, padding: const EdgeInsets.all(14), itemCount: c.messages.length,
          itemBuilder: (context, i) { final m = c.messages[i]; return Align(alignment: m.isMe ? Alignment.centerLeft : Alignment.centerRight, child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78), margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
            decoration: BoxDecoration(color: m.isMe ? const Color(0xFFDDF2E4) : Theme.of(context).cardColor, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(m.isMe ? 4 : 16), bottomRight: Radius.circular(m.isMe ? 16 : 4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(m.text, style: TextStyle(color: m.isMe ? const Color(0xFF173D2A) : null, fontSize: 15)), const SizedBox(height: 4), Text(m.time, style: TextStyle(fontSize: 9, color: m.isMe ? Colors.black45 : Colors.grey))]),
          )); },
        )),
        _composer(),
      ]),
    );
  }

  Widget _composer() => SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(7, 7, 7, 7), color: Theme.of(context).cardColor, child: Row(children: [
    IconButton(tooltip: 'إرفاق', onPressed: attachments, icon: const Icon(Icons.add_circle_outline_rounded, color: green, size: 27)),
    Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.send, onSubmitted: (_) => send(), decoration: InputDecoration(hintText: 'اكتب رسالة...', filled: true, fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24332B) : const Color(0xFFF0F5F1), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none)))),
    const SizedBox(width: 4),
    IconButton(tooltip: 'إرسال', onPressed: send, icon: const Icon(Icons.send_rounded, color: green)),
    IconButton(tooltip: 'رسالة صوتية تجريبية', onPressed: () { final start = !recording; setState(() => recording = start); if (start) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بدأ التسجيل التجريبي؛ اضغط الميكروفون مرة أخرى للإيقاف'))); } else { setState(() => widget.contact.messages.add(ChatMessage('🎤 رسالة صوتية تجريبية', true))); } }, icon: Icon(recording ? Icons.stop_circle : Icons.mic_none_rounded, color: recording ? Colors.red : green)),
  ])));

  void attachments() {
    showModalBottomSheet<void>(context: context, builder: (d) => SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, children: [
      _attachButton(d, Icons.photo_outlined, 'صورة', '📷 صورة تجريبية'),
      _attachButton(d, Icons.videocam_outlined, 'فيديو', '🎬 فيديو تجريبي'),
      _attachButton(d, Icons.insert_drive_file_outlined, 'ملف', '📎 ملف تجريبي'),
      _attachButton(d, Icons.location_on_outlined, 'الموقع', '📍 موقع تجريبي'),
      _attachButton(d, Icons.contact_page_outlined, 'جهة اتصال', '👤 جهة اتصال تجريبية'),
    ]))));
  }
  Widget _attachButton(BuildContext d, IconData icon, String label, String value) => SizedBox(width: 100, child: InkWell(onTap: () { Navigator.pop(d); setState(() => widget.contact.messages.add(ChatMessage(value, true))); }, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [CircleAvatar(backgroundColor: paleGreen, child: Icon(icon, color: green)), const SizedBox(height: 7), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]))));
  void callInfo(bool video) => showDialog<void>(context: context, builder: (d) => AlertDialog(title: Text(video ? 'مكالمة فيديو' : 'مكالمة صوتية'), content: const Text('واجهة المكالمات جاهزة، لكن الاتصال بين الأجهزة يحتاج خادم وخدمة مكالمات.'), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('حسناً'))]));
  void showSearchDialog() {
    final q = TextEditingController();
    showDialog<void>(context: context, builder: (d) => AlertDialog(title: const Text('البحث في المحادثة'), content: TextField(controller: q, decoration: const InputDecoration(hintText: 'اكتب كلمة للبحث')), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')), FilledButton(onPressed: () { final found = widget.contact.messages.where((m) => m.text.contains(q.text)).length; Navigator.pop(d); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('عدد النتائج: $found'))); }, child: const Text('بحث'))]));
  }
}