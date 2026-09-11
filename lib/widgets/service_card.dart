import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final GovernmentService service;
  final VoidCallback onTap;
  final bool expanded;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: expanded ? 56 : 48,
                      height: expanded ? 56 : 48,
                      decoration: BoxDecoration(
                        color: service.bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          service.emoji,
                          style: TextStyle(fontSize: expanded ? 28 : 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: expanded ? 15 : 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (expanded) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  service.fee,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: service.color,
                                  ),
                                ),
                                Text(
                                  '  ·  ${service.duration}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!expanded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            service.fee,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: service.color,
                            ),
                          ),
                          Text(
                            service.duration,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.border,
                        size: 22,
                      ),
                  ],
                ),
              ),
              // Color accent stripe
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.25),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
