import 'package:flutter/material.dart';
import '../models/blog_post_model.dart';
import '../models/improvement_proposal_model.dart';
import 'api_service.dart';

class BlogService extends ChangeNotifier {
  List<BlogPost> _posts = [];
  List<ImprovementProposal> _proposals = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<BlogPost> get posts => [..._posts];
  List<BlogPost> get pinnedPosts => _posts.where((p) => p.isPinned).toList();
  List<ImprovementProposal> get proposals => [..._proposals];
  bool get isLoading => _isLoading;

  // Cargar posts desde la API
  Future<void> loadPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/blog');

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted data from ApiService
        final List<dynamic> postsData = response.data as List<dynamic>;
        _posts = postsData.map((data) => BlogPost.fromJson(data as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Mantener datos locales en caso de error
      print('Error loading posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar propuestas desde la API
  Future<void> loadProposals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/proposals');

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted data from ApiService
        final List<dynamic> proposalsData = response.data as List<dynamic>;
        _proposals = proposalsData.map((data) => ImprovementProposal.fromJson(data as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Mantener datos locales en caso de error
    }

    _isLoading = false;
    notifyListeners();
  }

  // Blog methods
  BlogPost? getPostById(String id) {
    try {
      return _posts.firstWhere((post) => post.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createPost(BlogPost post) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔍 DEBUG createPost - Enviando datos: ${post.toJson()}');
      final response = await _apiService.post('/blog', body: post.toJson());
      print('🔍 DEBUG createPost - Respuesta: ${response.isSuccess}, Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        // La API devuelve {success: true, data: {...}}
        final responseData = response.data as Map<String, dynamic>;
        print('🔍 DEBUG createPost - Response data: $responseData');

        if (responseData['data'] != null) {
          try {
            final newPost = BlogPost.fromJson(responseData['data'] as Map<String, dynamic>);
            print('✅ DEBUG createPost - Post creado exitosamente: ${newPost.title}');
            _posts.insert(0, newPost);

            _isLoading = false;
            notifyListeners();
            return true;
          } catch (e) {
            print('❌ ERROR createPost - Error al parsear respuesta: $e');
            print('❌ ERROR createPost - Datos que causaron error: ${responseData['data']}');
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ ERROR createPost: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost(BlogPost updatedPost) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/blog/${updatedPost.id}',
        body: updatedPost.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final updated = BlogPost.fromJson(response.data as Map<String, dynamic>);
        final index = _posts.indexWhere((p) => p.id == updatedPost.id);

        if (index != -1) {
          _posts[index] = updated;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.delete('/blog/$postId');

      if (response.isSuccess) {
        _posts.removeWhere((p) => p.id == postId);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePostPin(String postId) async {
    try {
      final response = await _apiService.put('/blog/$postId/pin');

      if (response.isSuccess) {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index] = _posts[index].copyWith(
            isPinned: !_posts[index].isPinned,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _apiService.post('/blog/$postId/like');

      if (response.isSuccess) {
        // Recargar los posts para obtener los datos actualizados
        await loadPosts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addComment(String postId, String content) async {
    try {
      final response = await _apiService.post('/blog/$postId/comments', body: {
        'content': content,
      });

      if (response.isSuccess) {
        // Recargar los posts para obtener los comentarios actualizados
        await loadPosts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Improvement Proposals methods
  ImprovementProposal? getProposalById(String id) {
    try {
      return _proposals.firstWhere((proposal) => proposal.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createProposal(ImprovementProposal proposal) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/proposals', body: proposal.toJson());

      if (response.isSuccess && response.data != null) {
        final newProposal = ImprovementProposal.fromJson(response.data as Map<String, dynamic>);
        _proposals.insert(0, newProposal);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> voteProposal({
    required String proposalId,
    required String userId,
    required bool isUpvote,
  }) async {
    try {
      final response = await _apiService.post('/proposals/$proposalId/vote', body: {
        'userId': userId,
        'isUpvote': isUpvote,
      });

      if (response.isSuccess) {
        // Recargar propuesta actualizada
        await loadProposals();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProposalStatus({
    required String proposalId,
    required ProposalStatus newStatus,
    String? adminResponse,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/proposals/$proposalId/status', body: {
        'status': newStatus.toString().split('.').last,
        if (adminResponse != null) 'adminResponse': adminResponse,
      });

      if (response.isSuccess) {
        // Recargar propuestas actualizadas
        await loadProposals();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh data from API
  Future<void> refresh() async {
    await Future.wait([
      loadPosts(),
      loadProposals(),
    ]);
  }
}
