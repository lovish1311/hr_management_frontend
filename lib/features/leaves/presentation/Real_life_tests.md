### Intra-Day Permissions, Standing Tolerances & Punch Thresholds

#### Test Case 1: Standing Profile Exemption — Timely Punch-in Within Standing Exemption Window

* **Preconditions:** An employee has a permanent standing exemption configured on their profile: `lateArrivalAllowedUntil = 12:00 PM` (universal company cutoff is 10:15 AM).


* **Action:** The employee checks in at 11:40 AM and punches out at 7:15 PM.
* **Expected Result:** The biometric engine logs the raw machine punch timestamp (11:40 AM). Because 11:40 AM is on or before the employee's standing cutoff of 12:00 PM, attendance status is stamped as `PRESENT` with status label `"Present (Late Exemption Granted)"`. No late penalty is incurred, and no leave balance is deducted.



#### Test Case 2: Standing Profile Exemption Breached

* **Preconditions:** An employee has a standing exemption of `lateArrivalAllowedUntil = 12:00 PM`.


* **Action:** The employee checks in at 12:15 PM and works until 7:00 PM.
* **Expected Result:** The machine records the 12:15 PM check-in. Because 12:15 PM exceeds their custom 12:00 PM threshold, the system evaluates the breach against standard shift rules and stamps attendance status as `LATE` with status label `"Late Arrival (12:15 PM)"`.



#### Test Case 3: Pre-Approved Ad-Hoc Late Arrival Permission Satisfied

* **Preconditions:** An employee without profile exemptions applies for and receives manager approval for a one-time "Late Arrival" permission from 10:00 AM to 12:00 PM (120 minutes).


* **Action:** The employee punches in at 11:55 AM (5 minutes before the approved window closes) and works until 7:00 PM.
* **Expected Result:** The leave engine consumes 1 unit of the employee’s monthly permission quota with server-side `totalDays = 0.0` (zero leave balance deducted). The attendance engine identifies the active permission covering 10:00 AM to 12:00 PM and marks the arrival as authorized, preventing a `LATE` flag.



#### Test Case 4: Pre-Approved Late Arrival Permission Arriving Past Approved Window

* **Preconditions:** An employee has an approved "Late Arrival" permission from 10:00 AM to 12:00 PM.


* **Action:** The employee punches in at 12:20 PM (20 minutes after the permission window expired) and works until 7:00 PM.
* **Expected Result:** The leave system records the 120-minute permission. However, because the punch occurred at 12:20 PM without an active pass covering 12:00 PM to 12:20 PM and well past the standard 10:15 AM grace threshold, the attendance import engine flags the punch as `LATE` (reporting 20 minutes of unauthorized tardiness past the approved pass).



#### Test Case 5: Mid-Shift Short Break Duration Exceeded on Machine Punches

* **Preconditions:** An employee has an approved mid-shift "Short Break" pass from 11:30 AM to 1:30 PM (120 minutes).


* **Action:** The employee punches out at 11:30 AM but punches back in at 2:05 PM (break duration = 2 hours 35 minutes, exceeding the approved window by 35 minutes).
* **Expected Result:** The leave pass remains recorded at `totalDays = 0.0`. The biometric engine deducts the unexcused 35 minutes alongside the mandatory lunch window (2:00 PM to 3:00 PM). Because effective working hours fall between 4.0 and 7.9 hours, daily attendance evaluates to `HALF_DAY` with an audit flag indicating short hours.



#### Test Case 6: Standing Early Out Exemption Respected vs. Breached

* **Preconditions:** An employee profile has `earlyOutAllowedAfter = 05:00 PM` (universal shift conclusion is 07:00 PM).


* **Action A:** The employee punches out at 5:10 PM.
* **Expected Result A:** The engine verifies 5:10 PM is after 5:00 PM. Attendance status is stamped as `PRESENT` with status label `"Present (Early Out Exemption Granted)"`.


* **Action B:** The employee punches out at 4:45 PM.
* **Expected Result B:** 4:45 PM is before the allowed 5:00 PM cutoff. Attendance status is stamped as `LATE` with status label `"Left Early (04:45 PM)"`.



#### Test Case 7: Intra-Day Permission 120-Minute Hard Ceiling Enforcement

