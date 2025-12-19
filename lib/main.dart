import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:logging/logging.dart';

// Schema 별칭
typedef S = Schema;

// =========================================================
// 1. PainSlider (입력 컴포넌트)
// =========================================================

final _painSliderSchema = S.object(
  properties: {'initialValue': S.integer(description: '슬라이더의 초기값 (기본 5)')},
);

extension type _PainSliderData.fromMap(Map<String, Object?> _json) {
  factory _PainSliderData({int? initialValue}) => _PainSliderData.fromMap({
    if (initialValue != null) 'initialValue': initialValue,
  });

  int get initialValue => _json['initialValue'] as int? ?? 5;
}

final painSlider = CatalogItem(
  name: 'pain_slider',
  dataSchema: _painSliderSchema,
  widgetBuilder: (context) {
    final data = _PainSliderData.fromMap(context.data as Map<String, Object?>);

    return _PainSliderWidget(
      initialValue: data.initialValue,
      onChanged: (value) {
        context.dispatchEvent(
          UserActionEvent(
            name: 'submitPainLevel',
            sourceComponentId: context.id,
            context: {'painLevel': value},
          ),
        );
      },
    );
  },
);

class _PainSliderWidget extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const _PainSliderWidget({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_PainSliderWidget> createState() => _PainSliderWidgetState();
}

class _PainSliderWidgetState extends State<_PainSliderWidget> {
  late double _value;
  bool _submitted = false; // 전송 여부 체크

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "통증 정도를 알려주세요 (1-10)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _value,
              min: 1,
              max: 10,
              divisions: 9,
              label: _value.round().toString(),
              activeColor: Colors.redAccent,
              onChanged: _submitted
                  ? null
                  : (val) => setState(() => _value = val),
            ),
            if (!_submitted)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _submitted = true);
                    widget.onChanged(_value.round());
                  },
                  child: const Text("확인"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 2. SymptomSelector (입력 컴포넌트)
// =========================================================

final _symptomSelectorSchema = S.object(
  properties: {
    'options': S.list(description: '선택 가능한 증상 목록', items: S.string()),
  },
  required: ['options'],
);

extension type _SymptomSelectorData.fromMap(Map<String, Object?> _json) {
  List<String> get options => (_json['options'] as List).cast<String>();
}

final symptomSelector = CatalogItem(
  name: 'symptom_selector',
  dataSchema: _symptomSelectorSchema,
  widgetBuilder: (context) {
    final data = _SymptomSelectorData.fromMap(
      context.data as Map<String, Object?>,
    );

    return _SymptomSelectorWidget(
      options: data.options,
      onSelected: (selected) {
        context.dispatchEvent(
          UserActionEvent(
            name: 'submitSymptoms',
            sourceComponentId: context.id,
            context: {'selectedSymptoms': selected},
          ),
        );
      },
    );
  },
);

class _SymptomSelectorWidget extends StatefulWidget {
  final List<String> options;
  final ValueChanged<List<String>> onSelected;

  const _SymptomSelectorWidget({
    required this.options,
    required this.onSelected,
  });

  @override
  State<_SymptomSelectorWidget> createState() => _SymptomSelectorWidgetState();
}

class _SymptomSelectorWidgetState extends State<_SymptomSelectorWidget> {
  final Set<String> _selectedSymptoms = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: widget.options.map((option) {
              final isSelected = _selectedSymptoms.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: _submitted
                    ? null
                    : (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(option);
                          } else {
                            _selectedSymptoms.remove(option);
                          }
                        });
                      },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (!_submitted)
          ElevatedButton.icon(
            onPressed: _selectedSymptoms.isEmpty
                ? null
                : () {
                    setState(() => _submitted = true);
                    widget.onSelected(_selectedSymptoms.toList());
                  },
            icon: const Icon(Icons.send, size: 18),
            label: const Text("선택 완료"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

// =========================================================
// 3. DiagnosisCard (출력 컴포넌트)
// =========================================================

final _diagnosisCardSchema = S.object(
  properties: {
    'diagnosisName': A2uiSchemas.stringReference(description: '병명'),
    'description': A2uiSchemas.stringReference(description: '설명'),
    'severity': A2uiSchemas.stringReference(description: '심각도 (안전/주의/위험)'),
    'department': A2uiSchemas.stringReference(description: '추천 진료과'),
  },
  required: ['diagnosisName', 'description', 'severity', 'department'],
);

extension type _DiagnosisCardData.fromMap(Map<String, Object?> _json) {
  JsonMap get diagnosisName => _json['diagnosisName'] as JsonMap;
  JsonMap get description => _json['description'] as JsonMap;
  JsonMap get severity => _json['severity'] as JsonMap;
  JsonMap get department => _json['department'] as JsonMap;
}

final diagnosisCard = CatalogItem(
  name: 'diagnosis_card',
  dataSchema: _diagnosisCardSchema,
  widgetBuilder: (context) {
    final data = _DiagnosisCardData.fromMap(
      context.data as Map<String, Object?>,
    );

    final nameNotifier = context.dataContext.subscribeToString(
      data.diagnosisName,
    );
    final descNotifier = context.dataContext.subscribeToString(
      data.description,
    );
    final severityNotifier = context.dataContext.subscribeToString(
      data.severity,
    );
    final deptNotifier = context.dataContext.subscribeToString(data.department);

    return _DiagnosisCardWidget(
      nameNotifier: nameNotifier,
      descNotifier: descNotifier,
      severityNotifier: severityNotifier,
      deptNotifier: deptNotifier,
    );
  },
);

class _DiagnosisCardWidget extends StatelessWidget {
  final ValueNotifier<String?> nameNotifier;
  final ValueNotifier<String?> descNotifier;
  final ValueNotifier<String?> severityNotifier;
  final ValueNotifier<String?> deptNotifier;

  const _DiagnosisCardWidget({
    required this.nameNotifier,
    required this.descNotifier,
    required this.severityNotifier,
    required this.deptNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: severityNotifier,
      builder: (context, severity, _) {
        Color color = Colors.green;
        IconData icon = Icons.check_circle_outline;
        if (severity == '위험') {
          color = Colors.red;
          icon = Icons.warning_amber;
        } else if (severity == '주의') {
          color = Colors.orange;
          icon = Icons.priority_high;
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.5), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: nameNotifier,
                        builder: (_, name, __) => Text(
                          name ?? '분석 중...',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: descNotifier,
                  builder: (_, desc, __) => Text(
                    desc ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge(color, "심각도", severity ?? '...'),
                    ValueListenableBuilder<String?>(
                      valueListenable: deptNotifier,
                      builder: (_, dept, __) =>
                          _buildBadge(Colors.blue, "진료과", dept ?? '...'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 4. MedicationList (출력 컴포넌트)
// =========================================================

final _medicationListSchema = S.object(
  properties: {
    'medications': S.list(
      items: S.object(
        properties: {
          'name': A2uiSchemas.stringReference(description: "약 제품명"),
          'dosage': A2uiSchemas.stringReference(description: "복용법"),
        },
        required: ['name', 'dosage'],
      ),
    ),
  },
  required: ['medications'],
);

extension type _MedicationListData.fromMap(Map<String, Object?> _json) {
  List<_MedicationItemData> get medications => (_json['medications'] as List)
      .cast<Map<String, Object?>>()
      .map(_MedicationItemData.fromMap)
      .toList();
}

extension type _MedicationItemData.fromMap(Map<String, Object?> _json) {
  JsonMap get name => _json['name'] as JsonMap;
  JsonMap get dosage => _json['dosage'] as JsonMap;
}

final medicationList = CatalogItem(
  name: 'medication_list',
  dataSchema: _medicationListSchema,
  widgetBuilder: (context) {
    final data = _MedicationListData.fromMap(
      context.data as Map<String, Object?>,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            "💊 추천 약국 약",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...data.medications.map((item) {
          final nameNotifier = context.dataContext.subscribeToString(item.name);
          final dosageNotifier = context.dataContext.subscribeToString(
            item.dosage,
          );

          return _MedicationItemWidget(
            nameNotifier: nameNotifier,
            dosageNotifier: dosageNotifier,
          );
        }),
      ],
    );
  },
);

class _MedicationItemWidget extends StatelessWidget {
  final ValueNotifier<String?> nameNotifier;
  final ValueNotifier<String?> dosageNotifier;

  const _MedicationItemWidget({
    required this.nameNotifier,
    required this.dosageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: const Icon(
            Icons.medication_outlined,
            color: Colors.teal,
            size: 20,
          ),
        ),
        title: ValueListenableBuilder(
          valueListenable: nameNotifier,
          builder: (_, name, __) => Text(
            name ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: ValueListenableBuilder(
          valueListenable: dosageNotifier,
          builder: (_, dosage, __) => Text(
            dosage ?? '',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 5. 카탈로그 정의 & Main
// =========================================================

final medicalCatalog = Catalog([
  painSlider,
  symptomSelector,
  diagnosisCard,
  medicationList,
]);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureGenUiLogging(level: Level.ALL);
  runApp(const DrGenUiApp());
}

class DrGenUiApp extends StatelessWidget {
  const DrGenUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr. GenUI',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// 채팅 메시지 모델 & 위젯
// ----------------------------------------------------------------------
class MessageController {
  MessageController({this.text, this.surfaceId})
    : assert((surfaceId == null) != (text == null));

  final String? text;
  final String? surfaceId;
}

class MessageView extends StatelessWidget {
  const MessageView(this.controller, this.host, {super.key});

  final MessageController controller;
  final GenUiHost host;

  @override
  Widget build(BuildContext context) {
    final String? surfaceId = controller.surfaceId;

    if (surfaceId == null) {
      final isUser = controller.text!.startsWith('You:');
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.teal[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(controller.text ?? ''),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: GenUiSurface(host: host, surfaceId: surfaceId),
    );
  }
}

// ----------------------------------------------------------------------
// 메인 채팅 화면 (수정됨: Reverse List)
// ----------------------------------------------------------------------
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ⚠️ 중요: 실제 API 키 입력
  static const String _apiKey = '';

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MessageController> _messages = [];

  late final GenUiConversation _genUiConversation;
  late final GenUiManager _genUiManager;

  @override
  void initState() {
    super.initState();

    _genUiManager = GenUiManager(catalog: medicalCatalog);

    final contentGenerator = GoogleGenerativeAiContentGenerator(
      apiKey: _apiKey,
      // model: 'gemini-1.5-flash',
      systemInstruction: """
       당신은 친절하고 전문적인 의료 상담 AI '닥터 젠유'입니다.
        
        [시스템 절대 규칙: UI 생성]
        1. **새로운 Surface 생성 필수**: 
           - 사용자의 응답에 따라 새로운 UI 도구를 보여줄 때는, **반드시 이전과 다른 새로운 'surfaceId'를 사용**해야 합니다.
           - 예: 'question_pain', 'question_symptom', 'result_diagnosis', 'result_meds' 등으로 ID를 계속 바꾸세요.
           - 절대로 기존의 `surfaceId`를 재사용하거나 업데이트하지 마세요.
        
        [문진 순서 엄수]
        1. **Step 1 (통증 확인)**: 
           - "통증이 어느 정도인가요?"라고 묻고 **'pain_slider'**를 띄우세요. (ID: 'ui_pain')
           
        2. **Step 2 (증상 상세)**: 
           - 슬라이더 입력이 끝나면, "구체적인 증상을 선택해주세요."라고 묻고 **'symptom_selector'**를 띄우세요. (ID: 'ui_symptom')
           
        3. **Step 3 (진단 결과)**: 
           - 증상 선택이 완료되면, 즉시 **'diagnosis_card'**로 병명과 진료과를 보여주세요. (ID: 'ui_diagnosis')
           
        4. **Step 4 (약 추천 - 필수)**: 
           - 진단 카드 바로 뒤에 이어서, 증상 완화에 도움이 되는 약을 **'medication_list'** 위젯으로 보여주세요. (ID: 'ui_meds')
           - ⚠️ 약 이름은 텍스트로 절대 나열하지 말고, 오직 위젯으로만 보여주세요.

        [대화 예시]
        사용자: "머리가 아파요."
        AI: "통증이 어느 정도인가요?" 
        (Tool: 'pain_slider' 호출, surfaceId='q_pain')
        
        사용자: (입력 완료)
        AI: "알겠습니다. 증상을 모두 선택해주세요." 
        (Tool: 'symptom_selector' 호출, surfaceId='q_symptom')
        
        사용자: (선택 완료)
        AI: "분석 결과입니다. 긴장성 두통이 의심됩니다." 
        (Tool: 'diagnosis_card' 호출, surfaceId='res_diag')
        (Tool: 'medication_list' 호출, surfaceId='res_meds')
        
        [주의사항]
        - 이 앱은 실제 의사를 대체할 수 없으며 참고용임을 항상 상기시키세요.
        - 응급 상황으로 판단되면 즉시 응급실 방문을 권유하세요.
        - 말투는 부드럽고 공감하는 어조를 사용하세요.
      """,
      catalog: medicalCatalog,
    );

    _genUiConversation = GenUiConversation(
      genUiManager: _genUiManager,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      onError: (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('에러 발생: ${error.error}')));
      },
    );
  }

  // [수정] 메시지를 리스트의 맨 앞(0번 인덱스)에 추가합니다.
  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, MessageController(surfaceId: surface.surfaceId));
    });
    _scrollToBottom();
  }

  // [수정] 텍스트 응답도 맨 앞에 추가합니다.
  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.insert(0, MessageController(text: 'AI: $text'));
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      // [수정] 내 메시지도 맨 앞에 추가
      _messages.insert(0, MessageController(text: 'You: $text'));
    });
    _scrollToBottom();

    unawaited(_genUiConversation.sendRequest(UserMessage([TextPart(text)])));
  }

  // [수정] 스크롤을 0.0 (Reverse 리스트의 바닥)으로 이동
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _genUiConversation.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dr. GenUI 진료실")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true, // [핵심] 리스트를 뒤집어서 최신 메시지가 아래에 오게 함
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    // messages[0]이 최신이므로 그대로 인덱싱하면 됩니다.
                    return MessageView(
                      _messages[index],
                      _genUiConversation.host,
                    );
                  },
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _genUiConversation.isProcessing,
                builder: (_, isProcessing, __) {
                  return isProcessing
                      ? const LinearProgressIndicator()
                      : const SizedBox.shrink();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: '증상을 말씀해주세요...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// // ---------------------------------------------------------
// // [1단계] AI가 사용할 '레시피 카드' 위젯(부품) 정의하기
// // ---------------------------------------------------------
//
// // 1-1. 데이터 모양 정의 (Schema)
// // 가격 대신 '재료(배열)'와 '요리순서(배열)', '난이도' 등을 정의합니다.
// final recipeCardSchema = S.object(
//   properties: {
//     'dishName': S.string(description: '요리 이름'),
//     'cookingTime': S.string(description: '소요 시간 (예: 30분)'),
//     'difficulty': S.string(
//       enumValues: ['쉬움', '보통', '어려움'],
//       description: '요리 난이도',
//     ),
//     // S.array를 사용하여 목록 데이터를 받습니다.
//     'ingredients': S.list(items: S.string(), description: '필요한 재료 목록'),
//     'steps': S.list(items: S.string(), description: '요리 순서 (단계별)'),
//   },
//   required: ['dishName', 'cookingTime', 'ingredients', 'steps'],
// );
//
// // 1-2. 위젯 모양 정의 (CatalogItem)
// final recipeCardItem = CatalogItem(
//   name: 'RecipeCard', // AI가 사용할 도구 이름
//   dataSchema: recipeCardSchema,
//   widgetBuilder: (CatalogItemContext itemContext) {
//     final data = itemContext.data;
//     final json = data as Map<String, Object?>;
//
//     // JSON 배열을 Dart 리스트로 변환 (안전하게 처리)
//     final ingredients =
//         (json['ingredients'] as List<dynamic>?)?.cast<String>() ?? [];
//     final steps = (json['steps'] as List<dynamic>?)?.cast<String>() ?? [];
//
//     return Card(
//       elevation: 6,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       margin: const EdgeInsets.symmetric(vertical: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // 1. 헤더 (이미지 대신 색상 배너)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: const BoxDecoration(
//               color: Colors.green,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '🍳 ${json['dishName']}',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildTag(Icons.timer, json['cookingTime'] as String),
//                     const SizedBox(width: 8),
//                     _buildTag(Icons.bar_chart, json['difficulty'] as String),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // 2. 재료 섹션
//                 const Text(
//                   '🛒 재료',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const Divider(),
//                 ...ingredients.map(
//                   (ing) => Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 2),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.check_circle_outline,
//                           size: 16,
//                           color: Colors.green,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(child: Text(ing)),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // 3. 조리 순서 섹션
//                 const Text(
//                   '🔥 조리 순서',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const Divider(),
//                 ListView.separated(
//                   shrinkWrap: true,
//                   // 리스트뷰 안에 리스트뷰가 있으므로 필수
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: steps.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 12),
//                   itemBuilder: (context, index) {
//                     return Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         CircleAvatar(
//                           radius: 12,
//                           backgroundColor: Colors.orange[100],
//                           child: Text(
//                             '${index + 1}',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.deepOrange,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             steps[index],
//                             style: const TextStyle(height: 1.4),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   },
// );
//
// // 헬퍼 위젯: 상단 태그 만들기
// Widget _buildTag(IconData icon, String text) {
//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//     decoration: BoxDecoration(
//       color: Colors.white.withValues(alpha: 0.2),
//       borderRadius: BorderRadius.circular(12),
//     ),
//     child: Row(
//       children: [
//         Icon(icon, size: 14, color: Colors.white),
//         const SizedBox(width: 4),
//         Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
//       ],
//     ),
//   );
// }
//
// // ---------------------------------------------------------
// // [2단계] 메인 앱 화면 및 AI 연결
// // ---------------------------------------------------------
//
// class AiRecipeApp extends StatefulWidget {
//   const AiRecipeApp({super.key});
//
//   @override
//   State<AiRecipeApp> createState() => _AiRecipeAppState();
// }
//
// class _AiRecipeAppState extends State<AiRecipeApp> {
//   late final GenUiManager _manager;
//   late final GenUiConversation _conversation;
//   final TextEditingController _textController = TextEditingController();
//   final List<String> _surfaceIds = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     // 2-1. 매니저 생성: 레시피 카드 등록
//     _manager = GenUiManager(
//       catalog: CoreCatalogItems.asCatalog().copyWith([recipeCardItem]),
//     );
//
//     // 2-2. AI 생성기 연결
//     final contentGenerator = GoogleGenerativeAiContentGenerator(
//       apiKey: getApiKey(),
//       // 기존 키 가져오기 함수 유지
//       modelName: 'models/gemini-2.5-flash',
//
//       // 2-3. AI에게 셰프 역할 부여
//       systemInstruction: '''
//         당신은 미슐랭 스타 셰프입니다.
//         사용자가 요리법을 물어보거나 냉장고에 있는 재료를 말하면,
//         텍스트로 줄글을 쓰지 말고 반드시 'RecipeCard' 위젯을 사용하여 레시피를 보여주세요.
//
//         RecipeCard를 만들 때:
//         - cookingTime은 '15분', '1시간' 처럼 적어주세요.
//         - difficulty는 '쉬움', '보통', '어려움' 중 하나를 선택하세요.
//         - ingredients와 steps는 최대한 상세하게 리스트로 작성해주세요.
//       ''',
//       additionalTools: [],
//       catalog: _manager.catalog,
//     );
//
//     _conversation = GenUiConversation(
//       genUiManager: _manager,
//       contentGenerator: contentGenerator,
//       onSurfaceAdded: (update) =>
//           setState(() => _surfaceIds.add(update.surfaceId)),
//       onSurfaceDeleted: (update) =>
//           setState(() => _surfaceIds.remove(update.surfaceId)),
//     );
//   }
//
//   @override
//   void dispose() {
//     _textController.dispose();
//     _conversation.dispose();
//     super.dispose();
//   }
//
//   void _sendMessage() {
//     final text = _textController.text;
//     if (text.trim().isEmpty) return;
//     _conversation.sendRequest(UserMessage.text(text));
//     _textController.clear();
//     // 키보드 내리기
//     FocusScope.of(context).unfocus();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("👨‍🍳 AI 셰프")),
//       backgroundColor: Colors.grey[100],
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: _surfaceIds.length,
//               itemBuilder: (context, index) {
//                 return GenUiSurface(
//                   host: _conversation.host,
//                   surfaceId: _surfaceIds[index],
//                 );
//               },
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16.0),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _textController,
//                     decoration: const InputDecoration(
//                       hintText: "예: 김치볶음밥 레시피 알려줘",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.all(Radius.circular(30)),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 10,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 FloatingActionButton(
//                   onPressed: _sendMessage,
//                   mini: true,
//                   backgroundColor: Colors.green,
//                   child: const Icon(Icons.send, color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
