import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ca, this message translates to:
  /// **'Gestor d\'Activitats de Classe'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In ca, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCalendar.
  ///
  /// In ca, this message translates to:
  /// **'Calendari'**
  String get navCalendar;

  /// No description provided for @navModules.
  ///
  /// In ca, this message translates to:
  /// **'Mòduls'**
  String get navModules;

  /// No description provided for @navDailyNotes.
  ///
  /// In ca, this message translates to:
  /// **'Notes diàries'**
  String get navDailyNotes;

  /// No description provided for @navGroups.
  ///
  /// In ca, this message translates to:
  /// **'Grups'**
  String get navGroups;

  /// No description provided for @navTasks.
  ///
  /// In ca, this message translates to:
  /// **'Tasques'**
  String get navTasks;

  /// No description provided for @navReports.
  ///
  /// In ca, this message translates to:
  /// **'Informes'**
  String get navReports;

  /// No description provided for @navArchive.
  ///
  /// In ca, this message translates to:
  /// **'Arxiu'**
  String get navArchive;

  /// No description provided for @navSettings.
  ///
  /// In ca, this message translates to:
  /// **'Configuració'**
  String get navSettings;

  /// No description provided for @save.
  ///
  /// In ca, this message translates to:
  /// **'Desa'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·la'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ca, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In ca, this message translates to:
  /// **'Afegir'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In ca, this message translates to:
  /// **'Edita'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In ca, this message translates to:
  /// **'Tanca'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In ca, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In ca, this message translates to:
  /// **'D\'acord'**
  String get ok;

  /// No description provided for @understood.
  ///
  /// In ca, this message translates to:
  /// **'Entès'**
  String get understood;

  /// No description provided for @yes.
  ///
  /// In ca, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ca, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @back.
  ///
  /// In ca, this message translates to:
  /// **'Enrere'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ca, this message translates to:
  /// **'Següent'**
  String get next;

  /// No description provided for @today.
  ///
  /// In ca, this message translates to:
  /// **'Avui'**
  String get today;

  /// No description provided for @configure.
  ///
  /// In ca, this message translates to:
  /// **'Configurar'**
  String get configure;

  /// No description provided for @select.
  ///
  /// In ca, this message translates to:
  /// **'Selecciona'**
  String get select;

  /// No description provided for @clear.
  ///
  /// In ca, this message translates to:
  /// **'Neteja'**
  String get clear;

  /// No description provided for @search.
  ///
  /// In ca, this message translates to:
  /// **'Cerca'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In ca, this message translates to:
  /// **'Filtra'**
  String get filter;

  /// No description provided for @refresh.
  ///
  /// In ca, this message translates to:
  /// **'Actualitza'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant...'**
  String get loading;

  /// No description provided for @loadingData.
  ///
  /// In ca, this message translates to:
  /// **'Carregant dades...'**
  String get loadingData;

  /// No description provided for @name.
  ///
  /// In ca, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @code.
  ///
  /// In ca, this message translates to:
  /// **'Codi'**
  String get code;

  /// No description provided for @description.
  ///
  /// In ca, this message translates to:
  /// **'Descripció'**
  String get description;

  /// No description provided for @notes.
  ///
  /// In ca, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @hours.
  ///
  /// In ca, this message translates to:
  /// **'Hores'**
  String get hours;

  /// No description provided for @totalHours.
  ///
  /// In ca, this message translates to:
  /// **'Total hores'**
  String get totalHours;

  /// No description provided for @duration.
  ///
  /// In ca, this message translates to:
  /// **'Durada'**
  String get duration;

  /// No description provided for @durationHours.
  ///
  /// In ca, this message translates to:
  /// **'Durada (hores)'**
  String get durationHours;

  /// No description provided for @date.
  ///
  /// In ca, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @startDate.
  ///
  /// In ca, this message translates to:
  /// **'Data d\'inici'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In ca, this message translates to:
  /// **'Data de fi'**
  String get endDate;

  /// No description provided for @color.
  ///
  /// In ca, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @status.
  ///
  /// In ca, this message translates to:
  /// **'Estat'**
  String get status;

  /// No description provided for @content.
  ///
  /// In ca, this message translates to:
  /// **'Contingut'**
  String get content;

  /// No description provided for @objectives.
  ///
  /// In ca, this message translates to:
  /// **'Objectius'**
  String get objectives;

  /// No description provided for @objectivesHint.
  ///
  /// In ca, this message translates to:
  /// **'un per línia'**
  String get objectivesHint;

  /// No description provided for @officialReference.
  ///
  /// In ca, this message translates to:
  /// **'Referència oficial'**
  String get officialReference;

  /// No description provided for @language.
  ///
  /// In ca, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @catalan.
  ///
  /// In ca, this message translates to:
  /// **'Català'**
  String get catalan;

  /// No description provided for @english.
  ///
  /// In ca, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @academicYear.
  ///
  /// In ca, this message translates to:
  /// **'Curs acadèmic'**
  String get academicYear;

  /// No description provided for @academicYearName.
  ///
  /// In ca, this message translates to:
  /// **'Nom del curs'**
  String get academicYearName;

  /// No description provided for @academicYearNameHint.
  ///
  /// In ca, this message translates to:
  /// **'p.ex. 2024-2025'**
  String get academicYearNameHint;

  /// No description provided for @createAcademicYear.
  ///
  /// In ca, this message translates to:
  /// **'Crear curs acadèmic'**
  String get createAcademicYear;

  /// No description provided for @editAcademicYear.
  ///
  /// In ca, this message translates to:
  /// **'Editar curs acadèmic'**
  String get editAcademicYear;

  /// No description provided for @noAcademicYear.
  ///
  /// In ca, this message translates to:
  /// **'Cap curs acadèmic definit'**
  String get noAcademicYear;

  /// No description provided for @vacationPeriods.
  ///
  /// In ca, this message translates to:
  /// **'Períodes de vacances'**
  String get vacationPeriods;

  /// No description provided for @addVacationPeriod.
  ///
  /// In ca, this message translates to:
  /// **'Afegir període'**
  String get addVacationPeriod;

  /// No description provided for @editVacationPeriod.
  ///
  /// In ca, this message translates to:
  /// **'Editar període'**
  String get editVacationPeriod;

  /// No description provided for @noVacationPeriods.
  ///
  /// In ca, this message translates to:
  /// **'Cap període de vacances'**
  String get noVacationPeriods;

  /// No description provided for @recurringHolidays.
  ///
  /// In ca, this message translates to:
  /// **'Festius recurrents'**
  String get recurringHolidays;

  /// No description provided for @addRecurringHoliday.
  ///
  /// In ca, this message translates to:
  /// **'Afegir festiu'**
  String get addRecurringHoliday;

  /// No description provided for @editRecurringHoliday.
  ///
  /// In ca, this message translates to:
  /// **'Editar festiu'**
  String get editRecurringHoliday;

  /// No description provided for @holidayMonth.
  ///
  /// In ca, this message translates to:
  /// **'Mes'**
  String get holidayMonth;

  /// No description provided for @holidayDay.
  ///
  /// In ca, this message translates to:
  /// **'Dia'**
  String get holidayDay;

  /// No description provided for @holidayEnabled.
  ///
  /// In ca, this message translates to:
  /// **'Activat'**
  String get holidayEnabled;

  /// No description provided for @module.
  ///
  /// In ca, this message translates to:
  /// **'Mòdul'**
  String get module;

  /// No description provided for @modules.
  ///
  /// In ca, this message translates to:
  /// **'Mòduls'**
  String get modules;

  /// No description provided for @addModule.
  ///
  /// In ca, this message translates to:
  /// **'Afegir mòdul'**
  String get addModule;

  /// No description provided for @editModule.
  ///
  /// In ca, this message translates to:
  /// **'Editar mòdul'**
  String get editModule;

  /// No description provided for @deleteModule.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar mòdul'**
  String get deleteModule;

  /// No description provided for @deleteModuleConfirm.
  ///
  /// In ca, this message translates to:
  /// **'Esteu segur que voleu eliminar el mòdul \"{name}\"?'**
  String deleteModuleConfirm(String name);

  /// No description provided for @noModules.
  ///
  /// In ca, this message translates to:
  /// **'Cap mòdul'**
  String get noModules;

  /// No description provided for @moduleCode.
  ///
  /// In ca, this message translates to:
  /// **'Codi del mòdul'**
  String get moduleCode;

  /// No description provided for @moduleCodeHint.
  ///
  /// In ca, this message translates to:
  /// **'p.ex. MP06'**
  String get moduleCodeHint;

  /// No description provided for @moduleName.
  ///
  /// In ca, this message translates to:
  /// **'Nom del mòdul'**
  String get moduleName;

  /// No description provided for @importFromCurriculum.
  ///
  /// In ca, this message translates to:
  /// **'Importar del currículum'**
  String get importFromCurriculum;

  /// No description provided for @ra.
  ///
  /// In ca, this message translates to:
  /// **'RA'**
  String get ra;

  /// No description provided for @ras.
  ///
  /// In ca, this message translates to:
  /// **'RAs'**
  String get ras;

  /// No description provided for @raFull.
  ///
  /// In ca, this message translates to:
  /// **'Resultat d\'Aprenentatge'**
  String get raFull;

  /// No description provided for @addRa.
  ///
  /// In ca, this message translates to:
  /// **'Afegir RA'**
  String get addRa;

  /// No description provided for @editRa.
  ///
  /// In ca, this message translates to:
  /// **'Editar RA'**
  String get editRa;

  /// No description provided for @deleteRa.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar RA'**
  String get deleteRa;

  /// No description provided for @deleteRaConfirm.
  ///
  /// In ca, this message translates to:
  /// **'Esteu segur que voleu eliminar el RA \"{code}\"?'**
  String deleteRaConfirm(String code);

  /// No description provided for @noRas.
  ///
  /// In ca, this message translates to:
  /// **'Cap RA'**
  String get noRas;

  /// No description provided for @raCode.
  ///
  /// In ca, this message translates to:
  /// **'Codi del RA'**
  String get raCode;

  /// No description provided for @raCodeHint.
  ///
  /// In ca, this message translates to:
  /// **'p.ex. RA1'**
  String get raCodeHint;

  /// No description provided for @raTitle.
  ///
  /// In ca, this message translates to:
  /// **'Títol del RA'**
  String get raTitle;

  /// No description provided for @raSelectDates.
  ///
  /// In ca, this message translates to:
  /// **'Prem per seleccionar rang de dates'**
  String get raSelectDates;

  /// No description provided for @raNotScheduled.
  ///
  /// In ca, this message translates to:
  /// **'No planificat'**
  String get raNotScheduled;

  /// No description provided for @raActiveCount.
  ///
  /// In ca, this message translates to:
  /// **'{count} RAs actius'**
  String raActiveCount(int count);

  /// No description provided for @group.
  ///
  /// In ca, this message translates to:
  /// **'Grup'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In ca, this message translates to:
  /// **'Grups'**
  String get groups;

  /// No description provided for @addGroup.
  ///
  /// In ca, this message translates to:
  /// **'Afegir grup'**
  String get addGroup;

  /// No description provided for @editGroup.
  ///
  /// In ca, this message translates to:
  /// **'Editar grup'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar grup'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In ca, this message translates to:
  /// **'Esteu segur que voleu eliminar el grup \"{name}\"?'**
  String deleteGroupConfirm(String name);

  /// No description provided for @noGroups.
  ///
  /// In ca, this message translates to:
  /// **'Cap grup'**
  String get noGroups;

  /// No description provided for @groupName.
  ///
  /// In ca, this message translates to:
  /// **'Nom del grup'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In ca, this message translates to:
  /// **'p.ex. DAW1-A'**
  String get groupNameHint;

  /// No description provided for @groupColor.
  ///
  /// In ca, this message translates to:
  /// **'Color del grup'**
  String get groupColor;

  /// No description provided for @groupColorHint.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu un color per identificar el grup'**
  String get groupColorHint;

  /// No description provided for @groupModules.
  ///
  /// In ca, this message translates to:
  /// **'Mòduls del grup'**
  String get groupModules;

  /// No description provided for @noModulesAssigned.
  ///
  /// In ca, this message translates to:
  /// **'Cap mòdul assignat'**
  String get noModulesAssigned;

  /// No description provided for @assignModule.
  ///
  /// In ca, this message translates to:
  /// **'Assignar mòdul'**
  String get assignModule;

  /// No description provided for @unassignModule.
  ///
  /// In ca, this message translates to:
  /// **'Treure mòdul'**
  String get unassignModule;

  /// No description provided for @dailyNote.
  ///
  /// In ca, this message translates to:
  /// **'Nota diària'**
  String get dailyNote;

  /// No description provided for @dailyNotes.
  ///
  /// In ca, this message translates to:
  /// **'Notes diàries'**
  String get dailyNotes;

  /// No description provided for @addDailyNote.
  ///
  /// In ca, this message translates to:
  /// **'Afegir nota'**
  String get addDailyNote;

  /// No description provided for @editDailyNote.
  ///
  /// In ca, this message translates to:
  /// **'Editar nota'**
  String get editDailyNote;

  /// No description provided for @deleteDailyNote.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar nota'**
  String get deleteDailyNote;

  /// No description provided for @noDailyNotes.
  ///
  /// In ca, this message translates to:
  /// **'Cap nota diària'**
  String get noDailyNotes;

  /// No description provided for @plannedContent.
  ///
  /// In ca, this message translates to:
  /// **'Contingut planificat'**
  String get plannedContent;

  /// No description provided for @plannedContentHint.
  ///
  /// In ca, this message translates to:
  /// **'Què es preveu treballar avui?'**
  String get plannedContentHint;

  /// No description provided for @actualContent.
  ///
  /// In ca, this message translates to:
  /// **'Contingut real'**
  String get actualContent;

  /// No description provided for @actualContentHint.
  ///
  /// In ca, this message translates to:
  /// **'Què s\'ha treballat realment?'**
  String get actualContentHint;

  /// No description provided for @sessionNotes.
  ///
  /// In ca, this message translates to:
  /// **'Observacions de la sessió'**
  String get sessionNotes;

  /// No description provided for @completed.
  ///
  /// In ca, this message translates to:
  /// **'Completat'**
  String get completed;

  /// No description provided for @goToDailyNotes.
  ///
  /// In ca, this message translates to:
  /// **'Anar a notes diàries'**
  String get goToDailyNotes;

  /// No description provided for @selectGroup.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu un grup'**
  String get selectGroup;

  /// No description provided for @selectModule.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu un mòdul'**
  String get selectModule;

  /// No description provided for @selectRa.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu un RA'**
  String get selectRa;

  /// No description provided for @selectDate.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu una data'**
  String get selectDate;

  /// No description provided for @selectDates.
  ///
  /// In ca, this message translates to:
  /// **'Seleccionar dates'**
  String get selectDates;

  /// No description provided for @selectColor.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu un color'**
  String get selectColor;

  /// No description provided for @noSessionsScheduled.
  ///
  /// In ca, this message translates to:
  /// **'Cap sessió programada'**
  String get noSessionsScheduled;

  /// No description provided for @noSessionsToday.
  ///
  /// In ca, this message translates to:
  /// **'Cap sessió avui'**
  String get noSessionsToday;

  /// No description provided for @sessionsToday.
  ///
  /// In ca, this message translates to:
  /// **'Sessions d\'avui'**
  String get sessionsToday;

  /// No description provided for @upcomingSessions.
  ///
  /// In ca, this message translates to:
  /// **'Properes sessions'**
  String get upcomingSessions;

  /// No description provided for @welcome.
  ///
  /// In ca, this message translates to:
  /// **'Benvingut/da'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In ca, this message translates to:
  /// **'Gestor d\'Activitats de Classe'**
  String get welcomeMessage;

  /// No description provided for @quickStats.
  ///
  /// In ca, this message translates to:
  /// **'Estadístiques ràpides'**
  String get quickStats;

  /// No description provided for @totalModules.
  ///
  /// In ca, this message translates to:
  /// **'Total mòduls'**
  String get totalModules;

  /// No description provided for @totalGroups.
  ///
  /// In ca, this message translates to:
  /// **'Total grups'**
  String get totalGroups;

  /// No description provided for @activeRas.
  ///
  /// In ca, this message translates to:
  /// **'RAs actius'**
  String get activeRas;

  /// No description provided for @calendar.
  ///
  /// In ca, this message translates to:
  /// **'Calendari'**
  String get calendar;

  /// No description provided for @weekdayMon.
  ///
  /// In ca, this message translates to:
  /// **'Dilluns'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ca, this message translates to:
  /// **'Dimarts'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ca, this message translates to:
  /// **'Dimecres'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ca, this message translates to:
  /// **'Dijous'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ca, this message translates to:
  /// **'Divendres'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ca, this message translates to:
  /// **'Dissabte'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ca, this message translates to:
  /// **'Diumenge'**
  String get weekdaySun;

  /// No description provided for @weekdayMonShort.
  ///
  /// In ca, this message translates to:
  /// **'Dl'**
  String get weekdayMonShort;

  /// No description provided for @weekdayTueShort.
  ///
  /// In ca, this message translates to:
  /// **'Dt'**
  String get weekdayTueShort;

  /// No description provided for @weekdayWedShort.
  ///
  /// In ca, this message translates to:
  /// **'Dc'**
  String get weekdayWedShort;

  /// No description provided for @weekdayThuShort.
  ///
  /// In ca, this message translates to:
  /// **'Dj'**
  String get weekdayThuShort;

  /// No description provided for @weekdayFriShort.
  ///
  /// In ca, this message translates to:
  /// **'Dv'**
  String get weekdayFriShort;

  /// No description provided for @weekdaySatShort.
  ///
  /// In ca, this message translates to:
  /// **'Ds'**
  String get weekdaySatShort;

  /// No description provided for @weekdaySunShort.
  ///
  /// In ca, this message translates to:
  /// **'Dg'**
  String get weekdaySunShort;

  /// No description provided for @syncStatusOnline.
  ///
  /// In ca, this message translates to:
  /// **'En línia'**
  String get syncStatusOnline;

  /// No description provided for @syncStatusOffline.
  ///
  /// In ca, this message translates to:
  /// **'Fora de línia'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In ca, this message translates to:
  /// **'Sincronitzant...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusPending.
  ///
  /// In ca, this message translates to:
  /// **'{count} pendents'**
  String syncStatusPending(int count);

  /// No description provided for @offlineMode.
  ///
  /// In ca, this message translates to:
  /// **'Mode fora de línia'**
  String get offlineMode;

  /// No description provided for @offlineModeMessage.
  ///
  /// In ca, this message translates to:
  /// **'L\'aplicació funciona sense connexió a MongoDB'**
  String get offlineModeMessage;

  /// No description provided for @connectionError.
  ///
  /// In ca, this message translates to:
  /// **'Error de connexió'**
  String get connectionError;

  /// No description provided for @conflictVersionMismatch.
  ///
  /// In ca, this message translates to:
  /// **'Les dades han estat modificades des d\'un altre dispositiu. Els teus canvis no s\'han desat.'**
  String get conflictVersionMismatch;

  /// No description provided for @conflictDeleted.
  ///
  /// In ca, this message translates to:
  /// **'L\'element ha estat eliminat des d\'un altre dispositiu.'**
  String get conflictDeleted;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ca, this message translates to:
  /// **'Confirmar eliminació'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta acció no es pot desfer.'**
  String get deleteConfirmMessage;

  /// No description provided for @unsavedChanges.
  ///
  /// In ca, this message translates to:
  /// **'Canvis sense desar'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In ca, this message translates to:
  /// **'Tens canvis sense desar. Vols descartar-los?'**
  String get unsavedChangesMessage;

  /// No description provided for @discard.
  ///
  /// In ca, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @error.
  ///
  /// In ca, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorOccurred.
  ///
  /// In ca, this message translates to:
  /// **'S\'ha produït un error'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In ca, this message translates to:
  /// **'Torna-ho a provar'**
  String get tryAgain;

  /// No description provided for @success.
  ///
  /// In ca, this message translates to:
  /// **'Èxit'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In ca, this message translates to:
  /// **'Avís'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In ca, this message translates to:
  /// **'Informació'**
  String get info;

  /// No description provided for @dateRangeInvalid.
  ///
  /// In ca, this message translates to:
  /// **'La data de fi no pot ser anterior a la data d\'inici'**
  String get dateRangeInvalid;

  /// No description provided for @setupCurriculum.
  ///
  /// In ca, this message translates to:
  /// **'Configurar currículum'**
  String get setupCurriculum;

  /// No description provided for @importCurriculum.
  ///
  /// In ca, this message translates to:
  /// **'Importar currículum'**
  String get importCurriculum;

  /// No description provided for @selectCycles.
  ///
  /// In ca, this message translates to:
  /// **'Seleccioneu els cicles'**
  String get selectCycles;

  /// No description provided for @cycle.
  ///
  /// In ca, this message translates to:
  /// **'Cicle'**
  String get cycle;

  /// No description provided for @cycles.
  ///
  /// In ca, this message translates to:
  /// **'Cicles'**
  String get cycles;

  /// No description provided for @tasks.
  ///
  /// In ca, this message translates to:
  /// **'Tasques'**
  String get tasks;

  /// No description provided for @noTasks.
  ///
  /// In ca, this message translates to:
  /// **'Cap tasca'**
  String get noTasks;

  /// No description provided for @reports.
  ///
  /// In ca, this message translates to:
  /// **'Informes'**
  String get reports;

  /// No description provided for @noReports.
  ///
  /// In ca, this message translates to:
  /// **'Cap informe'**
  String get noReports;

  /// No description provided for @archive.
  ///
  /// In ca, this message translates to:
  /// **'Arxiu'**
  String get archive;

  /// No description provided for @noArchive.
  ///
  /// In ca, this message translates to:
  /// **'Cap element arxivat'**
  String get noArchive;

  /// No description provided for @comingSoon.
  ///
  /// In ca, this message translates to:
  /// **'Properament'**
  String get comingSoon;

  /// No description provided for @featureNotImplemented.
  ///
  /// In ca, this message translates to:
  /// **'Aquesta funcionalitat encara no està implementada'**
  String get featureNotImplemented;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
