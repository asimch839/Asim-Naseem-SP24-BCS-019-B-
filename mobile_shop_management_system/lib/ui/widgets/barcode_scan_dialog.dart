import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/services/barcode_lookup_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BarcodeScanDialog extends StatefulWidget {
  final String? initialBarcode;
  final String title;

  const BarcodeScanDialog({
    super.key,
    this.initialBarcode,
    this.title = 'Scan Barcode or Enter Code',
  });

  static Future<BarcodeProductInfo?> show(
    BuildContext context, {
    String? initialBarcode,
    String title = 'Scan Barcode & Auto-Fill Product',
  }) async {
    return await showDialog<BarcodeProductInfo>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BarcodeScanDialog(
        initialBarcode: initialBarcode,
        title: title,
      ),
    );
  }

  @override
  State<BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<BarcodeScanDialog> with SingleTickerProviderStateMixin {
  late final TextEditingController _barcodeCtrl;
  late final FocusNode _focusNode;
  late final AnimationController _animCtrl;

  bool _isSearching = false;
  BarcodeProductInfo? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.initialBarcode ?? '');
    _focusNode = FocusNode();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // If initial barcode provided, lookup right away
    if (widget.initialBarcode != null && widget.initialBarcode!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performLookup(widget.initialBarcode!.trim());
      });
    } else {
      // Auto-focus input for USB barcode guns
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _performLookup(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _result = null;
    });

    final inv = context.read<InventoryProvider>();
    final info = await BarcodeLookupService.lookupBarcode(
      barcode: trimmed,
      inventoryProvider: inv,
    );

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _result = info;
      if (!info.isFound) {
        _errorMessage = 'No existing catalog data found for "$trimmed". You can still use this barcode and type details manually.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Point USB barcode scanner gun or enter barcode manually',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated Visual Scanner Reticle
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _result != null && _result!.isFound
                      ? AppTheme.successGreen
                      : AppTheme.primaryBlue.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner targeting brackets
                    Positioned(
                      top: 10,
                      left: 14,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                            left: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 14,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                            right: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 14,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                            left: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 14,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                            right: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.8), width: 3),
                          ),
                        ),
                      ),
                    ),

                    // Central Barcode graphic
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.barcode_reader,
                          size: 42,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSearching
                              ? 'Scanning & searching database...'
                              : (_result != null && _result!.isFound
                                  ? 'Barcode Detected & Matched!'
                                  : 'Ready for Barcode Gun or Manual Input'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _result != null && _result!.isFound
                                ? AppTheme.successGreen
                                : (_isSearching ? AppTheme.primaryBlue : Colors.grey),
                          ),
                        ),
                      ],
                    ),

                    // Animated laser scan line
                    if (_isSearching || _result == null)
                      AnimatedBuilder(
                        animation: _animCtrl,
                        builder: (context, child) {
                          return Positioned(
                            top: 12 + (_animCtrl.value * 86),
                            left: 30,
                            right: 30,
                            child: Container(
                              height: 2.2,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.7),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barcode Input Box (with Enter / OnSubmitted listener)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: 'Barcode Number / EAN / UPC / IMEI',
                      hintText: 'e.g. 8806090558610',
                      prefixIcon: const Icon(Icons.qr_code_2_rounded),
                      suffixIcon: _barcodeCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _barcodeCtrl.clear();
                                setState(() {
                                  _result = null;
                                  _errorMessage = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (val) => _performLookup(val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Lookup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSearching ? null : () => _performLookup(_barcodeCtrl.text),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sample Barcode Chips for instant demo/test
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Quick Test: ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  _buildSampleChip('Samsung 25W', '8806090558610'),
                  _buildSampleChip('Apple 20W', '194252157015'),
                  _buildSampleChip('Xiaomi 67W', '6934177749827'),
                  _buildSampleChip('Baseus 65W GaN', '6932169315891'),
                  _buildSampleChip('Ronin R-860', '8964002448601'),
                  _buildSampleChip('iPhone 15', '195949038234'),
                  _buildSampleChip('Galaxy S24 Ultra', '8806095308692'),
                  _buildSampleChip('Audionic TWS', '8964001550018'),
                  _buildSampleChip('9D Glass', '9901000000018'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Result or Error Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isSearching)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Fetching product details from barcode databases...'),
                          ],
                        ),
                      )
                    else if (_result != null && _result!.isFound)
                      _buildFoundDetailsCard(_result!)
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                if (_result != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(_result!.isFound ? 'Apply & Fill Form' : 'Use Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, _result),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleChip(String label, String code) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          _barcodeCtrl.text = code;
          _performLookup(code);
        },
      ),
    );
  }

  Widget _buildFoundDetailsCard(BarcodeProductInfo info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppTheme.successGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Source: ${info.source}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  info.type.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Name
          Text(
            info.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Grid of details
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailItem('Brand', info.brand.isNotEmpty ? info.brand : '-'),
              _buildDetailItem('Category', info.category),
              if (info.model.isNotEmpty) _buildDetailItem('Model', info.model),
              if (info.purchasePrice > 0)
                _buildDetailItem('Cost Price', AppFormatters.currency(info.purchasePrice)),
              if (info.salePrice > 0)
                _buildDetailItem('Sale Price', AppFormatters.currency(info.salePrice)),
            ],
          ),

          if (info.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              info.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
