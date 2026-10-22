import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shia_text_library_page.dart';

const _favoritesPanel = Color(0xFF10251E);
const _favoritesGold = Color(0xFFD9B66D);
const _favoritesMuted = Color(0xFF9EB5A9);

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
        appBar: AppBar(title: const Text('المفضلة المباركة')),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _favoritesGold),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: _favoritesGold, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة المحاولة'),
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
                              const Icon(Icons.star_border_rounded,
                                  color: _favoritesGold, size: 52),
                              const SizedBox(height: 14),
                              const Text(
                                'مفضلتك فارغة حالياً',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _favoritesGold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'افتح أي دعاء أو زيارة واضغط النجمة لحفظه هنا. تُحفظ المفضلة على جهازك وتعمل دون إنترنت.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _favoritesMuted,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _openLibrary,
                                icon: const Icon(Icons.menu_book_rounded),
                                label: const Text('تصفح الأدعية والزيارات'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Card(
                            color: _favoritesPanel,
                            child: ListTile(
                              leading: const Icon(Icons.star_rounded,
                                  color: _favoritesGold),
                              title: Text(
                                entry.displayTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                entry.category,
                                style:
                                    const TextStyle(color: _favoritesMuted),
                              ),
                              trailing: IconButton(
                                tooltip: 'إزالة من المفضلة',
                                onPressed: () => _remove(entry),
                                icon: const Icon(Icons.star_rounded,
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
