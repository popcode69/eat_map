import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/shareable_status_card.dart';

/// Previews the user's shareable status card and lets them share it to a
/// social story or save it to their gallery as a high-resolution PNG.
class ShareStatusScreen extends StatefulWidget {
  final StatusCardData data;

  const ShareStatusScreen({super.key, required this.data});

  @override
  State<ShareStatusScreen> createState() => _ShareStatusScreenState();
}

class _ShareStatusScreenState extends State<ShareStatusScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isBusy = false;

  /// Renders the off-screen/​on-screen card boundary to PNG bytes at 3x for
  /// crisp story-quality output.
  Future<Uint8List?> _capturePng() async {
    final boundary = _cardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/eatmap_card_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _share() async {
    if (_isBusy) return;
    HapticFeedback.lightImpact();
    setState(() => _isBusy = true);
    try {
      final bytes = await _capturePng();
      if (bytes == null) throw Exception('Could not render card');
      final file = await _writeTempFile(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: widget.data.shareCaption,
      );
    } catch (e) {
      _toast('Could not share card: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isBusy) return;
    HapticFeedback.lightImpact();
    setState(() => _isBusy = true);
    try {
      final bytes = await _capturePng();
      if (bytes == null) throw Exception('Could not render card');

      // gal handles runtime permission requests internally.
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      final file = await _writeTempFile(bytes);
      await Gal.putImage(file.path, album: 'EatMap');
      _toast('Saved to your gallery! 🖼️');
    } on GalException catch (e) {
      _toast('Save failed: ${e.type.message}', isError: true);
    } catch (e) {
      _toast('Could not save card: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.getError(context) : AppColors.getSuccess(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text(
          'SHARE YOUR CARD',
          style: TextStyle(
            fontFamily: AppTypography.headingFont,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: ShareableStatusCard(data: widget.data),
                    ),
                  ),
                ),
              ),
            ),

            // Action bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                border: Border(
                  top: BorderSide(color: AppColors.getBorder(context), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _saveToGallery,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('SAVE'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                            color: AppColors.getPrimary(context), width: 1.5),
                        foregroundColor: AppColors.getPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _share,
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 20),
                      label: Text(_isBusy ? 'WORKING…' : 'SHARE TO STORY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getPrimary(context),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
