import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/room_model.dart';
import '../../data/models/bed_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'admission_controller.dart';

class AdmissionView extends GetView<AdmissionController> {
  const AdmissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header
              ResponsiveHeader(
                title: 'Student Admission Wizard',
                subtitle: 'Register a new student, assign available room and bed, and generate admission record',
                actions: [
                  CustomButton(
                    text: 'Reset Form',
                    type: ButtonType.secondary,
                    icon: Icons.restart_alt_rounded,
                    onPressed: controller.prepareNewAdmission,
                  ),
                  Obx(() => CustomButton(
                    text: 'Complete Admission',
                    icon: Icons.check_circle_rounded,
                    isLoading: controller.isSubmitting.value,
                    onPressed: controller.submitAdmission,
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // Responsive Form Layout: Two-Column on Desktop, Stacked on Small Laptops / Tablets / Mobile
              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 1000;
                  final isMobileField = constraints.maxWidth < 600;

                  final leftCard = Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('1. Student Personal Information', Icons.person_outline),
                        const SizedBox(height: 16),
                        _formRow(
                          isMobileField,
                          CustomTextField(
                            label: 'Student Code (Auto Generated) *',
                            controller: controller.studentCodeCtrl,
                            readOnly: true,
                          ),
                          CustomTextField(
                            label: 'Full Name *',
                            hint: 'e.g. Muhammad Ali',
                            controller: controller.fullNameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _formRow(
                          isMobileField,
                          CustomTextField(
                            label: 'Father / Guardian Name *',
                            hint: 'e.g. Tariq Mehmood',
                            controller: controller.fatherNameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Father name is required' : null,
                          ),
                          CustomTextField(
                            label: 'CNIC / B-Form Number *',
                            hint: 'e.g. 35202-1234567-1',
                            controller: controller.cnicCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'CNIC is required' : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _formRow(
                          isMobileField,
                          CustomTextField(
                            label: 'Primary Phone Number *',
                            hint: 'e.g. 03001234567',
                            controller: controller.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                          ),
                          CustomTextField(
                            label: 'Emergency Contact *',
                            hint: 'e.g. 03217654321',
                            controller: controller.emergencyPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Emergency contact is required' : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Permanent Address *',
                          hint: 'Full street address, city, province',
                          controller: controller.addressCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('2. Academic / Employment Information', Icons.school_outlined),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'University / College / Workplace *',
                          hint: 'e.g. FAST NUCES, UET, Software House',
                          controller: controller.universityCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Institute name is required' : null,
                        ),
                        const SizedBox(height: 14),
                        _formRow(
                          isMobileField,
                          CustomTextField(
                            label: 'Department / Program',
                            hint: 'e.g. Computer Science',
                            controller: controller.departmentCtrl,
                          ),
                          CustomTextField(
                            label: 'Semester / Year',
                            hint: 'e.g. 4th Semester',
                            controller: controller.semesterCtrl,
                          ),
                        ),
                      ],
                    ),
                  );

                  final rightCard = Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('3. Room & Bed Assignment', Icons.meeting_room_outlined),
                        const SizedBox(height: 16),

                        // Room Dropdown
                        Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Available Room *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<RoomModel>(
                              initialValue: controller.selectedRoom.value,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              hint: const Text('Choose a room with free beds'),
                              items: controller.availableRooms.map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text('Room ${r.roomNumber} (${r.availableBedsCount} Free) - ${r.block}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: controller.onRoomSelected,
                              validator: (v) => v == null ? 'Please select a room' : null,
                            ),
                          ],
                        )),
                        const SizedBox(height: 14),

                        // Bed Dropdown
                        Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Available Bed *', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<BedModel>(
                              initialValue: controller.selectedBed.value,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              hint: Text(controller.selectedRoom.value == null ? 'Select room first' : 'Choose available bed'),
                              items: controller.availableBeds.map((b) {
                                return DropdownMenuItem(
                                  value: b,
                                  child: Text('${b.bedNumber} (Available)'),
                                );
                              }).toList(),
                              onChanged: (b) => controller.selectedBed.value = b,
                              validator: (v) => v == null ? 'Please select a bed' : null,
                            ),
                          ],
                        )),
                        const SizedBox(height: 24),

                        _buildSectionTitle('4. Rent & Billing Terms', Icons.attach_money_rounded),
                        const SizedBox(height: 16),
                        _formRow(
                          isMobileField,
                          Obx(() => CustomTextField(
                            label: 'Monthly Rent (PKR) *',
                            hint: controller.rentHint.value,
                            controller: controller.rentCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final p = double.tryParse(v ?? '');
                              if (p == null || p < 0) return 'Valid rent required (e.g. 15000)';
                              return null;
                            },
                          )),
                          Obx(() => CustomTextField(
                            label: 'Security Deposit (PKR)',
                            hint: controller.depositHint.value,
                            controller: controller.depositCtrl,
                            keyboardType: TextInputType.number,
                          )),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Admission Date (YYYY-MM-DD) *',
                          controller: controller.admissionDateCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Date is required' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Special Notes / Remarks',
                          hint: 'e.g. Referral, meal preference, luggage note',
                          controller: controller.notesCtrl,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        Obx(() => CustomButton(
                          text: 'Submit & Finalize Admission',
                          icon: Icons.check_circle_rounded,
                          width: double.infinity,
                          height: 46,
                          isLoading: controller.isSubmitting.value,
                          onPressed: controller.submitAdmission,
                        )),
                      ],
                    ),
                  );

                  if (isStacked) {
                    return Column(
                      children: [
                        leftCard,
                        const SizedBox(height: 20),
                        rightCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: leftCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: rightCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

  Widget _formRow(bool isMobile, Widget child1, Widget child2) {
    if (isMobile) {
      return Column(
        children: [
          child1,
          const SizedBox(height: 14),
          child2,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: child1),
        const SizedBox(width: 14),
        Expanded(child: child2),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppStyles.h4.copyWith(color: AppColors.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
