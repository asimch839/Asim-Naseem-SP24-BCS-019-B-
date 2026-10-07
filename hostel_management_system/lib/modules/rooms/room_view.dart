import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/room_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_widget.dart';
import '../../core/utils/responsive.dart';
import 'room_controller.dart';

class RoomView extends GetView<RoomController> {
  const RoomView({super.key});

  void _showRoomFormDialog([RoomModel? room]) {
    final formKey = GlobalKey<FormState>();
    final roomNumberCtrl = TextEditingController(text: room?.roomNumber ?? '');
    final blockCtrl = TextEditingController(text: room?.block ?? 'Block A');
    final floorCtrl = TextEditingController(text: room?.floor ?? '1st Floor');
    final rentCtrl = TextEditingController(text: room != null ? room.monthlyRent.toStringAsFixed(0) : '');
    final bedsCtrl = TextEditingController(text: room != null ? room.totalBeds.toString() : '2');
    final notesCtrl = TextEditingController(text: room?.notes ?? '');
    final selectedType = (room?.roomType ?? 'Double').obs;

    CustomDialog.show(
      title: room == null ? 'Add New Room' : 'Edit Room ${room.roomNumber}',
      content: Form(
        key: formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 450;

            Widget buildRow(Widget c1, Widget c2) {
              if (isCompact) {
                return Column(
                  children: [
                    c1,
                    const SizedBox(height: 14),
                    c2,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: c1),
                  const SizedBox(width: 14),
                  Expanded(child: c2),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildRow(
                  CustomTextField(
                    label: 'Room Number *',
                    hint: 'e.g. 101, 102',
                    controller: roomNumberCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Room Type', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType.value,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: AppStrings.roomTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            selectedType.value = v;
                            if (v == 'Single') bedsCtrl.text = '1';
                            if (v == 'Double') bedsCtrl.text = '2';
                            if (v == 'Triple') bedsCtrl.text = '3';
                            if (v == 'Four Bed') bedsCtrl.text = '4';
                          }
                        },
                      ),
                    ],
                  )),
                ),
                const SizedBox(height: 14),
                buildRow(
                  CustomTextField(
                    label: 'Block / Building',
                    hint: 'e.g. Block A, West Wing',
                    controller: blockCtrl,
                  ),
                  CustomTextField(
                    label: 'Floor',
                    hint: 'e.g. Ground Floor, 2nd Floor',
                    controller: floorCtrl,
                  ),
                ),
                const SizedBox(height: 14),
                buildRow(
                  CustomTextField(
                    label: 'Total Beds *',
                    hint: 'Number of beds',
                    controller: bedsCtrl,
                    keyboardType: TextInputType.number,
                    readOnly: room != null,
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Valid number > 0 required';
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'Monthly Rent (PKR) *',
                    hint: 'e.g. 15000',
                    controller: rentCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed < 0) return 'Valid amount required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Notes / Facilities',
                  hint: 'e.g. Attached bath, AC, Balcony',
                  controller: notesCtrl,
                  maxLines: 2,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          type: ButtonType.secondary,
          onPressed: () {
            if (Get.isDialogOpen == true) Get.back();
          },
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: room == null ? 'Create Room' : 'Save Changes',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              controller.saveRoom(
                id: room?.id,
                roomNumber: roomNumberCtrl.text,
                block: blockCtrl.text,
                floor: floorCtrl.text,
                roomType: selectedType.value,
                totalBeds: int.tryParse(bedsCtrl.text) ?? 1,
                monthlyRent: double.tryParse(rentCtrl.text) ?? 0.0,
                notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            ResponsiveHeader(
              title: 'Rooms & Bed Allocations',
              subtitle: 'Manage room inventory, bed capacities, and real-time occupancy status',
              actions: [
                CustomButton(
                  text: 'Add New Room',
                  icon: Icons.add_home_work_rounded,
                  onPressed: () => _showRoomFormDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filters & Search Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final searchInput = TextField(
                  onChanged: (val) {
                    controller.searchQuery.value = val;
                    controller.fetchRooms();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by room number, block, or floor...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );

                final statusDropdown = Obx(() => DropdownButton<String>(
                  value: controller.statusFilter.value,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Available', child: Text('Available')),
                    DropdownMenuItem(value: 'Full', child: Text('Full')),
                    DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      controller.statusFilter.value = v;
                      controller.fetchRooms();
                    }
                  },
                ));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: isNarrow
                      ? Column(
                          children: [
                            searchInput,
                            const SizedBox(height: 10),
                            Align(alignment: Alignment.centerLeft, child: statusDropdown),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 16),
                            statusDropdown,
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Content Area: Split View (Rooms List + Selected Room Beds Visualizer)
            Obx(() {
                if (controller.isLoading.value && controller.rooms.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.rooms.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No Rooms Configured',
                    description: 'Get started by creating your hostel rooms and setting up bed inventory.',
                    actionText: 'Add First Room',
                    onAction: () => _showRoomFormDialog(),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isVertical = constraints.maxWidth < 950;

                    Widget buildGrid() {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 195,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.rooms.length,
                        itemBuilder: (context, index) {
                          final room = controller.rooms[index];
                          return Obx(() {
                            final isSelected = controller.selectedRoom.value?.id == room.id;

                            return InkWell(
                              onTap: () => controller.selectRoom(room),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.16),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : AppColors.cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Room ${room.roomNumber}',
                                            style: AppStyles.h3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        StatusBadge(status: room.roomStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${room.block} • ${room.floor} • ${room.roomType}',
                                      style: AppStyles.caption,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Occupancy', style: AppStyles.caption),
                                              Text(
                                                '${room.occupiedBedsCount} / ${room.totalBeds} Beds',
                                                style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Rent', style: AppStyles.caption),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  CurrencyFormatter.format(room.monthlyRent),
                                                  style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: room.totalBeds > 0 ? (room.occupiedBedsCount / room.totalBeds) : 0,
                                        minHeight: 6,
                                        backgroundColor: AppColors.surfaceSecondary,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          room.occupiedBedsCount >= room.totalBeds ? AppColors.danger : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      );
                    }

                    Widget buildBedManager() {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.cardDecoration,
                        child: Obx(() {
                          final r = controller.selectedRoom.value;
                          if (r == null) {
                            return const Center(child: Text('Select a room to view bed allocation details.'));
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Room ${r.roomNumber} Beds', style: AppStyles.h3, overflow: TextOverflow.ellipsis),
                                        Text('${r.block} | ${r.floor} | ${r.roomType}', style: AppStyles.caption, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                        tooltip: 'Edit Room Details',
                                        onPressed: () => _showRoomFormDialog(r),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                        tooltip: 'Delete Empty Room',
                                        onPressed: () async {
                                          final confirmed = await CustomDialog.showConfirm(
                                            title: 'Delete Room ${r.roomNumber}?',
                                            message: 'Are you sure you want to permanently delete room ${r.roomNumber}?',
                                          );
                                          if (confirmed) {
                                            controller.deleteRoom(r);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              Text('Bed Inventory & Allocations:', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),

                              if (controller.isLoadingBeds.value)
                                const Center(child: CircularProgressIndicator())
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: controller.selectedRoomBeds.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, bIdx) {
                                    final bed = controller.selectedRoomBeds[bIdx];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: bed.isOccupied
                                                  ? AppColors.primaryLight.withValues(alpha: 0.1)
                                                  : (bed.isMaintenance ? AppColors.infoBg : AppColors.successBg),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.single_bed_rounded,
                                              color: bed.isOccupied
                                                  ? AppColors.primaryLight
                                                  : (bed.isMaintenance ? AppColors.info : AppColors.success),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(bed.bedNumber, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 2),
                                                if (bed.studentName != null)
                                                  Text(
                                                    'Occupant: ${bed.studentName} (${bed.studentIdCode})',
                                                    style: AppStyles.caption.copyWith(color: AppColors.primary),)
                                                else
                                                  Text('No student assigned', style: AppStyles.caption),
                                              ],
                                            ),
                                          ),
                                          StatusBadge(status: bed.bedStatus),
                                          const SizedBox(width: 8),
                                          if (!bed.isOccupied)
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 18),
                                              onSelected: (newStatus) {
                                                if (bed.id != null) {
                                                  controller.setBedStatus(bed.id!, newStatus);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 'Available', child: Text('Mark Available')),
                                                const PopupMenuItem(value: 'Maintenance', child: Text('Mark Maintenance')),
                                              ],
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          );
                        }),
                      );
                    }

                    if (isVertical) {
                      return Column(
                        children: [
                          buildGrid(),
                          const SizedBox(height: 16),
                          buildBedManager(),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: buildGrid()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: buildBedManager()),
                      ],
                    );
                  },
                );
              }),
            ],
          ),
        );
    }
}
