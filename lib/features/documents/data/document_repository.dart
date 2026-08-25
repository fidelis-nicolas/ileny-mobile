// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/downloaded_file.dart';
import 'document_models.dart';

/// The caller's own documents, and what the organisation is still asking them for.
///
/// Entirely self-service: every path here is one of the `/employees/me/…` endpoints, which the
/// backend scopes to the signed-in account rather than taking an employee id. None of them needs
/// a permission, which is what makes this the right half of the feature to put on a phone — the
/// person who actually holds the certificate is the one who can photograph it.
///
/// HR's side — defining what is required, and filing documents against somebody else's record —
/// stays on the web client.
class DocumentRepository {
  DocumentRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  /// What is being asked for, and what has been filed against each requirement.
  ///
  /// Comes back empty when the organisation has defined no requirements, which is a normal state
  /// rather than an error — most organisations will not have set any up.
  Future<List<DocumentChecklistItem>> myChecklist() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/employees/me/documents/checklist',
      );
      return (response.data ?? [])
          .map((item) => DocumentChecklistItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Everything on the caller's record, including one-off documents that answer no requirement.
  Future<List<EmployeeDocument>> myDocuments() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>('/employees/me/documents');
      return (response.data ?? [])
          .map((item) => EmployeeDocument.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Files a document against the caller's own record.
  ///
  /// Exactly one of [documentRequirementId] and [documentType] is meaningful: naming a
  /// requirement is what puts the document on the checklist, and the requirement's own name then
  /// becomes the label, so sending a free-text one alongside it is ignored.
  ///
  /// [expiresOn] is **required** when the requirement is marked as expiring and **rejected**
  /// otherwise — the server refuses a date it would never check rather than storing one the
  /// caller believes is being tracked. Omitted rather than sent empty for that reason.
  ///
  /// There is deliberately no delete here. Staff replace a document by uploading a newer one, and
  /// the checklist takes the most recent as the answer; withdrawing one already handed to the
  /// organisation is HR's decision, not a button on the owner's own phone.
  Future<EmployeeDocument> uploadMyDocument({
    required String filePath,
    String? documentRequirementId,
    String? documentType,
    String? expiresOn,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'documentRequirementId': ?documentRequirementId,
        if (documentRequirementId == null && documentType != null && documentType.isNotEmpty)
          'documentType': documentType,
        if (expiresOn != null && expiresOn.isNotEmpty) 'expiresOn': expiresOn,
      });
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/employees/me/documents',
        data: formData,
      );
      return EmployeeDocument.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Downloads a stored document.
  ///
  /// `/files/**` is authenticated, so this goes through dio for the bearer token rather than
  /// handing a URL to the OS. [label] names the saved file because the backend deliberately does
  /// not — the stored name is a UUID, and the caller knows what the document is.
  Future<DownloadedFile> downloadDocument(String fileUrl, {required String label}) async {
    try {
      final response = await _dioClient.dio.get<List<int>>(
        fileUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return DownloadedFile(
        bytes: response.data!,
        filename: filenameFromContentDisposition(
          response.headers.value('content-disposition'),
          attachmentFilename(label, fileUrl),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
