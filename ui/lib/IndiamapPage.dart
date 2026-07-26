// india_map_page.dart
//
// Home tab: trending news carousel (live, from backend) + large
// interactive India map. Tapping a state opens a draggable bottom sheet.
// No own Scaffold — this is embedded as a tab inside RootShell.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Appcolors.dart';
import 'state_data.dart';
import 'trendingNews.dart';
import 'StateBottomSHeet.dart';

/// Public GeoJSON of Indian state boundaries (NAME_1 = state name).
const String indiaGeoJsonUrl =
    "https://raw.githubusercontent.com/geohacker/india/master/state/india_state.geojson";

class IndiaMapPage extends StatefulWidget {
  const IndiaMapPage({super.key});

  @override
  State<IndiaMapPage> createState() => _IndiaMapPageState();
}

class _IndiaMapPageState extends State<IndiaMapPage> {
  // ---- Map state ----
  List<_StateShape>? _shapes;
  String? _mapError;
  String? _selectedState;

  // ---- News state ----
  List<NewsItem>? _news; // null while loading
  String? _newsError;

  static const double _canvasW = 900;
  static const double _canvasH = 1000;

  @override
  void initState() {
    super.initState();
    _loadMap();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _newsError = null;
      _news = null;
    });
    try {
      final news = await fetchTrendingNews();
      if (!mounted) return;
      setState(() => _news = news);
    } catch (e) {
      if (!mounted) return;
      setState(() => _newsError = e.toString());
    }
  }

  Future<void> _loadMap() async {
    try {
      final res = await http.get(Uri.parse(indiaGeoJsonUrl));
      if (res.statusCode != 200) {
        throw Exception("Failed to load map (${res.statusCode})");
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;

      double minLon = 999, maxLon = -999, minLat = 999, maxLat = -999;
      final rawShapes = <_RawShape>[];

      for (final f in features) {
        final props = f['properties'] as Map<String, dynamic>;
        final name = (props['NAME_1'] ?? 'Unknown').toString();
        final geom = f['geometry'] as Map<String, dynamic>;
        final type = geom['type'] as String;
        final coords = geom['coordinates'];

        final polygons = <List<List<double>>>[];

        if (type == 'Polygon') {
          final outer = (coords[0] as List)
              .map<List<double>>((p) => [p[0] as double, p[1] as double])
              .toList();
          polygons.add(outer);
        } else if (type == 'MultiPolygon') {
          for (final poly in coords as List) {
            final outer = (poly[0] as List)
                .map<List<double>>((p) => [p[0] as double, p[1] as double])
                .toList();
            polygons.add(outer);
          }
        }

        for (final ring in polygons) {
          for (final pt in ring) {
            final lon = pt[0], lat = pt[1];
            if (lon < minLon) minLon = lon;
            if (lon > maxLon) maxLon = lon;
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
          }
        }

        rawShapes.add(_RawShape(name: name, polygons: polygons));
      }

      final meanLatRad = ((minLat + maxLat) / 2) * math.pi / 180;
      final lonCorrection = math.cos(meanLatRad);

      final projW = (maxLon - minLon) * lonCorrection;
      final projH = (maxLat - minLat);
      final scale = math.min(_canvasW / projW, _canvasH / projH) * 0.94;

      final usedW = projW * scale;
      final usedH = projH * scale;
      final offsetX = (_canvasW - usedW) / 2;
      final offsetY = (_canvasH - usedH) / 2;

      double toX(double lon) =>
          (lon - minLon) * lonCorrection * scale + offsetX;
      double toY(double lat) => (maxLat - lat) * scale + offsetY;

      final shapes = <_StateShape>[];
      for (final raw in rawShapes) {
        final path = Path();
        for (final ring in raw.polygons) {
          for (int i = 0; i < ring.length; i++) {
            final x = toX(ring[i][0]);
            final y = toY(ring[i][1]);
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
        }
        shapes.add(_StateShape(name: raw.name, path: path));
      }

      if (!mounted) return;
      setState(() => _shapes = shapes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _mapError = e.toString());
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_shapes == null) return;
    final pos = details.localPosition;
    for (final shape in _shapes!.reversed) {
      if (shape.path.contains(pos)) {
        setState(() => _selectedState = shape.name);
        showStateBottomSheet(context, shape.name);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'India Election Intelligence',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TrendingNewsCarousel(
              items: _news,
              error: _newsError,
              onRetry: _loadNews,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tap a state for details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (_selectedState != null)
                    Text(
                      _selectedState!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildMapBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBody() {
    if (_mapError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text('Could not load map:\n$_mapError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _mapError = null);
                  _loadMap();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_shapes == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading India map…'),
          ],
        ),
      );
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: FittedBox(
          child: SizedBox(
            width: _canvasW,
            height: _canvasH,
            child: GestureDetector(
              onTapUp: _onTapUp,
              child: CustomPaint(
                size: const Size(_canvasW, _canvasH),
                painter: _IndiaMapPainter(
                  shapes: _shapes!,
                  selected: _selectedState,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RawShape {
  final String name;
  final List<List<List<double>>> polygons;
  _RawShape({required this.name, required this.polygons});
}

class _StateShape {
  final String name;
  final Path path;
  _StateShape({required this.name, required this.path});
}

class _IndiaMapPainter extends CustomPainter {
  final List<_StateShape> shapes;
  final String? selected;

  _IndiaMapPainter({required this.shapes, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.mapFill
      ..style = PaintingStyle.fill;
    final selectedPaint = Paint()
      ..color = AppColors.mapSelected
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.mapBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (final shape in shapes) {
      final isSelected = shape.name == selected;
      canvas.drawPath(shape.path, isSelected ? selectedPaint : fillPaint);
      canvas.drawPath(shape.path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IndiaMapPainter oldDelegate) {
    return oldDelegate.selected != selected || oldDelegate.shapes != shapes;
  }
}