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
}
