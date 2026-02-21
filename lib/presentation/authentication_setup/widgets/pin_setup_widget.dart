import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// PIN Setup Widget
/// Handles PIN creation and confirmation with secure input
class PinSetupWidget extends StatefulWidget {
  final Function(String) onPinSetup;
  final bool isPinSetupComplete;

  const PinSetupWidget({
    super.key,
    required this.onPinSetup,
    required this.isPinSetupComplete,
  });

  @override
  State<PinSetupWidget> createState() => _PinSetupWidgetState();
}

class _PinSetupWidgetState extends State<PinSetupWidget> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();

  bool _isExpanded = false;
  bool _isPinEntered = false;
  bool _showMismatchError = false;
  String _enteredPin = '';

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _handlePinComplete(String pin) {
    HapticFeedback.mediumImpact();
    setState(() {
      _enteredPin = pin;
      _isPinEntered = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _confirmPinFocusNode.requestFocus();
    });
  }

  void _handleConfirmPinComplete(String confirmPin) {
    HapticFeedback.mediumImpact();

    if (_enteredPin == confirmPin) {
      setState(() => _showMismatchError = false);
      widget.onPinSetup(_enteredPin);
      _pinFocusNode.unfocus();
      _confirmPinFocusNode.unfocus();
    } else {
      setState(() => _showMismatchError = true);
      HapticFeedback.heavyImpact();
      _confirmPinController.clear();
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _showMismatchError = false);
      });
    }
  }

  void _resetPin() {
    setState(() {
      _pinController.clear();
      _confirmPinController.clear();
      _isPinEntered = false;
      _showMismatchError = false;
      _enteredPin = '';
    });
    _pinFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.isPinSetupComplete
              ? null
              : () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isPinSetupComplete
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: widget.isPinSetupComplete
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomIconWidget(
                    iconName: widget.isPinSetupComplete
                        ? 'check_circle'
                        : 'pin',
                    color: widget.isPinSetupComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code PIN de secours',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.isPinSetupComplete
                            ? 'PIN configuré avec succès'
                            : 'Alternative à la biométrie',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.isPinSetupComplete
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isPinSetupComplete)
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        if (_isExpanded && !widget.isPinSetupComplete) ...[
          SizedBox(height: 3.h),
          _buildPinInput(theme),
        ],
      ],
    );
  }

  Widget _buildPinInput(ThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 14.w,
      height: 14.w,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error, width: 2),
      ),
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un code PIN',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Entrez un code PIN à 4 chiffres',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Center(
            child: Pinput(
              controller: _pinController,
              focusNode: _pinFocusNode,
              length: 4,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              obscureText: true,
              obscuringCharacter: '●',
              hapticFeedbackType: HapticFeedbackType.mediumImpact,
              onCompleted: _handlePinComplete,
              keyboardType: TextInputType.number,
            ),
          ),
          if (_isPinEntered) ...[
            SizedBox(height: 3.h),
            Text(
              'Confirmer le code PIN',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Entrez à nouveau votre code PIN',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            Center(
              child:
                  Pinput(
                        controller: _confirmPinController,
                        focusNode: _confirmPinFocusNode,
                        length: 4,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        errorPinTheme: errorPinTheme,
                        obscureText: true,
                        obscuringCharacter: '●',
                        hapticFeedbackType: HapticFeedbackType.mediumImpact,
                        onCompleted: _handleConfirmPinComplete,
                        keyboardType: TextInputType.number,
                        forceErrorState: _showMismatchError,
                      )
                      .animate(target: _showMismatchError ? 1 : 0)
                      .shake(duration: 500.ms, hz: 5),
            ),
            if (_showMismatchError) ...[
              SizedBox(height: 1.h),
              Center(
                child: Text(
                  'Les codes PIN ne correspondent pas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),
            ],
            SizedBox(height: 2.h),
            Center(
              child: TextButton.icon(
                onPressed: _resetPin,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  'Réinitialiser le PIN',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
