// Phase 5c-4 — V2 ASAData (per-program drill).
//
// Renders one expanded ASA row's program list. Consumes ``v2.AsaItem``
// directly; iterates ``item.programs[]`` (a list of ``UserAsaProgram``).
//
// Differences from the v1 ``ASAData`` widget:
//   - v1 read from ``Values.dapps[i].entries.{value,amount,price,links}``
//     — structured legacy fields. V2 doesn't have ``entries`` at all;
//     equivalent data lives in ``UserAsaProgram.linked[]`` (a flat list
//     of ``LinkedData`` objects) plus ``program.{type,name,code,url}``
//     metadata. This rewrite renders from those directly, matching the
//     website's ``program.html`` template (anchor/span per linked row).
//   - The v1 per-program ``Price`` toggle (entries.price.unit toggle
//     between USD/asset and asset/USD) is removed per Q5 — no v2
//     equivalent (price is on AsaItem, not per-program).
//   - The auto-expand-balance-row heuristic that inspected
//     ``entries.value.text`` for "balance" is now driven by
//     ``program.type == 'Balance'``, which is the canonical signal in
//     v2 (e.g. the ALGO Balance program).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../config/color.dart';
import '../../config/dimensions.dart';
import '../../data/repository/app_setting_repo.dart';
import '../../models/v2/v2.dart' as v2;
import '../../providers/app_setting_provider.dart';
import '../../screens/menu/menu_screen.dart';
import '../../utility/utils.dart';

class ASADataV2 extends StatefulWidget {
  final v2.AsaItem item;
  final bool isAlgo;
  final v2.Total? total;
  final Function(bool isExpanded) onExpand;

  const ASADataV2({
    super.key,
    required this.item,
    required this.isAlgo,
    required this.total,
    required this.onExpand,
  });

  @override
  State<ASADataV2> createState() => _ASADataV2State();
}

class _ASADataV2State extends State<ASADataV2> {
  bool _isFirstExpand = true;
  final List<int> _selectedIndexes = [];

