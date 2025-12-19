// ---------------------------------------------------------
// [1단계] AI가 사용할 '음식 카드' 위젯(부품) 정의하기
// ---------------------------------------------------------
// 1-1. 데이터 모양 정의 (Schema): AI에게 "이 위젯은 이름, 가격, 설명이 필요해"라고 알려줌
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../io_get_api_key.dart'
    if (dart.library.html) '../web_get_api_key.dart';

final foodCardSchema = S.object(
  properties: {
    'foodName': S.string(description: '음식의 이름'),
    'price': S.string(description: '음식 가격 (예: 10,000원)'),
    'description': S.string(description: '음식에 대한 맛있는 설명'),
  },
  required: ['foodName', 'price', 'description'],
);

// 1-2. 위젯 모양 정의 (CatalogItem): 실제 화면에 그려질 Flutter 코드
final foodCardItem = CatalogItem(
  name: 'FoodCard', // AI가 부를 이름
  dataSchema: foodCardSchema,
  widgetBuilder: (CatalogItemContext itemContext) {
    final data = itemContext.data;
    final json = data as Map<String, Object?>;
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🍽️ ${json['foodName']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${json['description']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '가격: ${json['price']}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  },
);

// ---------------------------------------------------------
// [2단계] 메인 앱 화면 및 AI 연결
// ---------------------------------------------------------

class AiWaiterApp extends StatefulWidget {
  const AiWaiterApp({super.key});

  @override
  State<AiWaiterApp> createState() => _AiWaiterAppState();
}

class _AiWaiterAppState extends State<AiWaiterApp> {
  late final A2uiMessageProcessor _manager;
  late final GenUiConversation _conversation;
  final TextEditingController _textController = TextEditingController();

  // 생성된 UI들의 ID를 저장할 리스트
  final List<String> _surfaceIds = [];

  @override
  void initState() {
    super.initState();

    // 2-1. 매니저 생성: 기본 위젯들 + 우리가 만든 FoodCard 등록
    _manager = A2uiMessageProcessor(
      catalogs: [
        CoreCatalogItems.asCatalog().copyWith([foodCardItem]),
      ],
    );

    // 2-2. AI 생성기 연결 (Gemini)
    final contentGenerator = GoogleGenerativeAiContentGenerator(
      apiKey: getApiKey(),
      modelName: 'models/gemini-3-flash-preview',
      // 2-3. AI에게 역할 부여 (중요!)
      systemInstruction: '''
        당신은 친절한 AI 웨이터입니다.
        사용자가 배고프다고 하거나 메뉴를 추천해달라고 하면,
        텍스트로 길게 설명하지 말고 반드시 'FoodCard' 위젯을 사용하여 메뉴를 보여주세요.
        한 번에 하나의 메뉴만 추천하세요.
      ''',
      additionalTools: [
        // _manager.getTools(), // AI가 위젯을 만들 수 있게 도구 쥐어주기
      ],
      catalog: _manager.catalogs.first,
    );

    // 2-4. 대화 관리자 생성
    _conversation = GenUiConversation(
      a2uiMessageProcessor: _manager,
      contentGenerator: contentGenerator,
      // 화면이 추가될 때마다 호출되는 콜백
      onSurfaceAdded: (update) {
        setState(() {
          _surfaceIds.add(update.surfaceId);
        });
      },
      onSurfaceDeleted: (update) {
        setState(() {
          _surfaceIds.remove(update.surfaceId);
        });
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _conversation.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.isEmpty) return;

    // AI에게 메시지 전송
    _conversation.sendRequest(UserMessage.text(text));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI 메뉴 추천 앱")),
      body: Column(
        children: [
          // 3. AI가 만들어준 화면들이 표시되는 곳
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _surfaceIds.length,
              itemBuilder: (context, index) {
                // GenUiSurface가 실제 위젯을 그립니다
                return GenUiSurface(
                  host: _conversation.host,
                  surfaceId: _surfaceIds[index],
                );
              },
            ),
          ),
          // 입력창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "예: 배고파, 매운 거 추천해줘",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
