import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/blog_service.dart';
import '../../models/blog_post_model.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final blogService = Provider.of<BlogService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Blog de la Comunidad'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 20, color: Color(0xFF2196F3)),
            onPressed: () async {
              await blogService.refresh();
            },
            tooltip: 'Actualizar posts',
          ),
          if (authService.isAdmin)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus, size: 20, color: Color(0xFF2196F3)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await blogService.refresh();
        },
        color: const Color(0xFF2196F3),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            SliverToBoxAdapter(
              child: _buildCategoriesFilter(),
            ),
            if (_hasActiveFilters)
              SliverToBoxAdapter(
                child: _buildClearFiltersButton(),
              ),
            if (_hasActiveFilters || blogService.posts.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPostsCount(blogService),
              ),
            if (blogService.pinnedPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPinnedPosts(blogService),
              ),
            _buildPostsList(blogService),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar posts...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: 18,
              color: const Color(0xFF2196F3),
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF2196F3),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1A237E),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPostsCount(BlogService blogService) {
    final filteredPosts = blogService.posts.where((post) {
      final matchesSearch = _searchQuery.isEmpty ||
          post.title.toLowerCase().contains(_searchQuery) ||
          post.content.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == null || post.category.toString().split('.').last == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (!_hasActiveFilters) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Mostrando ${filteredPosts.length} de ${blogService.posts.length} posts',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = null;
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar filtros'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    final categories = [
      {'value': null, 'label': 'Todos', 'icon': '📋'},
      {'value': 'anuncio', 'label': 'Anuncios', 'icon': '📢'},
      {'value': 'evento', 'label': 'Eventos', 'icon': '🎉'},
      {'value': 'mejora', 'label': 'Mejoras', 'icon': '⭐'},
      {'value': 'mantenimiento', 'label': 'Mantenimiento', 'icon': '🔧'},
      {'value': 'seguridad', 'label': 'Seguridad', 'icon': '🔒'},
      {'value': 'general', 'label': 'General', 'icon': '📝'},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['value'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category['icon']!),
                  const SizedBox(width: 6),
                  Text(category['label']!),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategory = category['value'];
                  } else {
                    _selectedCategory = null;
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
              checkmarkColor: const Color(0xFF2196F3),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList(BlogService blogService) {
    final filteredPosts = blogService.posts.where((post) {
      // Filtro por búsqueda de texto
      final matchesSearch = _searchQuery.isEmpty ||
          post.title.toLowerCase().contains(_searchQuery) ||
          post.content.toLowerCase().contains(_searchQuery);

      // Filtro por categoría
      final matchesCategory =
          _selectedCategory == null || post.category.toString().split('.').last == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.newspaper,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters ? 'No hay posts que coincidan con los filtros' : 'No hay posts disponibles',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters ? 'Intenta ajustar los filtros o la búsqueda' : 'Sé el primero en publicar algo',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = null;
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Limpiar filtros'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPostCard(filteredPosts[index]),
          );
        },
        childCount: filteredPosts.length,
      ),
    );
  }

  Widget _buildPinnedPosts(BlogService blogService) {
    final pinnedPosts = blogService.pinnedPosts;
    if (pinnedPosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posts Fijados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ...pinnedPosts.map((post) => _buildPostCard(post)),
        ],
      ),
    );
  }

  Widget _buildPostCard(BlogPost post) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (post.isPinned)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.thumbtack,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(post.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(post.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (authService.isAdmin)
                        PopupMenuButton<String>(
                          icon: const FaIcon(
                            FontAwesomeIcons.ellipsisVertical,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onSelected: (value) async {
                            final blogService = Provider.of<BlogService>(context, listen: false);

                            switch (value) {
                              case 'edit':
                                // TODO: Implementar edición
                                break;
                              case 'delete':
                                final confirmed = await _showDeleteConfirmation(post.title);
                                if (confirmed) {
                                  final success = await blogService.deletePost(post.id);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Post eliminado exitosamente'),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  }
                                }
                                break;
                              case 'pin':
                                await blogService.togglePostPin(post.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                                  SizedBox(width: 12),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  FaIcon(
                                    post.isPinned ? FontAwesomeIcons.thumbtack : FontAwesomeIcons.thumbtack,
                                    size: 16,
                                    color: post.isPinned ? const Color(0xFFFFD700) : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(post.isPinned ? 'Desfijar' : 'Fijar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content.length > 150 ? '${post.content.substring(0, 150)}...' : post.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        child: Text(
                          post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.comment,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(BlogCategory category) {
    switch (category) {
      case BlogCategory.anuncio:
        return const Color(0xFF4CAF50); // Green
      case BlogCategory.evento:
        return const Color(0xFF2196F3); // Blue
      case BlogCategory.mejora:
        return const Color(0xFFFFC107); // Amber
      case BlogCategory.mantenimiento:
        return const Color(0xFFF44336); // Red
      case BlogCategory.seguridad:
        return const Color(0xFF9C27B0); // Purple
      case BlogCategory.general:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  Future<bool> _showDeleteConfirmation(String postTitle) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: Text('¿Estás seguro de que quieres eliminar el post "$postTitle"?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Eliminar'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
