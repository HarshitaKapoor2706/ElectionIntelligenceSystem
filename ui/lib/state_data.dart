// state_data.dart
//
// Models + data fetching for state details and trending news.
// News now fetches from your FastAPI backend (see backend/main.py).
// State info is still mock data — see mockStateInfo() below.

import 'dart:convert';
import 'package:http/http.dart' as http;

const String backendBaseUrl = "http://192.168.31.231:8000";

class CMRecord {
  final String name;
  final String party;
  final String years; // e.g. "2018 - 2023"
  const CMRecord({required this.name, required this.party, required this.years});
}

class TimelinePoint {
  final String year;
  final String party;
  const TimelinePoint({required this.year, required this.party});
}

class StateInfo {
  final String stateName;
  final CMRecord currentCM;
  final List<CMRecord> pastCMs;
  final String population;
  final String literacy;
  final String urbanPercent;
  final List<TimelinePoint> timeline;
  final Map<String, int> seatDistribution; // party -> seats
  final String publicSentiment;
  final List<String> keyIssues;
  final List<String> latestNews;

  const StateInfo({
    required this.stateName,
    required this.currentCM,
    required this.pastCMs,
    required this.population,
    required this.literacy,
    required this.urbanPercent,
    required this.timeline,
    required this.seatDistribution,
    required this.publicSentiment,
    required this.keyIssues,
    required this.latestNews,
  });
}

/// TODO: replace with `GET $backendBaseUrl/state/{name}` and parse the
/// JSON response into a StateInfo. Keeping this generator means the UI
/// works end-to-end today, before that backend endpoint exists.
StateInfo mockStateInfo(String stateName) {
  return StateInfo(
    stateName: stateName,
    currentCM: const CMRecord(name: 'TBD', party: 'BJP', years: '2023 - present'),
    pastCMs: const [
      CMRecord(name: 'Previous CM 1', party: 'INC', years: '2018 - 2023'),
      CMRecord(name: 'Previous CM 2', party: 'BJP', years: '2013 - 2018'),
    ],
    population: '68.5M',
    literacy: '69.7%',
    urbanPercent: '25%',
    timeline: const [
      TimelinePoint(year: '2013', party: 'BJP'),
      TimelinePoint(year: '2018', party: 'INC'),
      TimelinePoint(year: '2023', party: 'BJP'),
    ],
    seatDistribution: const {
      'BJP': 115,
      'INC': 69,
      'Others': 16,
    },
    publicSentiment: 'Mixed — cost of living and jobs dominate discussion',
    keyIssues: const [
      'Unemployment among youth',
      'Farmer support & MSP guarantees',
      'Water and infrastructure projects',
    ],
    latestNews: [
      '$stateName: Campaign rally draws large crowd',
      '$stateName: Manifesto release scheduled next week',
    ],
  );
}

class NewsItem {
  final String title;
  final String subtitle;
  final String? imageUrl; // null if the source didn't provide one
  final String? url; // article link, for "See all" / tap-through later
  const NewsItem({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.url,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: (json['title'] ?? 'Untitled').toString(),
      subtitle: (json['subtitle'] ?? 'News').toString(),
      imageUrl: json['imageUrl'] as String?,
      url: json['url'] as String?,
    );
  }
}

/// Fetches today's live news from the FastAPI backend's /news endpoint.
/// Throws on failure — callers should wrap this in a FutureBuilder or
/// try/catch and show an error/retry state (see TrendingNewsCarousel).
Future<List<NewsItem>> fetchTrendingNews() async {
  final res = await http
      .get(Uri.parse('$backendBaseUrl/news'))
      .timeout(const Duration(seconds: 12));

  if (res.statusCode != 200) {
    throw Exception('News request failed (${res.statusCode})');
  }

  final List<dynamic> data = jsonDecode(res.body);
  return data
      .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
      .toList();
}