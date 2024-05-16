import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CustomerInfo customerInfo;
  Offerings? offerings;

//* purchase_flutter
  Future<void> initCall() async {
    await Purchases.setDebugLogsEnabled(true);
    // revenuecat project api_key
    await Purchases.setup("goog_EgFUJfndWvpsTAJQmCdwgtciNHH");
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    Offerings offerings = await Purchases.getOfferings();

    this.customerInfo = customerInfo;
    this.offerings = offerings;
    setState(() {});
  }

  subScribeNow(Package package) async {
    try {
      if (offerings != null) {
        CustomerInfo purchaserInfo = await Purchases.purchasePackage(package);
        var isPro = purchaserInfo.entitlements.all["all_access"]!.isActive;
        if (isPro) {
          print("Subscribed");
        }
      }
    } catch (e) {
      print(e);
    }
  }

  //* in_app_purchase
  List<ProductDetails> productList = [];
  @override
  void initState() {
    initCall();
    getInAppPurchaseInitCall();
    initialize();
    super.initState();
  }

  Future<List<ProductDetails>> getProducts() async {
    if (await InAppPurchase.instance.isAvailable()) {
      Set<String> id = Platform.isIOS
          ? {
              "com.gymeats.mobile.1_month",
              "com.gymeats.mobile.6_month",
              "com.gymeats.mobile.12_month",
            }
          // google play console subscription id
          : {
              "com.gymeats.mobile",
            };

      ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(id);

      return response.productDetails;
    } else {
      return [];
    }
  }

  void getInAppPurchaseInitCall() async {
    productList = await getProducts();
    setState(() {});
  }

  Future<bool> buyProduct(ProductDetails productDetails) async {
    if (Platform.isIOS) {
      var transactions = await SKPaymentQueueWrapper().transactions();
      for (var skPaymentTransactionWrapper in transactions) {
        SKPaymentQueueWrapper().finishTransaction(skPaymentTransactionWrapper);
      }
    }
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    return await InAppPurchase.instance
        .buyNonConsumable(purchaseParam: purchaseParam);
  }

  StreamSubscription? _subscription;
  void initialize() {
    _subscription =
        InAppPurchase.instance.purchaseStream.listen(_handleInAppPurchase);
  }

  void _handleInAppPurchase(List<PurchaseDetails> purchase) {
    for (int i = 0; i < purchase.length; i++) {
      if (purchase[i].status == PurchaseStatus.purchased) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Purchased")));
      }
      print("status:${purchase[i].status}");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String? period;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription demo"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Purchase Revenuecat"),
            const SizedBox(height: 20),

            ///purchase_flutter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (offerings != null)
                  ...offerings!.current!.availablePackages.map(
                    (e) {
                      return GestureDetector(
                        onTap: () async {
                          await subScribeNow(e);
                        },
                        child: Container(
                          height: 50,
                          width: 100,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(.5),
                              borderRadius: BorderRadius.circular(15)),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(billingPeriod(
                                  e.storeProduct.subscriptionPeriod)),
                              Text(e.storeProduct.priceString),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  const Center(child: CircularProgressIndicator())
              ],
            ),
            const SizedBox(height: 20),
            const Text("In App Purchase"),
            const SizedBox(height: 20),

            ///in_app_flutter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...productList.asMap().map((key, value) {
                  if (value is GooglePlayProductDetails) {
                    if (value
                        .productDetails
                        .subscriptionOfferDetails![value.subscriptionIndex!]
                        .pricingPhases
                        .isNotEmpty) {
                      period = value
                          .productDetails
                          .subscriptionOfferDetails![value.subscriptionIndex!]
                          .pricingPhases
                          .first
                          .billingPeriod;
                    }
                  }

                  if (value is AppStoreProductDetails) {
                    period =
                        "${value.skProduct.subscriptionPeriod?.numberOfUnits} ${value.skProduct.subscriptionPeriod?.unit.name}";
                  }

                  return MapEntry(
                      key,
                      GestureDetector(
                        onTap: () async {
                          await buyProduct(value);
                        },
                        child: Container(
                          height: 50,
                          width: 100,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(.5),
                              borderRadius: BorderRadius.circular(15)),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(billingPeriod(period)),
                              Text(value.price),
                            ],
                          ),
                        ),
                      ));
                }).values,
              ],
            ),
          ],
        ),
      ),
    );
  }

  String billingPeriod(String? subscriptionPeriod) {
    switch (subscriptionPeriod) {
      case "P1M":
        return "1 Month";
      case "P6M":
        return "6 Month";
      case "P1Y":
        return "12 Month";
      default:
        return "";
    }
  }
}
