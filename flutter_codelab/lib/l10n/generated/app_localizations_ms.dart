// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get helloWorld => 'Halo Dunia';

  @override
  String get userProfile => 'Profil';

  @override
  String get logout => 'Log keluar';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String helloUser(String userName) {
    return 'Halo, $userName';
  }

  @override
  String get logoutConfirmation => 'Log keluar dari akaun anda?';

  @override
  String get cancel => 'Batal';

  @override
  String loginFailed(String error) {
    return 'Log Masuk Gagal: $error';
  }

  @override
  String get autofillSuccess => 'Isian automatik berjaya!';

  @override
  String get emailHint => 'user@contoh.com';

  @override
  String get emailValidation => 'Sila masukkan alamat e-mel yang sah';

  @override
  String get passwordValidation =>
      'Kata laluan mestilah sekurang-kurangnya 6 aksara';

  @override
  String get email => 'E-mel';

  @override
  String get emailPlaceholder => 'user@example.com';

  @override
  String get validEmailRequired => 'E-mel yang sah diperlukan';

  @override
  String get password => 'Kata Laluan';

  @override
  String get passwordRequired => 'Kata laluan diperlukan';

  @override
  String get login => 'Log Masuk';

  @override
  String get forgotPassword => 'Lupa Kata Laluan?';

  @override
  String get accountRecovery => 'Pemulihan Akaun';

  @override
  String get resetCodeSent => 'Kod tetapan semula dihantar! Semak e-mel anda.';

  @override
  String get enterEmailInstructions =>
      'Masukkan alamat e-mel anda untuk menerima kod pengesahan 6 digit.';

  @override
  String get sendResetCode => 'Hantar Kod Tetapan Semula';

  @override
  String get quiz => 'Kuiz';

  @override
  String get passwordResetSuccess =>
      'Kata laluan berjaya ditetapkan semula! Sila log masuk.';

  @override
  String get setNewPassword => 'Tetapkan Kata Laluan Baru';

  @override
  String get sixDigitCode => 'Kod 6 Digit';

  @override
  String get newPassword => 'Kata Laluan Baru';

  @override
  String get passwordsDoNotMatch => 'Kata laluan tidak sepadan';

  @override
  String get confirmPassword => 'Sahkan Kata Laluan';

  @override
  String get resetPassword => 'Tetapkan Semula Kata Laluan';

  @override
  String get name => 'Nama';

  @override
  String get date => 'Tarikh';

  @override
  String get unlocked => 'Dibuka';

  @override
  String get locked => 'Dikunci';

  @override
  String get ascending => 'Menaik';

  @override
  String get descending => 'Menurun';

  @override
  String get noLevelsFound => 'Tiada tahap dijumpai';

  @override
  String get delete => 'Padam';

  @override
  String forUser(Object email) {
    return 'untuk $email';
  }

  @override
  String get achievements => 'Pencapaian';

  @override
  String get searchHint => 'Cari tajuk atau penerangan...';

  @override
  String get all => 'Semua';

  @override
  String get createdByMe => 'Dicipta oleh Saya';

  @override
  String get sortBy => 'Susun Mengikut';

  @override
  String get order => 'Turutan';

  @override
  String get refreshList => 'Segarkan Senarai';

  @override
  String get sortOptions => 'Pilihan Susunan';

  @override
  String get gameLevels => 'Tahap Permainan';

  @override
  String get refreshLevels => 'Segarkan Tahap';

  @override
  String get addLevel => 'Tambah Tahap';

  @override
  String get searchLevels => 'Cari tahap...';

  @override
  String get visibility => 'Kebolehlihatan';

  @override
  String get public => 'Awam';

  @override
  String get private => 'Peribadi';

  @override
  String get deleteLevel => 'Padam Tahap';

  @override
  String get deleteLevelConfirmation =>
      'Adakah anda pasti mahu memadamkan tahap ini?';

  @override
  String get failedToLoadLevel => 'Gagal memuatkan data tahap';

  @override
  String get notes => 'Nota';

  @override
  String get searchNotesHint => 'Cari topik atau tajuk';

  @override
  String get users => 'Pengguna';

  @override
  String get games => 'Permainan';

  @override
  String get classes => 'Kelas';

  @override
  String get aiChat => 'Sembang AI';

  @override
  String get feedback => 'Maklum Balas';

  @override
  String get searchUserHint => 'Cari pengguna...';

  @override
  String get importingUsers => 'Mengimport pengguna...';

  @override
  String get usersImportedSuccess => 'Pengguna berjaya diimport!';

  @override
  String importFailed(String error) {
    return 'Import Gagal: $error';
  }

  @override
  String get student => 'Pelajar';

  @override
  String get teacher => 'Guru';

  @override
  String get admin => 'Admin';

  @override
  String get allStatus => 'Semua Status';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Tidak Aktif';

  @override
  String get myFeedback => 'Maklum Balas Saya';

  @override
  String failedToLoadFeedback(String error) {
    return 'Gagal memuatkan maklum balas: $error';
  }

  @override
  String get errorLoadingFeedback => 'Ralat memuatkan maklum balas';

  @override
  String get retry => 'Cuba Lagi';

  @override
  String get noFeedbackYet => 'Tiada maklum balas lagi';

  @override
  String get teachersFeedbackInstructions =>
      'Guru anda akan memberikan maklum balas di sini';

  @override
  String fromTeacher(String teacherName) {
    return 'Daripada: $teacherName';
  }

  @override
  String get classCreatedSuccess => 'Kelas berjaya dicipta!';

  @override
  String get noPermissionCreateUser =>
      'Anda tidak mempunyai kebenaran untuk mencipta akaun pengguna.';

  @override
  String get selectAction => 'Pilih Tindakan';

  @override
  String get createUserProfile => 'Cipta Profil Pengguna';

  @override
  String get importUserProfile => 'Import Profil Pengguna';

  @override
  String get studentsCannotCreateGames =>
      'Pelajar tidak boleh mencipta permainan. Ini hanya untuk Guru dan Admin sahaja.';

  @override
  String get studentsCannotAddNotes =>
      'Pelajar tidak boleh menambah nota. Ini hanya untuk Admin sahaja.';

  @override
  String get noAccessFunction => 'Anda tidak mempunyai akses kepada fungsi ini';

  @override
  String get noAccessCreateFeedback =>
      'Anda tidak mempunyai akses untuk mencipta maklum balas';

  @override
  String userAchievements(String name) {
    return 'Pencapaian $name';
  }

  @override
  String get createNewUser => 'Cipta Pengguna Baru';

  @override
  String get pleaseConfirmPassword => 'Sila sahkan kata laluan anda';

  @override
  String get userAccountCreatedSuccess => 'Akaun pengguna berjaya dicipta!';

  @override
  String get networkErrorCheckApi =>
      'Ralat Rangkaian: Semak URL API dan status pelayan.';

  @override
  String unknownErrorOccurred(String error) {
    return 'Ralat tidak diketahui berlaku: $error';
  }

  @override
  String get createUser => 'Cipta Pengguna';

  @override
  String get deleteUsers => 'Padam Pengguna';

  @override
  String deleteUsersConfirmation(int count) {
    return 'Adakah anda pasti mahu memadamkan $count pengguna? Tindakan ini tidak boleh dibatalkan.';
  }

  @override
  String get deletingUsers => 'Memadamkan pengguna yang dipilih...';

  @override
  String deletedUsersSuccess(int count) {
    return 'Berjaya memadamkan $count pengguna';
  }

  @override
  String errorDeletingUsers(String error) {
    return 'Ralat memadamkan pengguna: $error';
  }

  @override
  String errorLoadingAchievements(String error) {
    return 'Ralat memuatkan pencapaian: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count Dipilih';
  }

  @override
  String get deleteSelectedUsers => 'Padam Pengguna yang Dipilih';

  @override
  String resultsCount(int count) {
    return '$count Keputusan';
  }

  @override
  String get noUsersFound => 'Tiada pengguna dijumpai';

  @override
  String get deleteUserAccount => 'Padam Akaun Pengguna?';

  @override
  String deleteUserAccountConfirmation(String name) {
    return 'Adakah anda pasti mahu memadamkan akaun $name dan semua data berkaitan secara kekal? Tindakan ini tidak boleh dibatalkan.';
  }

  @override
  String deletedUserSuccess(String name) {
    return 'Berjaya memadamkan pengguna: $name';
  }

  @override
  String get accessDeniedAdminOnly =>
      'Akses Dinafikan: Hanya Administrator yang boleh memadamkan akaun pengguna.';

  @override
  String errorDeletingUser(String error) {
    return 'Ralat memadamkan pengguna: $error';
  }

  @override
  String get editUserProfile => 'Edit Profil Pengguna';

  @override
  String get errorLoadingProfile => 'Ralat memuatkan profil';

  @override
  String get userProfileDetails => 'Butiran Profil Pengguna';

  @override
  String get phone => 'Telefon';

  @override
  String get address => 'Alamat';

  @override
  String get genderLabel => 'Jantina';

  @override
  String get joinedDateLabel => 'Tarikh Menyertai';

  @override
  String get accountStatusLabel => 'Status Akaun';

  @override
  String get recentAchievements => 'Pencapaian Terkini';

  @override
  String get viewAll => 'Lihat Semua';

  @override
  String get noAchievementsYet => 'Tiada pencapaian dibuka lagi.';

  @override
  String get unknownDate => 'Tarikh Tidak Diketahui';

  @override
  String get achievement => 'Pencapaian';

  @override
  String unlockedOn(String date) {
    return 'Dibuka pada $date';
  }

  @override
  String get saveChanges => 'Simpan Perubahan';

  @override
  String get confirmNewPassword => 'Sahkan Kata Laluan Baru';

  @override
  String get passwordsMatchError =>
      'Ralat: Kata laluan baru dan pengesahan mestilah sama.';

  @override
  String get userProfileUpdated => 'Profil pengguna berjaya dikemas kini!';

  @override
  String get accessDeniedAdminModify =>
      'Akses Dinafikan: Hanya Administrator yang boleh mengubah profil pengguna.';

  @override
  String errorUpdatingProfile(String error) {
    return 'Ralat mengemas kini profil: $error';
  }

  @override
  String get pleaseEnterName => 'Sila masukkan nama';

  @override
  String get pleaseEnterEmail => 'Sila masukkan e-mel';

  @override
  String get enterValidEmail => 'Masukkan alamat e-mel yang sah';

  @override
  String get passwordLengthError =>
      'Kata laluan mestilah sekurang-kurangnya 8 aksara';

  @override
  String get confirmPasswordRequired => 'Sila sahkan kata laluan baru';

  @override
  String get pleaseEnterPhone => 'Sila masukkan nombor telefon';

  @override
  String get enterValidPhone => 'Masukkan nombor telefon Malaysia yang sah';

  @override
  String get pleaseEnterAddress => 'Sila masukkan alamat';

  @override
  String get pleaseSelectGender => 'Sila pilih jantina';

  @override
  String get pleaseSelectRole => 'Sila pilih peranan';

  @override
  String get roleLabel => 'Peranan';

  @override
  String get male => 'Lelaki';

  @override
  String get female => 'Perempuan';

  @override
  String get other => 'Lain-lain';

  @override
  String get feedbacks => 'Maklum Balas';

  @override
  String get results => 'Keputusan';

  @override
  String get noFeedbackFound => 'Tiada maklum balas dijumpai.';

  @override
  String get sortByTime => 'Susun Mengikut Masa';

  @override
  String get newestFirst => 'Terkini Dahulu';

  @override
  String get oldestFirst => 'Terlama Dahulu';

  @override
  String get refreshFeedbacks => 'Segarkan Maklum Balas';

  @override
  String get filterByStudent => 'Tapis Mengikut Pelajar';

  @override
  String get allStudents => 'Semua Pelajar';

  @override
  String get filterByTeacher => 'Tapis Mengikut Guru';

  @override
  String get allTeachers => 'Semua Guru';

  @override
  String get deleteFeedbackTitle => 'Padam Maklum Balas?';

  @override
  String get deleteFeedbackConfirmation =>
      'Adakah anda pasti mahu memadamkan maklum balas ini? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get feedbackDeleted => 'Maklum balas dipadam';

  @override
  String get editFeedback => 'Edit Maklum Balas';

  @override
  String get currentTopic => 'Topik Semasa';

  @override
  String get discardChangesTitle => 'Abaikan Perubahan?';

  @override
  String get discardChangesConfirmation =>
      'Anda mempunyai perubahan yang belum disimpan. Adakah anda pasti mahu mengabaikannya?';

  @override
  String get discard => 'Abaikan';

  @override
  String get changesSavedSuccess => 'Perubahan berjaya disimpan!';

  @override
  String updateFailed(String error) {
    return 'Kemas kini gagal: $error';
  }

  @override
  String from(String name) {
    return 'Daripada: $name';
  }

  @override
  String failedToLoadStudents(String error) {
    return 'Gagal memuatkan pelajar: $error';
  }

  @override
  String get pleaseSelectStudent => 'Sila pilih pelajar';

  @override
  String feedbackSentTo(String name) {
    return 'Maklum balas dihantar kepada $name';
  }

  @override
  String get accessDeniedCreateFeedback =>
      'Akses Ditolak: Hanya guru boleh membuat maklum balas.';

  @override
  String get newFeedback => 'Maklum Balas Baru';

  @override
  String get selectStudent => 'Pilih Pelajar';

  @override
  String get selectAStudent => 'Pilih seorang pelajar';

  @override
  String get noStudentsAvailable => 'Tiada pelajar tersedia';

  @override
  String get selectTopic => 'Pilih Topik';

  @override
  String get selectATopic => 'Pilih satu topik';

  @override
  String get pleaseSelectTopic => 'Sila pilih topik';

  @override
  String get title => 'Tajuk';

  @override
  String get titleHint => 'cth., Kerja Bagus!';

  @override
  String get pleaseEnterTitle => 'Sila masukkan tajuk';

  @override
  String get feedbackHint => 'Tulis maklum balas anda di sini...';

  @override
  String get pleaseWriteFeedback => 'Sila tulis maklum balas';

  @override
  String get send => 'Hantar';

  @override
  String errorLoadingHistory(String error) {
    return 'Ralat memuatkan sejarah: $error';
  }

  @override
  String errorLoadingMessages(String error) {
    return 'Ralat memuatkan mesej: $error';
  }

  @override
  String get clearHistory => 'Kosongkan Sejarah';

  @override
  String get clearHistoryConfirmation =>
      'Adakah anda pasti mahu memadamkan sesi sembang ini?';

  @override
  String get chatDeletedSuccessfully => 'Sembang berjaya dipadam';

  @override
  String get chatClearedSuccessfully => 'Sembang berjaya dikosongkan';

  @override
  String deleteFailed(String error) {
    return 'Gagal memadam: $error';
  }

  @override
  String get aiChatTitle => 'KalmNest AI (Gemini-2.0-flash)';

  @override
  String get howCanIHelp => 'Bagaimana saya boleh membantu anda hari ini?';

  @override
  String get askQuestion => 'Tanya Soalan';

  @override
  String get recentQuestions => 'Soalan Terkini';

  @override
  String get noQuestionsFound => 'Tiada soalan terdahulu ditemui.';

  @override
  String get untitledQuestion => 'Soalan Tanpa Tajuk';

  @override
  String get quickSuggestions => 'Cadangan Pembelajaran Pantas';

  @override
  String get suggestionPrefix => 'Berikan Cadangan Pembelajaran untuk ';

  @override
  String get typeQuestionHint => 'Taip soalan anda...';

  @override
  String get backToHistory => 'Kembali ke Sejarah';

  @override
  String get refreshQuestion => 'Segarkan Soalan';

  @override
  String get deleteChat => 'Padam Sembang';

  @override
  String get classCreatedSuccessfully => 'Kelas berjaya dicipta!';

  @override
  String get failedToCreateClass => 'Gagal mencipta kelas';

  @override
  String get ok => 'OK';

  @override
  String get createNewClass => 'Cipta Kelas Baru';

  @override
  String get indicatesRequiredFields => '* menunjukkan medan wajib';

  @override
  String get className => 'Nama Kelas';

  @override
  String get enterClassName => 'Masukkan nama kelas';

  @override
  String get description => 'Penerangan';

  @override
  String get enterDescription =>
      'Masukkan penerangan (sekurang-kurangnya 10 perkataan)';

  @override
  String get atLeast10Words => 'Sekurang-kurangnya 10 perkataan';

  @override
  String get focusOptional => 'Fokus (Pilihan)';

  @override
  String get noneOptional => 'Tiada (Pilihan)';

  @override
  String get assignTeacherOptional => 'Tugaskan Guru (Pilihan)';

  @override
  String get classUpdatedSuccessfully => 'Kelas berjaya dikemas kini!';

  @override
  String get failedToUpdateClass => 'Gagal mengemas kini kelas';

  @override
  String get editClass => 'Edit Kelas';

  @override
  String get editClassDetails => 'Edit Butiran Kelas';

  @override
  String get loading => 'Memuatkan...';

  @override
  String get selectTeacher => 'Pilih Guru';

  @override
  String get classNameRequired => 'Nama kelas diperlukan';

  @override
  String get classNameMinCharacters =>
      'Nama kelas mestilah sekurang-kurangnya 3 aksara';

  @override
  String get classNameMaxCharacters =>
      'Nama kelas tidak boleh melebihi 100 aksara';

  @override
  String get descriptionRequired => 'Penerangan diperlukan';

  @override
  String get descriptionMaxCharacters =>
      'Penerangan tidak boleh melebihi 500 aksara';

  @override
  String get descriptionMinWords =>
      'Penerangan mesti mengandungi sekurang-kurangnya 10 perkataan';

  @override
  String get thisClass => 'kelas ini';

  @override
  String deleteClassConfirmation(String className) {
    return 'Adakah anda pasti mahu memadamkan $className? Tindakan ini tidak boleh dibatalkan.';
  }

  @override
  String get classDeletedSuccessfully => 'Kelas berjaya dipadam!';

  @override
  String errorDeletingClass(String error) {
    return 'Ralat memadamkan kelas: $error';
  }

  @override
  String get unknown => 'Tidak Diketahui';

  @override
  String get nA => 'T/A';

  @override
  String get details => 'Butiran';

  @override
  String get refresh => 'Segarkan';

  @override
  String get deleteClass => 'Padam Kelas';

  @override
  String get noName => 'Tiada Nama';

  @override
  String get noTeacherAssigned => 'Tiada Guru Ditugaskan';

  @override
  String get generalInfo => 'Maklumat Am';

  @override
  String get searchStudents => 'Cari Pelajar';

  @override
  String get totalStudents => 'Jumlah Pelajar';

  @override
  String get completionRate => 'Kadar Penyiapan';

  @override
  String get quizzesAssigned => 'Kuiz Ditugaskan';

  @override
  String get moreOptions => 'Lebih Banyak Pilihan';

  @override
  String get viewDetails => 'Lihat Butiran';

  @override
  String get completed => 'Selesai';

  @override
  String get quizzes => 'Kuiz';

  @override
  String get courseProgress => 'Kemajuan Kursus';

  @override
  String get noStudentsFound => 'Tiada pelajar dijumpai';

  @override
  String get tryAdjustingSearchCriteria => 'Cuba laraskan kriteria carian anda';

  @override
  String get edit => 'Edit';

  @override
  String get noClassesFound => 'Tiada kelas dijumpai';

  @override
  String get tryAdjustingSearchQuery => 'Cuba laraskan pertanyaan carian anda';

  @override
  String get notEnrolledInAnyClasses =>
      'Anda tidak mendaftar dalam mana-mana kelas';

  @override
  String get classFocusUpdatedSuccessfully =>
      'Fokus kelas berjaya dikemas kini!';

  @override
  String get failedToUpdateClassFocus => 'Gagal mengemas kini fokus kelas';

  @override
  String get editClassFocus => 'Edit Fokus Kelas';

  @override
  String editFocusFor(String className) {
    return 'Edit Fokus untuk $className';
  }

  @override
  String get youCanOnlyEditFocus =>
      'Anda hanya boleh mengedit fokus untuk kelas anda sendiri';

  @override
  String get failedToLoadQuizStudentData => 'Gagal memuatkan data pelajar kuiz';

  @override
  String get never => 'Tidak Pernah';

  @override
  String get allQuizzes => 'Semua Kuiz';

  @override
  String get statistics => 'Statistik';

  @override
  String get pending => 'Menunggu';

  @override
  String get failedToLoadStudentQuizData => 'Gagal memuatkan data kuiz pelajar';

  @override
  String get gender => 'Jantina';

  @override
  String get joinedDate => 'Tarikh Menyertai';

  @override
  String get accountStatus => 'Status Akaun';

  @override
  String get totalQuizzes => 'Jumlah Kuiz';

  @override
  String get noQuizzesFound => 'Tiada kuiz dijumpai';

  @override
  String get quizVisibility => 'Kebolehlihatan Kuiz';

  @override
  String get howShouldQuizBeVisible => 'Bagaimanakah kuiz ini harus kelihatan?';

  @override
  String get onlyVisibleToThisClass => 'Hanya kelihatan kepada kelas ini';

  @override
  String get visibleToEveryone => 'Kelihatan kepada semua orang';

  @override
  String get quizCreatedAndAssignedSuccessfully =>
      'Kuiz berjaya dicipta dan ditugaskan!';

  @override
  String get failedToAssignQuiz => 'Gagal menugaskan kuiz';

  @override
  String get quizAssignedSuccessfully => 'Kuiz berjaya ditugaskan!';

  @override
  String get removeQuiz => 'Buang Kuiz';

  @override
  String get areYouSureRemoveQuiz =>
      'Adakah anda pasti mahu membuang kuiz ini dari kelas?';

  @override
  String get remove => 'Buang';

  @override
  String get quizRemovedSuccessfully => 'Kuiz berjaya dibuang!';

  @override
  String quizzesAvailable(int count) {
    return '$count kuiz tersedia';
  }

  @override
  String get viewAllQuizzes => 'Lihat Semua Kuiz';

  @override
  String get noQuizzesYet => 'Tiada kuiz lagi';

  @override
  String get createOrAssignQuizzes => 'Cipta atau tugaskan kuiz untuk bermula';

  @override
  String uploaded(String date) {
    return 'Dimuat naik $date';
  }

  @override
  String viewAllXQuizzes(int count) {
    return 'Lihat Semua $count Kuiz';
  }

  @override
  String get unknownTeacher => 'Guru Tidak Diketahui';

  @override
  String get noTeacher => 'Tiada Guru';

  @override
  String get studentSingular => 'pelajar';

  @override
  String get studentsPlural => 'pelajar';

  @override
  String get noStudents => 'Tiada pelajar';

  @override
  String get assignedTeacher => 'Guru Ditugaskan';

  @override
  String get play => 'Main';

  @override
  String get allClasses => 'Semua Kelas';

  @override
  String get myClasses => 'Kelas Saya';

  @override
  String get enrolledClasses => 'Kelas yang Didaftarkan';

  @override
  String get searchByClassName => 'Cari mengikut nama kelas';

  @override
  String get noDescriptionAvailable => 'Tiada penerangan tersedia';

  @override
  String get timestamps => 'Cap Masa';

  @override
  String get createdAt => 'Dicipta Pada';

  @override
  String get updatedAt => 'Dikemas Kini Pada';

  @override
  String get assignStudentsOptional => 'Tugaskan Pelajar (Pilihan)';

  @override
  String studentNumber(int number) {
    return 'Pelajar $number';
  }

  @override
  String get selectStudents => 'Pilih Pelajar';

  @override
  String get addStudent => 'Tambah Pelajar';

  @override
  String get reset => 'Tetapkan Semula';

  @override
  String get create => 'Cipta';

  @override
  String get creator => 'Pencipta';

  @override
  String get focus => 'Fokus';

  @override
  String get notSet => 'Tidak Ditentukan';

  @override
  String get cannotOpenTeacherProfile => 'Tidak boleh membuka profil guru';

  @override
  String get noTeacherAssignedToClass =>
      'Tiada guru ditugaskan kepada kelas ini';

  @override
  String get lastUpdated => 'Kemas Kini Terakhir';

  @override
  String get students => 'Pelajar';

  @override
  String moreStudents(int count) {
    return 'dan $count pelajar lagi';
  }

  @override
  String get noStudentsEnrolled => 'Tiada pelajar mendaftar';

  @override
  String get listOfEnrolledStudents => 'Senarai Pelajar yang Didaftarkan';

  @override
  String get status => 'Status';

  @override
  String get assigned => 'Ditugaskan';

  @override
  String get failedToRemoveQuiz => 'Gagal membuang kuiz';

  @override
  String get searchQuizzes => 'Cari Kuiz';

  @override
  String get assignQuiz => 'Tugaskan Kuiz';

  @override
  String get createQuiz => 'Cipta Kuiz';

  @override
  String get tapToViewStudentCompletion =>
      'Ketuk untuk melihat penyiapan pelajar';

  @override
  String get assignQuizToClass => 'Tugaskan Kuiz kepada Kelas';

  @override
  String get reloadQuizzes => 'Muat Semula Kuiz';

  @override
  String get noQuizzesAssigned => 'Tiada kuiz ditugaskan';

  @override
  String get pleaseEnterQuestion => 'Sila masukkan soalan';

  @override
  String get aiLanguageNotice =>
      'AI akan menjawab dalam bahasa yang sama dengan soalan anda';
}
