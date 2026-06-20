import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bannerAd = appState.preloadedBannerAd;

    if (bannerAd == null) {
      // Trigger lazy reload if for some reason the ad hasn't loaded / failed on startup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.preloadAd();
      });
    }

    if (appState.isAdLoaded && bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AdWidget(ad: bannerAd),
      );
    }
    // Return an empty spacer if not loaded to prevent layout shifts
    return const SizedBox.shrink();
  }
}