* **Preconditions:** An employee attempts to apply for a personal errand pass from 1:00 PM to 3:30 PM (150 minutes).
* **Action:** Submit request through API or mobile interface.
* **Expected Result:** `ShortLeaveQuotaRule` intercepts the application. The system throws an HTTP 400 Bad Request: `"Intra-day permission duration cannot exceed 2 hours (120 minutes). Requested: 150 minutes."` No record is persisted to the database.



#### Test Case 8: Monthly Free Permission Unit Ceiling Exhaustion

* **Preconditions:** Admin settings specify `UNITWISE` policy with a limit of 2 free permission units per month. The employee already has 2 approved permissions in the current month.


* **Action:** The employee attempts to submit a 3rd short break pass on the 26th of the month.
* **Expected Result:** `LeaveService.validateTimeBasedPolicy` queries `countTimeBasedRequestsInCycle`. Because existing units count equals the limit of 2, submission is blocked with: `"Short break limit reached (2 per monthly). Used: 2"`.



---

### Dual Half-Days, Session Splitting & Granular Coexistence

#### Test Case 9: Same-Day Dual Half-Day Coexistence (Morning CL + Afternoon Sick Leave)

* **Preconditions:** An employee has available Casual Leave (CL) and Sick Leave (SL) balances.


* **Action:** The employee applies for a Session 1 (Morning: 10:00 AM – 2:00 PM) Casual Leave on Oct 20. Later, they apply for a Session 2 (Afternoon: 3:00 PM – 7:00 PM) Sick Leave on the exact same date.


* **Expected Result:** `SessionOverlapRule` inspects slot occupancy (`occupiesSession1` and `occupiesSession2`). Because Session 1 and Session 2 do not occupy overlapping operational hours, both requests pass validation without clashing. Upon approval, CL used increments by 0.5 and SL used increments by 0.5.



#### Test Case 10: Same-Day Session Collision (Full Day Clashing with Existing Morning Half-Day)

* **Preconditions:** An employee has a pending or approved leave for Oct 20 covering Session 1 (Morning).


* **Action:** The employee attempts to submit a Full-Day leave request (or another Session 1 request) for Oct 20.
* **Expected Result:** `SessionOverlapRule` identifies that both requests occupy Session 1. Validation throws `IllegalStateException`: `"Leave conflict on 2026-10-20: You already have an active request covering Session 1 (Morning)."`



#### Test Case 11: Invalid Chronological Session Boundaries on Single-Day Leave

* **Preconditions:** An employee applies for a single-day leave on Nov 12.
* **Action:** The employee sets `startSession = SESSION_2` and `endSession = SESSION_1` for the same date.


* **Expected Result:** The server-authoritative `computeTotalDays` evaluates the invalid chronological sequence (starting in the afternoon and ending in the morning of the same day) and resolves `totalDays = 0.0`, preventing negative or corrupted deductions.



#### Test Case 12: Multi-Day Combined Session Boundary Calculation

* **Preconditions:** Shift schedule runs Monday through Friday.


* **Action:** An employee applies for leave from Wednesday Session 2 (Afternoon) to Friday Session 1 (Morning).
* **Expected Result:** `computeTotalDays` evaluates raw calendar duration (3 days: Wed, Thu, Fri). Starting Wed afternoon subtracts 0.5 day (morning worked); ending Fri morning subtracts 0.5 day (afternoon worked). Total leave duration authoritatively resolves to `2.0 days`.



---

### Weekend Sandwich Rules, Public Holidays & Accrual Rules

#### Test Case 13: Corporate Sandwich Rule Enforcement on Weekend Spans

* **Preconditions:** Saturday and Sunday are declared non-working weekend days.
* **Action:** An employee applies for Earned Leave from Friday (Full Day) to Monday (Full Day).
* **Expected Result:** `computeTotalDays` evaluates `ChronoUnit.DAYS.between(Friday, Monday) + 1 = 4.0`. Under standard corporate sandwich rule policy, the weekend enclosed between two active leave days is counted as part of the continuous absence, deducting a total of `4.0 days` from the employee’s balance.



#### Test Case 14: Collision with Declared Official General Holiday

* **Preconditions:** October 26 is declared an official general public holiday in `HolidayRepository`.


* **Action:** An employee attempts to apply for Casual Leave for a single day on October 26.
* **Expected Result:** `HolidayLeavePolicyRule` identifies that `startDate.equals(endDate)` matches an active general holiday and throws `IllegalArgumentException`: `"2026-10-26 is already an official company holiday (...). Leave application is not required."`