  void _toggleExpand(List<v2.Distribution> distribution, int index) {
    if (distribution.isEmpty) return;
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
    widget.onExpand(_selectedIndexes.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final programs = widget.item.programs;
    return ListView.builder(
      itemCount: programs.length,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        final program = programs[index];
        // Auto-expand the Balance row on first build, matching the v1
        // UX. The v1 widget detected this by substring-matching
        // ``entries.value.text`` against "balance"; in v2 the
        // ``program.type == 'Balance'`` check is exact and lives in
        // the canonical signal slot.
        final isBalance = program.program?.type == 'Balance';
        if (isBalance &&
            _selectedIndexes.isEmpty &&
            program.distribution.isNotEmpty &&
            _isFirstExpand) {
          _selectedIndexes.add(index);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onExpand(_selectedIndexes.isNotEmpty);
          });
          _isFirstExpand = false;
        }
        return _programRow(program, index);
      },
    );
  }

  Widget _programRow(v2.UserAsaProgram program, int index) {
    final isExpanded = _selectedIndexes.contains(index);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpanded)
          Expanded(
            flex: 1,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, distIndex) => DistributorWidgetV2(
                distributor: program.distribution[distIndex],
                program: program,
                item: widget.item,
                total: widget.total,
              ),
              itemCount: program.distribution.length,
            ),
          ),
        if (!isExpanded) const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () => _toggleExpand(program.distribution, index),
            child: Container(
              margin: EdgeInsets.only(
                  bottom: widget.item.programs.isNotEmpty ? 20 : 0),
              padding: isExpanded
                  ? const EdgeInsets.symmetric(vertical: 10, horizontal: 15)
                  : null,
              decoration: isExpanded
                  ? BoxDecoration(
                      color: ColorResources.themeDataBgColor(context),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: ColorResources.dataBgColor,
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, -1),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _programSummaryRows(program),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the right-hand summary column for one program — value line,
  /// program-name link, "Type: amount unit" line (for non-ALGO assets),
  /// and one row per ``LinkedData`` entry. Mirrors the website's
  /// ``program.html`` template structure.
  List<Widget> _programSummaryRows(v2.UserAsaProgram program) {
    final isAlgo = (widget.item.asset?.id ?? -1) == 0;
    final asaUnit = widget.item.asset?.unit ?? '';
    final decimals = widget.item.asset?.decimals ?? 0;
    final progType = program.program?.type;
    final progName = program.program?.name;
    final progCode = program.program?.code;
    final progUrl = program.program?.url;
    final progValue = program.value ?? 0.0;
    final progAmount = program.amount;

    // The value line: shown for every program. In ALGO mode (currency
    // toggle), display value in ALGO; in USD mode, divide by priceusdc.
    final isCurrencyAlgo =
        Provider.of<AppSettingProvider>(context).currency == Currency.algo;
    final displayValue = isCurrencyAlgo
        ? progValue
        : progValue / (widget.total?.priceusdc ?? 1.0);
    final displayUnit = isCurrencyAlgo ? 'ALGO' : 'USD';

    final rows = <Widget>[];

    // 1. The program value (always present).
    rows.add(Text(
      '${displayValue.toStringAsFixed(2)} $displayUnit',
      textAlign: TextAlign.end,
      style: TextStyle(
        color: ColorResources.themeTextColor(context),
        fontSize: Dimensions.FONT_SIZE_SMALL,
        fontWeight: FontWeight.w700,
        fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
      ),
    ));

    // 2. Program name+code link (or span when no URL).
    if (progName != null) {
      final label = progCode != null ? '$progName $progCode' : progName;
      if (progUrl != null && progUrl.isNotEmpty) {
        rows.add(_linkRow(label, progUrl));
      } else {
        rows.add(_textRow(label));
      }
    } else if (progCode != null) {
      // Edge case: code without a name — render as plain text.
      rows.add(_textRow(progCode));
    }

    // 3. Per-linked rows. Mirrors the website template's `{% for ld
    // in prog.linked %}` block. We filter out "Source LP token" rows
    // — those are an internal program-state marker the website and old
    // mobile app never rendered (they appear in v2 because the v2
    // serializer exposes the raw linked-data list, and the website
    // template happens to skip them). Match by exact text.
    for (final ld in program.linked) {
      if (ld.text == 'Source LP token') continue;
      rows.add(_linkedRow(ld, decimals, asaUnit, isAlgo: isAlgo));
    }

    // 4. Balance/amount line for non-ALGO assets with a program amount.
    // Rendered LAST (after the linked rows) — matches the v1 mobile
    // app's layout where the amount line appeared at the bottom of the
    // program block. For an "Added Liquidity" program the line reads
    // "Added: 1.134959 EURS"; for a "Balance" program "Balance: 0.4 X".
    //
    // Phase 5c-fixes / M4 — the "Balance:" label specifically gets a
    // green background (``ColorResources.primaryColor``), matching the
    // old version. ``Balance`` is the key value users look for, so the
    // visual cue draws attention. Other program types (Added, Locked,
    // Deposited, etc.) render with no background.
    if (!isAlgo && progAmount != null && progAmount > 0 && progType != null) {
      final formatted = AppConstants.formateNumber(
        double.parse(formateAmount(progAmount, decimals, 6)),
        points: '000000',
      );
      if (progType == 'Balance') {
        rows.add(_balanceRow(formatted, asaUnit));
      } else {
        rows.add(_textRow('$progType: $formatted $asaUnit'));
      }
    }

    // 5. Per-program price line (Phase 5c-fixes / M3) — mirrors the
    // website's ``<span class="price">`` row that appears under each
    // distribution and balance row, e.g. "1,240.85 ALGO/GOLD$" for a
    // Balance program. The displayed value is ``item.price`` (ALGO per
    // 1 unit of asset). Distribution-row prices are rendered separately
    // by ``DistributorWidgetV2`` (inverted form: ``USDC/ALGO``).
    //
    // We render this only for the Balance program here — other programs
    // (Added, Locked, etc.) get the inverted form via the distribution
    // sub-rows, which already include the price line. Skipped for ALGO
    // itself ("1 ALGO/ALGO" is meaningless) and when price is 0/null.
    if (progType == 'Balance' &&
        !isAlgo &&
        (widget.item.price ?? 0.0) > 0 &&
        asaUnit.isNotEmpty) {
      final price = widget.item.price!;
      rows.add(_textRow(
          '${AppConstants.formateNumber(price, points: '00000000')} ALGO/$asaUnit'));
    }

    return rows;
  }

  /// Balance row with a green ``Balance:`` label (M4). The amount
  /// portion is plain. Renders as a single ``RichText`` so the green
  /// background hugs only the "Balance:" text.
  Widget _balanceRow(String formatted, String asaUnit) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        textAlign: TextAlign.end,
        text: TextSpan(
          children: [
            TextSpan(
              text: ' Balance: ',
              style: TextStyle(
                color: ColorResources.whiteColor,
                backgroundColor: ColorResources.primaryColor,
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w700,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
            ),
            TextSpan(
              text: ' $formatted $asaUnit',
              style: TextStyle(
                color: ColorResources.themeTextColor(context),
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(String label, String url) {
    return GestureDetector(
      onTap: () => launchURLApp(url),
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          label,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: ColorResources.primaryColor,
            fontSize: Dimensions.FONT_SIZE_SMALL,
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
          ),
        ),
      ),
    );
  }

  Widget _textRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
          fontSize: Dimensions.FONT_SIZE_SMALL,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
        ),
      ),
    );
  }

  /// Render one ``LinkedData`` entry — text (linked or plain), optional
  /// value (with ``info`` suffix), optional amount in parentheses.
  Widget _linkedRow(v2.LinkedData ld, int decimals, String asaUnit,
      {required bool isAlgo}) {
    final text = ld.text ?? '';
    final hasLink = ld.link != null && ld.link!.isNotEmpty;

    // Build the suffix: " value info" or just " value" or empty.
    final parts = <InlineSpan>[];
    if (ld.value != null) {
      final valueStr = ld.value!.toStringAsFixed(6);
      final info = ld.info != null && ld.info!.isNotEmpty ? ' ${ld.info}' : '';
      parts.add(TextSpan(
        text: ': $valueStr$info',
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
        ),
      ));
    }
    if (ld.amount != null) {
      final amountStr = AppConstants.formateNumber(
        double.parse(formateAmount(ld.amount!, decimals, 6)),
        points: '000000',
      );
      parts.add(TextSpan(
        text: ' ($amountStr $asaUnit)',
        style: TextStyle(
          color: ColorResources.themeTextColor(context),
        ),
      ));
    }

    final textStyle = TextStyle(
      color: hasLink
          ? ColorResources.primaryColor
          : ColorResources.themeTextColor(context),
      fontSize: Dimensions.FONT_SIZE_SMALL,
      fontWeight: FontWeight.w600,
      fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        textAlign: TextAlign.end,
        text: TextSpan(
          text: text,
          style: textStyle,
          recognizer: hasLink
              ? (TapGestureRecognizer()..onTap = () => launchURLApp(ld.link!))
              : null,
          children: parts,
        ),
      ),
    );
  }
}

