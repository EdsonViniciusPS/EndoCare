import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_widgets.dart';
import 'package:endocare/features/timeline/domain/models/timeline_event.dart';

/// Card para um evento individual na Linha do tempo da doença.
class TimelineEventCard extends StatelessWidget {
  const TimelineEventCard({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;

  String _formatDate(DateTime dt) {
    final hasTime = dt.hour != 0 || dt.minute != 0;
    if (hasTime) {
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dt);
    }
    return DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final category = event.category;
    final color = category.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna visual da linha do tempo (linha vertical + nó)
          SizedBox(
            width: 36,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Linha vertical conectora
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.only(
                        top: isFirst ? 16 : 0,
                        bottom: isLast ? 16 : 0,
                      ),
                      color: AppColors.outline.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // Nó circular com ícone da categoria
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    category.icon,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Conteúdo do evento dentro de um EndoCareCard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: EndoCareCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                elevated: event.isHighlighted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha superior: categoria + badges de destaque / data
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            category.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (event.isUpcoming) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Agendado',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatDate(event.date),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Título do evento
                    Text(
                      event.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: event.isHighlighted ? color : null,
                      ),
                    ),

                    // Subtítulo descritivo
                    if (event.subtitle != null &&
                        event.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
