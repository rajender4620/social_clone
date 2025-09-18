import 'package:flutter/material.dart';

class ProfileEditButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const ProfileEditButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
