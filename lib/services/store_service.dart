import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StoreService extends ChangeNotifier {
  bool isPro = false;
  bool isLoading = false;
  String? errorMessage;

  static const String productId = 'com.jaime.highcountryoutdoors.pro.yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  StoreService() {
    _listenToPurchases();
  }

  void _listenToPurchases() {
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        errorMessage = 'Purchase error: $error';
        notifyListeners();
      },
    );
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          isPro = true;
          notifyListeners();
        } else if (purchase.status == PurchaseStatus.error) {
          errorMessage = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
        }

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        errorMessage = 'In-app purchases are not available on this device.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final ProductDetailsResponse response = await _iap.queryProductDetails(
        {productId},
      );

      if (response.error != null) {
        errorMessage = response.error!.message;
      } else if (response.notFoundIDs.isNotEmpty) {
        errorMessage = 'Product not found in the store.';
      } else {
        _products = response.productDetails;
      }
    } catch (e) {
      errorMessage = 'Could not load products.';
      debugPrint('StoreService loadProducts error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> purchasePro() async {
    if (_products.isEmpty) {
      await loadProducts();
    }

    if (_products.isEmpty) {
      errorMessage = 'No products available to purchase.';
      notifyListeners();
      return;
    }

    final ProductDetails product = _products.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      errorMessage = 'Purchase failed: $e';
      notifyListeners();
      debugPrint('StoreService purchasePro error: $e');
    }
  }

  Future<void> restorePurchases() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      errorMessage = 'Could not restore purchases.';
      debugPrint('StoreService restorePurchases error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void checkProStatus() {
    // On iOS, the purchase stream handles restores automatically.
    // This method can be extended to check local storage or a receipt validator.
    notifyListeners();
  }

  /// Returns the formatted price string, or a fallback.
  String get priceString {
    if (_products.isNotEmpty) {
      return _products.first.price;
    }
    return r'$9.99/year';
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
