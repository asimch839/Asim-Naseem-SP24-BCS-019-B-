import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inspection_model.dart';

class VehicleDiagramWidget extends StatelessWidget {
  final List<InspectionPartItem> parts;
  final Function(InspectionPartItem part) onPartTap;
  final VoidCallback onAddCustomPart;

  const VehicleDiagramWidget({
    super.key,
    required this.parts,
    required this.onPartTap,
    required this.onAddCustomPart,
  });

  InspectionPartItem? _findPart(String name) {
    try {
      return parts.firstWhere((p) => p.partName.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_car_rounded, color: AppColors.primaryLight),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Interactive Vehicle Inspection Diagram',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onAddCustomPart,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Custom Part'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap on any vehicle view or part to type its condition, mark dents/scratches, or attach damage photos.',
              style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
            ),
            const SizedBox(height: 20),

            // 5 Interactive Vehicle Views: Front, Rear, Top, Left Side, Right Side
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Column(
                    children: [
                      // Top Row: Front View | Top View (Center) | Rear View
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildFrontView()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildTopView()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRearView()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Bottom Row: Left Side View | Right Side View
                      Row(
                        children: [
                          Expanded(child: _buildSideView('Left Side', ['Left Front Fender', 'Left Front Door', 'Left Rear Door', 'Left Quarter Panel', 'Left Wheels / Rims'])),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSideView('Right Side', ['Right Front Fender', 'Right Front Door', 'Right Rear Door', 'Right Quarter Panel', 'Right Wheels / Rims'])),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTopView(),
                      const SizedBox(height: 16),
                      _buildFrontView(),
                      const SizedBox(height: 16),
                      _buildRearView(),
                      const SizedBox(height: 16),
                      _buildSideView('Left Side', ['Left Front Fender', 'Left Front Door', 'Left Rear Door', 'Left Quarter Panel', 'Left Wheels / Rims']),
                      const SizedBox(height: 16),
                      _buildSideView('Right Side', ['Right Front Fender', 'Right Front Door', 'Right Rear Door', 'Right Quarter Panel', 'Right Wheels / Rims']),
                    ],
                  );
                }
              },
            ),

            // Custom Added Parts Chips
            if (parts.any((p) => p.view == 'Custom')) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Custom Added Inspection Parts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parts.where((p) => p.view == 'Custom').map((p) => _buildPartChip(p.partName, p.view)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FRONT VIEW
  Widget _buildFrontView() {
    return _viewContainer(
      title: 'Front View',
      icon: Icons.expand_less_rounded,
      child: Column(
        children: [
          _buildPartTile('Front Bumper', 'Front'),
          const SizedBox(height: 6),
          _buildPartTile('Front Grille & Emblem', 'Front'),
          const SizedBox(height: 6),
          _buildPartTile('Bonnet / Hood', 'Front'),
          const SizedBox(height: 6),
          _buildPartTile('Headlights (L & R)', 'Front'),
          const SizedBox(height: 6),
          _buildPartTile('Front Fog Lights', 'Front'),
        ],
      ),
    );
  }

  // REAR VIEW
  Widget _buildRearView() {
    return _viewContainer(
      title: 'Rear View',
      icon: Icons.expand_more_rounded,
      child: Column(
        children: [
          _buildPartTile('Rear Bumper', 'Rear'),
          const SizedBox(height: 6),
          _buildPartTile('Trunk / Boot Lid', 'Rear'),
          const SizedBox(height: 6),
          _buildPartTile('Taillights (L & R)', 'Rear'),
          const SizedBox(height: 6),
          _buildPartTile('Exhaust & Diffuser', 'Rear'),
          const SizedBox(height: 6),
          _buildPartTile('Rear Number Plate Area', 'Rear'),
        ],
      ),
    );
  }

  // TOP VIEW (Full Body Plan)
  Widget _buildTopView() {
    return _viewContainer(
      title: 'Top View (Bird\'s Eye)',
      icon: Icons.directions_car_filled_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          if (isNarrow) {
            return Column(
              children: [
                _buildPartTile('Front Windscreen', 'Top'),
                const SizedBox(height: 6),
                _buildPartTile('Roof & Sunroof', 'Top'),
                const SizedBox(height: 6),
                _buildPartTile('Rear Windscreen', 'Top'),
                const SizedBox(height: 6),
                _buildPartTile('Left Side Mirrors', 'Top'),
                const SizedBox(height: 6),
                _buildPartTile('Antenna / Shark Fin', 'Top'),
                const SizedBox(height: 6),
                _buildPartTile('Right Side Mirrors', 'Top'),
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildPartTile('Front Windscreen', 'Top')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPartTile('Roof & Sunroof', 'Top')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPartTile('Rear Windscreen', 'Top')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPartTile('Left Side Mirrors', 'Top')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPartTile('Antenna / Shark Fin', 'Top')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPartTile('Right Side Mirrors', 'Top')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // SIDE VIEW
  Widget _buildSideView(String sideTitle, List<String> partNames) {
    return _viewContainer(
      title: '$sideTitle View',
      icon: Icons.swap_horiz_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: partNames.map((name) => _buildPartChip(name, sideTitle)).toList(),
      ),
    );
  }

  Widget _viewContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPartTile(String partName, String view) {
    final existing = _findPart(partName);
    final hasDamage = existing?.hasDamage ?? false;
    final conditionText = existing?.condition ?? 'Not inspected';

    return InkWell(
      onTap: () => onPartTap(existing ?? InspectionPartItem(partName: partName, view: view, condition: 'Good')),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasDamage
              ? AppColors.error.withValues(alpha: 0.15)
              : existing != null
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasDamage
                ? AppColors.error
                : existing != null
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasDamage ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 16,
              color: hasDamage ? AppColors.error : existing != null ? AppColors.success : AppColors.textDarkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    conditionText,
                    style: TextStyle(
                      fontSize: 11,
                      color: hasDamage ? AppColors.error : AppColors.textDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (existing?.photoUrls.isNotEmpty == true) ...[
              const SizedBox(width: 4),
              const Icon(Icons.photo_camera_rounded, size: 14, color: AppColors.primaryLight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartChip(String partName, String view) {
    final existing = _findPart(partName);
    final hasDamage = existing?.hasDamage ?? false;
    final conditionText = existing?.condition ?? 'Tap to inspect';

    return InkWell(
      onTap: () => onPartTap(existing ?? InspectionPartItem(partName: partName, view: view, condition: 'Good')),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasDamage
              ? AppColors.error.withValues(alpha: 0.15)
              : existing != null
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasDamage ? AppColors.error : existing != null ? AppColors.primary.withValues(alpha: 0.4) : AppColors.borderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasDamage ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 14,
              color: hasDamage ? AppColors.error : existing != null ? AppColors.success : AppColors.textDarkMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$partName: $conditionText',
                style: TextStyle(fontSize: 11, fontWeight: hasDamage ? FontWeight.bold : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (existing?.photoUrls.isNotEmpty == true) ...[
              const SizedBox(width: 4),
              const Icon(Icons.camera_alt_outlined, size: 12, color: AppColors.primaryLight),
            ],
          ],
        ),
      ),
    );
  }
}
