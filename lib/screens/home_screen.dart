import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mode_selector.dart';
import '../widgets/voice_card.dart';
import '../widgets/verdict_card.dart';
import 'account_screen.dart';
import 'login_screen.dart';

// ── Voice definitions (matching web SEAT_DEFS exactly) ─────────────────────
class _Voice {
  final String key;        // JSON response key
  final String name;       // display name
  final String subtitle;   // model · provider
  final Color  color;
  final IconData icon;
  const _Voice(this.key, this.name, this.subtitle, this.color, this.icon);
}

const _boardVoices = [
  _Voice('claude', 'Claude',   'claude-sonnet-4-6 · Anthropic', AppColors.claude,  Icons.auto_awesome_rounded),
  _Voice('gpt',    'ChatGPT',  'gpt-4o · OpenAI',               AppColors.gpt,     Icons.chat_bubble_outline_rounded),
  _Voice('grok',   'Grok',     'grok-4.3 · xAI',                AppColors.grok,    Icons.bolt_rounded),
];

const _freeVoices = [
  _Voice('ft-a', 'Freethinker A', 'llama-3.1 · Groq hosted · Free',       AppColors.ftA, Icons.lightbulb_outline_rounded),
  _Voice('ft-b', 'Freethinker B', 'gemini-2.5-flash · Google · Free',     AppColors.ftB, Icons.hub_rounded),
];

const _verdictStyles = ['analytical', 'balanced', 'decisive', 'custom'];