#### Test Case 15: Restricted Holiday (RH) Guardrails: Multi-Day and Unmatched Date

* **Preconditions:** The company holiday catalog lists Govardhan Puja on Nov 12 as an active Restricted Holiday.


* **Action A:** An employee attempts to book an RH spanning Nov 12 to Nov 13.


* **Expected Result A:** Blocked with `IllegalArgumentException: "A Restricted Holiday can only be applied for a single specific date."`

* **Action B:** An employee attempts to book an RH on Nov 14 (a date not in the published RH catalog).


* **Expected Result B:** Blocked with `IllegalArgumentException: "No active restricted holiday is configured on 2026-11-14."`

* **Action C:** An employee books an RH on Nov 12 (matching catalog date).


* **Expected Result C:** Accepted, validated for single-day duration (1.0 day), and deducts from the 2.0 RH annual entitlement upon approval.



#### Test Case 16: Probation Period Block on Earned Leave (EL)

* **Preconditions:** An employee profile has `status = "PROBATION"`.


* **Action:** The employee attempts to submit an application for 1.0 day of Earned Leave.


* **Expected Result:** `LeaveAccrualService` sets `earnedLeaveQuota = 0.0`. When the employee attempts to apply, `QuotaValidationRule` checks `employee.getStatus()` and throws `IllegalStateException: "Earned Leave is strictly blocked during probation period."`



#### Test Case 17: Mid-Year Hire Pro-Rata Accrual (15th-Day Cutoff Rule)

* **Preconditions:** Annual Casual Leave quota is 6.0 days.


* **Action A:** Employee A joins on March 14, 2026 (on or before the 15th).


* **Expected Result A:** March counts as an eligible worked month (10 eligible months). Quota calculates as `(6.0 / 12) * 10 = 5.0 days`.


* **Action B:** Employee B joins on March 16, 2026 (after the 15th).


* **Expected Result B:** Accrual begins from April (9 eligible months). Quota calculates as `(6.0 / 12) * 9 = 4.5 days`.



---

### Carryover Lifecycles, Expiration & Priority Deductions

#### Test Case 18: Post-March 31 FIFO Priority Earned Leave Consumption

* **Preconditions:** An employee has 5.0 days of carried-forward EL (expiring March 31) and 6.0 days of current-year EL quota.


* **Action A:** The employee applies for 3.0 days of EL for dates in February (prior to expiry).


* **Expected Result A:** `deductEarnedLeaveWithPriority` consumes from unexpired carried-forward quota first (`carriedForwardLeaveUsed = 3.0`, remaining CF = 2.0, current-year used = 0.0).


* **Action B:** The employee applies for 3.0 days of EL for dates in May (after March 31 expiry).


* **Expected Result B:** `deductEarnedLeaveWithPriority` detects `startDate.isAfter(expiryDate)` and deducts strictly from current-year quota (`earnedLeaveUsed = 3.0`), preventing utilization of expired carryover.



#### Test Case 19: Reversal and Refund of Approved Leave with Expired Carryover

* **Preconditions:** An employee utilized 2.0 days of carried-forward EL for a February vacation. In May (after carryover has officially expired), that approved leave is administratively cancelled.


* **Action:** Execute leave cancellation.
* **Expected Result:** `refundEarnedLeaveWithPriority` checks `isCarriedForwardCurrentlyExpired()`. Because carryover has passed its expiry threshold, the refund restores current-year balance first to prevent valid days from lapsing into an expired bucket.



#### Test Case 20: Work From Home (WFH) Cumulative Negative Balance Counter

* **Preconditions:** An employee has baseline WFH quota initialized at 0.0.


* **Action:** The employee applies for 2 consecutive days of WFH, and the manager approves.


* **Expected Result:** WFH approval does not reduce paid time-off quotas. The display balance calculates via `getWorkFromHomeRemaining()` returning `-2.0` (tracking availed remote duty days). Daily attendance records are set to `PRESENT (WFH)` with zero payroll deduction.



---

### State Machine Security, Two-Phase Cancellations & Access Controls

#### Test Case 21: Anti-Fraud Two-Phase Cancellation of Approved Leaves (Employee Self-Cancel)

* **Preconditions:** An employee took an approved 3-day Casual Leave last week (leave status is `APPROVED`).


