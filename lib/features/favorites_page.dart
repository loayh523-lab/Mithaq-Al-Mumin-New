import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shia_text_library_page.dart';

const _favoritesGold = Color(0xFFD9B66D);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _loading = true;
  String? _error;
  List<ShiaTextEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList('favorite_shia_text_slugs') ??
              const <String>[])
          .toSet();
      if (saved.isEmpty) {
        if (!mounted) return;
        setState(() {
          _entries = const [];
          _loading = false;
          _error = null;
        });
        return;
      }

      final data = await ShiaTextData.load();
      final sahifa = await ShiaTextData.loadSahifa();
      final entries = <ShiaTextEntry>[
        ...data.entries,
        ...sahifa.entries,
      ].where((entry) => saved.contains(entry.slug)).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل المفضلة المحفوظة على هذا الجهاز.';
      });
    }
  }

  Future<void> _remove(ShiaTextEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList('favorite_shia_text_slugs') ??
              const <String>[])
          .toSet()
        ..remove(entry.slug);
      await prefs.setStringList('favorite_shia_text_slugs', saved.toList());
      if (!mounted) return;
      setState(() {
        _entries = _entries.where((item) => item.slug != entry.slug).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أُزيل النص من المفضلة'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث المفضلة')),
      );
    }
  }

  void _openLibrary() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const Directionality(
        textDirection: TextDirection.rtl,
        child: ShiaTextLibraryPage(),
      ),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('المفضلة المباركة')),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(color: _favoritesGold),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: _favoritesGold, size: 40),
                          SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: Icon(Icons.refresh_rounded),
                            label: Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_border_rounded,
                                  color: _favoritesGold, size: 52),
                              SizedBox(height: 14),
                              Text(
                                'مفضلتك فارغة حالياً',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _favoritesGold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'افتح أي دعاء أو زيارة واضغط النجمة لحفظه هنا. تُحفظ المفضلة على جهازك وتعمل دون إنترنت.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.7,
                                ),
                              ),
                              SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _openLibrary,
                                icon: Icon(Icons.menu_book_rounded),
                                label: Text('تصفح الأدعية والزيارات'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Card(
                            color: Theme.of(context).colorScheme.surface,
                            child: ListTile(
                              leading: Icon(Icons.star_rounded,
                                  color: _favoritesGold),
                              title: Text(
                                entry.displayTitle,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                entry.category,
                                style:
                                    TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                tooltip: 'إزالة من المفضلة',
                                onPressed: () => _remove(entry),
                                icon: Icon(Icons.star_rounded,
                                    color: _favoritesGold),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: ShiaTextReaderPage(entry: entry),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      );
}