const _modeDesc = {
  'freethinkers': 'Free — Freethinkers A & B respond, no quota used.',
  'api':          'Claude, ChatGPT & Grok respond in parallel.',
  'full':         'All 5 voices respond simultaneously — most complete.',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _questionCtrl = TextEditingController();
  final _scrollCtrl   = ScrollController();

  String _mode         = 'freethinkers';
  String _verdictStyle = 'analytical';
  String _customStyle  = '';

  bool _loading = false;
  String? _error;

  // key → text string (already extracted from response object)
  Map<String, String> _responses = {};
  String? _verdict;

  // Quota tracking
  int? _quotaUsed;
  int? _quotaLimit;
  int? _quotaRemaining;

  // Which voices are active for current mode
  List<_Voice> get _activeVoices {
    switch (_mode) {
      case 'api':  return _boardVoices;
      case 'full': return [..._boardVoices, ..._freeVoices];
      default:     return _freeVoices;
    }
  }

  // ── API call ───────────────────────────────────────────────────────────
  Future<void> _deliberate() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) {
      setState(() => _error = 'Please enter a question or topic.');
      return;
    }
    setState(() { _loading = true; _error = null; _responses = {}; _verdict = null; });

    try {
      final data = await ApiService.deliberate(
        question: question,
        mode: _mode,
        verdictStyle: _verdictStyle,
        verdictCustom: _customStyle,
      );

      // Extract text from each voice — server returns { "text": "...", "tokens": n }
      final Map<String, String> res = {};
      for (final v in _activeVoices) {
        final raw = data[v.key];
        if (raw == null) continue;
        if (raw is Map && raw['text'] is String) {
          res[v.key] = raw['text'] as String;
        } else if (raw is String) {
          res[v.key] = raw; // fallback
        }
      }

      // Verdict is under synthesis.text
      String? verdict;
      final syn = data['synthesis'];
      if (syn is Map && syn['text'] is String) {
        verdict = syn['text'] as String;
      } else if (syn is String) {
        verdict = syn;
      }

      // Parse quota from response
      int? qUsed, qLimit, qRemaining;
      final quotaRaw = data['quota'];
      if (quotaRaw is Map) {
        qUsed      = quotaRaw['used'] as int?;
        qLimit     = quotaRaw['limit'] as int?;
        qRemaining = quotaRaw['remaining'] as int?;
      }

      setState(() {
        _responses     = res;
        _verdict       = verdict;
        if (qUsed      != null) _quotaUsed      = qUsed;
        if (qLimit     != null) _quotaLimit     = qLimit;
        if (qRemaining != null) _quotaRemaining = qRemaining;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'no_subscription') {
        _showUpgradeDialog();
      } else if (msg == 'quota_exceeded') {
        setState(() => _error = 'Monthly quota reached. Upgrade your plan to continue.');
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildQuotaCounter() {
    final remaining = _quotaRemaining;
    final limit     = _quotaLimit;
    final used      = _quotaUsed;

    Color color;
    if (remaining == null || limit == null || limit == 0) {
      color = AppColors.muted;
    } else {
      final pct = remaining / limit;
      if (pct > 0.25) color = AppColors.primary;
      else if (pct > 0.10) color = Colors.orange;
      else color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (remaining != null && limit != null)
                  ? '$remaining of $limit questions remaining this month'
                  : 'Loading quota…',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (used != null && limit != null && limit > 0) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (used / limit).clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upgrade Required',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        content: const Text(
          'You need an active subscription to use the API Board or Full Board. '
          'Freethinkers mode is always free.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()));
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  // ── Export / Share ─────────────────────────────────────────────────────
  String _buildExportText() {
    final sb = StringBuffer();
    sb.writeln('DELIB.IO DELIBERATION');
    sb.writeln('=' * 40);
    sb.writeln('Question: ${_questionCtrl.text.trim()}');
    sb.writeln('Mode: $_mode');
    sb.writeln();
    for (final v in _activeVoices) {
      if (_responses.containsKey(v.key)) {
        sb.writeln('── ${v.name} (${v.subtitle}) ──');
        sb.writeln(_responses[v.key]);
        sb.writeln();
      }
    }
    if (_verdict != null) {
      sb.writeln('── VERDICT ──');
      sb.writeln(_verdict);
    }
    sb.writeln();
    sb.writeln('Generated by Delib.io');
    return sb.toString();
  }

  Future<void> _share() async {
    if (_responses.isEmpty) return;
    await Share.share(_buildExportText(), subject: 'Delib.io Deliberation');
  }

  Future<void> _copy() async {
    if (_responses.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _buildExportText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'),
          backgroundColor: AppColors.card, duration: Duration(seconds: 2)),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            children: [
              TextSpan(text: 'Delib', style: TextStyle(color: AppColors.text)),
              TextSpan(text: '.io',   style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.muted),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.muted, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            // ── Mode selector (3 tabs) ──
            ModeSelector(
              selected: _mode,
              onChanged: (m) => setState(() {
                _mode = m;
                _responses = {};
                _verdict = null;
              }),
            ),
            const SizedBox(height: 6),

            // ── Mode description ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _modeDesc[_mode]!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            // ── Quota counter (paid modes only) ──
            if (_mode != 'freethinkers') _buildQuotaCounter(),
            const SizedBox(height: 8),

            // ── Question input ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Question',
                      style: TextStyle(color: AppColors.muted,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionCtrl,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 14, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything — strategic, creative, analytical…',
                      border: InputBorder.none,
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Verdict style ──
            _verdictStyleRow(),
            const SizedBox(height: 14),

            // ── Error ──
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],

            // ── Ask button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _deliberate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 10),
                          Text('Deliberating…',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : const Text('Ask Delib',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),

            // ── Results ──
            if (_responses.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Results · ${_responses.length} voice${_responses.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.text,
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  _actionBtn(icon: Icons.copy_rounded,  label: 'Copy',  color: AppColors.green,   onTap: _copy),
                  const SizedBox(width: 8),
                  _actionBtn(icon: Icons.share_rounded, label: 'Share', color: AppColors.primary, onTap: _share),
                ],
              ),
              const SizedBox(height: 14),

              // Paid board section (api / full)
              if (_mode == 'api' || _mode == 'full') ...[
                if (_mode == 'full')
                  _sectionLabel('Paid Board', AppColors.primary),
                ..._boardVoices.map((v) => _voiceCardFor(v)),
              ],

              // Freethinker section (freethinkers / full)
              if (_mode == 'freethinkers' || _mode == 'full') ...[
                if (_mode == 'full')
                  _sectionLabel('Freethinker Side', AppColors.ftA),
                ..._freeVoices.map((v) => _voiceCardFor(v)),
              ],

              // Verdict
              if (_verdict != null) ...[
                const SizedBox(height: 4),
                VerdictCard(content: _verdict!),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _voiceCardFor(_Voice v) {
    final text = _responses[v.key];
    if (text == null) return const SizedBox.shrink();
    return VoiceCard(
      name: v.name,
      role: v.subtitle,
      content: text,
      accentColor: v.color,
      icon: v.icon,
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: color,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          color: color, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _verdictStyleRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Verdict style',
                  style: TextStyle(color: AppColors.muted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _verdictStyle,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                    iconEnabledColor: AppColors.muted,
                    items: _verdictStyles.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _verdictStyle = v); },
                  ),
                ),
              ),
            ],
          ),
          if (_verdictStyle == 'custom') ...[
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: AppColors.text, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Describe how you want the verdict written…',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => _customStyle = v,
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Future<void> Function() onTap,
  }) =>
      GestureDetector(
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
