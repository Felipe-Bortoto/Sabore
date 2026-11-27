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
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF1F4D49),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

//Atributos da receita
class Recipe {
  final int id;
  final String name;
  final String image;
  final List<String> ingredients;
  final List<String> instructions;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final double? rating;
  final List<String> mealType;

  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    this.ingredients = const [],
    this.instructions = const [],
    this.prepTime,
    this.cookTime,
    this.servings,
    this.rating,
    this.mealType = const [],
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

    List<String> readStringList(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final id = readInt(json['id']);

    return Recipe(
      id: id ?? 0,
      name: json['name'] is String ? (json['name'] as String).trim() : '',
      image: json['image'] is String ? json['image'] as String : '',
      ingredients: readStringList(json['ingredients']),
      instructions: readStringList(json['instructions']),
      prepTime: readInt(json['prepTimeMinutes']),
      cookTime: readInt(json['cookTimeMinutes']),
      servings: readInt(json['servings']),
      rating: readDouble(json['rating']),
      mealType: readStringList(json['mealType']),
    );
  }

  int? get totalTime {
    if (prepTime == null && cookTime == null) return null;
    return (prepTime ?? 0) + (cookTime ?? 0);
  }
}

//API 
class RecipeApi {
  static const _baseUrl = 'https://dummyjson.com/recipes';

  Future<List<Recipe>> fetchRecipes() async {
    return _decodeList(await _get(Uri.parse(_baseUrl)));
  }

  Future<List<Recipe>> search(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/search?q=${Uri.encodeComponent(query.trim())}',
    );
    return _decodeList(await _get(uri));
  }

  Future<Recipe> fetchDetails(int id) async {
    final response = await _get(Uri.parse('$_baseUrl/$id'));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Os dados da receita estão incompatíveis.');
    }
    return Recipe.fromJson(decoded);
  }

  Future<http.Response> _get(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro HTTP ${response.statusCode}');
    }
    return response;
  }

  List<Recipe> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['recipes'] is! List) {
      throw const FormatException('A resposta da API está incompatível.');
    }

    return (decoded['recipes'] as List)
        .whereType<Map>()
        .map((item) => Recipe.fromJson(Map<String, dynamic>.from(item)))
        .where((recipe) => recipe.id != 0)
        .toList();
  }
}

// Toggle de favoritos
class FavoritesStore extends ChangeNotifier {
  final Map<int, Recipe> _favorites = {};

  List<Recipe> get items => _favorites.values.toList();

  bool contains(int id) => _favorites.containsKey(id);

  void toggle(Recipe recipe) {
    if (_favorites.containsKey(recipe.id)) {
      _favorites.remove(recipe.id);
    } else {
      _favorites[recipe.id] = recipe;
    }
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FavoritesStore _favorites = FavoritesStore();
  int _index = 0;

  @override
  void dispose() {
    _favorites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _favorites,
      builder: (context, _) {
        final pages = <Widget>[
          HomeScreen(favorites: _favorites),
          FavoritesScreen(favorites: _favorites),
        ];

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
              selectedItemColor: const Color(0xFF1F4D49),
              unselectedItemColor: const Color(0xFF69747A),
              backgroundColor: Colors.white,
              elevation: 8,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: _favorites.items.isNotEmpty,
                    label: Text('${_favorites.items.length}'),
                    child: const Icon(Icons.favorite_border),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: _favorites.items.isNotEmpty,
                    label: Text('${_favorites.items.length}'),
                    child: const Icon(Icons.favorite),
                  ),
                  label: 'Favoritos',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.favorites});

