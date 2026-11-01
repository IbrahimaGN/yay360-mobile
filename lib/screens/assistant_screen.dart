import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  final List<AssistantMessage> _conversation = [];
  bool _consent = false;
  bool _sending = false;
  String? _error;
  String? _warning;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _message.text.trim();
    if (question.isEmpty || _sending) return;
    if (!_consent) {
      setState(
        () => _error =
            'Veuillez lire la notice et donner votre accord avant d’envoyer votre question.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _warning = null;
    });
    try {
      final history = _conversation
          .skip((_conversation.length - 12).clamp(0, _conversation.length))
          .map((message) => message.toJson())
          .toList();
      final result = await widget.api.post('/assistant-ia/chat', {
        'message': question,
        'canal': 'TEXTE',
        'historique': history,
        'consentementTransmission': true,
      });
      if (!mounted) return;
      final answer = result['reponse'] as String?;
      if (answer == null || answer.trim().isEmpty) {
        throw const ApiException(
          'L’assistant n’a pas retourné de réponse exploitable.',
        );
      }
      setState(() {
        _conversation
          ..add(AssistantMessage('user', question))
          ..add(AssistantMessage('assistant', answer));
        _warning = result['avertissement'] as String?;
        _message.clear();
        _consent = false;
        _sending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _consent = false;
        _error = exception.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: context.yayRoseContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: YayColors.rose),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistant YAY360',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.yayInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Des informations générales, avec bienveillance',
                    style: TextStyle(color: context.yayMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_conversation.isNotEmpty)
              IconButton(
                onPressed: () => setState(() {
                  _conversation.clear();
                  _warning = null;
                  _error = null;
                }),
                tooltip: 'Effacer la conversation',
                icon: Icon(Icons.delete_outline, color: context.yayMuted),
              ),
          ],
        ),
      ),
      Expanded(
        child: _conversation.isEmpty
            ? _Welcome(
                onSuggestion: (value) => setState(() => _message.text = value),
              )
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 15),
                itemCount: _conversation.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _conversation.length) {
                    return const _TypingIndicator();
                  }
                  final item = _conversation[index];
                  return _ChatBubble(message: item);
                },
              ),
      ),
      if (_warning != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.yayWarningContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            _warning!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
      if (_error != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.yayRoseContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      _Composer(
        controller: _message,
        consent: _consent,
        sending: _sending,
        onConsentChanged: (value) => setState(() {
          _consent = value;
          _error = null;
        }),
        onSend: _send,
      ),
    ],
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
    children: [
      Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: YayColors.green,
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.forum_outlined, color: Color(0xFFE9AFB9), size: 24),
            SizedBox(height: 12),
            Text(
              'Bonjour, je suis là pour vous informer.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Posez vos questions générales sur la grossesse et le suivi prénatal. Pour une situation personnelle, parlez-en à un professionnel de santé.',
              style: TextStyle(
                color: Color(0xFFD6E4DA),
                height: 1.55,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      const SectionHeading('Quelques idées de questions'),
      _Suggestion(
        text: 'Quels rendez-vous sont importants pendant la grossesse ?',
        onTap: onSuggestion,
      ),
      const SizedBox(height: 9),
      _Suggestion(
        text: 'Comment bien préparer ma prochaine consultation ?',
        onTap: onSuggestion,
      ),
      const SizedBox(height: 9),
      _Suggestion(
        text: 'Quels repères pour prendre soin de moi au quotidien ?',
        onTap: onSuggestion,
      ),
    ],
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.text, required this.onTap});
  final String text;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onTap(text),
    borderRadius: BorderRadius.circular(14),
    child: ContentCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 17,
            color: YayColors.rose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.yayInk,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 13, color: context.yayMuted),
        ],
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.role == 'user';
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fromUser
              ? Theme.of(context).colorScheme.secondary
              : context.yaySurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
          border: fromUser ? null : Border.all(color: context.yayBorder),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: fromUser ? Colors.white : context.yayInk,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.consent,
    required this.sending,
    required this.onConsentChanged,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool consent;
  final bool sending;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      14,
      9,
      14,
      8 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: BoxDecoration(
      color: context.yaySurface,
      border: Border(top: BorderSide(color: context.yayBorder)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: consent,
          onChanged: sending
              ? null
              : (value) => onConsentChanged(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          activeColor: Theme.of(context).colorScheme.secondary,
          title: Text(
            'J’accepte que ma question soit transmise à un fournisseur IA externe. Je n’inclus pas de données identifiantes.',
            style: TextStyle(
              color: context.yayMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 2000,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre question…',
                  counterText: '',
                  filled: true,
                  fillColor: context.yayCanvas,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                fixedSize: const Size(46, 46),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'L’assistant ne pose pas de diagnostic et ne remplace pas un professionnel de santé.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.yayMuted, fontSize: 9),
        ),
      ],
    ),
  );
}
