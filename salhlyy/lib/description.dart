import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'time&date.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class AudioRecording {
  final File file;
  final int duration;

  AudioRecording({required this.file, required this.duration});
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Playback'),
        backgroundColor: const Color(0xFF0C5FB3),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit height to 50% of screen
                      maxWidth: MediaQuery.of(context).size.width * 0.9,  // Limit width to 90% of screen
                    ),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class DescriptionScreen extends StatefulWidget {
  final Map<String, Map<String, int>> problemPriceRanges;
  final String phoneNumber;

  const DescriptionScreen({
    super.key,
    required this.problemPriceRanges,
    required this.phoneNumber,
  });

  @override
  _DescriptionScreenState createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isTyping = false;
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = [];
  final List<AudioRecording> _recordedAudios = [];
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  int? _playingAudioIndex;
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  final Map<int, String?> _videoThumbnails = {};

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_checkTyping);
    _initAudioRecorder();
    _initAudioPlayer();
    _loadSavedData();
  }

  @override
  void dispose() {
    _noteController.removeListener(_checkTyping);
    _noteController.dispose();
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.openPlayer();
  }

  Future<void> _loadSavedData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.phoneNumber)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        if (data['description'] != null) {
          final descriptionData = data['description'] as Map<String, dynamic>;
          setState(() {
            _noteController.text = descriptionData['note'] ?? '';
            _selectedImages.clear();
            _selectedVideos.clear();
            _recordedAudios.clear();

            if (descriptionData['images'] != null) {
              final imagePaths = List<String>.from(descriptionData['images']);
              _selectedImages.addAll(imagePaths.map((path) => File(path)).where((file) => file.existsSync()));
            }

            if (descriptionData['videos'] != null) {
              final videoPaths = List<String>.from(descriptionData['videos']);
              _selectedVideos.addAll(videoPaths.map((path) => File(path)).where((file) => file.existsSync()));
              for (int i = 0; i < _selectedVideos.length; i++) {
                _generateThumbnail(i, _selectedVideos[i]);
              }
            }

            if (descriptionData['audios'] != null) {
              final audios = List<dynamic>.from(descriptionData['audios']);
              for (var audio in audios) {
                final file = File(audio['path']);
                if (file.existsSync()) {
                  _recordedAudios.add(AudioRecording(file: file, duration: audio['duration']));
                }
              }
            }
          });
          _checkTyping();
        }
      }
    } catch (e) {
      print('Error loading saved data: $e');
    }
  }

  String _sanitizeKey(String key) {
    return key
        .replaceAll('.', '-')
        .replaceAll('#', '-')
        .replaceAll('\$', '-')
        .replaceAll('/', '-')
        .replaceAll('[', '-')
        .replaceAll(']', '-');
  }

  Future<void> _saveData() async {
    try {
      final Map<String, dynamic> problemsData = {};
      for (var problem in widget.problemPriceRanges.keys) {
        String sanitizedKey = _sanitizeKey(problem);
        problemsData[sanitizedKey] = {
          'min': widget.problemPriceRanges[problem]!['min'],
          'max': widget.problemPriceRanges[problem]!['max'],
          'note': _noteController.text,
          'images': _selectedImages.map((file) => file.path).toList(),
          'videos': _selectedVideos.map((file) => file.path).toList(),
          'audios': _recordedAudios.map((audio) => {
                'path': audio.file.path,
                'duration': audio.duration,
              }).toList(),
        };
      }

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.phoneNumber)
          .update({
        'plumbingproblem': problemsData,
        'description': {
          'note': _noteController.text,
          'images': _selectedImages.map((file) => file.path).toList(),
          'videos': _selectedVideos.map((file) => file.path).toList(),
          'audios': _recordedAudios.map((audio) => {
                'path': audio.file.path,
                'duration': audio.duration,
              }).toList(),
        },
      });
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  void _checkTyping() {
    setState(() {
      _isTyping = _noteController.text.isNotEmpty ||
          _selectedImages.isNotEmpty ||
          _selectedVideos.isNotEmpty ||
          _recordedAudios.isNotEmpty;
    });
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String fileName = '${directory.path}/audio_record_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _audioRecorder.startRecorder(toFile: fileName);
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      if (path != null) {
        setState(() {
          _recordedAudios.add(AudioRecording(file: File(path), duration: _recordingDuration));
          _isRecording = false;
          _recordingTimer?.cancel();
          _checkTyping();
        });
        _saveData();
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playAudio(int index) async {
    if (_playingAudioIndex != null) {
      await _audioPlayer.stopPlayer();
      setState(() {
        _playingAudioIndex = null;
      });
    }

    await _audioPlayer.setVolume(1.0); // Set volume to maximum for louder playback

    await _audioPlayer.startPlayer(
      fromURI: _recordedAudios[index].file.path,
      whenFinished: () {
        setState(() {
          _playingAudioIndex = null;
        });
      },
    );

    setState(() {
      _playingAudioIndex = index;
    });
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stopPlayer();
    setState(() {
      _playingAudioIndex = null;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
        _checkTyping();
      });
      _saveData();
    }
  }

  Future<void> _pickVideos() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final videoFile = File(video.path);
        setState(() {
          _selectedVideos.add(videoFile);
          _checkTyping();
          _generateThumbnail(_selectedVideos.length - 1, videoFile);
        });
        _saveData();
      }
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  Future<void> _generateThumbnail(int index, File videoFile) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 120,
        quality: 75,
      );
      if (thumbnailPath != null) {
        setState(() {
          _videoThumbnails[index] = thumbnailPath;
        });
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  bool _validateForm() {
    if (!_isTyping) {
      setState(() {
        _errorMessage = "Please add at least one note, image, video, or audio description";
      });
      return false;
    }
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  void _navigateToNext() {
    if (_validateForm()) {
      _saveData();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DateTimePickerScreen(phoneNumber: widget.phoneNumber)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Describe Your Request',
          style: TextStyle(fontFamily: 'Playfair_Display', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0C5FB3),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Could you describe your request in detail?',
                                style: TextStyle(fontSize: 24, fontFamily: 'Playfair_Display', color: const Color(0xFF0C5FB3), fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildSectionLabel('Add Text Description'),
                        const SizedBox(height: 10),
                        _buildInputField('Add Note', controller: _noteController),
                        const SizedBox(height: 25),
                        _buildSectionLabel('Add Voice Descriptions'),
                        const SizedBox(height: 10),
                        _buildVoiceNoteField(),
                        const SizedBox(height: 25),
                        _buildSectionLabel('Add Images'),
                        const SizedBox(height: 10),
                        _buildImagePickerField(),
                        const SizedBox(height: 25),
                        _buildSectionLabel('Add Videos'),
                        const SizedBox(height: 10),
                        _buildVideoPickerField(),
                        const SizedBox(height: 25),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        if (widget.problemPriceRanges.isNotEmpty) _buildPriceRangeSection(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildNavigationRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 18, fontFamily: 'Open Sans', fontWeight: FontWeight.bold, color: Color(0xFF0C5FB3)));
  }

  Widget _buildInputField(String placeholder, {TextEditingController? controller}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: const Color(0x4D000000)),
            border: InputBorder.none,
          ),
          maxLines: 5,
          onChanged: (_) => _saveData(),
        ),
      ),
    );
  }

  Widget _buildVoiceNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording) ...[
                  const Icon(Icons.stop, size: 30, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text('Recording... ', style: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: Colors.red, fontWeight: FontWeight.w500)),
                  Text(_formatDuration(_recordingDuration), style: const TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: Colors.red, fontWeight: FontWeight.w500)),
                ] else ...[
                  const Text('Record New Voice Note', style: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: Color(0xFF0C5FB3), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  const Icon(Icons.mic, size: 26, color: Color(0xFF0C5FB3)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (_recordedAudios.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recordedAudios.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_playingAudioIndex == index) {
                              _stopAudio();
                            } else {
                              _playAudio(index);
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(color: const Color(0xFF0C5FB3), borderRadius: BorderRadius.circular(25)),
                            child: Icon(_playingAudioIndex == index ? Icons.pause : Icons.play_arrow, size: 30, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Audio Recording ${index + 1}', style: const TextStyle(fontSize: 16, fontFamily: 'Open Sans', fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Container(
                                height: 20,
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('Duration: ${_formatDuration(_recordedAudios[index].duration)}', style: const TextStyle(fontSize: 12))],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            if (_playingAudioIndex == index) {
                              _stopAudio();
                            }
                            setState(() {
                              _recordedAudios.removeAt(index);
                              _checkTyping();
                            });
                            _saveData();
                          },
                          child: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImagePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_selectedImages.isNotEmpty ? 'Add More Images' : 'Add Images', style: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: const Color(0xFF0C5FB3), fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                const Icon(Icons.image, size: 26, color: Color(0xFF0C5FB3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  InteractiveViewer(
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                            image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        top: -5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                              _checkTyping();
                            });
                            _saveData();
                          },
                          child: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickVideos,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_selectedVideos.isNotEmpty ? 'Add More Videos' : 'Add Videos', style: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: const Color(0xFF0C5FB3), fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                const Icon(Icons.videocam, size: 26, color: Color(0xFF0C5FB3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (_selectedVideos.isNotEmpty)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVideos.length,
              itemBuilder: (context, index) {
                final thumbnailPath = _videoThumbnails[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(videoFile: _selectedVideos[index]),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                            image: thumbnailPath != null
                                ? DecorationImage(image: FileImage(File(thumbnailPath)), fit: BoxFit.cover)
                                : null,
                            color: thumbnailPath == null ? Colors.grey[300] : null,
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -5,
                        top: -5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedVideos.removeAt(index);
                              _videoThumbnails.remove(index);
                              // Rebuild thumbnail indices
                              final newThumbnails = <int, String?>{};
                              for (int i = 0; i < _selectedVideos.length; i++) {
                                newThumbnails[i] = _videoThumbnails[i + 1];
                              }
                              _videoThumbnails.clear();
                              _videoThumbnails.addAll(newThumbnails);
                              _checkTyping();
                            });
                            _saveData();
                          },
                          child: const CircleAvatar(backgroundColor: Colors.red, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const SizedBox(width: 8), const Text('Price Estimate', style: TextStyle(fontSize: 20, fontFamily: 'Open Sans', color: Color(0xFF0C5FB3), fontWeight: FontWeight.bold))]),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            ...widget.problemPriceRanges.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: Text(entry.key, style: const TextStyle(fontSize: 16, fontFamily: 'Open Sans', color: Colors.black87))),
                    Expanded(
                      flex: 1,
                      child: Text(
                        entry.value['min'] == entry.value['max'] ? 'EGP ${entry.value['min']}' : 'EGP ${entry.value['min']} - EGP ${entry.value['max']}',
                        style: const TextStyle(fontSize: 16, fontFamily: 'Open Sans', color: Colors.black87, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(thickness: 1),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Estimate:', style: TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: Color(0xFF0C5FB3), fontWeight: FontWeight.bold)),
                Text(
                  'EGP ${widget.problemPriceRanges.values.map((range) => range['min']).reduce((a, b) => a! + b!)} - EGP ${widget.problemPriceRanges.values.map((range) => range['max']).reduce((a, b) => a! + b!)}',
                  style: const TextStyle(fontSize: 18, fontFamily: 'Open Sans', color: Color(0xFF0C5FB3), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(child: Text('Final price depends on materials and problem complexity', style: TextStyle(fontSize: 14, fontFamily: 'Open Sans', color: Colors.black54, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _buildCircleButton(Icons.arrow_back),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '2 of 4',
              style: TextStyle(
                fontSize: 27,
                fontFamily: 'Open Sans',
                color: Color(0xFF0C5FB3),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isTyping ? _navigateToNext : null,
            child: _buildNextButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0C5FB3),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 24, color: Colors.white)),
      );

  Widget _buildNextButton() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _isTyping ? const Color(0xFF0C5FB3) : Colors.grey,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isTyping
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Open Sans',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plumbing Service',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DescriptionScreen(
        problemPriceRanges: {
          'Filter': {'min': 200, 'max': 500},
          'Toilet': {'min': 150, 'max': 1500},
        },
        phoneNumber: 'exampleUser',
      ),
    );
  }
}