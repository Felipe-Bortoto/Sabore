import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SaboreApp());
}

class SaboreApp extends StatelessWidget {
  const SaboreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saborê',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4D49),
          brightness: Brightness.light,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}

class Recipe {
  final int id;
  final String name;
  final String image;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final double? rating;

  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.rating,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    int? readInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double? readDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Recipe(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name'] is String ? json['name'] as String : '',
      image: json['image'] is String ? json['image'] as String : '',
      prepTime: readInt(json['prepTimeMinutes']),
      cookTime: readInt(json['cookTimeMinutes']),
      servings: readInt(json['servings']),
      rating: readDouble(json['rating']),
    );
  }

  int? get totalTime {
    if (prepTime == null && cookTime == null) return null;
    return (prepTime ?? 0) + (cookTime ?? 0);
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Recipe> _recipes = [];
  bool _loading = false;
  bool _hasSearched = false;
  bool _networkError = false;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _networkError = false;
        _recipes = [];
        _query = '';
      });
      return;
    }

    if (_loading) return;

    setState(() {
      _loading = true;
      _hasSearched = true;
      _networkError = false;
      _query = query;
    });

    try {
      final uri = Uri.parse(
        'https://dummyjson.com/recipes/search?q=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['recipes'] is! List) {
        throw Exception();
      }

      final recipes = (decoded['recipes'] as List)
          .whereType<Map>()
          .map((item) => Recipe.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipes = [];
        _loading = false;
        _networkError = true;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _controller.clear();
      _recipes = [];
      _hasSearched = false;
      _networkError = false;
      _query = '';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildContent(),
                ),
              ),
              _BottomNavigation(onSearch: _focusNode.requestFocus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const _LoadingView();
    }
    if (_networkError) {
      return _ErrorView(onRetry: _search);
    }
    if (!_hasSearched) {
      return _InitialSearchView(
        controller: _controller,
        focusNode: _focusNode,
        onSearch: _search,
      );
    }
    if (_recipes.isEmpty) {
      return _NoResultsView(query: _query, onClear: _clearSearch);
    }
    return _SearchResultsView(
      query: _query,
      recipes: _recipes,
      controller: _controller,
      focusNode: _focusNode,
      onSearch: _search,
      onClear: _clearSearch,
    );
  }
}

class _InitialSearchView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const _InitialSearchView({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saborê',
            style: TextStyle(
              color: Color(0xFF1F4D49),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Qual receita você procura?',
            style: TextStyle(
              color: Color(0xFF1F4D49),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _SearchField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Você pode buscar por parte do nome da receita.',
            style: TextStyle(
              color: Color(0xFF69747A),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 34),
          _PrimaryButton(label: 'Pesquisar', onPressed: onSearch),
        ],
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  final String query;
  final List<Recipe> recipes;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchResultsView({
    required this.query,
    required this.recipes,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1F4D49)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pesquisar receitas',
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFE1E5E3)),
        const Text(
          'Nome da receita',
          style: TextStyle(
            color: Color(0xFF1F4D49),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _SearchField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSearch(),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(label: 'Pesquisar', onPressed: onSearch),
        const SizedBox(height: 20),
        Text(
          'Resultados para "$query"',
          style: const TextStyle(
            color: Color(0xFF1F4D49),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toque na receita para ver o preparo.',
          style: TextStyle(color: Color(0xFF69747A), fontSize: 13),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _RecipeCard(recipe: recipes[index]);
            },
          ),
        ),
        const SizedBox(height: 10),
        _SecondaryButton(label: 'Limpar pesquisa', onPressed: onClear),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E5E3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: recipe.image.isEmpty
                  ? const _ImageFallback()
                  : Image.network(
                      recipe.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  recipe.name.isEmpty ? 'Receita sem nome' : recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F4D49),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  recipe.totalTime == null
                      ? 'Tempo não informado'
                      : '${recipe.totalTime} min',
                  style: const TextStyle(
                    color: Color(0xFF69747A),
                    fontSize: 12,
                  ),
                ),
                if (recipe.rating != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.rating!.toStringAsFixed(1)} / 5',
                    style: const TextStyle(
                      color: Color(0xFF69747A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoResultsView({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1F4D49)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            ),
            const SizedBox(width: 6),
            const Text(
              'Pesquisar receitas',
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFE1E5E3)),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.search,
                  size: 38,
                  color: Color(0xFF69747A),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nenhum resultado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1F4D49),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Não encontramos receitas para "$query".\nTente outro termo.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF69747A),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        _PrimaryButton(label: 'Alterar pesquisa', onPressed: onClear),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onClear,
          child: const Text(
            'Ver todas as receitas',
            style: TextStyle(
              color: Color(0xFF1F4D49),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Saborê',
            style: TextStyle(
              color: Color(0xFF1F4D49),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 32),
          CircularProgressIndicator(color: Color(0xFF1F4D49)),
          SizedBox(height: 18),
          Text(
            'Pesquisando receitas...',
            style: TextStyle(color: Color(0xFF69747A), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F1ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFF1F4D49),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Não foi possível\ncarregar as receitas.',
            style: TextStyle(
              color: Color(0xFF1F4D49),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Verifique sua conexão e tente novamente.',
            style: TextStyle(color: Color(0xFF69747A), fontSize: 14),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Buscar pelo nome',
        hintStyle: const TextStyle(color: Color(0xFF69747A), fontSize: 14),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF69747A),
          size: 24,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD6DCD9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1F4D49), width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1F4D49),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F4D49),
          side: const BorderSide(color: Color(0xFF69747A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final VoidCallback onSearch;

  const _BottomNavigation({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE1E5E3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onSearch,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1F4D49),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 23),
                  SizedBox(height: 2),
                  Text(
                    'Explorar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: null,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 23,
                    color: Color(0xFF69747A),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Favoritos',
                    style: TextStyle(
                      color: Color(0xFF69747A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F1ED),
      child: const Icon(Icons.restaurant, color: Color(0xFF1F4D49), size: 34),
    );
  }
}
