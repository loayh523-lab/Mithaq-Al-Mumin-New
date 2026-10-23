import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rakahPanel = Color(0xFF10251E);
const _rakahGold = Color(0xFFD9B66D);
const _rakahMuted = Color(0xFF9EB5A9);
const _rakahEmerald = Color(0xFF1C8060);

class RakahCounterPage extends StatefulWidget {
  const RakahCounterPage({super.key});

  @override
  State<RakahCounterPage> createState() => _RakahCounterPageState();
}

class _RakahCounterPageState extends State<RakahCounterPage> {
  static const _prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  String _prayer = 'الظهر';
  int _targetRakahs = 4;
  int _currentRakah = 1;
  int _sajdahs = 0;
  bool _completed = false;
  bool _loading = true;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTarget = (prefs.getInt('rakah_helper_target') ?? 4)
          .clamp(2, 4)
          .toInt();
      final storedCurrent = (prefs.getInt('rakah_helper_current') ?? 1)
          .clamp(1, storedTarget)
          .toInt();
      final storedSajdahs = (prefs.getInt('rakah_helper_sajdahs') ?? 0)
          .clamp(0, 2)
          .toInt();
      final storedPrayer = prefs.getString('rakah_helper_prayer') ?? 'الظهر';
      if (!mounted) return;
      setState(() {
        _targetRakahs = storedTarget;
        _currentRakah = storedCurrent;
        _sajdahs = storedSajdahs;
        _prayer = _prayers.contains(storedPrayer) ? storedPrayer : 'الظهر';
        _completed = prefs.getBool('rakah_helper_completed') ??
            (storedCurrent == storedTarget && storedSajdahs == 2);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist() {
    // Queue writes so quick taps cannot cause a newer count to be overwritten
    // by an older asynchronous preferences write.
    final prayer = _prayer;
    final target = _targetRakahs;
    final current = _currentRakah;
    final sajdahs = _sajdahs;
    final completed = _completed;
    _saveQueue = _saveQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rakah_helper_prayer', prayer);
        await prefs.setInt('rakah_helper_target', target);
        await prefs.setInt('rakah_helper_current', current);
        await prefs.setInt('rakah_helper_sajdahs', sajdahs);
        await prefs.setBool('rakah_helper_completed', completed);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر حفظ تقدم العدّاد على الجهاز')),
          );
        }
      }
    });
    return _saveQueue;
  }

  Future<void> _changePrayer(String prayer) async {
    final defaultTarget = switch (prayer) {
      'الفجر' => 2,
      'المغرب' => 3,
      _ => 4,
    };
    setState(() {
      _prayer = prayer;
      _targetRakahs = defaultTarget;
      _currentRakah = 1;
      _sajdahs = 0;
      _completed = false;
    });
    await _persist();
  }

  Future<void> _changeTarget(int target) async {
    if (target == _targetRakahs) return;
    setState(() {
      _targetRakahs = target;
      _currentRakah = 1;
      _sajdahs = 0;
      _completed = false;
    });
    await _persist();
  }

  Future<void> _recordSajdah() async {
    if (_loading || _completed || _sajdahs >= 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      _sajdahs++;
      if (_currentRakah == _targetRakahs && _sajdahs == 2) {
        _completed = true;
      }
    });
    await _persist();
  }

  Future<void> _undoSajdah() async {
    if (_loading || _sajdahs == 0) return;
    setState(() {
      _sajdahs--;
      _completed = false;
    });
    await _persist();
  }

  Future<void> _nextRakah() async {
    if (_sajdahs < 2 || _completed || _currentRakah >= _targetRakahs) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _currentRakah++;
      _sajdahs = 0;
    });
    await _persist();
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بدء عدّ جديد؟'),
        content: const Text('سيُمسح تقدم العدّاد الحالي من هذا الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إعادة التصفير'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _currentRakah = 1;
      _sajdahs = 0;
      _completed = false;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _completed
        ? 1.0
        : ((_currentRakah - 1 + _sajdahs / 2) / _targetRakahs)
            .clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة الركعات'),
        actions: [
          IconButton(
            tooltip: 'إعادة التصفير',
            onPressed: _loading ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _rakahGold),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _rakahPanel,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _rakahGold.withValues(alpha: .3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عداد مساعد للصلاة',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _rakahGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر الصلاة وعدد الركعات المقصود، ثم سجّل السجدتين يدوياً لكل ركعة. يُحفظ التقدم محلياً على جهازك.',
                        style: TextStyle(color: _rakahMuted, height: 1.7),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _prayer,
                        decoration: InputDecoration(
                          labelText: 'الصلاة',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _prayers
                            .map((prayer) => DropdownMenuItem(
                                  value: prayer,
                                  child: Text(prayer),
                                ))
                            .toList(),
                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value != null) _changePrayer(value);
                              },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'عدد الركعات المستهدف',
                        style: TextStyle(
                          color: _rakahMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [2, 3, 4]
                            .map((target) => ChoiceChip(
                                  label: Text('$target ركعات'),
                                  selected: _targetRakahs == target,
                                  onSelected: _loading
                                      ? null
                                      : (_) => _changeTarget(target),
                                  selectedColor:
                                      _rakahEmerald.withValues(alpha: .35),
                                  labelStyle: TextStyle(
                                    color: _targetRakahs == target
                                        ? _rakahGold
                                        : Colors.white,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF174936), Color(0xFF0B211A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _rakahGold.withValues(alpha: .25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _completed ? 'اكتمل العدّ' : 'الركعة $_currentRakah من $_targetRakahs',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '$_sajdahs / 2',
                        style: const TextStyle(
                          color: _rakahGold,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'السجدات المسجّلة في الركعة الحالية',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _rakahMuted),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          color: _rakahGold,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_completed)
                        const Text(
                          'سجّلت العدد الذي اخترته. هذا تسجيل للعدّ فقط وليس حكماً بصحة الصلاة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.7),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _sajdahs < 2 ? _recordSajdah : null,
                            icon: const Icon(Icons.touch_app_rounded),
                            label: Text(
                              _sajdahs == 0
                                  ? 'تسجيل السجدة الأولى'
                                  : _sajdahs == 1
                                      ? 'تسجيل السجدة الثانية'
                                      : 'اكتملت السجدتان',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sajdahs > 0 ? _undoSajdah : null,
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text('تراجع عن سجدة'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sajdahs == 2 &&
                                        _currentRakah < _targetRakahs
                                    ? _nextRakah
                                    : null,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('الركعة التالية'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _rakahPanel,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: _rakahGold),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'هذا عدّاد يدوي للتذكّر فقط؛ لا يعتمد على حساس التقارب لأن الهاتف لا يستطيع ضمان اكتشاف السجود أو تمييز الركعات بدقة. لا يحدّد صحة الصلاة، وعند الشك راجع أحكام مرجع تقليدك.',
                          style: TextStyle(color: _rakahMuted, height: 1.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
