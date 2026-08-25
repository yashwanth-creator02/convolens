import 'package:flutter/material.dart';

import 'cosmo_nebula.dart';

class CosmoPreviewScreen extends StatelessWidget {
  const CosmoPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmoNebula(
        child: SafeArea(
          child: Center(
            child: Text(
              'COSMO',
              style: Theme
                  .of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}