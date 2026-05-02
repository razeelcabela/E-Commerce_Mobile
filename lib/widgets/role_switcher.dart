import 'package:flutter/material.dart';
import '../services/unified_auth_service.dart';

/// Compact role switcher for users with multiple roles
class RoleSwitcher extends StatelessWidget {
  final List<UnifiedAuthService.UserRole> availableRoles;
  final UnifiedAuthService.UserRole currentRole;
  final Function(UnifiedAuthService.UserRole) onRoleChanged;

  const RoleSwitcher({
    super.key,
    required this.availableRoles,
    required this.currentRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableRoles.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableRoles.map((role) {
          final isSelected = role == currentRole;
          return GestureDetector(
            onTap: () => onRoleChanged(role),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0A0A0A) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Dialog version of role switcher for more prominent role selection
class RoleSwitcherDialog extends StatelessWidget {
  final List<UnifiedAuthService.UserRole> availableRoles;
  final UnifiedAuthService.UserRole currentRole;
  final Function(UnifiedAuthService.UserRole) onRoleChanged;

  const RoleSwitcherDialog({
    super.key,
    required this.availableRoles,
    required this.currentRole,
    required this.onRoleChanged,
  });

  static Future<void> show(
    BuildContext context,
    List<UnifiedAuthService.UserRole> availableRoles,
    UnifiedAuthService.UserRole currentRole,
    Function(UnifiedAuthService.UserRole) onRoleChanged,
  ) {
    return showDialog(
      context: context,
      builder: (context) => RoleSwitcherDialog(
        availableRoles: availableRoles,
        currentRole: currentRole,
        onRoleChanged: onRoleChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'SWITCH ROLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: 24,
              height: 1.5,
              color: const Color(0xFF0A0A0A),
            ),

            const SizedBox(height: 16),

            const Text(
              'Choose how you want to use Varón',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Role options
            ...availableRoles.map((role) {
              final isSelected = role == currentRole;
              return GestureDetector(
                onTap: () {
                  onRoleChanged(role);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getRoleIcon(role),
                        color: isSelected ? Colors.white : const Color(0xFF666666),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        role.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF0A0A0A),
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UnifiedAuthService.UserRole role) {
    switch (role) {
      case UnifiedAuthService.UserRole.buyer:
        return Icons.shopping_bag_outlined;
      case UnifiedAuthService.UserRole.seller:
        return Icons.storefront_outlined;
      case UnifiedAuthService.UserRole.rider:
        return Icons.delivery_dining;
      case UnifiedAuthService.UserRole.none:
        return Icons.person_outline;
    }
  }
}