// state_data.dart
//
// Models + placeholder data for state details and trending news.
// Replace the `mock*` functions with real calls to your FastAPI backend
// once it's live — see comments inline.

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
/// works end-to-end today, before the backend endpoint exists.
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
  final String imageSeed; // used to generate a placeholder image
  const NewsItem({required this.title, required this.subtitle, required this.imageSeed});
}

/// TODO: replace with `GET $backendBaseUrl/news` per your architecture doc.
List<NewsItem> mockTrendingNews() {
  return const [
    NewsItem(
      title: 'Beredar Susunan Kabinet Paslon 02',
      subtitle: 'Trending',
      imageSeed: 'rally1',
    ),
    NewsItem(
      title: 'Penyebab Paslon 01 Kalah di Jatim',
      subtitle: 'Trending',
      imageSeed: 'rally2',
    ),
    NewsItem(
      title: 'Alliance Talks Continue in Bihar',
      subtitle: 'Live Update',
      imageSeed: 'rally3',
    ),
    NewsItem(
      title: 'Election Commission Issues Advisory',
      subtitle: 'Breaking',
      imageSeed: 'rally4',
    ),
  ];
}