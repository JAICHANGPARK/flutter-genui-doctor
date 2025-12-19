import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';

import '../configuration.dart';
import '../io_get_api_key.dart'
    if (dart.library.html) '../web_get_api_key.dart';
import '../message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<MessageController> _messages = [];
  late final GenUiConversation _genUiConversation;
  late final A2uiMessageProcessor _genUiManager;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final Catalog catalog = CoreCatalogItems.asCatalog();
    _genUiManager = A2uiMessageProcessor(catalogs: [catalog]);

    final systemInstruction =
        '''You are a helpful assistant who chats with a user,
giving exactly one response for each user message.
Your responses should contain acknowledgment
of the user message.


IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

${GenUiPromptFragments.basicChat}''';

    // Create the appropriate content generator based on configuration
    // final ContentGenerator contentGenerator = switch (aiBackend) {
    //   AiBackend.googleGenerativeAi => () {
    //     return GoogleGenerativeAiContentGenerator(
    //       catalog: catalog,
    //       systemInstruction: systemInstruction,
    //       apiKey: getApiKey(),
    //     );
    //   }(),
    //   AiBackend.firebase => FirebaseAiContentGenerator(
    //     catalog: catalog,
    //     systemInstruction: systemInstruction,
    //   ),
    // };

    final ContentGenerator contentGenerator =
        GoogleGenerativeAiContentGenerator(
          catalog: catalog,
          systemInstruction: systemInstruction,
          apiKey: getApiKey(),
        );

    _genUiConversation = GenUiConversation(
      a2uiMessageProcessor: _genUiManager,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      onError: (error) {
        genUiLogger.severe(
          'Error from content generator',
          error.error,
          error.stackTrace,
        );
      },
    );
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(surfaceId: surface.surfaceId));
    });
    _scrollToBottom();
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(text: 'AI: $text'));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final String title = switch (aiBackend) {
      AiBackend.googleGenerativeAi => 'Chat with Google Generative AI',
      AiBackend.firebase => 'Chat with Firebase AI',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final MessageController message = _messages[index];
                  return ListTile(
                    title: MessageView(message, _genUiConversation.host),
                  );
                },
              ),
            ),

            ValueListenableBuilder(
              valueListenable: _genUiConversation.isProcessing,
              builder: (_, isProcessing, _) {
                if (!isProcessing) return Container();
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
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
                        hintText: 'Type your message...',
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
    );
  }

  void _sendMessage() {
    final String text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();

    setState(() {
      _messages.add(MessageController(text: 'You: $text'));
    });

    _scrollToBottom();

    unawaited(_genUiConversation.sendRequest(UserMessage([TextPart(text)])));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _genUiConversation.dispose();
    super.dispose();
  }
}
