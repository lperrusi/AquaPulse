/// Water Intake Buttons Widget
///
/// Displays quick-add buttons for logging water intake using customizable cup sizes.
/// Allows users to manage cup sizes via a modal. Used on the dashboard for fast water logging.
// ignore_for_file: deprecated_member_use
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cup_size.dart';
import '../providers/app_providers.dart';
import '../utils/neumorphic_style.dart';

/// Widget that displays quick-add water intake buttons and manages cup sizes.
class WaterIntakeButtons extends ConsumerWidget {
  final Function(double) onIntakeAdded;

  const WaterIntakeButtons({
    super.key,
    required this.onIntakeAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cupSizes = ref.watch(cupSizesProvider);
    final hydrationState = ref.watch(hydrationStateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeumorphicStyle.surfaceBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NeumorphicStyle.softBorder.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    color: NeumorphicStyle.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Add',
                    style: NeumorphicStyle.neumorphicText(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: NeumorphicStyle.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: NeumorphicStyle.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () => _showManageCupSizesModal(context, ref, cupSizes),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (cupSizes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              decoration: NeumorphicStyle.neumorphicContainer(
                borderRadius: 16,
                isElevated: false,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 48,
                      color: NeumorphicStyle.lightText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No quick add amounts',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: NeumorphicStyle.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the edit icon to add your favorite cup sizes!',
                      style: NeumorphicStyle.neumorphicText(
                        fontSize: 14,
                        color: NeumorphicStyle.lightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: cupSizes.map((cupSize) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildCupButton(
                      context,
                      cupSize,
                      hydrationState.remaining,
                    ),
                  )).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

    Widget _buildCupButton(BuildContext context, CupSize cupSize, double remaining) {
    return GestureDetector(
      onTap: () {
        // Haptic feedback
        HapticFeedback.mediumImpact();
        onIntakeAdded(cupSize.amount);
        _showSuccessSnackBar(context, cupSize);
      },
      child: Container(
        width: 90,
        height: 95,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              NeumorphicStyle.primaryBlue.withOpacity(0.12),
              NeumorphicStyle.primaryBlue.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: NeumorphicStyle.primaryBlue.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: NeumorphicStyle.primaryBlue.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smaller, more minimalistic icon - always the same style
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NeumorphicStyle.primaryBlue.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.water_drop,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${cupSize.amount.round()}',
              style: NeumorphicStyle.neumorphicText(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: NeumorphicStyle.primaryBlue,
              ),
            ),
            const SizedBox(height: 0),
            Text(
              'ml',
              style: NeumorphicStyle.neumorphicText(
                fontSize: 10,
                color: NeumorphicStyle.primaryBlue.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (cupSize.name.isNotEmpty) ...[
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  cupSize.name,
                  style: NeumorphicStyle.neumorphicText(
                    fontSize: 9,
                    color: NeumorphicStyle.primaryBlue.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, CupSize cupSize) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: NeumorphicStyle.primaryBlue,
            ),
            const SizedBox(width: 12),
            Text(
              'Added ${cupSize.amount.round()} ml',
              style: NeumorphicStyle.neumorphicText(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: NeumorphicStyle.backgroundBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showManageCupSizesModal(BuildContext context, WidgetRef ref, List<CupSize> cupSizes) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: NeumorphicStyle.backgroundBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NeumorphicStyle.lightText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Manage Cup Sizes',
              style: NeumorphicStyle.neumorphicText(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Existing cup sizes
            if (cupSizes.isNotEmpty) ...[
              Text(
                'Your Cup Sizes',
                style: NeumorphicStyle.neumorphicText(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cupSizes.length,
                  itemBuilder: (context, index) {
                    final cupSize = cupSizes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: NeumorphicStyle.neumorphicContainer(
                        borderRadius: 12,
                        isElevated: false,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: NeumorphicStyle.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cupSize.name.isNotEmpty ? cupSize.name : 'Custom',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${cupSize.amount.round()} ml',
                                  style: NeumorphicStyle.neumorphicText(
                                    fontSize: 12,
                                    color: NeumorphicStyle.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(cupSizesProvider.notifier).deleteCupSize(cupSize.id);
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: NeumorphicStyle.lightText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add new cup size form
            Text(
              'Add New Cup Size',
              style: NeumorphicStyle.neumorphicText(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: NeumorphicStyle.neumorphicInput(
                      labelText: 'Name (optional)',
                      hintText: 'e.g., Coffee mug, Water bottle',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: NeumorphicStyle.neumorphicInput(
                      labelText: 'Amount (ml)',
                      hintText: 'e.g., 250',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: NeumorphicStyle.neumorphicButton(
                      backgroundColor: NeumorphicStyle.surfaceBlue,
                      foregroundColor: NeumorphicStyle.lightText,
                    ),
                    child: Text(
                      'Cancel',
                      style: NeumorphicStyle.neumorphicText(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final amount = double.parse(amountController.text);
                        final name = nameController.text.trim();
                                                 ref.read(cupSizesProvider.notifier).addCupSize(
                           CupSize(
                             id: DateTime.now().millisecondsSinceEpoch.toString(),
                             name: name,
                             amount: amount,
                             createdAt: DateTime.now(),
                           ),
                         );
                        Navigator.of(context).pop();
                      }
                    },
                    style: NeumorphicStyle.neumorphicButton(),
                    child: Text(
                      'Add',
                      style: NeumorphicStyle.neumorphicText(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 