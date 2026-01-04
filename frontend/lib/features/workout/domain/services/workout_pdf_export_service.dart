import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Service for exporting workout sessions to PDF format.
///
/// Generates formatted PDF documents containing workout details including
/// exercises, sets, reps, weights, and timing information. PDFs can be
/// saved to device storage or shared directly.
///
/// Example usage:
/// ```dart
/// final service = WorkoutPdfExportService();
/// final pdfFile = await service.exportWorkoutToPdf(workout, useImperial: true);
/// await service.shareWorkoutPdf(pdfFile);
/// ```
class WorkoutPdfExportService {
  /// Exports a workout session to PDF format.
  ///
  /// Parameters:
  /// - [workout]: The workout session to export
  /// - [useImperialUnits]: If true, displays weights in lbs, otherwise kg
  ///
  /// Returns a [File] object pointing to the generated PDF.
  Future<File> exportWorkoutToPdf(
    WorkoutSession workout, {
    bool useImperialUnits = true,
  }) async {
    final pdf = pw.Document();

    // Format dates and times
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final startDate = dateFormat.format(workout.startedAt);
    final startTime = timeFormat.format(workout.startedAt);

    String? endTime;
    if (workout.completedAt != null) {
      endTime = timeFormat.format(workout.completedAt!);
    }

    final weightUnit = useImperialUnits ? 'lbs' : 'kg';

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(workout.title, startDate),

          pw.SizedBox(height: 20),

          // Workout summary
          _buildSummarySection(
            startTime: startTime,
            endTime: endTime,
            duration: workout.durationMinutes,
            exerciseCount: workout.exercises.length,
          ),

          pw.SizedBox(height: 20),

          // Exercises
          ...workout.exercises.map((exercise) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 16),
                _buildExerciseSection(
                  exercise.exerciseName,
                  exercise.sets,
                  weightUnit,
                  exercise.notes,
                ),
              ],
            );
          }),

          // Notes section
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildNotesSection(workout.notes!),
          ],

          // Footer
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    // Save PDF to temporary directory
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        'workout_${workout.title.replaceAll(' ', '_')}_$timestamp.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Shares a PDF file using the platform's share dialog.
  Future<void> shareWorkoutPdf(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'My Workout',
      text: 'Check out my workout from LiftLink!',
    );
  }

  /// Builds the PDF header with title and date.
  pw.Widget _buildHeader(String title, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          date,
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Builds the summary section with workout metadata.
  pw.Widget _buildSummarySection({
    required String startTime,
    String? endTime,
    int? duration,
    required int exerciseCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Start Time', startTime),
          if (endTime != null) _buildSummaryItem('End Time', endTime),
          if (duration != null) _buildSummaryItem('Duration', '$duration min'),
          _buildSummaryItem('Exercises', '$exerciseCount'),
        ],
      ),
    );
  }

  /// Builds a single summary item.
  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds an exercise section with sets table.
  pw.Widget _buildExerciseSection(
    String exerciseName,
    List<dynamic> sets,
    String weightUnit,
    String? notes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          exerciseName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),

        // Sets table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: [
                _buildTableCell('Set', isHeader: true),
                _buildTableCell('Weight ($weightUnit)', isHeader: true),
                _buildTableCell('Reps', isHeader: true),
              ],
            ),
            // Data rows
            ...sets.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final set = entry.value;
              return pw.TableRow(
                children: [
                  _buildTableCell('$index'),
                  _buildTableCell(
                    set.weightKg != null
                        ? set.weightKg!.toStringAsFixed(1)
                        : '-',
                  ),
                  _buildTableCell(set.reps?.toString() ?? '-'),
                ],
              );
            }),
          ],
        ),

        // Exercise notes
        if (notes != null && notes.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Notes: $notes',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a table cell widget.
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Builds the workout notes section.
  pw.Widget _buildNotesSection(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Workout Notes',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Builds the PDF footer.
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by LiftLink',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}
