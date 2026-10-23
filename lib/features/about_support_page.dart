import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _aboutGold = Color(0xFFD9B66D);
const _projectUri = 'https://github.com/loayh523-lab/Mithaq-Al-Mumin-New';
const _supportUri = 'https://github.com/loayh523-lab/Mithaq-Al-Mumin-New/issues';
const _quranSourceUri = 'https://tanzil.net/';
const _adhanSourceUri =
    'https://github.com/loayh523-lab/Mithaq-Al-Mumin-New/blob/main/assets/audio/adhan_shabbar_maalla.mp3';

class AboutSupportPage extends StatefulWidget {
  const AboutSupportPage({super.key});

  @override
  State<AboutSupportPage> createState() => _AboutSupportPageState();
}

class _AboutSupportPageState extends State<AboutSupportPage> {
  bool _busy = false;

  Future<void> _shareProject() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'مشاركة ميثاق المؤمن',
          text: 'ميثاق المؤمن — تطبيق للقرآن والأدعية والعبادات.\n'
              'هذه نسخة قيد التطوير؛ تابع المشروع والتحديثات من هنا:\n'
              '$_projectUri',
        ),
      );
    } catch (_) {
      if (mounted) {
        _message('تعذّر فتح نافذة المشاركة على هذا الجهاز.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri, {required String label}) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _message('تعذّر فتح $label. تحقق من اتصال الإنترنت.');
      }
    } catch (_) {
      if (mounted) _message('تعذّر فتح $label. تحقق من اتصال الإنترنت.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('عن التطبيق والدعم')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF174936), Color(0xFF0B211A)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _aboutGold.withValues(alpha: .3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.mosque_rounded, color: _aboutGold, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'ميثاق المؤمن',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'درب العبادة والطمأنينة',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'الإصدار 0.2.0+3 • نسخة تطويرية',
                    style: TextStyle(color: _aboutGold, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _section(
              title: 'المشاركة والدعم',
              icon: Icons.volunteer_activism_outlined,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _shareProject,
                    icon: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.share_rounded),
                    label: Text('مشاركة ميثاق المؤمن'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      Uri.parse(_supportUri),
                      label: 'صفحة الدعم الفني',
                    ),
                    icon: Icon(Icons.support_agent_rounded),
                    label: Text('الدعم الفني والإبلاغ عن مشكلة'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      Uri.parse(_projectUri),
                      label: 'صفحة المشروع',
                    ),
                    icon: Icon(Icons.code_rounded),
                    label: Text('المصدر والتحديثات'),
                  ),
                ),
                SizedBox(height: 8),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.star_border_rounded, color: _aboutGold),
                    title: Text('تقييم التطبيق على Google Play'),
                    subtitle: Text(
                      'سيُفعّل رابط التقييم بعد نشر النسخة الرسمية على المتجر.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            _section(
              title: 'المصادر والتراخيص',
              icon: Icons.verified_outlined,
              children: [
                Text(
                  'نص القرآن العثماني وفهرس السور يعتمدان على مصادر موثّقة مذكورة في المشروع. قد تتطلب بعض المصادر اتصالاً بالإنترنت.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7),
                ),
                SizedBox(height: 8),
                _sourceButton(
                  title: 'مصدر نص القرآن — Tanzil',
                  onPressed: () => _open(
                    Uri.parse(_quranSourceUri),
                    label: 'مصدر القرآن',
                  ),
                ),
                _sourceButton(
                  title: 'ملف الأذان المختار داخل المشروع',
                  onPressed: () => _open(
                    Uri.parse(_adhanSourceUri),
                    label: 'مصدر التسجيل الصوتي',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'التسجيل المختار داخل التطبيق هو الأذان من العتبة العلوية المقدسة بصوت الشيخ شبّر معلة، وفق تسمية الملف الذي اختاره صاحب التطبيق. يلزم التحقق من مصدر التسجيل وحقوق إعادة نشره قبل الإصدار العام.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 14),
            _section(
              title: 'تنبيه للمستخدم',
              icon: Icons.info_outline_rounded,
              children: [
                Text(
                  'المواقيت والتاريخ الهجري في النسخة الحالية تقديرية وقد تختلف عن التقويم المحلي وثبوت الهلال. راجع تقويم مكتب مرجع تقليدك في المواقيت والمسائل الشرعية.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7),
                ),
                SizedBox(height: 8),
                Text(
                  'التفسير الكامل دون إنترنت، والختمات الجماعية المتزامنة، ومكتبة الصوتيات المرخّصة، والخلفيات القابلة للتعيين، واختيار تسجيلات متعددة للأذان ما زالت تحتاج إلى مصادر وخدمات إضافية.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.7),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _sourceButton({
    required String title,
    required VoidCallback onPressed,
  }) =>
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(title),
        ),
      );

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _aboutGold),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}
