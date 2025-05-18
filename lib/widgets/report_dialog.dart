import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../providers/riverpod/auth_provider.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String roomId;
  final String? messageId;

  const ReportDialog({
    super.key,
    required this.roomId,
    this.messageId,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final _reasonController = TextEditingController();
  String _selectedReason = '';
  bool _isSubmitting = false;
  
  final List<String> _predefinedReasons = [
    'Inappropriate content',
    'Harassment or bullying',
    'Spam',
    'Hate speech',
    'Illegal activity',
    'Personal information sharing',
    'Other (please specify)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = _predefinedReasons.first;
  }

  Future<void> _submitReport() async {
    if (_selectedReason.isEmpty && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or provide a reason')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to report')),
        );
        Navigator.pop(context);
        return;
      }
      
      final reason = _selectedReason == 'Other (please specify)'
          ? _reasonController.text.trim()
          : _selectedReason;
          
      final chatService = ref.read(chatServiceProvider);
      
      if (widget.messageId != null) {
        // Report a specific message
        await chatService.reportMessage(
          widget.roomId,
          widget.messageId!,
          user.uid,
          reason,
        );
      } else {
        // Report the entire chat room
        await chatService.reportChatRoom(
          widget.roomId,
          user.uid,
          reason,
        );
      }
      
      // Close the dialog
      if (mounted) {
        Navigator.pop(context, true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your report. Our team will review it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.messageId != null ? 'Report Message' : 'Report Chat Room'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select a reason for your report:'),
            const SizedBox(height: 16),
            
            ...List.generate(_predefinedReasons.length, (index) {
              final reason = _predefinedReasons[index];
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value!;
                  });
                },
              );
            }),
            
            if (_selectedReason == 'Other (please specify)')
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                child: TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
} 