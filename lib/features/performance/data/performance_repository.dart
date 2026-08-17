// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/page_response.dart';
import 'performance_models.dart';

/// The employee's half of the performance module.
///
/// Mobile carries the employee's side only: their own appraisals, their own
/// self-assessment, the outcome, and their goals. Setting up templates, opening
/// cycles, and writing reviews are administrative jobs done sitting down, and
/// they live on the web client.
///
/// Every call here is scoped to the caller by the server, which is why none of
/// them takes an employee id, and why none needs a performance permission — an
/// ordinary employee holds none. An account with no linked employee record (an
/// admin-only login) gets an empty page rather than an error.
class PerformanceRepository {
  PerformanceRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  // --------------------------------------------------------------
  // Appraisals
  // --------------------------------------------------------------

  Future<PageResponse<Appraisal>> myAppraisals({int page = 0, int size = 20}) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/performance/appraisals/me',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, Appraisal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// One of the caller's own appraisals, with its criteria. `403` if it is not
  /// theirs.
  ///
  /// Reviewer fields come back null until the review is submitted, so a screen
  /// built on this must not assume a score is present just because the appraisal
  /// is.
  Future<Appraisal> myAppraisal(String appraisalId) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/performance/appraisals/me/$appraisalId',
      );
      return Appraisal.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Saves a partial self-assessment without submitting it.
  ///
  /// Only the criteria named are touched, so this is safe to call with one
  /// answer. Nothing is scored — an unsubmitted draft has no score.
  Future<Appraisal> saveSelfAssessment({
    required String appraisalId,
    required List<CriterionAnswer> answers,
    String? overallComment,
  }) async {
    return _writeSelfAssessment(
      appraisalId: appraisalId,
      answers: answers,
      overallComment: overallComment,
      submit: false,
    );
  }

  /// Submits the self-assessment and hands the appraisal to the reviewer.
  ///
  /// Every criterion must be rated; the server answers 400 otherwise. Final, and
  /// the UI should say so before calling this.
  Future<Appraisal> submitSelfAssessment({
    required String appraisalId,
    required List<CriterionAnswer> answers,
    String? overallComment,
  }) async {
    return _writeSelfAssessment(
      appraisalId: appraisalId,
      answers: answers,
      overallComment: overallComment,
      submit: true,
    );
  }

  Future<Appraisal> _writeSelfAssessment({
    required String appraisalId,
    required List<CriterionAnswer> answers,
    required bool submit,
    String? overallComment,
  }) async {
    final path = submit
        ? '/performance/appraisals/me/$appraisalId/self-assessment/submit'
        : '/performance/appraisals/me/$appraisalId/self-assessment';
    final body = <String, dynamic>{
      if (overallComment != null && overallComment.isNotEmpty) 'overallComment': overallComment,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
    try {
      final response = submit
          ? await _dioClient.dio.post<Map<String, dynamic>>(path, data: body)
          : await _dioClient.dio.put<Map<String, dynamic>>(path, data: body);
      return Appraisal.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Records that the employee has read the outcome, completing the appraisal.
  ///
  /// The comment is optional but kept permanently and never editable — a right
  /// of reply that can be revised away is not one. Acknowledging is not
  /// agreeing, and the screen that calls this must not imply otherwise.
  Future<Appraisal> acknowledge({
    required String appraisalId,
    String? comment,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/performance/appraisals/me/$appraisalId/acknowledge',
        data: {if (comment != null && comment.isNotEmpty) 'comment': comment},
      );
      return Appraisal.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // --------------------------------------------------------------
  // Goals
  // --------------------------------------------------------------

  Future<PageResponse<Goal>> myGoals({int page = 0, int size = 20}) async {
    try {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/performance/goals/me',
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data!, Goal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// A goal's check-ins, newest first. Readable by the employee the goal belongs
  /// to as well as by managers.
  Future<List<GoalUpdate>> goalUpdates(String goalId) async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/performance/goals/$goalId/updates',
      );
      return response.data!
          .map((e) => GoalUpdate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Records a check-in.
  ///
  /// Needs no permission when the goal is the caller's own — progress is
  /// reported by whoever is doing the work. Omitting [progressPercent] records a
  /// note without moving the goal. Closing a goal out is deliberately not
  /// offered here: whether it was achieved or missed is a judgement for whoever
  /// set it, and that decision belongs on the web client.
  Future<GoalUpdate> addGoalUpdate({
    required String goalId,
    String? note,
    int? progressPercent,
  }) async {
    try {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/performance/goals/$goalId/updates',
        data: {
          if (note != null && note.isNotEmpty) 'note': note,
          if (progressPercent != null) 'progressPercent': progressPercent,
        },
      );
      return GoalUpdate.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
