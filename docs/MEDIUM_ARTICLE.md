# Flutter와 Gemini로 구현하는 차세대 의료 AI: GenUI(Generative UI)의 강력함

텍스트로만 답변하는 챗봇의 시대는 저물고 있습니다. 이제 AI는 사용자의 상황을 이해하고, 그에 가장 적합한 **UI(User Interface)를 실시간으로 생성**하여 제공합니다. 구글의 Gemini AI와 Flutter의 유연함을 결합한 **Dr. GenUI(닥터 젠유)** 프로젝트를 통해 Generative UI가 어떻게 사용자 경험을 혁신하는지 살펴보겠습니다.

## 1. GenUI(Generative UI)란 무엇인가?

기존의 챗봇은 정해진 텍스트나 고정된 버튼 세트만을 반환했습니다. 하지만 **GenUI**는 AI가 대화의 맥락을 분석하여 "지금은 슬라이더가 필요해", "지금은 상세 진단 카드를 보여줘야 해"라고 스스로 판단하고, 실제 Flutter 위젯을 화면에 띄웁니다.

Dr. GenUI는 의료 상담 시나리오를 바탕으로, 환자의 통증 정도를 묻거나 증상을 선택하고, 최종 진단 결과와 상비약 리스트를 동적인 위젯으로 렌더링합니다.

---

## 2. 핵심 컴포넌트 구현: AI와 통하는 위젯 만들기

GenUI를 구현하기 위해서는 AI가 이해할 수 있는 **데이터 구조(Schema)**와 이를 그릴 **위젯(CatalogItem)**이 필요합니다.

### A. 사용자의 입력을 받는 `PainSlider` (Input Component)
환자가 느끼는 통증의 강도를 AI에게 전달하기 위한 슬라이더입니다. 단순히 텍스트를 입력받는 것보다 훨씬 직관적인 UX를 제공합니다.

```dart
// 1. 데이터 스키마 정의
final _painSliderSchema = S.object(
  properties: {'initialValue': S.integer(description: '슬라이더의 초기값 (기본 5)')},
);

// 2. 카탈로그 아이템 정의
final painSlider = CatalogItem(
  name: 'pain_slider',
  dataSchema: _painSliderSchema,
  widgetBuilder: (context) {
    return _PainSliderWidget(
      onChanged: (value) {
        // 사용자의 액션을 AI에게 다시 이벤트로 전달 (Dispatch Event)
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
```

### B. AI의 분석 결과를 보여주는 `DiagnosisCard` (Output Component)
AI가 분석한 병명, 심각도, 추천 진료과를 아름답게 시각화합니다. `ValueListenableBuilder`를 사용하여 AI가 데이터를 스트리밍함에 따라 UI가 실시간으로 업데이트됩니다.

```dart
final diagnosisCard = CatalogItem(
  name: 'diagnosis_card',
  dataSchema: _diagnosisCardSchema,
  widgetBuilder: (context) {
    final data = _DiagnosisCardData.fromMap(context.data as Map<String, Object?>);

    // AI가 보내주는 데이터를 실시간으로 구독(Subscribe)
    final nameNotifier = context.dataContext.subscribeToString(data.diagnosisName);
    final severityNotifier = context.dataContext.subscribeToString(data.severity);

    return _DiagnosisCardWidget(
      nameNotifier: nameNotifier,
      severityNotifier: severityNotifier,
      // ... 기타 데이터 전달
    );
  },
);
```

---

## 3. AI에게 "생성 본능" 불어넣기 (System Instruction)

AI(Gemini)가 언제 어떤 도구를 꺼내 써야 할지 알려주는 지침(System Instruction)이 핵심입니다. Dr. GenUI는 다음과 같은 규칙을 AI에게 부여합니다.

1. **Step 1 (통증 확인)**: `pain_slider`를 호출하여 통증 수치를 파악할 것.
2. **Step 2 (증상 상세)**: 수치가 입력되면 `symptom_selector`로 구체적인 증상을 물을 것.
3. **Step 3 (진단 및 처방)**: 분석 후 `diagnosis_card`와 `medication_list`를 동시에 띄울 것.

이 지침 덕분에 AI는 의사처럼 체계적인 문진 과정을 UI를 통해 진행하게 됩니다.

---

## 4. GenUIConversation: 대화와 UI의 오케스트레이션

메인 로직에서는 `GenUiConversation`을 통해 대화 흐름을 관리합니다. AI가 텍스트 응답을 보낼 때와 UI 위젯(Surface)을 추가할 때를 각각 핸들링합니다.

```dart
_genUiConversation = GenUiConversation(
  contentGenerator: contentGenerator,
  onSurfaceAdded: (surface) {
    setState(() {
      // 새로운 UI 컴포넌트가 추가되면 메시지 리스트에 삽입
      _messages.insert(0, MessageController(surfaceId: surface.surfaceId));
    });
  },
  onTextResponse: (text) {
    setState(() {
      _messages.insert(0, MessageController(text: 'AI: $text'));
    });
  },
  a2uiMessageProcessor: _genUiManager,
);
```

---

## 5. 마치며: GenUI가 가져올 미래

**Dr. GenUI** 프로젝트는 Generative UI가 단순한 대화형 인터페이스를 넘어, 얼마나 전문적이고 유연한 사용자 경험을 제공할 수 있는지 보여줍니다. 

- **상황 맞춤형 인터페이스**: 정적이지 않고 상황에 따라 레이아웃이 변화합니다.
- **데이터 구조화**: 자연어 대화 속에서 구조화된 데이터를 추출하여 정확한 처리가 가능합니다.
- **UX의 극대화**: 사용자는 복잡한 타이핑 대신 클릭과 슬라이드로 직관적으로 소통합니다.

이제 여러분의 Flutter 앱에도 Gemini와 GenUI를 결합하여 "살아있는 UI"를 구현해 보세요!

---

**참고 문서 및 소스 코드:**
*   [Flutter GenUI Package (pub.dev)](https://pub.dev/packages/genui)
*   [Google Generative AI SDK](https://ai.google.dev/)

#Flutter #Gemini #GenUI #AI #Dart #MobileDevelopment #GenerativeAI
