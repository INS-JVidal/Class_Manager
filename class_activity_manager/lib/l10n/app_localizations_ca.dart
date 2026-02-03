// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Gestor d\'Activitats de Classe';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCalendar => 'Calendari';

  @override
  String get navModules => 'Mòduls';

  @override
  String get navDailyNotes => 'Notes diàries';

  @override
  String get navGroups => 'Grups';

  @override
  String get navTasks => 'Tasques';

  @override
  String get navReports => 'Informes';

  @override
  String get navArchive => 'Arxiu';

  @override
  String get navSettings => 'Configuració';

  @override
  String get save => 'Desa';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get delete => 'Elimina';

  @override
  String get add => 'Afegir';

  @override
  String get edit => 'Edita';

  @override
  String get close => 'Tanca';

  @override
  String get confirm => 'Confirmar';

  @override
  String get ok => 'D\'acord';

  @override
  String get understood => 'Entès';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get back => 'Enrere';

  @override
  String get next => 'Següent';

  @override
  String get today => 'Avui';

  @override
  String get configure => 'Configurar';

  @override
  String get select => 'Selecciona';

  @override
  String get clear => 'Neteja';

  @override
  String get search => 'Cerca';

  @override
  String get filter => 'Filtra';

  @override
  String get refresh => 'Actualitza';

  @override
  String get loading => 'Carregant...';

  @override
  String get loadingData => 'Carregant dades...';

  @override
  String get name => 'Nom';

  @override
  String get code => 'Codi';

  @override
  String get description => 'Descripció';

  @override
  String get notes => 'Notes';

  @override
  String get hours => 'Hores';

  @override
  String get totalHours => 'Total hores';

  @override
  String get duration => 'Durada';

  @override
  String get durationHours => 'Durada (hores)';

  @override
  String get date => 'Data';

  @override
  String get startDate => 'Data d\'inici';

  @override
  String get endDate => 'Data de fi';

  @override
  String get color => 'Color';

  @override
  String get status => 'Estat';

  @override
  String get content => 'Contingut';

  @override
  String get objectives => 'Objectius';

  @override
  String get objectivesHint => 'un per línia';

  @override
  String get officialReference => 'Referència oficial';

  @override
  String get language => 'Idioma';

  @override
  String get catalan => 'Català';

  @override
  String get english => 'English';

  @override
  String get academicYear => 'Curs acadèmic';

  @override
  String get academicYearName => 'Nom del curs';

  @override
  String get academicYearNameHint => 'p.ex. 2024-2025';

  @override
  String get createAcademicYear => 'Crear curs acadèmic';

  @override
  String get editAcademicYear => 'Editar curs acadèmic';

  @override
  String get noAcademicYear => 'Cap curs acadèmic definit';

  @override
  String get vacationPeriods => 'Períodes de vacances';

  @override
  String get addVacationPeriod => 'Afegir període';

  @override
  String get editVacationPeriod => 'Editar període';

  @override
  String get noVacationPeriods => 'Cap període de vacances';

  @override
  String get recurringHolidays => 'Festius recurrents';

  @override
  String get addRecurringHoliday => 'Afegir festiu';

  @override
  String get editRecurringHoliday => 'Editar festiu';

  @override
  String get holidayMonth => 'Mes';

  @override
  String get holidayDay => 'Dia';

  @override
  String get holidayEnabled => 'Activat';

  @override
  String get module => 'Mòdul';

  @override
  String get modules => 'Mòduls';

  @override
  String get addModule => 'Afegir mòdul';

  @override
  String get editModule => 'Editar mòdul';

  @override
  String get deleteModule => 'Eliminar mòdul';

  @override
  String deleteModuleConfirm(String name) {
    return 'Esteu segur que voleu eliminar el mòdul \"$name\"?';
  }

  @override
  String get noModules => 'Cap mòdul';

  @override
  String get moduleCode => 'Codi del mòdul';

  @override
  String get moduleCodeHint => 'p.ex. MP06';

  @override
  String get moduleName => 'Nom del mòdul';

  @override
  String get importFromCurriculum => 'Importar del currículum';

  @override
  String get ra => 'RA';

  @override
  String get ras => 'RAs';

  @override
  String get raFull => 'Resultat d\'Aprenentatge';

  @override
  String get addRa => 'Afegir RA';

  @override
  String get editRa => 'Editar RA';

  @override
  String get deleteRa => 'Eliminar RA';

  @override
  String deleteRaConfirm(String code) {
    return 'Esteu segur que voleu eliminar el RA \"$code\"?';
  }

  @override
  String get noRas => 'Cap RA';

  @override
  String get raCode => 'Codi del RA';

  @override
  String get raCodeHint => 'p.ex. RA1';

  @override
  String get raTitle => 'Títol del RA';

  @override
  String get raSelectDates => 'Prem per seleccionar rang de dates';

  @override
  String get raNotScheduled => 'No planificat';

  @override
  String raActiveCount(int count) {
    return '$count RAs actius';
  }

  @override
  String get group => 'Grup';

  @override
  String get groups => 'Grups';

  @override
  String get addGroup => 'Afegir grup';

  @override
  String get editGroup => 'Editar grup';

  @override
  String get deleteGroup => 'Eliminar grup';

  @override
  String deleteGroupConfirm(String name) {
    return 'Esteu segur que voleu eliminar el grup \"$name\"?';
  }

  @override
  String get noGroups => 'Cap grup';

  @override
  String get groupName => 'Nom del grup';

  @override
  String get groupNameHint => 'p.ex. DAW1-A';

  @override
  String get groupColor => 'Color del grup';

  @override
  String get groupColorHint => 'Seleccioneu un color per identificar el grup';

  @override
  String get groupModules => 'Mòduls del grup';

  @override
  String get noModulesAssigned => 'Cap mòdul assignat';

  @override
  String get assignModule => 'Assignar mòdul';

  @override
  String get unassignModule => 'Treure mòdul';

  @override
  String get dailyNote => 'Nota diària';

  @override
  String get dailyNotes => 'Notes diàries';

  @override
  String get addDailyNote => 'Afegir nota';

  @override
  String get editDailyNote => 'Editar nota';

  @override
  String get deleteDailyNote => 'Eliminar nota';

  @override
  String get noDailyNotes => 'Cap nota diària';

  @override
  String get plannedContent => 'Contingut planificat';

  @override
  String get plannedContentHint => 'Què es preveu treballar avui?';

  @override
  String get actualContent => 'Contingut real';

  @override
  String get actualContentHint => 'Què s\'ha treballat realment?';

  @override
  String get sessionNotes => 'Observacions de la sessió';

  @override
  String get completed => 'Completat';

  @override
  String get goToDailyNotes => 'Anar a notes diàries';

  @override
  String get selectGroup => 'Seleccioneu un grup';

  @override
  String get selectModule => 'Seleccioneu un mòdul';

  @override
  String get selectRa => 'Seleccioneu un RA';

  @override
  String get selectDate => 'Seleccioneu una data';

  @override
  String get selectDates => 'Seleccionar dates';

  @override
  String get selectColor => 'Seleccioneu un color';

  @override
  String get noSessionsScheduled => 'Cap sessió programada';

  @override
  String get noSessionsToday => 'Cap sessió avui';

  @override
  String get sessionsToday => 'Sessions d\'avui';

  @override
  String get upcomingSessions => 'Properes sessions';

  @override
  String get welcome => 'Benvingut/da';

  @override
  String get welcomeMessage => 'Gestor d\'Activitats de Classe';

  @override
  String get quickStats => 'Estadístiques ràpides';

  @override
  String get totalModules => 'Total mòduls';

  @override
  String get totalGroups => 'Total grups';

  @override
  String get activeRas => 'RAs actius';

  @override
  String get calendar => 'Calendari';

  @override
  String get weekdayMon => 'Dilluns';

  @override
  String get weekdayTue => 'Dimarts';

  @override
  String get weekdayWed => 'Dimecres';

  @override
  String get weekdayThu => 'Dijous';

  @override
  String get weekdayFri => 'Divendres';

  @override
  String get weekdaySat => 'Dissabte';

  @override
  String get weekdaySun => 'Diumenge';

  @override
  String get weekdayMonShort => 'Dl';

  @override
  String get weekdayTueShort => 'Dt';

  @override
  String get weekdayWedShort => 'Dc';

  @override
  String get weekdayThuShort => 'Dj';

  @override
  String get weekdayFriShort => 'Dv';

  @override
  String get weekdaySatShort => 'Ds';

  @override
  String get weekdaySunShort => 'Dg';

  @override
  String get syncStatusOnline => 'En línia';

  @override
  String get syncStatusOffline => 'Fora de línia';

  @override
  String get syncStatusSyncing => 'Sincronitzant...';

  @override
  String syncStatusPending(int count) {
    return '$count pendents';
  }

  @override
  String get offlineMode => 'Mode fora de línia';

  @override
  String get offlineModeMessage =>
      'L\'aplicació funciona sense connexió a MongoDB';

  @override
  String get connectionError => 'Error de connexió';

  @override
  String get conflictVersionMismatch =>
      'Les dades han estat modificades des d\'un altre dispositiu. Els teus canvis no s\'han desat.';

  @override
  String get conflictDeleted =>
      'L\'element ha estat eliminat des d\'un altre dispositiu.';

  @override
  String get deleteConfirmTitle => 'Confirmar eliminació';

  @override
  String get deleteConfirmMessage => 'Aquesta acció no es pot desfer.';

  @override
  String get unsavedChanges => 'Canvis sense desar';

  @override
  String get unsavedChangesMessage =>
      'Tens canvis sense desar. Vols descartar-los?';

  @override
  String get discard => 'Descartar';

  @override
  String get error => 'Error';

  @override
  String get errorOccurred => 'S\'ha produït un error';

  @override
  String get tryAgain => 'Torna-ho a provar';

  @override
  String get success => 'Èxit';

  @override
  String get warning => 'Avís';

  @override
  String get info => 'Informació';

  @override
  String get dateRangeInvalid =>
      'La data de fi no pot ser anterior a la data d\'inici';

  @override
  String get setupCurriculum => 'Configurar currículum';

  @override
  String get importCurriculum => 'Importar currículum';

  @override
  String get selectCycles => 'Seleccioneu els cicles';

  @override
  String get cycle => 'Cicle';

  @override
  String get cycles => 'Cicles';

  @override
  String get tasks => 'Tasques';

  @override
  String get noTasks => 'Cap tasca';

  @override
  String get reports => 'Informes';

  @override
  String get noReports => 'Cap informe';

  @override
  String get archive => 'Arxiu';

  @override
  String get noArchive => 'Cap element arxivat';

  @override
  String get comingSoon => 'Properament';

  @override
  String get featureNotImplemented =>
      'Aquesta funcionalitat encara no està implementada';
}
