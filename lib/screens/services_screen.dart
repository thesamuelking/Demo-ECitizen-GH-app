import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/data/services_data.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/service_card.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class ServicesScreen extends StatefulWidget {
  final ServiceCategory? category;

  const ServicesScreen({super.key, this.category});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchController = TextEditingController();
  List<GovernmentService> _filtered = kServices;

  @override
  void initState() {
    super.initState();
    _filtered = _servicesForCategory;
    _searchController.addListener(_onSearch);
  }

  List<GovernmentService> get _servicesForCategory => widget.category == null
      ? kServices
      : kServices.where((s) => s.category == widget.category!.title).toList();

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _servicesForCategory
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.subtitle.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            pinned: true,
            toolbarHeight: 76,
            leading: const AppBackButton(),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Text(
                      widget.category?.title ?? 'All Services',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                Text(
                  widget.category == null
                      ? 'Choose a service category'
                      : '${_filtered.length} services available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ),
              ],
            ),
          ),
          if (widget.category == null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = kServiceCategories[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 16 : 0,
                      16,
                      10,
                    ),
                    child: _CategoryTile(
                      category: category,
                      onTap: () => context.push('/services', extra: category),
                    ),
                  );
                },
                childCount: kServiceCategories.length,
              ),
            ),
          if (widget.category != null) ...[
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.mutedLight,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),

            // Service list
            _filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No services found',
                        style: GoogleFonts.inter(
                          color: AppColors.mutedLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final svc = _filtered[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            index == 0 ? 8 : 0,
                            16,
                            12,
                          ),
                          child: ServiceCard(
                            service: svc,
                            expanded: true,
                            onTap: () =>
                                context.push('/services/detail', extra: svc),
                          ),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ghBlack,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
