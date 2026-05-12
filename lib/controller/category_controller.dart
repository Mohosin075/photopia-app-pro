import 'package:flutter/material.dart';
import 'package:photopia/controller/client/service_list_controller.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/data/models/category_model.dart';
import 'package:provider/provider.dart';

class CategoryController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  List<CategoryModel> _subCategories = [];
  List<CategoryModel> get subCategories => _subCategories;

  List<CategoryModel> _popularCategories = [];
  List<CategoryModel> get popularCategories => _popularCategories;

  String? _selectedTheme;
  String? get selectedTheme => _selectedTheme;

  final List<String> _themes = [
    'PHOTOGRAPHY',
    'VIDEOGRAPHY',
    'EDITING AND POST-PRODUCTION',
  ];
  List<String> get themes => _themes;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  String? _selectedSubCategoryId;
  String? get selectedSubCategoryId => _selectedSubCategoryId;

  // Root categories (type == 'category') filtered by theme if selected
  List<CategoryModel> get rootCategories {
    var list = _categories.where((c) => c.type == 'category').toList();
    
    if (_selectedTheme != null && _selectedTheme != 'ALL') {
      var filteredList = list.where((c) => c.theme == _selectedTheme).toList();
      if (filteredList.isNotEmpty) {
        list = filteredList;
      }
    }
    
    // Sort alphabetically by name
    list.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return list;
  }

  // Select a theme and reset category/subcategory
  void selectTheme(String? theme) {
    _selectedTheme = theme;
    _selectedCategoryId = null;
    _selectedSubCategoryId = null;
    _subCategories = [];
    notifyListeners();
  }

  // Select a category and fetch its subcategories
  Future<void> selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    _selectedSubCategoryId = null; // Reset subcategory when category changes
    _subCategories = [];
    notifyListeners();

    if (categoryId != null) {
      await fetchSubCategories(categoryId);
    }
  }

  // --- New Methods according to update_category_Api.txt ---

  // ক্যাটাগরি লোড করা (থিম অনুযায়ী)
  Future<void> loadCategories({String? theme}) async {
    _selectedTheme = theme ?? 'ALL';
    _selectedCategoryId = null;
    _selectedSubCategoryId = null;
    _subCategories = [];
    
    _isLoading = true;
    notifyListeners();

    try {
      // Use Uri.encodeComponent to handle special characters like '&'
      final String themeQuery = _selectedTheme == 'ALL' ? '' : '&theme=${Uri.encodeComponent(_selectedTheme!)}';
      final String url = '${Urls.categories}?type=category$themeQuery&limit=100';
      
      debugPrint('🌐 [CategoryController] Loading categories from: $url');
      
      final response = await NetworkCaller.getRequest(
        url: url,
        requireAuth: false,
      );

      if (response.isSuccess && response.body != null) {
        final dynamic rawData = response.body?['data'];
        List<dynamic> listData = [];

        if (rawData is Map && rawData.containsKey('data')) {
          listData = rawData['data'] as List<dynamic>;
        } else if (rawData is List) {
          listData = rawData;
        }

        _categories = listData
            .map((json) => CategoryModel.fromJson(json))
            .toList();
            
        debugPrint('✅ [CategoryController] Successfully loaded ${_categories.length} categories for theme: $_selectedTheme');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ক্যাটাগরি সিলেক্ট করা এবং সাব-ক্যাটাগরি লোড করা
  Future<void> onCategorySelected(CategoryModel category, BuildContext context) async {
    _selectedCategoryId = category.id;
    _selectedSubCategoryId = null;
    _subCategories = [];
    notifyListeners();

    _isLoading = true;
    notifyListeners();
   
    // API: GET /api/v1/category?parent=${category.id}&type=subcategory
    await fetchSubCategories(category.id);
   
    // যদি সাব-ক্যাটাগরি না থাকে, তাহলে সরাসরি এই ক্যাটাগরির সার্ভিস লোড করুন
    if (_subCategories.isEmpty) {
      await fetchServices(context);
    }
   
    _isLoading = false;
    notifyListeners();
  }

  // সাব-ক্যাটাগরি সিলেক্ট করা এবং সার্ভিস লোড করা
  Future<void> onSubCategorySelected(CategoryModel subCat, BuildContext context) async {
    _selectedSubCategoryId = subCat.id;
    notifyListeners();
    await fetchServices(context);
  }

  // সার্ভিস ফেচ করার মেথড
  Future<void> fetchServices(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
   
    final serviceController = context.read<ServiceListController>();
    Map<String, dynamic> filters = {
      'category': _selectedCategoryId,
    };
    if (_selectedSubCategoryId != null) {
      filters['subCategory'] = _selectedSubCategoryId;
    }

    await serviceController.getAllServices(filters: filters);
   
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getAllCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.getRequest(
        url: '${Urls.categories}?type=category', // Ensure we fetch top-level categories
        requireAuth: false,
      );

      if (response.isSuccess && response.body != null) {
        final dynamic rawData = response.body?['data'];
        List<dynamic> listData = [];

        // Updated parsing to handle the "data" within "data" structure
        if (rawData is Map && rawData.containsKey('data')) {
          listData = rawData['data'] as List<dynamic>;
        } else if (rawData is List) {
          listData = rawData;
        }

        debugPrint('📦 [CategoryController] Fetched ${listData.length} categories');

        _categories = listData
            .map((json) => CategoryModel.fromJson(json))
            .toList();
            
        // Log category themes for debugging
        final themes = _categories.map((c) => c.theme).toSet();
        debugPrint('🎨 [CategoryController] Available themes: $themes');
      } else {
        _errorMessage =
            response.body?['message'] ?? 'Failed to fetch categories';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubCategories(String parentId) async {
    // If we already have categories, filter locally first for speed
    final localSub = _categories.where((c) => c.parent == parentId).toList();
    if (localSub.isNotEmpty) {
      _subCategories = localSub;
      notifyListeners();
      return;
    }

    // If not found locally, try API with parent query parameter as per guide
    try {
      final response = await NetworkCaller.getRequest(
        url: '${Urls.categories}?parent=$parentId&type=subcategory',
        requireAuth: false,
      );

      if (response.isSuccess && response.body != null) {
        final dynamic rawData = response.body?['data'];
        List<dynamic> listData = [];

        if (rawData is Map && rawData.containsKey('data')) {
          listData = rawData['data'] as List<dynamic>;
        } else if (rawData is List) {
          listData = rawData;
        }

        _subCategories = listData
            .map((json) => CategoryModel.fromJson(json))
            .toList();
        
        // Sort alphabetically
        _subCategories.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    }
  }

  Future<void> getPopularCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await NetworkCaller.getRequest(
        url: Urls.popularCategories,
        requireAuth: false,
      );

      if (response.isSuccess && response.body != null) {
        final dynamic rawData = response.body?['data'];
        List<dynamic> listData = [];

        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map && rawData.containsKey('data')) {
          listData = rawData['data'] as List<dynamic>;
        }

        _popularCategories = listData
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      } else {
        _errorMessage =
            response.body?['message'] ?? 'Failed to fetch popular categories';
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching popular categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _categories = [];
    _popularCategories = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
