import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Sarvam AI Service for speech-to-text transcription and translation
class SarvamService {
  static final SarvamService _instance = SarvamService._internal();
  factory SarvamService() => _instance;
  SarvamService._internal();

  static const Map<String, String> languageCodes = {
    'Hindi': 'hi-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
    'Bengali': 'bn-IN',
    'Marathi': 'mr-IN',
    'Gujarati': 'gu-IN',
    'Punjabi': 'pa-IN',
    'Odia': 'od-IN',
    'Assamese': 'unknown',
    'English': 'en-IN',
  };

  String getLanguageCode(String language) {
    return languageCodes[language] ?? 'hi-IN';
  }

  /// Transcribe and translate audio file
  /// Uses batch API for longer files with diarization
  Future<TranscriptionResult> transcribeAudio({
    required String audioFilePath,
    required String language,
  }) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return TranscriptionResult.error('Audio file not found');
      }

      final fileSize = await file.length();
      
      // Better duration estimation based on WAV file header or heuristics
      // Default: assume 16-bit mono at 16kHz (32000 bytes/sec)
      // But also handle stereo 44.1kHz (176400 bytes/sec)
      double estimatedDuration;
      
      // Try to read WAV header for accurate duration
      try {
        final bytes = await file.openRead(0, 44).toList();
        final headerBytes = bytes.expand((x) => x).toList();
        
        if (headerBytes.length >= 44 && 
            String.fromCharCodes(headerBytes.sublist(0, 4)) == 'RIFF') {
          // Parse WAV header
          final sampleRate = headerBytes[24] | 
                            (headerBytes[25] << 8) | 
                            (headerBytes[26] << 16) | 
                            (headerBytes[27] << 24);
          final byteRate = headerBytes[28] | 
                          (headerBytes[29] << 8) | 
                          (headerBytes[30] << 16) | 
                          (headerBytes[31] << 24);
          
          if (byteRate > 0) {
            estimatedDuration = (fileSize - 44) / byteRate;
            print('WAV header parsed: sampleRate=$sampleRate, byteRate=$byteRate');
          } else {
            // Fallback: assume common format (stereo 44.1kHz 16-bit)
            estimatedDuration = fileSize / 176400;
          }
        } else {
          // Not a WAV file or can't parse, use conservative estimate
          estimatedDuration = fileSize / 32000;
        }
      } catch (e) {
        // Fallback to conservative estimate
        estimatedDuration = fileSize / 32000;
        print('Could not parse audio header: $e');
      }

      print(
        'Audio file size: $fileSize bytes, estimated duration: ${estimatedDuration.toStringAsFixed(1)}s',
      );

      // Always use batch API to get diarization (speaker identification)
      // The real-time API doesn't support diarization
      print('Using batch API for diarization support');
      return await _transcribeWithDiarization(audioFilePath, language);
    } catch (e) {
      return TranscriptionResult.error('Transcription error: $e');
    }
  }

  /// Batch translate API with diarization support
  Future<TranscriptionResult> _transcribeWithDiarization(
    String audioFilePath,
    String language,
  ) async {
    try {
      final languageCode = getLanguageCode(language);
      final file = File(audioFilePath);
      final filename = audioFilePath.split('/').last;

      // Step 1: Create translate job with diarization
      print('Creating batch translate job with diarization...');
      final createJobResponse = await http.post(
        Uri.parse('${AppConfig.sarvamApiUrl}/speech-to-text-translate/job/v1'),
        headers: {
          'api-subscription-key': AppConfig.sarvamApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'job_parameters': {
            'model': 'saaras:v2.5',
            'with_diarization': true,
            'num_speakers': 2,
          },
        }),
      );

      print('Create job response: ${createJobResponse.statusCode} - ${createJobResponse.body}');

      if (createJobResponse.statusCode != 202 && createJobResponse.statusCode != 200) {
        return TranscriptionResult.error(
          'Failed to create job: ${createJobResponse.body}',
        );
      }

      final jobData = jsonDecode(createJobResponse.body);
      final jobId = jobData['job_id'];
      print('Job created with ID: $jobId');

      // Step 2: Get upload URL
      print('Getting upload URL...');
      final uploadUrlResponse = await http.post(
        Uri.parse(
          '${AppConfig.sarvamApiUrl}/speech-to-text-translate/job/v1/upload-files',
        ),
        headers: {
          'api-subscription-key': AppConfig.sarvamApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'job_id': jobId,
          'files': [filename],
        }),
      );

      if (uploadUrlResponse.statusCode != 200) {
        return TranscriptionResult.error(
          'Failed to get upload URL: ${uploadUrlResponse.body}',
        );
      }

      final uploadData = jsonDecode(uploadUrlResponse.body);
      final uploadUrls = uploadData['upload_urls'] as Map<String, dynamic>;
      final fileDetails = uploadUrls[filename];
      final uploadUrl = fileDetails['file_url'] ?? fileDetails['url'];

      if (uploadUrl == null) {
        return TranscriptionResult.error('Could not extract upload URL');
      }

      print('Got upload URL');

      // Step 3: Upload audio file
      print('Uploading audio file...');
      final audioBytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'x-ms-blob-type': 'BlockBlob', 'Content-Type': 'audio/wav'},
        body: audioBytes,
      );

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        return TranscriptionResult.error(
          'Upload failed: ${uploadResponse.statusCode}',
        );
      }

      print('Audio file uploaded successfully');

      // Step 4: Start the job
      print('Starting translate job...');
      final startResponse = await http.post(
        Uri.parse(
          '${AppConfig.sarvamApiUrl}/speech-to-text-translate/job/v1/$jobId/start',
        ),
        headers: {'api-subscription-key': AppConfig.sarvamApiKey},
      );

      if (startResponse.statusCode != 200 && startResponse.statusCode != 202) {
        return TranscriptionResult.error(
          'Failed to start job: ${startResponse.body}',
        );
      }

      print('Job started');

      // Step 5: Poll for completion
      print('Waiting for transcription and translation to complete...');
      String? outputFilename;

      for (int attempt = 0; attempt < 120; attempt++) {
        await Future.delayed(const Duration(seconds: 5));

        final statusResponse = await http.get(
          Uri.parse(
            '${AppConfig.sarvamApiUrl}/speech-to-text-translate/job/v1/$jobId/status',
          ),
          headers: {'api-subscription-key': AppConfig.sarvamApiKey},
        );

        if (statusResponse.statusCode != 200) {
          continue;
        }

        final statusData = jsonDecode(statusResponse.body);
        final status = (statusData['job_state'] ?? statusData['status'] ?? '')
            .toString()
            .toLowerCase();
        print('Job status (attempt ${attempt + 1}): $status');

        if (status == 'completed' || status == 'success' || status == 'done') {
          // Extract output filename
          final jobDetails = statusData['job_details'] as List?;
          if (jobDetails != null && jobDetails.isNotEmpty) {
            final outputs = jobDetails[0]['outputs'] as List?;
            if (outputs != null && outputs.isNotEmpty) {
              outputFilename = outputs[0]['file_name'];
              print('Output filename: $outputFilename');
            }
          }
          break;
        } else if (status == 'failed' || status == 'error') {
          return TranscriptionResult.error(
            'Job failed: ${statusData['error_message'] ?? 'Unknown error'}',
          );
        }
      }

      // Step 6: Get download URL and fetch results
      print('Getting translation results...');
      outputFilename ??= '0.json';

      final downloadUrlResponse = await http.post(
        Uri.parse(
          '${AppConfig.sarvamApiUrl}/speech-to-text-translate/job/v1/download-files',
        ),
        headers: {
          'api-subscription-key': AppConfig.sarvamApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'job_id': jobId,
          'files': [outputFilename],
        }),
      );

      if (downloadUrlResponse.statusCode != 200) {
        return TranscriptionResult.error(
          'Failed to get download URL: ${downloadUrlResponse.body}',
        );
      }

      final downloadData = jsonDecode(downloadUrlResponse.body);
      final downloadUrls =
          downloadData['download_urls'] as Map<String, dynamic>;
      final downloadDetails = downloadUrls[outputFilename];
      final downloadUrl = downloadDetails['file_url'] ?? downloadDetails['url'];

      if (downloadUrl == null) {
        return TranscriptionResult.error('Could not extract download URL');
      }

      // Download result
      final resultResponse = await http.get(Uri.parse(downloadUrl));
      final resultData = jsonDecode(resultResponse.body);

      // Extract transcript and translation
      String transcript = resultData['transcript'] ?? '';
      String translation = resultData['translation'] ?? '';

      // Handle diarization results - API may return different formats
      print('Result data keys: ${resultData.keys}');
      List<dynamic>? diarization;
      
      // Try to extract diarization data from various possible formats
      final diarizedTranscript = resultData['diarized_transcript'];
      print('diarized_transcript type: ${diarizedTranscript?.runtimeType}');
      print('diarized_transcript value: $diarizedTranscript');
      
      if (diarizedTranscript != null) {
        if (diarizedTranscript is List) {
          // Direct list format
          diarization = diarizedTranscript;
        } else if (diarizedTranscript is Map) {
          // Map format - look for entries/segments/speakers inside
          if (diarizedTranscript['entries'] is List) {
            diarization = diarizedTranscript['entries'] as List;
          } else if (diarizedTranscript['segments'] is List) {
            diarization = diarizedTranscript['segments'] as List;
          } else if (diarizedTranscript['speakers'] is List) {
            diarization = diarizedTranscript['speakers'] as List;
          } else {
            // Try to convert map entries to a list format
            // The map might have speaker keys with their text
            final entries = <Map<String, dynamic>>[];
            diarizedTranscript.forEach((key, value) {
              if (value is Map) {
                entries.add({
                  'speaker': key,
                  'text': value['text'] ?? value['transcript'] ?? '',
                  'start': value['start'] ?? 0,
                  'end': value['end'] ?? 0,
                });
              } else if (value is String) {
                entries.add({
                  'speaker': key,
                  'text': value,
                });
              }
            });
            if (entries.isNotEmpty) {
              diarization = entries;
            }
          }
        }
      }
      
      // Fallback to 'diarization' key if diarized_transcript didn't work
      if (diarization == null && resultData['diarization'] is List) {
        diarization = resultData['diarization'] as List;
      }
      
      print('Parsed diarization: $diarization');
      if (diarization != null && diarization.isNotEmpty) {
        print('Diarization found with ${diarization.length} segments');
      } else {
        print('No diarization data found in API response');
      }

      // Alternative format handling
      if (transcript.isEmpty && resultData['results'] != null) {
        final results = resultData['results'] as List;
        transcript = results.map((r) => r['transcript'] ?? '').join(' ');
        translation = results.map((r) => r['translation'] ?? '').join(' ');
      }

      // Build combined text - skip headers if we have diarization
      String combinedText;
      if (diarization != null && diarization.isNotEmpty) {
        // Just use the transcript for diarization mode
        // The UI will handle formatting with speaker names
        combinedText = transcript;
      } else {
        // No diarization - show original format with headers
        combinedText = transcript;
        if (translation.isNotEmpty) {
          combinedText += '\n\n[English Translation]\n$translation';
        }
      }
      
      print(
        'Translation completed. Transcript: ${transcript.length} chars, Translation: ${translation.length} chars',
      );

      return TranscriptionResult.success(
        transcription: combinedText,
        originalTranscript: transcript,
        englishTranslation: translation,
        languageCode: languageCode,
        diarization: diarization,
      );
    } catch (e) {
      return TranscriptionResult.error('Batch transcription error: $e');
    }
  }
}

/// Result of transcription operation
class TranscriptionResult {
  final bool success;
  final String? transcription;
  final String? originalTranscript;
  final String? englishTranslation;
  final String? languageCode;
  final List<dynamic>? diarization;
  final String? error;

  TranscriptionResult._({
    required this.success,
    this.transcription,
    this.originalTranscript,
    this.englishTranslation,
    this.languageCode,
    this.diarization,
    this.error,
  });

  factory TranscriptionResult.success({
    required String transcription,
    String? originalTranscript,
    String? englishTranslation,
    String? languageCode,
    List<dynamic>? diarization,
  }) {
    return TranscriptionResult._(
      success: true,
      transcription: transcription,
      originalTranscript: originalTranscript,
      englishTranslation: englishTranslation,
      languageCode: languageCode,
      diarization: diarization,
    );
  }

  factory TranscriptionResult.error(String error) {
    return TranscriptionResult._(success: false, error: error);
  }
}
