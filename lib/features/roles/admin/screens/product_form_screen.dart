import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/config.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets.dart';
import '../../../../core/models.dart';
import '../../../../core/repositories.dart';
import '../../../../core/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  late final String _targetProductId;

  // Tab 1: Identity
  late TextEditingController _nameController;
  late TextEditingController _genericNameController;
  late TextEditingController _strengthController;
  DosageForm _dosageForm = DosageForm.tablet;

  // Tab 2: Manufacturer & Category
  late TextEditingController _brandController;
  String _categoryId = 'medicines';

  // Tab 3: Pricing & Stock
  late TextEditingController _mrpController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _flashSalePriceController;
  bool _isAvailable = true;
  bool _requiresPrescription = false;
  bool _isFeatured = false;
  bool _isFlashSale = false;
  ProductLifecycleStatus _lifecycleStatus = ProductLifecycleStatus.draft;
  late TextEditingController _expiryController;

  // Tab 4: Medical Info
  late TextEditingController _descController;

  // Tab 5: Media
  String? _imageUrl;
  bool _hasImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _targetProductId =
        widget.productId ?? getIt<ProductRepository>().generateId();
    _tabController = TabController(length: 5, vsync: this);

    _nameController = TextEditingController();
    _genericNameController = TextEditingController();
    _strengthController = TextEditingController();

    _brandController = TextEditingController();

    _mrpController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController(text: '100');
    _flashSalePriceController = TextEditingController();
    _expiryController = TextEditingController();

    _descController = TextEditingController();

    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await getIt<ProductRepository>().getProductById(
        widget.productId!,
      );
      if (product != null) {
        _nameController.text = product.drugName;
        _genericNameController.text = product.genericName;
        _strengthController.text = product.strength;
        _dosageForm = product.dosageForm;

        _brandController.text = product.manufacturer;
        _categoryId = product.categoryId;

        _mrpController.text = product.mrp.toString();
        _priceController.text = product.salePrice.toString();
        _stockController.text = product.countInStock.toString();
        _isAvailable = product.isAvailable;
        _requiresPrescription = product.requiresPrescription;
        _isFeatured = product.isFeatured;
        _isFlashSale = product.isFlashSale;
        _flashSalePriceController.text =
            product.flashSalePrice?.toString() ?? '';
        _lifecycleStatus = product.lifecycleStatus;

        _descController.text = product.description;

        _imageUrl = product.imageUrl.isNotEmpty ? product.imageUrl : null;
        _hasImage = product.hasImage;
      }
    } catch (e) {
      debugPrint("Error loading product: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _genericNameController.dispose();
    _strengthController.dispose();
    _brandController.dispose();
    _mrpController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _flashSalePriceController.dispose();
    _expiryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.show(
        context,
        'Please fix the errors in the form.',
        type: ToastType.error,
      );
      return;
    }

    final mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
    final salePrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (mrp <= 0 || salePrice <= 0) {
      AppToast.show(
        context,
        'MRP and Sale Price must be greater than 0.',
        type: ToastType.error,
      );
      return;
    }

    if (salePrice > mrp) {
      AppToast.show(
        context,
        'Sale Price cannot exceed MRP.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = getIt<ProductRepository>();

      // Build the slug for search
      final slug = _nameController.text.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '-',
      );

      // Build search tokens
      final tokens = ProductTokenizer.tokenize(
        _nameController.text.trim(),
        _genericNameController.text.trim(),
        _brandController.text.trim(),
      );

      final data = <String, dynamic>{
        'id': _targetProductId,
        'drugName': _nameController.text.trim(),
        'genericName': _genericNameController.text.trim(),
        'strength': _strengthController.text.trim(),
        'dosageForm': _dosageForm.name,
        'manufacturer': _brandController.text.trim(),
        'categoryId': _categoryId,
        'mrp': mrp,
        'salePrice': salePrice,
        'countInStock': stock,
        'isAvailable': _isAvailable,
        'requiresPrescription': _requiresPrescription,
        'isFeatured': _isFeatured,
        'isFlashSale': _isFlashSale,
        'flashSalePrice': _isFlashSale
            ? double.tryParse(_flashSalePriceController.text.trim())
            : null,
        'lifecycleStatus': _lifecycleStatus.name,
        'description': _descController.text.trim(),
        'imageUrl': _imageUrl ?? '',
        'slug': slug,
        'searchTokens': tokens,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final isEdit = widget.productId != null;
      if (isEdit) {
        await repo.updateProduct(widget.productId!, data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await repo.createProduct(data);
      }

      if (mounted) {
        AppToast.show(
          context,
          isEdit
              ? 'Product updated successfully!'
              : 'Product created successfully!',
          type: ToastType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error: ${e.toString()}', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Medicine' : 'Add New Medicine'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Identity'),
            Tab(text: 'Classification'),
            Tab(text: 'Pricing & Status'),
            Tab(text: 'Medical Info'),
            Tab(text: 'Media'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Identity
                        ListView(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          children: [
                            HealMealTextField(
                              controller: _nameController,
                              label: 'Medicine Name',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            SizedBox(height: AppSpacing.md),
                            HealMealTextField(
                              controller: _genericNameController,
                              label: 'Generic Name',
                            ),
                            SizedBox(height: AppSpacing.md),
                            HealMealTextField(
                              controller: _strengthController,
                              label: 'Strength',
                              hint: 'e.g. 500mg',
                            ),
                            SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<DosageForm>(
                              value: _dosageForm,
                              decoration: InputDecoration(
                                labelText: 'Dosage Form',
                                border: OutlineInputBorder(),
                              ),
                              items: DosageForm.values
                                  .where((e) => e != DosageForm.unknown)
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _dosageForm = v!),
                            ),
                            SizedBox(height: AppSpacing.md),
                          ],
                        ),
                        // Tab 2: Classification
                        ListView(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          children: [
                            HealMealTextField(
                              controller: _brandController,
                              label: 'Brand/Manufacturer',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            SizedBox(height: AppSpacing.md),
                            FutureBuilder<List<AppCategory>>(
                              future: getIt<CategoryRepository>()
                                  .getCategories(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final categories = (snapshot.data ?? [])
                                    .where((c) => c.isActive)
                                    .toList();
                                if (categories.isEmpty) {
                                  return Text(
                                    'No categories found. Please create a category first.',
                                  );
                                }

                                final isValid = categories.any(
                                  (c) => c.id == _categoryId,
                                );
                                final currentValue = isValid
                                    ? _categoryId
                                    : categories.first.id;
                                if (!isValid && _categoryId != currentValue) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(
                                        () => _categoryId = currentValue,
                                      );
                                    }
                                  });
                                }

                                return DropdownButtonFormField<String>(
                                  value: currentValue,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: categories
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _categoryId = v!),
                                );
                              },
                            ),
                          ],
                        ),
                        // Tab 3: Pricing & Status
                        ListView(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: HealMealTextField(
                                    controller: _mrpController,
                                    label: 'MRP',
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: HealMealTextField(
                                    controller: _priceController,
                                    label: 'Sale Price',
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            HealMealTextField(
                              controller: _stockController,
                              label: 'Initial Stock (Display Only)',
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<ProductLifecycleStatus>(
                              value: _lifecycleStatus,
                              decoration: InputDecoration(
                                labelText: 'Lifecycle Status',
                                border: OutlineInputBorder(),
                              ),
                              items: ProductLifecycleStatus.values
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _lifecycleStatus = v!),
                            ),
                            SizedBox(height: AppSpacing.md),
                            SwitchListTile(
                              title: Text('Is Available'),
                              value: _isAvailable,
                              onChanged: (v) =>
                                  setState(() => _isAvailable = v),
                            ),
                            SwitchListTile(
                              title: Text('Requires Prescription (Rx)'),
                              value: _requiresPrescription,
                              onChanged: (v) =>
                                  setState(() => _requiresPrescription = v),
                            ),
                            SwitchListTile(
                              title: Text('Featured Medicine'),
                              value: _isFeatured,
                              onChanged: (v) => setState(() => _isFeatured = v),
                            ),
                            SwitchListTile(
                              title: Text('Flash Sale'),
                              value: _isFlashSale,
                              onChanged: (v) =>
                                  setState(() => _isFlashSale = v),
                            ),
                            if (_isFlashSale)
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.md),
                                child: HealMealTextField(
                                  controller: _flashSalePriceController,
                                  label: 'Flash Sale Price',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.isEmpty
                                      ? 'Required for flash sale'
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        // Tab 4: Medical Info
                        ListView(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          children: [
                            HealMealTextField(
                              controller: _descController,
                              label: 'Description / Indications',
                              maxLines: 5,
                            ),
                          ],
                        ),
                        // Tab 5: Media
                        ListView(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          children: [
                            Text(
                              'Main Product Image',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.h),
                            _ImagePickerBox(
                              imageUrl: _imageUrl,
                              targetProductId: _targetProductId,
                              hasImage: _hasImage,
                              onImagePicked: (url) => setState(() {
                                _imageUrl = url;
                                _hasImage = true;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: HealMealButton(
                      label: isEdit ? 'Update Medicine' : 'Create Medicine',
                      onPressed: _isLoading ? null : _save,
                      isLoading: _isLoading,
                      size: ButtonSize.large,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    this.imageUrl,
    required this.targetProductId,
    required this.hasImage,
    required this.onImagePicked,
  });
  final String? imageUrl;
  final String targetProductId;
  final bool hasImage;
  final Function(String) onImagePicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final b64 = await ImageUploadUtil.pickImageAsBase64();
        if (b64 != null && b64 != 'TOO_LARGE') {
          onImagePicked(b64);
        } else if (b64 == 'TOO_LARGE') {
          if (context.mounted) {
            AppToast.show(
              context,
              'Image is too large.',
              type: ToastType.error,
            );
          }
        }
      },
      child: Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: (imageUrl == null || imageUrl!.isEmpty) && !hasImage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48.w,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Click to upload image',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              )
            : HealMealImage(
                imageUrl: imageUrl,
                productId: targetProductId,
                hasImage: hasImage,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
