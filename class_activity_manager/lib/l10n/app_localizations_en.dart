// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Class Activity Manager';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navModules => 'Modules';

  @override
  String get navDailyNotes => 'Daily Notes';

  @override
  String get navGroups => 'Groups';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navReports => 'Reports';

  @override
  String get navArchive => 'Archive';

  @override
  String get navSettings => 'Settings';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get understood => 'Understood';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get today => 'Today';

  @override
  String get configure => 'Configure';

  @override
  String get select => 'Select';

  @override
  String get clear => 'Clear';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get name => 'Name';

  @override
  String get code => 'Code';

  @override
  String get description => 'Description';

  @override
  String get notes => 'Notes';

  @override
  String get hours => 'Hours';

  @override
  String get totalHours => 'Total hours';

  @override
  String get duration => 'Duration';

  @override
  String get durationHours => 'Duration (hours)';

  @override
  String get date => 'Date';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get color => 'Color';

  @override
  String get status => 'Status';

  @override
  String get content => 'Content';

  @override
  String get objectives => 'Objectives';

  @override
  String get objectivesHint => 'one per line';

  @override
  String get officialReference => 'Official reference';

  @override
  String get language => 'Language';

  @override
  String get catalan => 'Català';

  @override
  String get english => 'English';

  @override
  String get academicYear => 'Academic year';

  @override
  String get academicYearName => 'Year name';

  @override
  String get academicYearNameHint => 'e.g. 2024-2025';

  @override
  String get createAcademicYear => 'Create academic year';

  @override
  String get editAcademicYear => 'Edit academic year';

  @override
  String get noAcademicYear => 'No academic year defined';

  @override
  String get vacationPeriods => 'Vacation periods';

  @override
  String get addVacationPeriod => 'Add period';

  @override
  String get editVacationPeriod => 'Edit period';

  @override
  String get noVacationPeriods => 'No vacation periods';

  @override
  String get recurringHolidays => 'Recurring holidays';

  @override
  String get addRecurringHoliday => 'Add holiday';

  @override
  String get editRecurringHoliday => 'Edit holiday';

  @override
  String get holidayMonth => 'Month';

  @override
  String get holidayDay => 'Day';

  @override
  String get holidayEnabled => 'Enabled';

  @override
  String get module => 'Module';

  @override
  String get modules => 'Modules';

  @override
  String get addModule => 'Add module';

  @override
  String get editModule => 'Edit module';

  @override
  String get deleteModule => 'Delete module';

  @override
  String deleteModuleConfirm(String name) {
    return 'Are you sure you want to delete the module \"$name\"?';
  }

  @override
  String get noModules => 'No modules';

  @override
  String get moduleCode => 'Module code';

  @override
  String get moduleCodeHint => 'e.g. MP06';

  @override
  String get moduleName => 'Module name';

  @override
  String get importFromCurriculum => 'Import from curriculum';

  @override
  String get ra => 'LO';

  @override
  String get ras => 'LOs';

  @override
  String get raFull => 'Learning Outcome';

  @override
  String get addRa => 'Add LO';

  @override
  String get editRa => 'Edit LO';

  @override
  String get deleteRa => 'Delete LO';

  @override
  String deleteRaConfirm(String code) {
    return 'Are you sure you want to delete the LO \"$code\"?';
  }

  @override
  String get noRas => 'No LOs';

  @override
  String get raCode => 'LO code';

  @override
  String get raCodeHint => 'e.g. LO1';

  @override
  String get raTitle => 'LO title';

  @override
  String get raSelectDates => 'Click to select date range';

  @override
  String get raNotScheduled => 'Not scheduled';

  @override
  String raActiveCount(int count) {
    return '$count active LOs';
  }

  @override
  String get evaluationCriteria => 'Evaluation criteria';

  @override
  String get addCriterion => 'Add criterion';

  @override
  String get editCriterion => 'Edit criterion';

  @override
  String get deleteCriterion => 'Delete criterion';

  @override
  String get noCriteria => 'No criteria';

  @override
  String get criterionCode => 'Criterion code';

  @override
  String get criterionCodeHint => 'e.g. EC1.1';

  @override
  String get group => 'Group';

  @override
  String get groups => 'Groups';

  @override
  String get addGroup => 'Add group';

  @override
  String get editGroup => 'Edit group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String deleteGroupConfirm(String name) {
    return 'Are you sure you want to delete the group \"$name\"?';
  }

  @override
  String get noGroups => 'No groups';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'e.g. DAW1-A';

  @override
  String get groupColor => 'Group color';

  @override
  String get groupColorHint => 'Select a color to identify the group';

  @override
  String get groupModules => 'Group modules';

  @override
  String get noModulesAssigned => 'No modules assigned';

  @override
  String get assignModule => 'Assign module';

  @override
  String get unassignModule => 'Unassign module';

  @override
  String get dailyNote => 'Daily note';

  @override
  String get dailyNotes => 'Daily notes';

  @override
  String get addDailyNote => 'Add note';

  @override
  String get editDailyNote => 'Edit note';

  @override
  String get deleteDailyNote => 'Delete note';

  @override
  String get noDailyNotes => 'No daily notes';

  @override
  String get plannedContent => 'Planned content';

  @override
  String get plannedContentHint => 'What is planned for today?';

  @override
  String get actualContent => 'Actual content';

  @override
  String get actualContentHint => 'What was actually covered?';

  @override
  String get sessionNotes => 'Session notes';

  @override
  String get completed => 'Completed';

  @override
  String get goToDailyNotes => 'Go to daily notes';

  @override
  String get selectGroup => 'Select a group';

  @override
  String get selectModule => 'Select a module';

  @override
  String get selectRa => 'Select a LO';

  @override
  String get selectDate => 'Select a date';

  @override
  String get selectDates => 'Select dates';

  @override
  String get selectColor => 'Select a color';

  @override
  String get noSessionsScheduled => 'No sessions scheduled';

  @override
  String get noSessionsToday => 'No sessions today';

  @override
  String get sessionsToday => 'Today\'s sessions';

  @override
  String get upcomingSessions => 'Upcoming sessions';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeMessage => 'Class Activity Manager';

  @override
  String get quickStats => 'Quick stats';

  @override
  String get totalModules => 'Total modules';

  @override
  String get totalGroups => 'Total groups';

  @override
  String get activeRas => 'Active LOs';

  @override
  String get calendar => 'Calendar';

  @override
  String get weekdayMon => 'Monday';

  @override
  String get weekdayTue => 'Tuesday';

  @override
  String get weekdayWed => 'Wednesday';

  @override
  String get weekdayThu => 'Thursday';

  @override
  String get weekdayFri => 'Friday';

  @override
  String get weekdaySat => 'Saturday';

  @override
  String get weekdaySun => 'Sunday';

  @override
  String get weekdayMonShort => 'Mon';

  @override
  String get weekdayTueShort => 'Tue';

  @override
  String get weekdayWedShort => 'Wed';

  @override
  String get weekdayThuShort => 'Thu';

  @override
  String get weekdayFriShort => 'Fri';

  @override
  String get weekdaySatShort => 'Sat';

  @override
  String get weekdaySunShort => 'Sun';

  @override
  String get syncStatusOnline => 'Online';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String syncStatusPending(int count) {
    return '$count pending';
  }

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeMessage => 'The app works without MongoDB connection';

  @override
  String get connectionError => 'Connection error';

  @override
  String get conflictVersionMismatch =>
      'Data was modified from another device. Your changes were not saved.';

  @override
  String get conflictDeleted => 'The item was deleted from another device.';

  @override
  String get deleteConfirmTitle => 'Confirm deletion';

  @override
  String get deleteConfirmMessage => 'This action cannot be undone.';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get error => 'Error';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try again';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get dateRangeInvalid => 'End date cannot be before start date';

  @override
  String get setupCurriculum => 'Setup curriculum';

  @override
  String get importCurriculum => 'Import curriculum';

  @override
  String get selectCycles => 'Select cycles';

  @override
  String get cycle => 'Cycle';

  @override
  String get cycles => 'Cycles';

  @override
  String get tasks => 'Tasks';

  @override
  String get noTasks => 'No tasks';

  @override
  String get reports => 'Reports';

  @override
  String get noReports => 'No reports';

  @override
  String get archive => 'Archive';

  @override
  String get noArchive => 'No archived items';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get featureNotImplemented => 'This feature is not yet implemented';
}
