import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:payparse/features/company_profile/domain/company_model.dart';
import 'package:payparse/services/storage_service.dart';

/// Repository for managing company profile data.
class CompanyRepository {
  /// Saves the company profile to local storage.
  Future<void> saveProfile(CompanyProfile profile) async {
    await StorageService.saveCompanyProfile(profile);
  }

  /// Retrieves the company profile from local storage.
  CompanyProfile? getProfile() {
    return StorageService.getCompanyProfile();
  }

  /// Checks if a company profile has been set up.
  bool hasProfile() {
    return StorageService.hasCompanyProfile();
  }

  /// Saves a logo image to the app's document directory and returns the path.
  Future<String> saveLogoFile(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final logoDir = Directory('${appDir.path}/logo');
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }

    final extension = sourceFile.path.split('.').last;
    final destPath = '${logoDir.path}/company_logo.$extension';
    final destFile = await sourceFile.copy(destPath);
    return destFile.path;
  }
}