* **Action:** The employee calls `PUT /api/v1/leaves/{id}/cancel` through the mobile app.


* **Expected Result:** Because the caller is a standard employee and the leave is already `APPROVED`, the system refuses immediate balance refund. Status transitions to `CANCEL_REQUESTED`, the cancellation reason is appended, and the item routes to the manager’s review queue.



#### Test Case 22: Manager Adjudication of CANCEL_REQUESTED (Approved vs. Rejected)

* **Preconditions:** A leave request sits in `CANCEL_REQUESTED` status.


* **Action A:** The manager approves the cancellation (`status = "CANCELLED"`).


* **Expected Result A:** The dedicated adjudication block triggers `refundApprovedLeaveDays()`, restores balance, sets terminal status to `CANCELLED`, and fires `LeaveWithdrawnEvent` to clear attendance records.


* **Action B:** The manager rejects the cancellation request (`status = "APPROVED"`).


* **Expected Result B:** Status returns to `APPROVED`, rejection reason is logged, and balance deduction logic is completely skipped (preventing double-deduction).



#### Test Case 23: Terminal State Immobility (Blocking Resurrection of Dead Requests)

* **Preconditions:** A leave request was previously rejected or cancelled (`status = "CANCELLED"` or `"REJECTED"`).


* **Action:** An administrative user calls `PUT /api/v1/leaves/{id}/status` passing `status = "APPROVED"`.


* **Expected Result:** `updateStatus` identifies that `previousStatus` is terminal and throws `IllegalStateException: "Cannot change status of a leave request that is already in terminal state: CANCELLED"`.



#### Test Case 24: Strict Anti-Self-Approval Enforcement

* **Preconditions:** A Reporting Manager or System Administrator applies for 2 days of leave.


* **Action:** The manager attempts to call `PUT /api/v1/leaves/{id}/status` to approve their own request using their authenticated account.


* **Expected Result:** The service checks `actor.getId().equals(targetEmployee.getId())` and throws `AccessDeniedException: "Cannot approve or reject your own leave request."`


#### Test Case 25: Admin Proxy Application ("Apply On Behalf") for Dynamic Quotas

* **Preconditions:** An employee has 1.0 day of granted `COMP_OFF` in `EmployeeLeaveQuota` and 6.0 days of Casual Leave.


* **Action:** HR Admin uses `POST /admin/apply-on-behalf` to log 1.0 day of Comp-Off for the employee.


* **Expected Result:** `applyOnBehalfByHr` acquires a pessimistic lock on `EmployeeLeaveQuota`, increments `used` on the Comp-Off record to 1.0, and marks the request as `APPROVED`. The employee's Casual Leave balance remains untouched.



#### Test Case 26: Attendance Tracking Exemption Profile Upload

* **Preconditions:** An executive profile has `isAttendanceTracked = false`.


* **Action:** A daily biometric Excel file is imported with zero punch records for this executive.


* **Expected Result:** The import engine matches the employee by machine alias. Recognizing `isAttendanceTracked == false`, attendance status is stamped as `EXEMPT` with status label `"Tracking Disabled"`. The executive is omitted from absent counts and incurs 0.0 Loss of Pay (LOP) days.



#### Test Case 27: Concurrent Double-Click Overdraw Race Condition

* **Preconditions:** An employee has exactly 1.0 day of Casual Leave remaining.


* **Action:** The employee opens two browser tabs and submits two distinct 1.0-day leave requests simultaneously at the same millisecond.


* **Expected Result:** Thread A acquires the PostgreSQL pessimistic write lock (`findByEmployeeIdAndYearForUpdate`) first. Thread A validates balance, creates pending buffer (pending = 1.0, available = 0.0), and commits. When Thread B acquires the lock, it queries the updated row, detects 0.0 available balance, and throws `IllegalStateException: "Insufficient leave balance (including pending requests). Effective Available: 0.0 days."`



#### Test Case 28: Cross-Year Boundary Split Enforcement

* **Preconditions:** An employee plans an extended holiday break from Dec 29, 2026, to Jan 4, 2027.


* **Action:** The employee submits a single leave request spanning both years.


* **Expected Result:** `applyForLeave` compares `startDate.getYear() != endDate.getYear()` and rejects the payload with `IllegalArgumentException: "Leave requests cannot span across calendar years (Dec 31 / Jan 1). Please submit two separate requests for each respective year."`