  final FavoritesStore favorites;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeApi _api = RecipeApi();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Recipe> _recipes = [];
  bool _loading = false;
  bool _hasSearched = false;
  bool _networkError = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRecipes() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _networkError = false;
      _hasSearched = false;
      _query = '';
    });

    await _runRequest(() => _api.fetchRecipes());
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _networkError = false;
        _hasSearched = false;
        _query = '';
      });
      await _loadInitialRecipes();
      return;
    }
    if (_loading) return;

    setState(() {
      _loading = true;
      _networkError = false;
      _hasSearched = true;
      _query = query;
    });
    await _runRequest(() => _api.search(query));
  }

  Future<void> _runRequest(Future<List<Recipe>> Function() request) async {
    try {
      final recipes = await request();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _loading = false;
        _networkError = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _recipes = [];
        _loading = false;
        _networkError = true;
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
      _hasSearched = false;
      _networkError = false;
      _query = '';
    });
    _loadInitialRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Saborê',
                    style: TextStyle(
                      color: Color(0xFF1F4D49),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pesquisar',
                  onPressed: () => _searchFocus.requestFocus(),
                  icon: const Icon(Icons.search, color: Color(0xFF1F4D49)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const LoadingView();
    if (_networkError) {
      return ErrorView(onRetry: _hasSearched ? _search : _loadInitialRecipes);
    }

    return RefreshIndicator(
      onRefresh: _hasSearched ? _search : _loadInitialRecipes,
      color: const Color(0xFF1F4D49),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            _hasSearched
                ? 'Resultados da pesquisa'
                : 'Qual receita você procura?',
            style: const TextStyle(
              color: Color(0xFF1F4D49),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SearchField(
            controller: _controller,
            focusNode: _searchFocus,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _loading ? 'Pesquisando...' : 'Pesquisar',
                  onPressed: _loading ? null : _search,
                ),
              ),
              if (_hasSearched) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Limpar',
                    onPressed: _clearSearch,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _recipes.isEmpty
                    ? 'Nenhum resultado para "$_query"'
                    : '${_recipes.length} resultado${_recipes.length == 1 ? '' : 's'} para "$_query"',
                style: const TextStyle(
                  color: Color(0xFF69747A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_hasSearched && _recipes.isEmpty)
            const NoSearchResultsView()
          else
            ..._recipes.map(
              (recipe) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecipeCard(
                  recipe: recipe,
                  isFavorite: widget.favorites.contains(recipe.id),
                  onFavorite: () => widget.favorites.toggle(recipe),
                  onTap: () => _openDetails(recipe),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openDetails(Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          initialRecipe: recipe,
          api: _api,
          favorites: widget.favorites,
        ),
      ),
    );
  }
}

// Card das receitas
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 118,
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
                width: 94,
                height: 94,
                child: recipe.image.isEmpty
                    ? const ImageFallback()
                    : Image.network(
                        recipe.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ImageFallback(),
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
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFE6A33A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          recipe.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF69747A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: onFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? const Color(0xFFE04F5F)
                    : const Color(0xFF69747A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.initialRecipe,
    required this.api,
    required this.favorites,
  });

  final Recipe initialRecipe;
  final RecipeApi api;
  final FavoritesStore favorites;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Recipe _recipe = widget.initialRecipe;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (_recipe.ingredients.isEmpty || _recipe.instructions.isEmpty) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final recipe = await widget.api.fetchDetails(_recipe.id);
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favorites.contains(_recipe.id);

    return AnimatedBuilder(
      animation: widget.favorites,
      builder: (context, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                backgroundColor: const Color(0xFF1F4D49),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: () => widget.favorites.toggle(_recipe),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 56,
                    end: 56,
                    bottom: 14,
                  ),
                  title: Text(
                    _recipe.name.isEmpty ? 'Receita sem nome' : _recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: _recipe.image.isEmpty
                      ? const ImageFallback()
                      : Image.network(
                          _recipe.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ImageFallback(),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: LoadingView(),
                        )
                      : _error
                      ? ErrorView(onRetry: _loadDetails)
                      : _buildDetails(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetails() {
    final totalTime = _recipe.totalTime;
    final infoItems = <_InfoItem>[
      if (totalTime != null)
        _InfoItem(icon: Icons.schedule, label: '$totalTime min'),
      if (_recipe.servings != null)
        _InfoItem(icon: Icons.restaurant, label: '${_recipe.servings} porções'),
      if (_recipe.rating != null)
        _InfoItem(
          icon: Icons.star_rounded,
          label: _recipe.rating!.toStringAsFixed(1),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _recipe.name.isEmpty ? 'Receita sem nome' : _recipe.name,
          style: const TextStyle(
            color: Color(0xFF1F4D49),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        if (infoItems.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: infoItems
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1E5E3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 17,
                          color: const Color(0xFF1F4D49),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Color(0xFF69747A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        if (_recipe.mealType.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _recipe.mealType.join(' • '),
            style: const TextStyle(color: Color(0xFF69747A), fontSize: 13),
          ),
        ],
        const SizedBox(height: 28),
        const Text(
          'Ingredientes',
          style: TextStyle(
            color: Color(0xFF1F4D49),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_recipe.ingredients.isEmpty)
          const Text(
            'Ingredientes não informados.',
            style: TextStyle(color: Color(0xFF69747A)),
          )
        else
          ..._recipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB46A4C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: const TextStyle(
                        color: Color(0xFF3F4A47),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Modo de preparo',
          style: TextStyle(
            color: Color(0xFF1F4D49),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_recipe.instructions.isEmpty)
          const Text(
            'Instruções não informadas.',
            style: TextStyle(color: Color(0xFF69747A)),
          )
        else
          ..._recipe.instructions.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1E5E3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F4D49),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Color(0xFF3F4A47),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.favorites});

  final FavoritesStore favorites;

  @override
  Widget build(BuildContext context) {
    final items = favorites.items;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              'Favoritos',
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyFavoritesView()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final recipe = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecipeCard(
                          recipe: recipe,
                          isFavorite: true,
                          onFavorite: () => favorites.toggle(recipe),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailsScreen(
                                initialRecipe: recipe,
                                api: RecipeApi(),
                                favorites: favorites,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


//Widget de pesquisa att01
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

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

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF1F4D49)),
          SizedBox(height: 16),
          Text(
            'Carregando receitas...',
            style: TextStyle(color: Color(0xFF69747A), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 56,
              backgroundColor: Color(0xFFF0F1ED),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 52,
                color: Color(0xFF1F4D49),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Não foi possível carregar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique sua conexão ou tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF69747A), fontSize: 14),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class NoSearchResultsView extends StatelessWidget {
  const NoSearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 62, color: Color(0xFF69747A)),
            SizedBox(height: 16),
            Text(
              'Nenhuma receita encontrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tente pesquisar por outro nome.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF69747A)),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyFavoritesView extends StatelessWidget {
  const EmptyFavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Color(0xFFF0F1ED),
              child: Icon(
                Icons.favorite_border,
                size: 52,
                color: Color(0xFF69747A),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Nenhuma receita favorita',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F4D49),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no coração das receitas para salvá-las aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF69747A)),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageFallback extends StatelessWidget {
  const ImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F1ED),
      child: const Icon(Icons.restaurant, color: Color(0xFF1F4D49), size: 34),
    );
  }
}
