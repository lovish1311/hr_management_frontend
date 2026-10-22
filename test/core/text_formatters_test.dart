import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/core/utils/text_formatters.dart';

void main() {
  group('TextFormatter Production Unit Tests', () {
    test('formatRole formats technical IAM and custom roles', () {
      expect(TextFormatter.formatRole('ROLE_SUPER_ADMIN'), 'Super Admin');
      expect(TextFormatter.formatRole('SUPER_ADMIN'), 'Super Admin');
      expect(TextFormatter.formatRole('ROLE_HR_ADMIN'), 'HR Admin');
      expect(TextFormatter.formatRole('HR'), 'HR Admin');
      expect(TextFormatter.formatRole('ROLE_MANAGER'), 'Manager');
      expect(TextFormatter.formatRole('ROLE_EMPLOYEE'), 'Employee');
      expect(TextFormatter.formatRole(''), 'Employee');
      expect(TextFormatter.formatRole(null), 'Employee');
      expect(TextFormatter.formatRole('SENIOR_SOFTWARE_ENGINEER'), 'Senior Software Engineer');
      expect(TextFormatter.formatRole('POWER_BI_DEVELOPER'), 'Power BI Developer');
    });

    test('formatStatus formats status enums', () {
      expect(TextFormatter.formatStatus('ON_LEAVE'), 'On Leave');
      expect(TextFormatter.formatStatus('WORK_FROM_HOME'), 'Work From Home');
      expect(TextFormatter.formatStatus('WFH'), 'Work From Home');
      expect(TextFormatter.formatStatus('IN_OFFICE'), 'In Office');
      expect(TextFormatter.formatStatus('PENDING_APPROVAL'), 'Pending Approval');
      expect(TextFormatter.formatStatus('PENDING_ACTIVATION'), 'Pending Activation');
      expect(TextFormatter.formatStatus('DEACTIVATED'), 'Deactivated');
    });

    test('formatLeaveType formats leave types correctly', () {
      expect(TextFormatter.formatLeaveType('CASUAL_LEAVE'), 'Casual Leave');
      expect(TextFormatter.formatLeaveType('SICK_LEAVE'), 'Sick Leave');
      expect(TextFormatter.formatLeaveType('EARNED_LEAVE'), 'Earned Leave');
      expect(TextFormatter.formatLeaveType('COMP_OFF'), 'Compensatory Off');
      expect(TextFormatter.formatLeaveType('LOSS_OF_PAY'), 'Loss of Pay');
      expect(TextFormatter.formatLeaveType('LOP'), 'Loss of Pay');
      expect(TextFormatter.formatLeaveType('RESTRICTED_HOLIDAY'), 'Restricted Holiday');
      expect(TextFormatter.formatLeaveType('GENERAL_HOLIDAY'), 'General Holiday');
    });

    test('formatGreeting creates time-sensitive personalized greetings', () {
      final greeting = TextFormatter.formatGreeting('Lovish Kumar');
      expect(greeting, matches(r'Good (Morning|Afternoon|Evening), Lovish 👋'));

      final anonymous = TextFormatter.formatGreeting(null);
      expect(anonymous, matches(r'Good (Morning|Afternoon|Evening) 👋'));
    });

    test('formatDate generates dynamic human readable date string', () {
      final date = DateTime(2026, 10, 21); // Wednesday
      expect(TextFormatter.formatDate(date), 'Wednesday, Oct 21');
      expect(TextFormatter.formatDate(date, includeYear: true), 'Wednesday, Oct 21, 2026');
      expect(TextFormatter.formatDate(date, includeWeekday: false), 'Oct 21');
    });
  });
}
