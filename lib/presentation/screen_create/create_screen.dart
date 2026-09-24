import 'package:flutter/material.dart';
import '../../values/app_colors.dart';
import '../common_components/section_header.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  static const _quickCreate = [
    _QC('collage', 'Collage', 'Combine photos', Icons.grid_view, Color(0xFFFFECEC)),
    _QC('story', 'Story', 'For social media', Icons.movie_outlined, Color(0xFFDCFAF0)),
    _QC('poster', 'Poster', 'Stunning designs', Icons.article_outlined, Color(0xFFEEEAFF)),
    _QC('product', 'Product Card', 'For business', Icons.storefront_outlined, Color(0xFFE0F7E0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sample', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.textPrimary)),
                        const Text('Make stylish content in minutes', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(gradient: AppColors.heroBannerGradient, borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IDEAS • TEMPLATES • AI MAGIC', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                      SizedBox(height: 6),
                      Text('Create\nSomething\nBeautiful', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick Create
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Quick Create', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _quickCreate
                      .map((qc) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _QCCard(qc: qc),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Templates
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Templates', onSeeAll: () {}),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _TemplateCard(tag: 'STORY', name: 'Instagram Story', sub: 'Trendy & stylish templates'),
                    SizedBox(width: 12),
                    _TemplateCard(tag: 'POST', name: 'Post Design', sub: 'Perfect for Instagram, Fb, etc.'),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _QC {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;

  const _QC(this.id, this.label, this.sub, this.icon, this.color);
}

class _QCCard extends StatelessWidget {
  final _QC qc;

  const _QCCard({required this.qc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: qc.color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(qc.icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(qc.label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String tag;
  final String name;
  final String sub;

  const _TemplateCard({required this.tag, required this.name, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