/// Per-distribution sub-row. Same layout as the v1 ``DistributorWidget``
/// but reads from ``v2.Distribution`` / ``v2.UserAsaProgram`` /
/// ``v2.AsaItem`` directly. The v1 unit-toggle on
/// ``dapps.entries.price.unit`` is dropped because that field doesn't
/// exist in v2 (price is on the AsaItem itself, not per-program).
class DistributorWidgetV2 extends StatelessWidget {
  final v2.Distribution distributor;
  final v2.UserAsaProgram program;
  final v2.AsaItem item;
  final v2.Total? total;

  const DistributorWidgetV2({
    super.key,
    required this.distributor,
    required this.program,
    required this.item,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final asaUnit = item.asset?.unit ?? '';
    final decimals = item.asset?.decimals ?? 0;
    final isCurrencyAlgo =
        Provider.of<AppSettingProvider>(context).currency == Currency.algo;
    final priceusdc = total?.priceusdc ?? 1.0;
    final valueDisplay = (distributor.value ?? 1.0) /
        (isCurrencyAlgo ? 1.0 : priceusdc);
    final valueUnit = isCurrencyAlgo ? 'ALGO' : 'USD';
    final text = distributor.link?.text ?? '';
    final href = distributor.link?.url ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: text,
              style: const TextStyle(
                color: ColorResources.primaryColor,
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchURLApp(href),
              children: [
                TextSpan(
                  text: '  ${valueDisplay.toStringAsFixed(2)} $valueUnit',
                  style: TextStyle(
                    color: ColorResources.themeTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 7.h),
          if (distributor.amount != null)
            Text(
              '${AppConstants.formateNumber(
                double.parse(formateAmount(distributor.amount!, decimals, 6)),
                points: '000000',
              )} $asaUnit',
              style: TextStyle(
                color: ColorResources.themeTextColor(context),
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
            ),
          // Per-distribution price line. Phase 5c-fixes / M3 — mirrors
          // the website's ``<span class="price">`` row, e.g.
          // "0.10966392 USDC/ALGO". The numeric value is
          // ``1 / item.price``, formatted to 8 decimals; the unit is
          // "<asset_unit>/ALGO". Skipped for ALGO itself (price line
          // of 1 ALGO/ALGO is meaningless) and when price is null/zero.
          if ((item.price ?? 0.0) > 0 &&
              asaUnit.isNotEmpty &&
              asaUnit != 'ALGO') ...[
            SizedBox(height: 4.h),
            Text(
              '${AppConstants.formateNumber(1.0 / item.price!, points: '00000000')} $asaUnit/ALGO',
              style: TextStyle(
                color: ColorResources.themeTextColor(context),
                fontSize: Dimensions.FONT_SIZE_SMALL,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.FONT_FAMILY_OUTFIT,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
