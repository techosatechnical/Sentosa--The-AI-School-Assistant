import 'package:flutter/material.dart';
import 'package:sentosa/widgets/widgets.dart';
import 'package:sentosa/widgets/widget.admissiondesk.dart';
import 'package:sentosa/screens/map/screen.maps.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onRobotReaction;

  const HomeQuickActions({super.key, required this.onRobotReaction});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('QuickActions'),
      children: [_buildQuickActionsHeader(), _buildQuickActionsGrid(context)],
    );
  }

  Widget _buildQuickActionsHeader() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Icon(Icons.auto_awesome, size: 28, color: Color(0xFF38BDF8)),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F2942),
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ],
    );
  }

  Widget _buildCardGraphic(int index, Color dashColor) {
    CustomPainter painter;
    switch (index) {
      case 0:
        painter = TalkGraphicPainter(dashColor);
        break;
      case 1:
        painter = AdmissionGraphicPainter(dashColor);
        break;
      case 2:
        painter = PrincipalGraphicPainter(dashColor);
        break;
      case 3:
        painter = MapGraphicPainter(dashColor);
        break;
      case 4:
      default:
        painter = CafeteriaGraphicPainter(dashColor);
        break;
    }
    return SizedBox(
      width: 76,
      height: 72,
      child: CustomPaint(painter: painter),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final cards = [
      ActionCardData(
        title: "Mini Admission\nAssistant",
        subtitle: "Quick admission process\nwith photo & details.",
        bgColor: const Color(0xFFE6F9F9),
        hoverColor: const Color(0xFFD3F5F5),
        borderColor: const Color(0xFFCEF4F4),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF14B8A6),
        accentDashColor: const Color(0xFF5EEAD4),
      ),
      ActionCardData(
        title: "Principal's\nOffice",
        subtitle: "Get office location,\ncontact or assistance.",
        bgColor: const Color(0xFFF3EFFF),
        hoverColor: const Color(0xFFE8E1FD),
        borderColor: const Color(0xFFE5DEFB),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF818CF8),
        accentDashColor: const Color(0xFFC4B5FD),
      ),
      ActionCardData(
        title: "Where is\nthe library?",
        subtitle: "Find books, study areas\nand more.",
        bgColor: const Color(0xFFEBF5FF),
        hoverColor: const Color(0xFFDCEEFE),
        borderColor: const Color(0xFFD6EBFF),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF38BDF8),
        accentDashColor: const Color(0xFF93C5FD),
      ),
      ActionCardData(
        title: "Cafeteria",
        subtitle: "Check meal timings,\nmenu and location.",
        bgColor: const Color(0xFFEDFAF3),
        hoverColor: const Color(0xFFDCF6E8),
        borderColor: const Color(0xFFD1F2E2),
        titleColor: const Color(0xFF0F2942),
        arrowColor: const Color(0xFF10B981),
        accentDashColor: const Color(0xFF86EFAC),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 768 ? 4 : 2;
        final totalSpacing = 16.0 * (crossAxisCount - 1);
        final itemWidth =
            (constraints.maxWidth - totalSpacing) / crossAxisCount;
        const desiredItemHeight = 252.0;
        final childAspectRatio = itemWidth / desiredItemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildTouchCard(context, card, index);
          },
        );
      },
    );
  }

  Widget _buildTouchCard(BuildContext context, ActionCardData card, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (card.title == "Mini Admission\nAssistant") {
            showDialog(
              context: context,
              builder: (_) => const AdmissionAssistantDialog(),
            );
          } else if (card.title == "Principal's\nOffice") {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MapScreen(mapId: 'principal'),
              ),
            );
          } else if (card.title == "Where is\nthe library?") {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MapScreen(mapId: 'library'),
              ),
            );
          } else if (card.title == "Cafeteria") {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MapScreen(mapId: 'cafeteria'),
              ),
            );
          } else {
            onRobotReaction();
          }
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: card.arrowColor.withValues(alpha: 0.18),
        highlightColor: card.hoverColor.withValues(alpha: 0.6),
        child: Container(
          decoration: BoxDecoration(
            color: card.bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: card.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 72,
                      child: Center(
                        child: _buildCardGraphic(index, card.accentDashColor),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      card.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: card.titleColor,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      card.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.arrowColor,
                    boxShadow: [
                      BoxShadow(
                        color: card.arrowColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
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
