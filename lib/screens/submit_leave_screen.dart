import 'package:flutter/material.dart';
import 'package:teamio_hr/services/leave_service.dart';

class SubmitLeaveScreen extends StatefulWidget {
  final dynamic user;

  const SubmitLeaveScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SubmitLeaveScreen> createState() => _SubmitLeaveScreenState();
}

class _SubmitLeaveScreenState extends State<SubmitLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedType = 'Annual Leave';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _selectingStart = true;
  bool _isSubmitting = false;

  static const Color bgDark = Color(0xFF0B0E17);
  static const Color cardDark = Color(0xFF151A28);
  static const Color surfaceDark = Color(0xFF1E2538);
  static const Color accentPrimary = Color(0xFF38BDF8);

  final _leaveTypes = [
    {'label': 'Annual Leave', 'icon': Icons.beach_access_rounded},
    {'label': 'Sick Leave', 'icon': Icons.medical_services_rounded},
    {'label': 'Casual Leave', 'icon': Icons.coffee_rounded},
    {'label': 'Remote Work', 'icon': Icons.laptop_mac_rounded},
  ];

  String get _currentUserId {
    try {
      return widget.user.id.toString();
    } catch (_) {
      return widget.user.toString();
    }
  }

  String _formatShortDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _submitForm() async {
    debugPrint("SUBMIT TAPPED");
    debugPrint("USER ID = $_currentUserId");

    if (!_formKey.currentState!.validate()) {
      debugPrint("VALIDATION FAILED");
      return;
    }

    setState(() => _isSubmitting = true);

    String formattedRange = "${_formatShortDate(_startDate)} - ${_formatShortDate(_endDate)}";

    String? errorMessage = await LeaveService.submitLeaveRequest(
      userId: _currentUserId,
      type: _selectedType,
      dateRange: formattedRange,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text("Leave request submitted!", style: TextStyle(color: Colors.white)),
        ),
      );
      Navigator.pop(context, true); // Return true so LeavesScreen refreshes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFEF4444),
          content: Text(errorMessage),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = _endDate.difference(_startDate).inDays + 1;
    if (totalDays < 1) totalDays = 1;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Request Time Off",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$totalDays ${totalDays == 1 ? 'Day' : 'Days'}",
                style: const TextStyle(color: accentPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Leave Category Grid
            const Text("Leave Category", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _leaveTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 50,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, idx) {
                final item = _leaveTypes[idx];
                final label = item['label'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = _selectedType == label;

                return InkWell(
                  onTap: () => setState(() => _selectedType = label),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? accentPrimary.withOpacity(0.18) : cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentPrimary : Colors.white10,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: isSelected ? accentPrimary : Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // 2. From / To Date Cards
            const Text("Select Dates", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectingStart = true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectingStart ? accentPrimary.withOpacity(0.15) : cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectingStart ? accentPrimary : Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("FROM", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(_formatShortDate(_startDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white38, size: 18),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectingStart = false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: !_selectingStart ? accentPrimary.withOpacity(0.15) : cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_selectingStart ? accentPrimary : Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TO", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(_formatShortDate(_endDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Embedded Interactive Calendar
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: accentPrimary,
                    onPrimary: bgDark,
                    surface: cardDark,
                    onSurface: Colors.white,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selectingStart ? _startDate : _endDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (pickedDate) {
                    setState(() {
                      if (_selectingStart) {
                        _startDate = pickedDate;
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                        _selectingStart = false;
                      } else {
                        if (pickedDate.isBefore(_startDate)) {
                          _startDate = pickedDate;
                        } else {
                          _endDate = pickedDate;
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Reason Text Field
            const Text("Reason", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a short note or reason...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentPrimary),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? "Please enter a reason" : null,
            ),
            const SizedBox(height: 24),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPrimary,
                  foregroundColor: bgDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: bgDark),
                )
                    : const Text("Submit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}