import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'features/admin/admin_panel_screen.dart' as admin_feature;
import 'features/agent/agent_panel_screen.dart' as agent_feature;
import 'features/ai_guide/guide_selection_screen.dart' as guide_feature;
import 'features/auth/login_screen.dart' as auth_feature;
import 'features/tours/tours_list_screen.dart' as tours_feature;
import 'localized_content.dart';
import 'services/auth_service.dart';
import 'services/locations_override_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SacredKgApp()));
}

String t(String value) => LocalizedContent.phrase(value);

String tWith(String value, Map<String, Object> args) {
  var result = t(value);
  for (final entry in args.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value.toString());
  }
  return result;
}

final authProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});

final settingsProvider = ChangeNotifierProvider<SettingsController>((ref) {
  return SettingsController();
});

final appStateProvider = ChangeNotifierProvider<MockAppState>((ref) {
  return MockAppState();
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      _appRoute('/', (_, __) => const SplashScreen()),
      _appRoute('/onboarding', (_, __) => const OnboardingScreen()),
      _appRoute('/login', (_, __) => const auth_feature.LoginScreen()),
      _appRoute('/register', (_, __) => const RegisterScreen()),
      _appRoute('/admin', (_, __) => const admin_feature.AdminPanelScreen()),
      _appRoute('/agent', (_, __) => const agent_feature.AgentPanelScreen()),
      _appRoute('/tours', (_, __) => const tours_feature.ToursListScreen()),
      _appRoute('/home', (_, __) => const HomeScreen()),
      _appRoute('/map', (_, __) => const RegionsScreen()),
      _appRoute(
        '/region/:id',
        (_, state) => CatalogScreen(regionId: state.pathParameters['id']),
      ),
      _appRoute('/catalog', (_, __) => const CatalogScreen()),
      _appRoute(
        '/place/:id',
        (_, state) => PlaceDetailScreen(placeId: state.pathParameters['id']!),
      ),
      _appRoute(
        '/ai',
        (_, __) => const guide_feature.GuideSelectionScreen(),
      ),
      _appRoute('/feed', (_, __) => const FeedScreen()),
      _appRoute('/feed/create', (_, __) => const CreatePostScreen()),
      _appRoute(
        '/booking',
        (_, state) =>
            BookingScreen(placeId: state.uri.queryParameters['place']),
      ),
      _appRoute('/settings', (_, __) => const SettingsScreen()),
      _appRoute('/account', (_, __) => const AccountScreen()),
    ],
  );
});

GoRoute _appRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return GoRoute(path: path, pageBuilder: _animatedPage(builder));
}

Page<void> Function(BuildContext, GoRouterState) _animatedPage(
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return (context, state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 190),
      child: builder(context, state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0.015),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  };
}

class SacredKgApp extends ConsumerWidget {
  const SacredKgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    Intl.defaultLocale = settings.language;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale(settings.language),
    );
  }
}

class AppTheme {
  static const ink = Color(0xFF202721);
  static const leaf = Color(0xFF2D6A4F);
  static const mint = Color(0xFFB7E4C7);
  static const clay = Color(0xFF9B4D2E);
  static const gold = Color(0xFFE0A02E);
  static const rose = Color(0xFFB93F55);
  static const cloud = Color(0xFFF4F7F2);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: leaf,
      brightness: Brightness.light,
      primary: leaf,
      secondary: clay,
      tertiary: rose,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cloud,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      chipTheme: ChipThemeData(
        selectedColor: mint,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: leaf,
      brightness: Brightness.dark,
      primary: mint,
      secondary: gold,
      tertiary: rose,
      surface: const Color(0xFF18201A),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101510),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF18201A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

enum PlaceType {
  sacredPlace('Sacred place'),
  petroglyphSite('Petroglyph site'),
  mausoleum('Mausoleum'),
  sacredSpring('Sacred spring'),
  historicalComplex('Historical complex'),
  archaeologicalSite('Archaeological site'),
  naturalSacredPlace('Natural sacred place');

  const PlaceType(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('placeType', name, _label);
}

enum PostType {
  review('Review'),
  issue('Issue'),
  tip('Tip'),
  experience('Experience');

  const PostType(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('postType', name, _label);
}

enum BookingStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const BookingStatus(this._label);
  final String _label;

  String get label => LocalizedContent.enumLabel('bookingStatus', name, _label);
}

class Region {
  const Region({
    required this.id,
    required String name,
    required String subtitle,
    required this.color,
    required List<String> highlights,
  }) : _name = name,
       _subtitle = subtitle,
       _highlights = highlights;

  final String id;
  final String _name;
  final String _subtitle;
  final Color color;
  final List<String> _highlights;

  String get name => LocalizedContent.regionField(id, 'name', _name);
  String get subtitle =>
      LocalizedContent.regionField(id, 'subtitle', _subtitle);
  List<String> get highlights =>
      LocalizedContent.regionHighlights(id, _highlights);
}

class Place {
  const Place({
    required this.id,
    required String title,
    required this.regionId,
    required this.type,
    required this.rating,
    required this.popularity,
    required this.reviewsCount,
    required String shortDescription,
    required String description,
    required String culturalNote,
    required String visitingRules,
    required String route,
    required this.colors,
    String fullDescription = '',
    String imageUrl = '',
    List<String> images = const <String>[],
  }) : _title = title,
       _shortDescription = shortDescription,
       _description = description,
       _culturalNote = culturalNote,
       _visitingRules = visitingRules,
       _route = route,
       _fullDescription = fullDescription,
       _imageUrl = imageUrl,
       _images = images;

  final String id;
  final String _title;
  final String regionId;
  final PlaceType type;
  final double rating;
  final int popularity;
  final int reviewsCount;
  final String _shortDescription;
  final String _description;
  final String _culturalNote;
  final String _visitingRules;
  final String _route;
  final String _fullDescription;
  final String _imageUrl;
  final List<String> _images;
  final List<Color> colors;

  LocationOverride? get _override =>
      LocationOverridesService.overrideForSync(id);

  String get title {
    final o = _override?.title;
    if (o != null && o.isNotEmpty) return o;
    return LocalizedContent.placeField(id, 'title', _title);
  }

  String get shortDescription {
    final o = _override?.shortDescription;
    if (o != null && o.isNotEmpty) return o;
    return LocalizedContent.placeField(id, 'shortDescription', _shortDescription);
  }

  String get description =>
      LocalizedContent.placeField(id, 'description', _description);

  String get fullDescription {
    final o = _override?.fullDescription;
    if (o != null && o.isNotEmpty) return o;
    return _fullDescription;
  }

  String get imageUrl {
    final o = _override?.imageUrl;
    if (o != null && o.isNotEmpty) return o;
    if (_imageUrl.isNotEmpty) return _imageUrl;
    if (_images.isNotEmpty) return _images.first;
    return '';
  }

  /// Полная галерея фотографий для места.
  /// Если админ переопределил imageUrl — возвращаем [imageUrl, ...остальные].
  List<String> get images {
    final overrideUrl = _override?.imageUrl;
    final list = <String>[];
    if (overrideUrl != null && overrideUrl.isNotEmpty) {
      list.add(overrideUrl);
    }
    for (final img in _images) {
      if (!list.contains(img)) list.add(img);
    }
    if (list.isEmpty && _imageUrl.isNotEmpty) list.add(_imageUrl);
    return list;
  }

  String get culturalNote {
    final o = _override?.culturalNote;
    if (o != null && o.isNotEmpty) return o;
    return LocalizedContent.placeField(id, 'culturalNote', _culturalNote);
  }

  String get visitingRules {
    final o = _override?.visitingRules;
    if (o != null && o.isNotEmpty) return o;
    return LocalizedContent.placeField(id, 'visitingRules', _visitingRules);
  }

  String get route {
    final o = _override?.route;
    if (o != null && o.isNotEmpty) return o;
    return LocalizedContent.placeField(id, 'route', _route);
  }
}

class Review {
  const Review({
    required this.placeId,
    required this.user,
    required this.rating,
    required String text,
  }) : _text = text;

  final String placeId;
  final String user;
  final double rating;
  final String _text;

  String get text => LocalizedContent.reviewText(placeId, user, _text);
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required String userName,
    required String text,
    required this.timestamp,
    required this.type,
    required this.likeCount,
    required this.commentCount,
    this.placeId,
    this.color = AppTheme.leaf,
  }) : _userName = userName,
       _text = text;

  final String id;
  final String _userName;
  final String _text;
  final DateTime timestamp;
  final PostType type;
  final int commentCount;
  final String? placeId;
  final Color color;
  int likeCount;
  bool liked = false;

  String get userName => LocalizedContent.phrase(_userName);
  String get text => LocalizedContent.postText(id, _text);
}

class Booking {
  Booking({
    required this.id,
    required this.placeId,
    required String placeTitle,
    required this.date,
    required this.peopleCount,
    required String notes,
    required this.rulesConfirmed,
    required this.status,
    required this.createdAt,
  }) : _placeTitle = placeTitle,
       _notes = notes;

  final String id;
  final String placeId;
  final String _placeTitle;
  final DateTime date;
  final int peopleCount;
  final String _notes;
  final bool rulesConfirmed;
  final BookingStatus status;
  final DateTime createdAt;

  String get placeTitle =>
      LocalizedContent.placeField(placeId, 'title', _placeTitle);
  String get notes => LocalizedContent.bookingNote(id, _notes);
}

class AiCharacter {
  const AiCharacter({
    required this.id,
    required String name,
    required String role,
    required this.color,
  }) : _name = name,
       _role = role;

  final String id;
  final String _name;
  final String _role;
  final Color color;

  String get name => LocalizedContent.characterField(id, 'name', _name);
  String get role => LocalizedContent.characterField(id, 'role', _role);
}

class ChatMessage {
  const ChatMessage({
    required String text,
    required this.fromUser,
    required this.timestamp,
  }) : _text = text;

  final String _text;
  final bool fromUser;
  final DateTime timestamp;

  String get text => fromUser ? _text : LocalizedContent.phrase(_text);
}

class MockData {
  static const regions = [
    Region(
      id: 'chuy',
      name: 'Chuy',
      subtitle: 'Towers, valleys, and old caravan roads',
      color: Color(0xFF2D6A4F),
      highlights: ['Burana', 'Ala-Archa', 'pilgrim routes'],
    ),
    Region(
      id: 'issyk_kul',
      name: 'Issyk-Kul',
      subtitle: 'Lake legends and ancient stones',
      color: Color(0xFF1D7D73),
      highlights: ['Cholpon-Ata', 'Manjyly-Ata', 'lake shrines'],
    ),
    Region(
      id: 'naryn',
      name: 'Naryn',
      subtitle: 'High passes and caravan memory',
      color: Color(0xFF5B7C46),
      highlights: ['Tash Rabat', 'Son-Kul', 'mountain trails'],
    ),
    Region(
      id: 'talas',
      name: 'Talas',
      subtitle: 'Epic heritage and open valleys',
      color: Color(0xFF9B4D2E),
      highlights: ['Manas Ordo', 'Kirov valley', 'oral history'],
    ),
    Region(
      id: 'osh',
      name: 'Osh',
      subtitle: 'Sulaiman-Too and Silk Road layers',
      color: Color(0xFFB93F55),
      highlights: ['Sulaiman-Too', 'old city', 'springs'],
    ),
    Region(
      id: 'jalal_abad',
      name: 'Jalal-Abad',
      subtitle: 'Walnut forests and healing waters',
      color: Color(0xFFE0A02E),
      highlights: ['Arslanbob', 'springs', 'forest paths'],
    ),
    Region(
      id: 'batken',
      name: 'Batken',
      subtitle: 'Rock, flowers, and southern legends',
      color: Color(0xFF8064A2),
      highlights: ['Aigul-Tash', 'caves', 'borderland stories'],
    ),
  ];

  static final places = [
    Place(
      id: 'burana',
      title: 'Burana Tower',
      regionId: 'chuy',
      type: PlaceType.historicalComplex,
      rating: 4.8,
      popularity: 96,
      reviewsCount: 42,
      shortDescription:
          'A minaret and open-air museum near the ancient city of Balasagun.',
      description:
          'Burana Tower is one of the most recognizable heritage sites in northern Kyrgyzstan. The demo story frames it as a calm starting point for learning about caravan routes, stone balbals, and city life on the Silk Road.',
      culturalNote:
          'Visitors often connect the site with memory, travel, and the long exchange of languages and crafts across the valley.',
      visitingRules:
          'Walk carefully around stones, do not climb restricted areas, keep voices low near memorial objects, and leave no marks.',
      route:
          'From Bishkek, take the road toward Tokmok. Local transport or a short taxi ride can complete the route.',
      colors: [Color(0xFF2D6A4F), Color(0xFFE0A02E), Color(0xFF9B4D2E)],
      fullDescription:
          'История.\n'
          'Башня Бурана — последнее, что осталось от древнего города Баласагун, столицы Караханидского каганата (X–XII вв.). Город был одним из главных центров Великого Шёлкового пути и духовно-научной жизни Центральной Азии: здесь жили астрономы, поэты, суфийские учителя. После монгольского нашествия в XIII в. Баласагун пришёл в упадок и постепенно был занесён песком; от него остались минарет, фундаменты медресе и мавзолеев, а также сотни каменных истуканов-балбалов. Сам минарет изначально достигал около 45 м; современная высота — 24 м: верхушка обрушилась во время мощного землетрясения XV в.\n\n'
          'Архитектура.\n'
          'Башня сложена из обожжённого кирпича с восемью поясами орнамента: ромбы, плетёнки, «звёздные» узоры. Внутри — тесная винтовая лестница на 38 ступеней, сначала наружная, затем внутренняя. У подножия — фундамент мечети и фрагменты караван-сарайных стен. Вокруг — открытое поле с балбалами (каменными воинами, отмечавшими могилы знати), жерновами и каменными жертвенниками-чашами.\n\n'
          'Легенды.\n'
          'По местному преданию хан построил башню, чтобы укрыть дочь от пророчества о её скорой смерти. Но в день её 18-летия в башню всё равно попал смертельный укол — паук, спрятанный в плодах. Историки относят эту легенду к XIX веку, но она хорошо передаёт ощущение «башни-стражницы» посреди степи.\n\n'
          'Ритуалы и духовное значение.\n'
          'Балбалы — это не идолы, а память: каждый камень обозначал воина, погибшего за общину. К ним относятся уважительно: не садятся, не фотографируются «верхом», не оставляют мусор. В дни поминовения местные жители ставят рядом пиалу воды и кусочек лепёшки.\n\n'
          'Как добраться.\n'
          'Из Бишкека: маршрутка №353 до Токмока (около 1 ч), далее такси 12 км к башне (≈300 сом туда-обратно с ожиданием). На своём авто — по трассе Бишкек–Иссык-Куль, после Токмока поворот на юг, указатели на «Burana». Билет в музей — символический, около 70 сом.\n\n'
          'Лучшее время.\n'
          'Апрель–октябрь, утром до 10:00 или после 17:00 — днём в долине жарко и нет тени. Особенно красиво в мае (зелёные холмы) и октябре (золотая степь).\n\n'
          'Окрестности.\n'
          'В радиусе 20 минут езды: город Токмок (с краеведческим музеем и базаром), парк «Бурана-Археопарк», ущелье Кегеты с водопадом (час езды). Идеально совместить с однодневным выездом по Чуйской долине.\n\n'
          'Советы.\n'
          'Возьмите воду, головной убор и удобную обувь (винтовая лестница узкая и неровная). Поднимайтесь медленно и не толпой. Не царапайте кирпич и не прикасайтесь к надписям. На территории живут суслики — кормить их нельзя, это нарушает местную экосистему.',
      imageUrl: 'assets/places/burana_1.jpg',
      images: [
        'assets/places/burana_1.jpg',
        'assets/places/burana_2.jpg',
        'assets/places/burana_3.jpg',
        'assets/places/burana_4.jpg',
        'assets/places/burana_5.jpg',
      ],
    ),
    Place(
      id: 'ala_archa',
      title: 'Ala-Archa Sacred Valley',
      regionId: 'chuy',
      type: PlaceType.naturalSacredPlace,
      rating: 4.7,
      popularity: 88,
      reviewsCount: 31,
      shortDescription:
          'Mountain paths, clear water, and quiet places for reflection.',
      description:
          'This prototype treats Ala-Archa as a nature-centered sacred route, focusing on respectful hiking, water sources, and the feeling of entering a protected mountain space.',
      culturalNote:
          'Mountain valleys are often treated with care because water, stones, and paths carry family and seasonal memory.',
      visitingRules:
          'Stay on marked paths, respect wildlife, avoid loud music, and pack out all waste.',
      route:
          'Reach the park from Bishkek by car or organized transport, then follow marked trails.',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFF5B7C46)],
      fullDescription:
          'История.\n'
          'Природный парк Ала-Арча — самая близкая к Бишкеку горная территория Кыргызского хребта, открытая для посещения с 1976 года. Площадь — около 200 км², высоты от 1500 до 4895 м (пик Семёнова-Тян-Шанского). С советских времён это база подготовки альпинистов: здесь тренировались экспедиции на Памир и Тянь-Шань, до сих пор работает альпинистский лагерь с памятником погибшим восходителям.\n\n'
          'Природа и архитектура ландшафта.\n'
          '«Ала-Арча» означает «пёстрая арча», т.е. разноцветный можжевельник. Парк делится на нижнюю зону елово-арчовых лесов, среднюю — субальпийские луга, и верхнюю — ледники Ак-Сай, Тёштюк и Корона. По ущелью бежит чистая горная река Ала-Арча, которая снабжает водой пригороды Бишкека. Главные тропы: к водопаду Ак-Сай (≈1,5 ч от базы), к леднику Ак-Сай и хижине Рацека (5–6 ч), к Адыгене (3 ч), к мемориалу альпинистов (40 мин), круговая по нижнему ущелью (1,5 ч).\n\n'
          'Легенды и культурное значение.\n'
          'Арча у кыргызов считается священным деревом, очищающим жильё: её хвою сжигают на похоронах, при болезни, при переезде в новый дом. На скалах вдоль реки до сих пор встречаются завязанные ленточки — у родников и старых деревьев традиция «жалбарык» (тихая молитва-просьба). Не рвать арчу — это не туристический запрет, а народная этика.\n\n'
          'Ритуалы.\n'
          'Местные семьи приезжают «на свежий воздух» — это часть кыргызской культуры здоровья: подышать арчой, выпить родниковой воды, поесть бешбармака на природе. Любое мусорение или громкая музыка считаются неуважением к горе.\n\n'
          'Как добраться.\n'
          'Из Бишкека: такси или Yandex Go до «КПП Ала-Арча» (около 40 км, 40–50 мин, 600–900 сом). Также можно с экскурсионным автобусом или арендованной машиной по дороге через село Кашка-Суу. Вход в парк платный (для иностранцев ~250 сом, для граждан КР меньше). Машины проезжают глубже до «альплагеря».\n\n'
          'Лучшее время.\n'
          'Май–октябрь. В июне–июле — больше цветов, в сентябре — стабильная погода без снега. Зимой парк открыт для скитуров и ледолазания, но требует подготовки.\n\n'
          'Окрестности.\n'
          'Совсем рядом — село Кашка-Суу с конными прогулками, термальные источники, музей Айтматова в Бишкеке (30 мин). Часто комбинируют с поездкой в Бурану или Иссык-Куль.\n\n'
          'Советы.\n'
          'Берите слой одежды на случай похолодания: на 2000 м на 6–8°С холоднее, чем в городе. На высоте быстро меняется погода — гроза может прийти за 15 минут. Не сходите с троп: склоны сыпучие. Уносите весь мусор: в парке нет полноценного вывоза. Лучше не приходить со своими дровами — арчу жечь нельзя.',
      imageUrl: 'assets/places/ala_archa_1.jpg',
      images: [
        'assets/places/ala_archa_1.jpg',
        'assets/places/ala_archa_2.jpg',
        'assets/places/ala_archa_3.jpg',
        'assets/places/ala_archa_4.jpg',
        'assets/places/ala_archa_5.jpg',
      ],
    ),
    Place(
      id: 'cholpon_ata',
      title: 'Cholpon-Ata Petroglyphs',
      regionId: 'issyk_kul',
      type: PlaceType.petroglyphSite,
      rating: 4.9,
      popularity: 93,
      reviewsCount: 58,
      shortDescription:
          'Open-air stone drawings near Issyk-Kul with animal and hunting scenes.',
      description:
          'The petroglyph field gives the MVP a strong visual anchor: ancient stones, symbolic animals, and a route that can be explored as a gallery.',
      culturalNote:
          'Rock drawings are presented as fragile records of observation, belief, and movement through the landscape.',
      visitingRules:
          'Do not touch or trace carvings, keep to paths, photograph without flash where requested, and avoid stepping on marked stones.',
      route:
          'Travel to Cholpon-Ata on the north shore of Issyk-Kul, then follow local museum signage.',
      colors: [Color(0xFF1D7D73), Color(0xFFE0A02E), Color(0xFF202721)],
      fullDescription:
          'История.\n'
          'Музей петроглифов под открытым небом «Таш-Тулга» в Чолпон-Ате — крупнейшая в Северном Кыргызстане коллекция древних наскальных рисунков, расположенная на северном берегу Иссык-Куля. Поле занимает около 42 гектаров и содержит более двух тысяч изображений возрастом от II тысячелетия до н.э. до VIII–IX вв. н.э. Камни сюда не приносили: это морена ледника, который тысячелетия назад сполз с хребта Кунгей-Ала-Тоо, и древние люди использовали готовое «холмище» как святилище.\n\n'
          'Что выбито на камнях.\n'
          'Чаще всего — горные козлы (тэке), олени, барсы, лошади, сцены охоты с луком и копьём, шаманы с бубнами, солнечные знаки, тамги (родовые клейма) и колесницы бронзового века. Стиль меняется от эпохи к эпохе: тонкие силуэты бронзы → грубые «ковровые» сцены сакского времени → схематичные тюркские всадники. Это буквально учебник истории Иссык-Куля под небом.\n\n'
          'Легенды.\n'
          'В кыргызских сказаниях гора Кунгей и северное побережье — место, где «солнце сходит к воде», поэтому многие рисунки связаны с культом солнца и плодородия. Местные старики считают, что некоторые камни «говорят»: если приложить ладонь и постоять молча, можно «услышать» давнюю просьбу о хорошей охоте.\n\n'
          'Ритуалы и духовное значение.\n'
          'Поле петроглифов воспринимается как открытое святилище: тут не курят, не пьют алкоголь и не шумят. Местные приходят сюда не как в музей, а как в место памяти предков.\n\n'
          'Как добраться.\n'
          'Из Бишкека: маршрутка/автобус с Западного автовокзала до Чолпон-Аты (≈4 ч, 350–500 сом). От центральной площади Чолпон-Аты до музея 1,5 км пешком на север, или такси (≈100 сом). Вход — около 100 сом. На входе берите бумажную карту: рисунки разбросаны, и без карты вы пройдёте мимо самых интересных.\n\n'
          'Лучшее время.\n'
          'Май–октябрь. Особенно — утром до 10:00 и под вечер 16:00–19:00: солнце светит низко, и контраст «выбитых линий» становится максимальным. В жаркий полдень рисунки буквально «исчезают» в плоском свете.\n\n'
          'Окрестности.\n'
          'Сама Чолпон-Ата (городская набережная, культурный центр «Рух-Ордо», ипподром), пляжи Иссык-Куля, музей под открытым небом «Сказка Иссык-Куля» — всё в радиусе 5 км. К югу — выход к озеру за 10 минут.\n\n'
          'Советы.\n'
          'Ни в коем случае не обводите рисунки мелом, маркером или мокрой палочкой — это разрушает патину, и линии бледнеют навсегда. Не лазайте по камням с рисунками — становитесь рядом. Носите закрытую обувь: змеи и осы встречаются. Возьмите воду — на территории мало тени.',
      imageUrl: 'assets/places/cholpon_ata_1.jpg',
      images: [
        'assets/places/cholpon_ata_1.jpg',
        'assets/places/cholpon_ata_2.jpg',
        'assets/places/cholpon_ata_3.jpg',
        'assets/places/cholpon_ata_4.jpg',
      ],
    ),
    Place(
      id: 'manjyly_ata',
      title: 'Manjyly-Ata Springs',
      regionId: 'issyk_kul',
      type: PlaceType.sacredSpring,
      rating: 4.6,
      popularity: 82,
      reviewsCount: 27,
      shortDescription:
          'A spring area connected with blessings, quiet walks, and family visits.',
      description:
          'The screen content emphasizes a mindful visit: water, dry hills, lake air, and small rituals that should be approached respectfully.',
      culturalNote:
          'Springs are commonly associated with healing, gratitude, and careful behavior around water.',
      visitingRules:
          'Dress respectfully, keep the spring clean, avoid interrupting private prayers, and ask before photographing people.',
      route:
          'Approach from the south shore road of Issyk-Kul; local guides can help find the spring area.',
      colors: [Color(0xFF2D6A4F), Color(0xFF1D7D73), Color(0xFFF4F7F2)],
      fullDescription:
          'История.\n'
          'Манжылы-Ата — древний паломнический комплекс на южном берегу Иссык-Куля, в долине между сёлами Тосор и Кок-Сай. Имя «Манжылы-Ата» носит суфийский святой XV века; по преданию, он пришёл сюда учить и лечить людей, и после его кончины из-под камней забили родники. Сегодня здесь насчитывается до сорока источников, каждый со своим «характером» — для глаз, сердца, детей, женского здоровья, удачи, мира в доме.\n\n'
          'Что увидеть.\n'
          'Комплекс растянулся на 2–3 километра вдоль склонов. Главные ориентиры: мазар Манжылы-Ата (скромное побелённое сооружение с зелёным платком на куполе), «глазной» родник (вода едва заметно солоноватая), «женский» родник с двумя чашами, «детский» с маленьким каменным жертвенником, и «дерево желаний» — старый карагач с тысячами ленточек. Везде стоят простые скамьи и каменные «алтарики» для умывания.\n\n'
          'Легенды.\n'
          'Местные рассказывают, что Манжылы-Ата на закате жизни сел у камня и сказал: «Кто придёт сюда с чистым сердцем — найдёт свою воду». С тех пор каждый родник «выбирает» паломника сам: если у вас «не идёт» один источник, переходите к следующему. Считается дурным тоном пить из всех подряд «для коллекции».\n\n'
          'Ритуалы и духовное значение.\n'
          'Перед тем как пить, читают короткую молитву или говорят про себя просьбу. Воду берут ладонями, не плещутся, не плюются. На дереве желаний завязывают ленту белого, синего или зелёного цвета — НЕ красного и не чёрного. Алкоголь, табак и громкая речь на территории строго запрещены.\n\n'
          'Как добраться.\n'
          'Из Бишкека: маршрутка в сторону Каракола (≈6 ч), сойти в Тосоре, далее 6–8 км вглубь долины по грунтовке — без машины не подняться. Из Каракола — около 60 км по южной трассе, такси ≈ 1500 сом туда-обратно с ожиданием. Удобно совмещать с поездкой в Барскоон или Сказку.\n\n'
          'Лучшее время.\n'
          'Май–октябрь. Самые многолюдные дни — пятница и время после Орозо айт / Курман айт. Если хотите тишины — приезжайте в обычный будний день утром.\n\n'
          'Окрестности.\n'
          'Ущелье «Сказка» с красными скалами (15 мин), Барскоонский водопад (40 мин), пляжи южного берега, ущелье Жети-Огуз (1 ч).\n\n'
          'Советы.\n'
          'Одевайтесь скромно: закрытые плечи и колени, женщинам — лучше косынка или платок. Не фотографируйте молящихся в лицо. Не пейте без согласия смотрителя. Не оставляйте мусор и пустые бутылки. Если рядом семья проводит обряд — отойдите в сторону и подождите.',
      imageUrl: 'assets/places/manjyly_ata_1.jpg',
      images: [
        'assets/places/manjyly_ata_1.jpg',
        'assets/places/manjyly_ata_2.jpg',
        'assets/places/manjyly_ata_3.jpg',
        'assets/places/manjyly_ata_4.jpg',
      ],
    ),
    Place(
      id: 'jeti_oguz',
      title: 'Jeti-Oguz Red Rocks',
      regionId: 'issyk_kul',
      type: PlaceType.naturalSacredPlace,
      rating: 4.7,
      popularity: 86,
      reviewsCount: 36,
      shortDescription: 'Red cliffs, legends, and mountain air near Karakol.',
      description:
          'Jeti-Oguz is used as a dramatic nature story in the prototype, with attention to local legends and careful movement around fragile slopes.',
      culturalNote:
          'Landscape legends help visitors understand why a natural formation can hold emotional and cultural meaning.',
      visitingRules:
          'Avoid climbing unstable slopes, keep picnic areas clean, and treat local stories with respect.',
      route:
          'Travel from Karakol toward Jeti-Oguz village, then continue to the main rock viewpoints.',
      colors: [Color(0xFFB93F55), Color(0xFF9B4D2E), Color(0xFFE0A02E)],
      fullDescription:
          'История и геология.\n'
          'Джеты-Огуз — это массив красных конгломератных скал в южной части Иссык-Куля, в 28 км от Каракола. Породы сформировались около 25 миллионов лет назад: древние реки сносили в озеро гальку и песок, цементировали железом — отсюда характерный «кровавый» цвет. С запада в горы уходит ущелье реки Джеты-Огуз, которое поднимается до альпийских лугов и ледников Терскей-Ала-Тоо.\n\n'
          'Что увидеть.\n'
          'Главная смотровая площадка над «Семью быками» — массивный ребристый барьер из семи скал. В 2 км вверх по ущелью — отдельный гребень «Разбитое сердце» (Жарылган-Жүрөк) с глубокой расщелиной посередине. Дальше — водопад «Девичьи слёзы» (1–1,5 ч пешком), летние пастбища Кок-Жайык (≈10 км по долине, лучше на машине или верхом), горячие источники санатория «Джеты-Огуз», построенного в 1932 году.\n\n'
          'Легенды.\n'
          '«Семь быков»: древний хан решил отнять жену у соседнего хана. Тот созвал семерых лучших воинов на пир и казнил их — кровь застыла камнями. «Разбитое сердце»: красавица любила одного, но её отдали другому; в ночь свадьбы из её сердца ушла кровь и расколола скалу. Эти легенды дети учат в школах Иссык-Куля.\n\n'
          'Ритуалы.\n'
          'Местные приезжают сюда на семейный пикник, на «жарма-той» (праздник летних кочёвок), на конные прогулки. У водопада «Девичьи слёзы» загадывают желание — пишут или говорят шёпотом и смачивают руки в брызгах.\n\n'
          'Как добраться.\n'
          'Из Каракола: маршрутка или такси до села Джеты-Огуз (28 км, 30–40 мин, 250–400 сом). Далее вверх по ущелью только на машине или верхом — 12 км до водопада, 20 км до Кок-Жайыка. Многие туры включают конную прогулку (3–5 ч).\n\n'
          'Лучшее время.\n'
          'Июнь–сентябрь. Июнь — самая зелёная трава и цветение эдельвейсов; август — самая стабильная погода; сентябрь — пожелтевшие лиственницы.\n\n'
          'Окрестности.\n'
          'Каракол (30 мин), Каракольский ущельный парк, дунганская мечеть в Караколе, термальные источники Джылы-Суу (через Барскоон), Барскоонский водопад.\n\n'
          'Советы.\n'
          'Не лазайте на сами скалы — конгломерат рыхлый и легко сыпется (бывали смертельные случаи). Берегите альпийские цветы — некоторые виды эндемики. Держитесь подальше от пасущихся лошадей и яков. На высоте от 2000 м может тошнить — поднимайтесь не торопясь и пейте воду.',
      imageUrl: 'assets/places/jeti_oguz_1.jpg',
      images: [
        'assets/places/jeti_oguz_1.jpg',
        'assets/places/jeti_oguz_2.jpg',
        'assets/places/jeti_oguz_3.jpg',
        'assets/places/jeti_oguz_4.jpg',
        'assets/places/jeti_oguz_5.jpg',
      ],
    ),
    Place(
      id: 'tash_rabat',
      title: 'Tash Rabat Caravanserai',
      regionId: 'naryn',
      type: PlaceType.archaeologicalSite,
      rating: 4.8,
      popularity: 79,
      reviewsCount: 22,
      shortDescription: 'A stone caravanserai in a high mountain valley.',
      description:
          'The demo presents Tash Rabat as a place for understanding shelter, trade, weather, and mountain hospitality.',
      culturalNote:
          'Stone architecture in high valleys speaks to endurance and the care given to travelers.',
      visitingRules:
          'Follow local guidance inside the structure, avoid smoke or candles, and protect the surrounding pasture.',
      route:
          'From Naryn, take the road toward At-Bashy and continue by mountain road with suitable transport.',
      colors: [Color(0xFF5B7C46), Color(0xFF9B4D2E), Color(0xFF2D6A4F)],
      fullDescription:
          'История.\n'
          'Таш-Рабат — каменный купольный караван-сарай на высоте 3200 м в Ат-Башинском районе Нарынской области, в 90 км от перевала Торугарт (граница с Китаем). Историки спорят о возрасте: по одной версии это христианский несторианский монастырь X–XI вв., переделанный в XV в. в мусульманский караван-сарай; по другой — изначально была стоянкой высокогорного отрезка Шёлкового пути. Через этот проход вели караваны из Ферганы и Самарканда в Кашгар и далее в Глубинный Китай.\n\n'
          'Архитектура.\n'
          'Здание из тёсаного сланца и кирпича — почти сорока помещений, из них 31 жилая комната и большой купольный зал. Купол — 14 м в диаметре, высотой около 9 м, выложен без раствора — камни держатся по принципу высокоточной тяжёсти. Внутри была система подвода воды, печи, коридоры для лошадей и скорбящих помещений «худжра» (кельи) для практикующих.\n\n'
          'Легенды.\n'
          'Рассказывают о «камне правды»: в одной из келий якобы жил мудрый старец, который разрешал споры путников: лжец не мог выйти из комнаты пока не признавался. Другая история — о «втором выходе»: якобы из зала водит тайный туннель, по которому можно выйти на обратную сторону хребта.\n\n'
          'Ритуалы.\n'
          'Сегодня это в первую очередь археологический памятник, но местные сводят сюда гостей как в храм «времени и выносливости»: люди были способны построить такое на 3200 м без бетонных растворов. Внутри не кричат и не зажигают огонь — это повреждает свод.\n\n'
          'Как добраться.\n'
          'Из Нарына: ≈3 ч по трассе Нарын–Торугарт до села Кара-Суу, затем 15 км вверх по грунтовой дороге — лучше на 4×4. Из Бишкека это двухдневный выезд (с ночёвкой в юрте рядом). Многие туры комбинируют Сон-Кёль + Таш-Рабат + Салы-Саз.\n\n'
          'Лучшее время.\n'
          'Конец июня – начало сентября. До июня и после сентября возможен снег. Днём «тепло» (+15..+22°С), ночью холодно (+2..+5°С). Небо ночью — без светового загрязнения, виден Млечный Путь.\n\n'
          'Окрестности.\n'
          'Сон-Кёль (высокогорное озеро в 4 часах), Кёл-Суу (по другой трассе), Ат-Башы (село с крепостью и музеем эпоса), юрточные лагеря на берегу реки.\n\n'
          'Советы.\n'
          'Обязательно ночуйте в юрте (≈1000–1500 сом с ужином и завтраком): ночное небо и тишина — главное впечатление. Берите тёплую одежду даже в августе. Внутри караван-сарая не зажигайте свечи и не курите — сажа повреждает камень. На высоте 3200 м возможна горная болезнь: снижайте темп, пейте воду.',
      imageUrl: 'assets/places/tash_rabat_1.jpg',
      images: [
        'assets/places/tash_rabat_1.jpg',
        'assets/places/tash_rabat_2.jpg',
        'assets/places/tash_rabat_3.jpg',
      ],
    ),
    Place(
      id: 'saimaluu_tash',
      title: 'Saimaluu-Tash',
      regionId: 'naryn',
      type: PlaceType.petroglyphSite,
      rating: 4.9,
      popularity: 90,
      reviewsCount: 19,
      shortDescription:
          'A high-altitude petroglyph landscape with thousands of rock images.',
      description:
          'Saimaluu-Tash is treated as a premium heritage route for the app: remote, powerful, and visually distinct.',
      culturalNote:
          'The drawings are framed as a mountain archive of movement, ritual, animals, and sky observation.',
      visitingRules:
          'Use a guide, never scratch or chalk carvings, prepare for weather, and leave the site exactly as found.',
      route:
          'Access is seasonal and remote. The prototype recommends guided travel from Jalal-Abad or Naryn routes.',
      colors: [Color(0xFF202721), Color(0xFF8064A2), Color(0xFFE0A02E)],
      fullDescription:
          'История.\n'
          'Саймалуу-Таш («узорчатый камень») — крупнейшее в Центральной Азии скопление петроглифов: от более чем 90 тысяч рисунков на чёрных валунах в высокогорной долине на высоте 3000–3450 м, на стыке Джалал-Абадской и Нарынской областей. Нарывать рисунки начали в IV–III тысячелетиях до н.э. и продолжали до раннего Средневековья — это примерно 60 веков изобразительной традиции под открытым небом.\n\n'
          'Что выбито на камнях.\n'
          'Охотничьи и скотоводческие сцены, ритуальные танцы, солнечные и «колёсные» символы, обряды «священного брака», божества в лучах, колесницы бронзового века, эротические сцены плодородия. Рисунки отличаются необычным сюжетным богатством: некоторые «хроники» выбиты в несколько слоёв — более поздние люди добавляли персонажей к «историям» предков.\n\n'
          'Легенды.\n'
          'Местные считают Саймалуу-Таш «открытым словарём»: в долину пустят только «чистых сердцем», иначе «ветер прогонит». Другая история — о древнем художнике, который «разговаривал с Солнцем»: если приложить камень к виску, можно «услышать» его ответ. Это народная поэтика, но она объясняет, почему высокая долина воспринимается как «святое место».\n\n'
          'Ритуалы.\n'
          'Изначально на Саймалуу-Таш приходили наверху «по весне» и просили о хорошем приплоде и урожае. Сегодня посещение регулируется: «след не оставить» — главный принцип.\n\n'
          'Как добраться.\n'
          'Только с гидом и в сезон (июль–август), иначе перевалы закрыты снегом. Старт из Казармана или Кёкарта (Джалал-Абадская область). Схема: машиной до подъёма → пеший/конный переход через перевал 3500 м (1,5–2 дня в один конец). Со всем снаряжением и проводником это не «прогулка», а экспедиция.\n\n'
          'Лучшее время.\n'
          'Середина июля – середина августа. В остальное время долина закрыта снегом. Малый сезон (≈1,5 месяца) — одна из причин, почему это место остаётся «спрятанным».\n\n'
          'Окрестности.\n'
          'По пути — юрточные лагеря в высокогорных долинах, альпийские озёра, реликтовые леса Арсланбоба в предгорьях. Казарман славен «Медвежьим водопадом».\n\n'
          'Советы.\n'
          'Никогда не идите сюда в одиночку. Не скалывайте лишайник с камней — он прикрывает рисунки. Не переворачивайте плиты: можно разрушить контекст. Работайте только с лицензированными гидами из Кыргызской Ассоциации Туроператоров — это важно для безопасности и для местных.',
      imageUrl: 'assets/places/saimaluu_tash_1.jpg',
      images: [
        'assets/places/saimaluu_tash_1.jpg',
        'assets/places/saimaluu_tash_2.jpg',
        'assets/places/saimaluu_tash_3.jpg',
        'assets/places/saimaluu_tash_4.jpg',
      ],
    ),
    Place(
      id: 'manas_ordo',
      title: 'Manas Ordo',
      regionId: 'talas',
      type: PlaceType.mausoleum,
      rating: 4.7,
      popularity: 84,
      reviewsCount: 25,
      shortDescription: 'A memorial complex connected with the epic of Manas.',
      description:
          'The mock content makes this a place for epic memory, respectful storytelling, and learning through guided stops.',
      culturalNote:
          'The Manas epic is central to identity, oral history, and shared cultural memory.',
      visitingRules:
          'Keep a respectful tone, follow museum rules, and avoid interrupting ceremonies or guided groups.',
      route:
          'Travel from Talas city toward the complex by road; signage and local transport are available.',
      colors: [Color(0xFF9B4D2E), Color(0xFFE0A02E), Color(0xFF2D6A4F)],
      fullDescription:
          'История.\n'
          'Манас Ордо — мемориальный комплекс в 22 км к востоку от города Талас, в селе Таш-Арык, посвящённый эпическому богатырю Манасу. Эпос «Манас» — крупнейший в мире (около 500 тысяч строк, в 20 раз больше «Илиады» и «Одиссеи» вместе), включён в нематериальное наследие ЮНЕСКО. Центральный купольный мавзолей (гумбез) датируется 1334 годом. По одной версии, он построен Каныкей — женой Манаса — над могилой мужа.\n\n'
          'Что посмотреть.\n'
          'Гумбез Манаса (портальная арка с резным фасадом, стрельчатый купол около 12 м), Музей Манаса (рукописи, экспонаты о манасчи, предметы кочевого быта), монументальные скульптуры 40 «чоро» (ближайших воинов Манаса), «Алтын-бешик» — большая статуя Манаса на коне, древний курган «Кырк-Чоро». Обычно посещение занимает 1,5–2 часа.\n\n'
          'Сюжет эпоса и интересные факты.\n'
          'Эпос рассказывает о богатыре Манасе, объединившем сорок племён в единый народ, о его сыне Семетее и внуке Сейтеке — это трилогия. Манасчи исполняют эпос без книги, импровизируя, иногда по неделям. Это живая устная традиция, а не музейный текст.\n\n'
          'Ритуалы и духовное значение.\n'
          'Сюда приходят «взять благословение Манаса» перед важными решениями, свадьбами и перед дальними поездками. Мужчины часто выполняют маленький «тавап» (обход) вокруг гумбеза. Внутри возможна короткая молитва. Не разрешается фотографировать людей в молитве вблизи, повышать голос внутри гумбеза, входить в мавзолей в обуви.\n\n'
          'Как добраться.\n'
          'Из Бишкека: ≈3,5–4 ч на машине (300 км) через перевал Тоо-Ашуу (3586 м, туннель) и Отмок (3326 м). Маршрутки из Западного автовокзала в Талас, далее такси до Таш-Арыка (≈7 ч всё вместе). Лучше выезжать рано утром, чтобы вернуться до темноты (перевалы опасны ночью).\n\n'
          'Лучшее время.\n'
          'Май–октябрь. Лучший день — «День Эпоса» в июле или августе, когда выступают манасчи и проводятся конные игры. Побывавшие рекомендуют желательно брать местный тур с манасчи.\n\n'
          'Окрестности.\n'
          'Город Талас (исторический музей), водопад Беш-Таш в эпонимном парке (1 ч), термальные источники Манжылги, историческая битва на реке Талас (751 г.) — памятник вблизи.\n\n'
          'Советы.\n'
          'Одевайтесь скромно: колени и плечи закрыты. Снимайте обувь перед входом в гумбез. Не прикасайтесь к резьбе (лёссовый кирпич разрушается). Не торопите манасчи, если он исполняет эпос; короткое исполнение — 5–10 минут, это уважение к традиции.',
      imageUrl: 'assets/places/manas_ordo_1.jpg',
      images: [
        'assets/places/manas_ordo_1.jpg',
        'assets/places/manas_ordo_2.jpg',
        'assets/places/manas_ordo_3.jpg',
        'assets/places/manas_ordo_4.jpg',
      ],
    ),
    Place(
      id: 'sulaiman_too',
      title: 'Sulaiman-Too',
      regionId: 'osh',
      type: PlaceType.sacredPlace,
      rating: 5.0,
      popularity: 99,
      reviewsCount: 73,
      shortDescription: 'A sacred mountain rising from the heart of Osh.',
      description:
          'Sulaiman-Too is the centerpiece of the prototype: routes, viewpoints, museum stops, and etiquette around sacred spaces.',
      culturalNote:
          'The mountain connects pilgrimage, urban life, memory, and the layered history of the Fergana Valley.',
      visitingRules:
          'Dress modestly, respect prayer spaces, keep pathways clear, and ask before photographing visitors.',
      route:
          'Start from central Osh and use marked walking routes around the mountain and museum areas.',
      colors: [Color(0xFFB93F55), Color(0xFFE0A02E), Color(0xFF1D7D73)],
      fullDescription:
          'История.\n'
          'Сулайман-Тоо («Гора Соломона») — пятивершинная известняковая гора длиной 1,6 км и высотой до 175 м над городом. С 2009 года это первый в Кыргызстане объект Всемирного наследия ЮНЕСКО. Сулайман-Тоо была обитаема уже в палеолите, а как живое место паломничества известна не менее 1500 лет — здесь встречаважнейшие «ворота Оша» и верховья Ферганы. На горе было расположено 17 культовых мест, более 100 петроглифов и десятки пещер.\n\n'
          'Что посмотреть.\n'
          'Мечеть «Бабур хаузи» (XVI в.) на вершине — считается «беседкой Бабура», основателя империи Моголов. Национальный историко-археологический музейный комплекс внутри горы (вырублен в скале, 1978 г.). Мавзолей Асафа ибн Бархии, «Дом Павлина» («Тахт и Сулайман» — ниша в скале). Петроглифы: козлы, всадники, солнечные знаки. «Катящийся камень» — полированный жёлоб, по которому просят здоровья спине.\n\n'
          'Легенды.\n'
          'Говорят, что пророк Сулайман (Соломон) молился на этой горе; поэтому всякое желание, сказанное здесь, якобы сбывается. Женщины скатываются по «жёлобам» в надежде на ребёнка. Мужчины ищут «святой след» Сулаймана на камне вершины. Официальный ислам скептичен к подобным ритуалам, но они хранят живую народную веру.\n\n'
          'Ритуалы.\n'
          'Паломники восходят босиком, обходят мечеть три раза, пьют воду из «вечного» родника, выбивают льняные или платочные «узелки» на ветках над родником. Нельзя приходить с алкоголем, вызывающе фотографировать молящихся, ходить в открытой одежде.\n\n'
          'Как добраться.\n'
          'Пешком из центра Оша — 15 минут от Большого базара. Главная тропа начинается с южной стороны, вход символический (50–100 сом вкл. музей). Подъём до вершины — 30–40 мин, лестница под солнцем средней крутизны.\n\n'
          'Лучшее время.\n'
          'Апрель–июнь и сентябрь–ноябрь. Летом в Оше жарко (+38..+42°С) — лучше подниматься до рассвета или после 17:00. С вершины лучшие закаты над Ферганой.\n\n'
          'Окрестности.\n'
          'Большой базар «Джаыма» (в 5 мин), медресе Алымбека, мечеть Рават-Абдуллахана, Нооруз у Оша. Обязательно включите прогулку по набережной реки Ак-Буура.\n\n'
          'Советы.\n'
          'Женщинам — платок, одежда до локтей и коленей. Не пишите на камнях и выбивайте «селфи» на фоне молящихся. Не биться о камни в пещере «ради исцеления» — это миф. Берите воду: на тропе продают курт и лёд, но в пиковые часы бывают очереди.',
      imageUrl: 'assets/places/sulaiman_too_1.jpg',
      images: [
        'assets/places/sulaiman_too_1.jpg',
        'assets/places/sulaiman_too_2.jpg',
        'assets/places/sulaiman_too_3.jpg',
        'assets/places/sulaiman_too_4.jpg',
      ],
    ),
    Place(
      id: 'osh_spring',
      title: 'Ak-Buura Old Spring',
      regionId: 'osh',
      type: PlaceType.sacredSpring,
      rating: 4.5,
      popularity: 70,
      reviewsCount: 14,
      shortDescription: 'A local water stop in an old urban route.',
      description:
          'This mock entry adds a smaller sacred water location to show that the catalog can handle famous and neighborhood-scale places.',
      culturalNote:
          'Water places often carry everyday traditions: greeting elders, sharing shade, and keeping the area clean.',
      visitingRules:
          'Do not pollute water, keep containers orderly, and give space to local residents.',
      route:
          'Use local directions from central Osh; the route is intended as a short city visit.',
      colors: [Color(0xFF1D7D73), Color(0xFFB7E4C7), Color(0xFFE0A02E)],
      fullDescription:
          'История.\n'
          'Река Ак-Буура («Белый верблюд») берёт начало на северных склонах Алайского хребта, течёт в ыжном Кыргызстане и выходит к Ферганской долине через самый центр Оша. Река является «жилой» города: из неё орошают сады, рядом завтракают и пьют чай, бегают дети. Вдоль берегов выросли несколько старых «булаков» (родников) — «Чылтеннин булагы» у подножия Сулайман-Тоо, «Сулайман-булагы» у моста Курувборвр, «Окжети» у «Навруз». К таким родникам местные приходят «выпить воды» при простуде, бессоннице, важных решениях.\n\n'
          'Что посмотреть.\n'
          'Набережная Ак-Бууры в центре (парк, пешеходные мосты, чайханы), переход от Большого базара к подножию Сулайман-Тоо, посевы верблюжьих фигур (скульптур «белый верблюд») по городу, «Чылтеннин булагы» с каменным жёлобом, мечеть Рават-Абдуллахана.\n\n'
          'Легенды.\n'
          'Название реки связывают с преданием о белой верблюдице, которая из любви к своему верблюжонку проплакала целую реку. Другая версия — река «белая» из-за лёдниковой взвеси вверху. Обе истории рассказывают в школах Оша.\n\n'
          'Ритуалы.\n'
          'Родники вдоль Ак-Бууры — это «мини-Манжылы-Ата» в центре города: мыть лицо водой, ополоснуть руки, сказать про себя «бисмиллах» и просьбу. Никто не берёт воду в большие бутылки «в запас» — считается невежливым. Принято уступать пожилым и женщинам с детьми.\n\n'
          'Как добраться.\n'
          'Пешком от центральной площади Оша от 5 до 30 минут в зависимости от нужного родника. Удобно включить в прогулку по Сулайман-Тоо: спустившись с вершины, выйти на набережную и пройти к базару. Бесплатно.\n\n'
          'Лучшее время.\n'
          'Круглый год. Раннее утро — самое медитативное время: пар над водой, первые торговцы идут на базар. Летом у родников прохладно даже в жару.\n\n'
          'Окрестности.\n'
          'Сулайман-Тоо, Большой базар «Джаыма» (один из старейших в Центральной Азии, работает более 2000 лет), Национальный историко-археологический музей, старое «Кара-Суу» (жилые районы с ремесленниками).\n\n'
          'Советы.\n'
          'Не мойте ноги и не стирайте одежду в родниках — это питьевая вода для других. Хотите набрать воды — набирайте из отводного крана, не из чаши. Не бросайте монеты «на удачу» — это засоряет источник и нарушает традицию («вода не берёт платы»).',
      imageUrl: 'assets/places/osh_spring_1.jpg',
      images: [
        'assets/places/osh_spring_1.jpg',
        'assets/places/osh_spring_2.jpg',
        'assets/places/osh_spring_3.jpg',
        'assets/places/osh_spring_4.jpg',
      ],
    ),
    Place(
      id: 'arslanbob',
      title: 'Arslanbob Sacred Forest',
      regionId: 'jalal_abad',
      type: PlaceType.naturalSacredPlace,
      rating: 4.8,
      popularity: 91,
      reviewsCount: 44,
      shortDescription:
          'Walnut forests, waterfalls, and community-guided walks.',
      description:
          'The app frames Arslanbob as a living landscape where nature, local livelihood, and visitor care meet.',
      culturalNote:
          'Forest routes are connected with hospitality, harvest seasons, and stories passed through families.',
      visitingRules:
          'Use local paths, avoid damaging trees, respect private orchards, and support local guides where possible.',
      route:
          'Travel from Jalal-Abad toward Bazar-Korgon and continue to Arslanbob village.',
      colors: [Color(0xFF2D6A4F), Color(0xFF5B7C46), Color(0xFFE0A02E)],
      fullDescription:
          'История.\n'
          'Арсланбоб — большое село и природный заповедник в Отрогах Чаткальского хребта, в 80 км к северу от Джалал-Абада. Окружён крупнейшим в мире реликтовым лесом грецкого ореха и яблони Сиверса площадью около 11 000 га. Деревья растут здесь более 50 миллионов лет (реликты третичного периода), выжившие ледниковые периоды благодаря уникальному микроклимату. Орехи отсюда экспортируются в США, Германию, Японию; в сезон (сентябрь–октябрь) все семьи выходят в лес собирать урожай.\n\n'
          'Легенды.\n'
          'По преданию пророк Мухаммед поручил «льву-шейху» Каббул Кубра найти рай на земле. Шейх пришёл в эту долину и бросил в землю ореховые плоды — вырос лес. С тех пор село носит имя Арсланбоб (от «арслан-бобо» — «лев-шейх»). Мавзолей святого стоит у въезда в село и считается «покровителем» леса: срубить старый орех считается тяжким грехом.\n\n'
          'Что посмотреть.\n'
          'Малый водопад (30 мин пешком от центра) — поток 35 м посреди ореховых рощ. Большой водопад (80 м, 3–4 ч подъёма). Мавзолей Шейха Арсланбоба (прямо в селе). Панорамная точка «Священная скала» (1 ч подъёма на хребет над долиной). Ореховые рощи — «Сары-Челек» и «Кара-Алма». Зимой — бесплатный «лыжный склон» (лыжи из дерева, подъёмников нет — но свободных склонов полно).\n\n'
          'Ритуалы и культура.\n'
          'Сбор ореха — семейный и соседский ритуал: в лес выходят на 2–3 недели, живут в палатках и временных хижинах, варят бешбармак на костре, пеют. Каждая семья имеет свой наследственный участок леса («пайва»), границы которого передаются из поколения в поколение. Чужой «пайве» трогать нельзя.\n\n'
          'Как добраться.\n'
          'Из Джалал-Абада: маршрутка до Базар-Коргона (40 мин), пересадка на маршрутку/такси до Арсланбоба (≈1,5–2 ч по горной дороге). Из Оша: ≈4 ч, лучше такси напрямую. Временами включается в тур «южный Кыргызстан» (Сулайман-Тоо + Арсланбоб + Кёл-Суу).\n\n'
          'Лучшее время.\n'
          'Май–октябрь. Идеал: конец сентября — начало октября, пока семьи собирают орехи и лес «живёт». Декабрь–январь — «зимнее лицо» с провинциальными лыжниками.\n\n'
          'Окрестности.\n'
          'Озёра Кёл-Көгүл («Голубые озёра») — 1,5 ч вверх от большого водопада. Кёл-Суу (в 4 ч езды). Национальный парк Падыш-Ата. Базар и мечеть в Базар-Коргоне.\n\n'
          'Советы.\n'
          'Остановитесь у местной семьи через CBT (Community Based Tourism) — это и дешевле гостиницы, и деньги остаются в деревне. Никогда не собирайте орехи без приглашения — это чужой урожай и «асыл хлеб» семьи. Не ломайте ветки. Берите хорошую обувь: тропы каменистые. Среди высокогорных водопадов вода холодная даже в июле.',
      imageUrl: 'assets/places/arslanbob_1.jpg',
      images: [
        'assets/places/arslanbob_1.jpg',
        'assets/places/arslanbob_2.jpg',
        'assets/places/arslanbob_3.jpg',
        'assets/places/arslanbob_4.jpg',
        'assets/places/arslanbob_5.jpg',
      ],
    ),
    Place(
      id: 'jalal_abad_springs',
      title: 'Jalal-Abad Springs',
      regionId: 'jalal_abad',
      type: PlaceType.sacredSpring,
      rating: 4.4,
      popularity: 68,
      reviewsCount: 18,
      shortDescription: 'Healing water traditions in a resort-town setting.',
      description:
          'This mock entry demonstrates how wellness, local history, and sacred-water etiquette can sit in one detail screen.',
      culturalNote:
          'People visit springs with hopes for health, gratitude, and quiet renewal.',
      visitingRules:
          'Observe posted rules, do not block water access, and keep bathing or drinking areas clean.',
      route: 'Reach the resort area from Jalal-Abad city by local road.',
      colors: [Color(0xFF1D7D73), Color(0xFF2D6A4F), Color(0xFFF4F7F2)],
      fullDescription:
          'История.\n'
          'Курорт Джалал-Абад (Джалал-Абад-Аршан) — старейший бальнеологический санаторий Кыргызстана, основан в 1882 году. Минеральные источники с температурой 30–44°C известны были ещё со времён Великого Шёлкового пути: караваны останавливались здесь на отдых, а паломники — «выпить воды» перед дальними путешествиями. Комплекс лежит на склоне Гири-Аршан в 5 км к востоку от центра Джалал-Абада, на высоте 1000 м.\n\n'
          'Что посмотреть.\n'
          'Главный источник «Архат Булак» с бюветным павильоном (питьевая сульфатная вода), санаторный парк с старыми чинарами и тополями, лечебные ванные корпуса, врачебный флигель. Смотровая площадка над городом (вид на долину и хребет Бабаш-Ата). Маленькая мечеть и мазар ибн Аббаса (XVIII в.) на склоне.\n\n'
          'Легенды.\n'
          'Говорят, «архат» (праведник) Ибн Аббас остановился здесь на ночь, воткнул посох в землю и попросил воды — из-под посоха забили горячие источники. Отсюда название источника. Местные приходят «выпить воды Ибн Аббаса» перед свадьбами и рождением детей.\n\n'
          'Ритуалы и лечение.\n'
          'Стандартный курс — 14–21 день: питьевые процедуры (200 мл 3 раза в день за 30 мин до еды), ванны 36–40°C по 12–15 мин, ингаляции, грязевые обёртывания. Показания: желудочно-кишечные, опорно-двигательные, кожные и гинекологические заболевания. Нельзя лечиться без осмотра врача — вода действительно сильная.\n\n'
          'Как добраться.\n'
          'Из центра города Джалал-Абад: маршрутка № 4 или такси до санатория «Джалал-Абад» (15 мин). Из Оша — 1,5 ч до центра Джалал-Абада. Для проживания в санатории бронируйте заранее — зимой места раскупают быстро.\n\n'
          'Лучшее время.\n'
          'Круглый год, но идеальные месяцы — апрель–май и сентябрь–октябрь (мягкое солнце, фрукты на базаре). Зимой популярны «горячие ванны на воздухе».\n\n'
          'Окрестности.\n'
          'Город Джалал-Абад (базар, мечети), святое озеро Көл-Кёгүл (1 ч езды), Арсланбоб (2 ч), «Майли-Сай» (нефтяные лужи с сакральным значением — 30 мин). Часто комбинируют с поездкой в Сары-Челек (природный парк).\n\n'
          'Советы.\n'
          'Не пейте минеральную воду «литрами» — высокое содержание солей может вызвать расстройство. Не ложитесь в ванну более 15 минут. Обязательно отдыхайте после ванны 30–40 мин в тёплом палате. Не приходите на процедуры голодными или сразу после еды.',
      imageUrl: 'assets/places/jalal_abad_springs_1.jpg',
      images: [
        'assets/places/jalal_abad_springs_1.jpg',
        'assets/places/jalal_abad_springs_2.jpg',
        'assets/places/jalal_abad_springs_3.jpg',
        'assets/places/jalal_abad_springs_4.jpg',
      ],
    ),
    Place(
      id: 'aigul_tash',
      title: 'Aigul-Tash',
      regionId: 'batken',
      type: PlaceType.naturalSacredPlace,
      rating: 4.6,
      popularity: 74,
      reviewsCount: 16,
      shortDescription:
          'A rocky slope tied to the rare Aigul flower and local legend.',
      description:
          'Aigul-Tash gives the MVP a southern nature story with a seasonal rhythm and a strong conservation message.',
      culturalNote:
          'The Aigul flower is treated as a symbol of beauty, loss, and care for rare living heritage.',
      visitingRules:
          'Never pick flowers, stay on marked paths, visit with local guidance, and protect fragile slopes.',
      route:
          'Travel from Batken city toward the protected area during the permitted season.',
      colors: [Color(0xFFB93F55), Color(0xFF8064A2), Color(0xFF5B7C46)],
      fullDescription:
          'История и биология.\n'
          'Айгуль-Таш («Камень Айгуль») — известняковая гора высотой около 1800 м в Кадамжайском районе Баткенской области, на южном склоне Киргизского хребта. Это одно из немногих мест в мире, где встречается редкий эндемик — рябчик Эдуарда (Fritillaria eduardii), или «Айгуль». Это луковичный многолетник 80–100 см высотой с крупным кирпично-красными поникшими колокольчиками и «короной» из листьев на верхушке. Цветёт всего 2–3 недели в конце апреля — начале мая. Растение внесено в Красные книги Кыргызстана и СНГ, сбор тянет уголовное наказание.\n\n'
          'Легенда.\n'
          'Девушка Айгуль любила бедного юношу, но родители решили выдать её за жестокого богача. Накануне свадьбы она прибежала на эту скалу и бросилась вниз. Из её крови выросли красные «поникшие» цветы — поэтому они всегда смотрят вниз, как будто плачут. Легенда объясняет, почему местные считают склон священным и стараются беречь растение.\n\n'
          'Что посмотреть.\n'
          'Южный склон во время цветения — стреляющие кверху «факелы» на фоне жёлтых лугов. При подходе — памятный камень с легендой на трёх языках. Со смотровой вид на Алайский хребет и выход в Ферганскую долину. Рядом растёт редкая краснокнижная флора: тюльпаны Кауфмана, ирисы вибрис.\n\n'
          'Ритуалы и охрана.\n'
          'Каждый год в первую субботу мая в Кадамжае проходит «Праздник Айгуль» с конными играми, блинами из муки кольраби, ярмаркой. Склон охраняется местным рейнджером (в сезон патрулирует и экологическая полиция). Сорвать хотя бы один цветок — преступление по ст. 271 УК КР.\n\n'
          'Как добраться.\n'
          'Из Оша: маршрутка до Сулюкты/Кадамжая (3–4 ч), далее такси 30–40 мин до «урочища Айгуль». Из Баткена: ≈1,5 ч до Кадамжая, дальше местный гид. До подножия склона можно доехать на 4×4; вверх — пешком 30–40 мин по маркированной тропе.\n\n'
          'Лучшее время.\n'
          '20 апреля – 10 мая. До этого цветы ещё не раскрылись, после — увяли. До поездки уточните у местных: в холодные вёсны цветение смещается на неделю.\n\n'
          'Окрестности.\n'
          'Село Кадамжай (краеведческий музей), «Шахимардан» (святилище с мавзолеем, 30 мин), Абшыр-Ата (вход в Кара-Суу), «Суръёзный рыбный рынок» в баткенских сёлах. Из Оша удобно сделать выезд на 2–3 дня.\n\n'
          'Советы.\n'
          'НИКОГДА не срывайте, не выкапывайте и не покупайте «букеты» Айгуль — это убивает популяцию и ведёт к исчезновению эндемика. Не лягайте на цветы для фото и не топчите склон: луковицы нежные и восстанавливаются годами. Одевайтесь скромно: близко в Шахимардане является действующим мавзолеем.',
      imageUrl: 'assets/places/aigul_tash_1.jpg',
      images: [
        'assets/places/aigul_tash_1.jpg',
        'assets/places/aigul_tash_2.jpg',
        'assets/places/aigul_tash_3.jpg',
        'assets/places/aigul_tash_4.jpg',
      ],
    ),
  ];

  static const characters = [
    AiCharacter(
      id: 'atashka',
      name: 'Atashka',
      role: 'History keeper',
      color: AppTheme.clay,
    ),
    AiCharacter(
      id: 'apashka',
      name: 'Apashka',
      role: 'Tradition guide',
      color: AppTheme.rose,
    ),
  ];

  static const reviews = [
    Review(
      placeId: 'sulaiman_too',
      user: 'Aizada',
      rating: 5,
      text:
          'Sunset from the path felt unforgettable. Go early and bring water.',
    ),
    Review(
      placeId: 'cholpon_ata',
      user: 'Temir',
      rating: 4.8,
      text:
          'The stones need patience. A guide makes the drawings easier to read.',
    ),
    Review(
      placeId: 'burana',
      user: 'Nurai',
      rating: 4.7,
      text: 'A calm stop with strong history. The balbals are the best part.',
    ),
    Review(
      placeId: 'arslanbob',
      user: 'Daniel',
      rating: 4.9,
      text: 'Beautiful forest route and warm local guidance.',
    ),
  ];

  static final posts = [
    CommunityPost(
      id: 'p1',
      userName: 'Aizada',
      text:
          'Sulaiman-Too is best before the afternoon heat. The upper path is quiet at sunrise.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: PostType.tip,
      likeCount: 18,
      commentCount: 4,
      placeId: 'sulaiman_too',
      color: AppTheme.rose,
    ),
    CommunityPost(
      id: 'p2',
      userName: 'Bek',
      text:
          'The road after rain near Tash Rabat can be rough. High-clearance transport helped us.',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
      type: PostType.issue,
      likeCount: 9,
      commentCount: 3,
      placeId: 'tash_rabat',
      color: AppTheme.gold,
    ),
    CommunityPost(
      id: 'p3',
      userName: 'Maya',
      text:
          'At Cholpon-Ata, the animal carvings become easier to see when the sun is lower.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      type: PostType.experience,
      likeCount: 27,
      commentCount: 6,
      placeId: 'cholpon_ata',
      color: AppTheme.leaf,
    ),
  ];

  static List<Booking> demoBookings() {
    return [
      Booking(
        id: 'b1',
        placeId: 'burana',
        placeTitle: 'Burana Tower',
        date: DateTime.now().add(const Duration(days: 9)),
        peopleCount: 3,
        notes: 'Need a guide for the stone museum.',
        rulesConfirmed: true,
        status: BookingStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Region regionById(String id) =>
      regions.firstWhere((region) => region.id == id);

  static Place placeById(String id) =>
      places.firstWhere((place) => place.id == id);
}

class AuthController extends ChangeNotifier {
  bool loaded = false;
  bool isLoggedIn = false;
  String userName = 'Guest';
  String email = 'guest@sacred.kg';

  AuthController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('session') ?? false;
    userName = prefs.getString('userName') ?? 'Guest';
    email = prefs.getString('email') ?? 'guest@sacred.kg';
    loaded = true;
    notifyListeners();
  }

  Future<bool> login(String emailValue, String password) async {
    if (emailValue.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = true;
    email = emailValue.trim();
    userName = email.split('@').first;
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String emailValue, String password) async {
    if (name.trim().isEmpty ||
        emailValue.trim().isEmpty ||
        password.trim().isEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = true;
    userName = name.trim();
    email = emailValue.trim();
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
    return true;
  }

  Future<void> guest() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = true;
    userName = 'Guest';
    email = 'guest@sacred.kg';
    await prefs.setBool('session', true);
    await prefs.setString('email', email);
    await prefs.setString('userName', userName);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session', false);
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn = false;
    userName = 'Guest';
    email = 'guest@sacred.kg';
    notifyListeners();
  }
}

class SettingsController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  String language = 'ky';
  bool musicEnabled = false;
  bool loaded = false;

  SettingsController() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = (prefs.getBool('darkMode') ?? false)
        ? ThemeMode.dark
        : ThemeMode.light;
    language = normalizeLanguageCode(prefs.getString('language'));
    Intl.defaultLocale = language;
    musicEnabled = prefs.getBool('music') ?? false;
    loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalizeLanguageCode(value);
    await prefs.setString('language', normalized);
    language = normalized;
    Intl.defaultLocale = language;
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music', value);
    musicEnabled = value;
    notifyListeners();
  }
}

class MockAppState extends ChangeNotifier {
  final Set<String> favorites = {};
  final List<CommunityPost> posts = [...MockData.posts];
  final List<Booking> bookings = MockData.demoBookings();

  MockAppState() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favorites.addAll(prefs.getStringList('favorites') ?? []);
    notifyListeners();
  }

  Future<void> toggleFavorite(String placeId) async {
    if (favorites.contains(placeId)) {
      favorites.remove(placeId);
    } else {
      favorites.add(placeId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void toggleLike(String postId) {
    final post = posts.firstWhere((item) => item.id == postId);
    post.liked = !post.liked;
    post.likeCount += post.liked ? 1 : -1;
    notifyListeners();
  }

  void addPost(String text, PostType type, String? placeId) {
    posts.insert(
      0,
      CommunityPost(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        userName: 'You',
        text: text,
        timestamp: DateTime.now(),
        type: type,
        likeCount: 0,
        commentCount: 0,
        placeId: placeId,
        color: AppTheme.leaf,
      ),
    );
    notifyListeners();
  }

  void addBooking(Booking booking) {
    bookings.insert(0, booking);
    notifyListeners();
  }
}


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    LocationOverridesService.loadIfNeeded();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    final role = await AuthService.getCurrentRole();
    if (!mounted || _redirected) return;
    _redirected = true;
    switch (role) {
      case UserRole.admin:
        final viewingAsUser = await AuthService.isAdminViewingAsUser();
        if (!mounted) return;
        context.go(viewingAsUser ? '/home' : '/admin');
      case UserRole.agent:
        context.go('/agent');
      case UserRole.user:
        context.go('/home');
      case null:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 180,
              height: 180,
              child: AnimatedSacredModel(compact: true),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(l10n.tagline),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const AnimatedSacredModel(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(l10n.login)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.go('/register'),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(l10n.createAccount)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(authProvider).guest();
                  if (context.mounted) context.go('/home');
                },
                child: Text(l10n.continueAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(text: 'demo@sacred.kg');
  final password = TextEditingController(text: 'demo');
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.welcomeBack,
      subtitle: l10n.loginSubtitle,
      children: [
        TextField(
          controller: email,
          decoration: InputDecoration(labelText: l10n.email),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.password),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            final ok = await ref
                .read(authProvider)
                .login(email.text, password.text);
            if (ok && context.mounted) {
              context.go('/home');
            } else {
              setState(() => error = l10n.bothFieldsRequired);
            }
          },
          child: Text(l10n.login),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final name = TextEditingController(text: 'Aizada');
  final email = TextEditingController(text: 'aizada@sacred.kg');
  final password = TextEditingController(text: 'demo');
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.createAccount,
      subtitle: l10n.registerSubtitle,
      children: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          decoration: InputDecoration(labelText: l10n.email),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.password),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            final ok = await ref
                .read(authProvider)
                .register(name.text, email.text, password.text);
            if (ok && context.mounted) {
              context.go('/home');
            } else {
              setState(() => error = l10n.allFieldsRequired);
            }
          },
          child: Text(l10n.register),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.alreadyHaveAccount),
        ),
      ],
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const AnimatedSacredModel(compact: true),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final appState = ref.watch(appStateProvider);
    final featured = [
      MockData.placeById('sulaiman_too'),
      MockData.placeById('cholpon_ata'),
      MockData.placeById('burana'),
      MockData.placeById('arslanbob'),
    ];
    final heroPlace = featured.first;
    final quickActions = [
      (
        t('Seven regions'),
        t('Choose a route'),
        Icons.public,
        '/map',
        AppTheme.leaf,
      ),
      (
        t('Ask Apashka'),
        t('Rules and stories'),
        Icons.auto_awesome,
        '/ai',
        AppTheme.rose,
      ),
      (
        t('Visit request'),
        t('Plan respectfully'),
        Icons.event_available,
        '/booking',
        AppTheme.gold,
      ),
    ];
    final menu = [
      (
        t('Sacred catalog'),
        t('Search shrines, stones, springs'),
        Icons.grid_view_rounded,
        '/catalog',
        AppTheme.clay,
      ),
      (
        t('Community yurt'),
        t('Read tips from visitors'),
        Icons.forum,
        '/feed',
        AppTheme.leaf,
      ),
      (
        t('Language and theme'),
        t('Theme, language, music'),
        Icons.tune,
        '/settings',
        AppTheme.gold,
      ),
      (
        t('Account'),
        t('Bookings and favorites'),
        Icons.person,
        '/account',
        AppTheme.rose,
      ),
      (
        'Туры',
        'Маршруты от наших турагентов',
        Icons.tour_outlined,
        '/tours',
        AppTheme.leaf,
      ),
    ];
    return AppScaffold(
      selectedIndex: 0,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeTopBar(userName: auth.userName),
                  const SizedBox(height: 12),
                  const _KyrgyzOrnamentBand(),
                  const SizedBox(height: 12),
                  _HomeHeroPanel(place: heroPlace),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeMetric(
                          value: '${MockData.regions.length}',
                          label: t('regions'),
                          icon: Icons.map_outlined,
                          color: AppTheme.leaf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeMetric(
                          value: '${MockData.places.length}',
                          label: t('places'),
                          icon: Icons.place_outlined,
                          color: AppTheme.clay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeMetric(
                          value: '${appState.favorites.length}',
                          label: t('saved'),
                          icon: Icons.favorite_border,
                          color: AppTheme.rose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _CultureStoryRow(),
                  const SizedBox(height: 22),
                  _HomeSectionHeader(
                    title: t('Pilgrim paths'),
                    action: t('Open catalog'),
                    onAction: () => context.go('/catalog'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickActions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = quickActions[index];
                        return SizedBox(
                              width: 162,
                              child: _HomeQuickAction(
                                title: item.$1,
                                subtitle: item.$2,
                                icon: item.$3,
                                color: item.$5,
                                onTap: () => _openHomeRoute(context, item.$4),
                              ),
                            )
                            .animate(delay: (35 * index).ms)
                            .fadeIn()
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HomeSectionHeader(
                    title: t('Sacred highlights'),
                    action: t('See all'),
                    onAction: () => context.go('/catalog'),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                              width: 286,
                              child: _FeaturedHomePlaceCard(
                                place: featured[index],
                              ),
                            )
                            .animate(delay: (45 * index).ms)
                            .fadeIn()
                            .slideY(begin: 0.04, end: 0);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _KyrgyzOrnamentBand(compact: true),
                  const SizedBox(height: 16),
                  _HomeSectionHeader(title: t('More to explore')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: menu.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = menu[index];
                return _HomeToolRow(
                      title: item.$1,
                      subtitle: item.$2,
                      icon: item.$3,
                      color: item.$5,
                      onTap: () => _openHomeRoute(context, item.$4),
                    )
                    .animate(delay: (35 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.04, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _openHomeRoute(BuildContext context, String route) {
  const primaryRoutes = {'/home', '/map', '/catalog', '/ai', '/account'};
  if (primaryRoutes.contains(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t('Salam')}, ${LocalizedContent.phrase(userName)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                t('Sacred KG cultural routes'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/account'),
          child: Container(
            width: 52,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.rose,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.72)),
            ),
            child: const _TundukMark(size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroPanel extends StatelessWidget {
  const _HomeHeroPanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 336,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.92),
                mountain: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                children: [
                  _HeroBadge(label: t('Tunduk route')),
                  const SizedBox(width: 8),
                  _HeroBadge(label: MockData.regionById(place.regionId).name),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              top: 18,
              child: _TundukMark(size: 54, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Kyrgyz sacred routes'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Mountains, petroglyphs, springs, and stories held with respect.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/map'),
                          icon: const Icon(Icons.public),
                          label: Text(t('Open regions')),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () => context.push('/place/${place.id}'),
                        icon: const Icon(Icons.arrow_forward),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, end: 0);
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KyrgyzOrnamentBand extends StatelessWidget {
  const _KyrgyzOrnamentBand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 18 : 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: KyrgyzOrnamentPainter(
            base: AppTheme.rose,
            accent: AppTheme.gold,
            secondary: AppTheme.leaf,
            compact: compact,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _TundukMark extends StatelessWidget {
  const _TundukMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: TundukPainter(color)),
    );
  }
}

class _CultureStoryRow extends StatelessWidget {
  const _CultureStoryRow();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Tunduk', t('shared sky'), Icons.circle_outlined, AppTheme.rose),
      ('Shyrdak', t('ornament paths'), Icons.diamond_outlined, AppTheme.gold),
      ('Komuz', t('living memory'), Icons.music_note, AppTheme.leaf),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _CultureStoryTile(
              title: items[i].$1,
              subtitle: items[i].$2,
              icon: items[i].$3,
              color: items[i].$4,
            ).animate(delay: (45 * i).ms).fadeIn().slideY(begin: 0.06, end: 0),
          ),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _CultureStoryTile extends StatelessWidget {
  const _CultureStoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.lerp(color, Theme.of(context).colorScheme.surface, 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(icon, color: color.withValues(alpha: 0.18), size: 46),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniOrnament extends StatelessWidget {
  const _MiniOrnament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 16,
      child: CustomPaint(
        painter: MiniOrnamentPainter(color.withValues(alpha: 0.72)),
      ),
    );
  }
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const Spacer(),
                _MiniOrnament(color: color),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedHomePlaceCard extends StatelessWidget {
  const _FeaturedHomePlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ArtStrip(place: place),
                  CustomPaint(
                    painter: KyrgyzCornerPainter(
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    place.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        MockData.regionById(place.regionId).name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _HomeToolRow extends StatelessWidget {
  const _HomeToolRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class RegionsScreen extends StatelessWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: t('Choose a region'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _RegionsHero(),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 16),
          const _RegionStatsRow(),
          const SizedBox(height: 20),
          _DetailSectionTitle(
            title: t('Seven sacred directions'),
            action: t('All places'),
            onAction: () => context.go('/catalog'),
          ),
          const SizedBox(height: 10),
          const _RegionSpotlightStrip(),
          const SizedBox(height: 16),
          _DetailSectionTitle(title: t('Regional routes')),
          const SizedBox(height: 10),
          ...MockData.regions.indexed.map((entry) {
            final index = entry.$1;
            final region = entry.$2;
            final places = MockData.places
                .where((place) => place.regionId == region.id)
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RegionRouteCard(region: region, places: places)
                  .animate(delay: (45 * index).ms)
                  .fadeIn()
                  .slideY(begin: 0.04, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _RegionsHero extends StatelessWidget {
  const _RegionsHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 276,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedKyrgyzstanMap(),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.88),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: _TundukMark(size: 54, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: t('Kyrgyzstan regions')),
                  const SizedBox(height: 10),
                  Text(
                    t('Choose a sacred direction'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      'Browse valleys, lake routes, southern mountains, forests, and petroglyph paths.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.03, end: 0);
  }
}

class _RegionStatsRow extends StatelessWidget {
  const _RegionStatsRow();

  @override
  Widget build(BuildContext context) {
    final petroglyphCount = MockData.places
        .where((place) => place.type == PlaceType.petroglyphSite)
        .length;
    final stats = [
      ('7', t('regions'), Icons.public, AppTheme.leaf),
      (
        '${MockData.places.length}',
        t('places'),
        Icons.place_outlined,
        AppTheme.clay,
      ),
      ('$petroglyphCount', t('petroglyphs'), Icons.history_edu, AppTheme.rose),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _DetailStatTile(
              icon: stats[i].$3,
              value: stats[i].$1,
              label: stats[i].$2,
              color: stats[i].$4,
            ).animate(delay: (35 * i).ms).fadeIn().slideY(begin: 0.04, end: 0),
          ),
          if (i != stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _RegionSpotlightStrip extends StatelessWidget {
  const _RegionSpotlightStrip();

  @override
  Widget build(BuildContext context) {
    final spotlight = MockData.regions.take(4).toList();
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: spotlight.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final region = spotlight[index];
          return SizedBox(
                width: 178,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push('/region/${region.id}'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: region.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: KyrgyzCornerPainter(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _TundukMark(size: 30, color: Colors.white),
                            const Spacer(),
                            Text(
                              region.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              region.highlights.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(delay: (40 * index).ms)
              .fadeIn()
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }
}

class _RegionRouteCard extends StatelessWidget {
  const _RegionRouteCard({required this.region, required this.places});

  final Region region;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final featured = places.isEmpty ? t('No places yet') : places.first.title;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/region/${region.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: region.color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 92,
              decoration: BoxDecoration(
                color: region.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _TundukMark(size: 30, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${places.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          region.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: region.highlights
                        .map(
                          (highlight) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: region.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              highlight,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tWith('Featured: {place}', {'place': featured}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
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

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({this.regionId, super.key});

  final String? regionId;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final searchController = TextEditingController();
  String query = '';
  String? regionId;
  PlaceType? type;
  bool sortByRating = true;

  @override
  void initState() {
    super.initState();
    regionId = widget.regionId;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var places = MockData.places.where((place) {
      final matchesQuery =
          place.title.toLowerCase().contains(query.toLowerCase()) ||
          place.shortDescription.toLowerCase().contains(query.toLowerCase());
      final matchesRegion = regionId == null || place.regionId == regionId;
      final matchesType = type == null || place.type == type;
      return matchesQuery && matchesRegion && matchesType;
    }).toList();
    places.sort(
      (a, b) => sortByRating
          ? b.rating.compareTo(a.rating)
          : b.popularity.compareTo(a.popularity),
    );
    final regionName = regionId == null
        ? null
        : MockData.regionById(regionId!).name;
    final activeFilterCount =
        (regionId == null ? 0 : 1) + (type == null ? 0 : 1);

    return AppScaffold(
      selectedIndex: 2,
      title: regionName == null
          ? t('Sacred catalog')
          : tWith('{region} places', {'region': regionName}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _CatalogHero(regionName: regionName, resultCount: places.length),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 14),
          _CatalogSearchCard(
            controller: searchController,
            query: query,
            activeFilterCount: activeFilterCount,
            onChanged: (value) => setState(() => query = value),
            onClear: () => setState(() {
              searchController.clear();
              query = '';
              regionId = null;
              type = null;
            }),
          ),
          const SizedBox(height: 14),
          _CatalogFilterSection(
            selectedRegionId: regionId,
            selectedType: type,
            sortByRating: sortByRating,
            onRegionSelected: (value) => setState(() => regionId = value),
            onTypeSelected: (value) => setState(() => type = value),
            onSortChanged: (value) => setState(() => sortByRating = value),
          ),
          const SizedBox(height: 18),
          _DetailSectionTitle(
            title: tWith('{count} sacred places', {'count': places.length}),
            action: sortByRating ? t('Top rated') : t('Popular'),
          ),
          const SizedBox(height: 10),
          if (places.isEmpty)
            EmptyView(message: t('No matching places yet.'))
          else
            ...places.indexed.map((entry) {
              final index = entry.$1;
              final place = entry.$2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CatalogPlaceCard(place: place)
                    .animate(delay: (35 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.04, end: 0),
              );
            }),
        ],
      ),
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.regionName, required this.resultCount});

  final String? regionName;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedSacredModel(compact: true, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.88),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: _TundukMark(size: 48, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: regionName ?? t('All Kyrgyzstan')),
                  const SizedBox(height: 10),
                  Text(
                    t('Sacred catalog'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tWith(
                      '{count} places with stories, rules, routes, and local mock reviews.',
                      {'count': resultCount},
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
  }
}

class _CatalogSearchCard extends StatelessWidget {
  const _CatalogSearchCard({
    required this.controller,
    required this.query,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _TundukMark(size: 28, color: AppTheme.rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Find a place by name or story'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (query.isNotEmpty || activeFilterCount > 0)
                TextButton(onPressed: onClear, child: Text(t('Clear'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: t('Search sacred places'),
              suffixText: activeFilterCount == 0
                  ? null
                  : tWith('{count} filters', {'count': activeFilterCount}),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CatalogFilterSection extends StatelessWidget {
  const _CatalogFilterSection({
    required this.selectedRegionId,
    required this.selectedType,
    required this.sortByRating,
    required this.onRegionSelected,
    required this.onTypeSelected,
    required this.onSortChanged,
  });

  final String? selectedRegionId;
  final PlaceType? selectedType;
  final bool sortByRating;
  final ValueChanged<String?> onRegionSelected;
  final ValueChanged<PlaceType?> onTypeSelected;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: t('Route filters')),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CulturalFilterChip(
                  selected: selectedRegionId == null,
                  label: t('All regions'),
                  color: AppTheme.leaf,
                  onTap: () => onRegionSelected(null),
                ),
                const SizedBox(width: 8),
                ...MockData.regions.map(
                  (region) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CulturalFilterChip(
                      selected: selectedRegionId == region.id,
                      label: region.name,
                      color: region.color,
                      onTap: () => onRegionSelected(region.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CulturalFilterChip(
                  selected: selectedType == null,
                  label: t('All types'),
                  color: AppTheme.clay,
                  onTap: () => onTypeSelected(null),
                ),
                const SizedBox(width: 8),
                ...PlaceType.values.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CulturalFilterChip(
                      selected: selectedType == item,
                      label: item.label,
                      color: AppTheme.rose,
                      onTap: () => onTypeSelected(item),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(t('Rating')),
                icon: const Icon(Icons.star),
              ),
              ButtonSegment(
                value: false,
                label: Text(t('Popular')),
                icon: const Icon(Icons.trending_up),
              ),
            ],
            selected: {sortByRating},
            onSelectionChanged: (value) => onSortChanged(value.first),
          ),
        ],
      ),
    );
  }
}

class _CulturalFilterChip extends StatelessWidget {
  const _CulturalFilterChip({
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: selected
          ? const _TundukMark(size: 18, color: Colors.white)
          : null,
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _CatalogPlaceCard extends StatelessWidget {
  const _CatalogPlaceCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: place.colors.first.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              height: 140,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ArtStrip(place: place),
                    CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.34),
                      ),
                    ),
                    const Center(
                      child: _TundukMark(size: 38, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        InfoChip(
                          icon: Icons.place,
                          label: MockData.regionById(place.regionId).name,
                        ),
                        InfoChip(
                          icon: Icons.star,
                          label: place.rating.toStringAsFixed(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: place.colors.first,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({required this.placeId, super.key});

  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    LocationOverridesService.loadIfNeeded();
    LocationOverridesService.addListener(_onOverrides);
  }

  @override
  void dispose() {
    LocationOverridesService.removeListener(_onOverrides);
    super.dispose();
  }

  void _onOverrides() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final place = MockData.placeById(widget.placeId);
    final appState = ref.watch(appStateProvider);
    final isFavorite = appState.favorites.contains(place.id);
    final reviews = MockData.reviews
        .where((review) => review.placeId == place.id)
        .toList();
    return AppScaffold(
      title: place.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PlaceDetailHero(
            place: place,
            isFavorite: isFavorite,
            onFavorite: () =>
                ref.read(appStateProvider).toggleFavorite(place.id),
          ),
          if (place.images.isNotEmpty) ...[
            const SizedBox(height: 14),
            PlaceGallery(place: place),
          ],
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 14),
          _PlaceDetailStats(place: place),
          const SizedBox(height: 18),
          _PlaceIntroCard(place: place),
          if (place.fullDescription.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionBlock(
              title: 'Подробно',
              text: place.fullDescription,
              icon: Icons.menu_book_outlined,
            ),
          ],
          const SizedBox(height: 14),
          _PlaceActionPanel(place: place),
          const SizedBox(height: 18),
          _DetailSectionTitle(
            title: t('Sacred knowledge'),
            action: t('Ask guide'),
            onAction: () => context.push('/ai'),
          ),
          const SizedBox(height: 10),
          SectionBlock(
            title: t('Cultural note'),
            text: place.culturalNote,
            icon: Icons.auto_stories,
          ),
          SectionBlock(
            title: t('Visiting rules'),
            text: place.visitingRules,
            icon: Icons.volunteer_activism,
          ),
          SectionBlock(title: t('Route'), text: place.route, icon: Icons.route),
          const SizedBox(height: 18),
          _DetailSectionTitle(title: t('Place palette')),
          const SizedBox(height: 10),
          _PlacePaletteStrip(place: place),
          const SizedBox(height: 20),
          _DetailSectionTitle(title: t('Visitor voices')),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            EmptyView(message: t('No local reviews for this place yet.'))
          else
            ...reviews.map(
              (review) => _ReviewCard(
                review: review,
              ).animate().fadeIn().slideY(begin: 0.04, end: 0),
            ),
        ],
      ),
    );
  }
}

class _PlaceDetailHero extends StatelessWidget {
  const _PlaceDetailHero({
    required this.place,
    required this.isFavorite,
    required this.onFavorite,
  });

  final Place place;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 372,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.95),
                mountain: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.74),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: [
                  _HeroBadge(label: MockData.regionById(place.regionId).name),
                  const SizedBox(width: 8),
                  _HeroBadge(label: place.type.label),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isFavorite
                          ? AppTheme.rose
                          : Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 18,
              top: 74,
              child: _TundukMark(size: 58, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.gold, size: 19),
                      const SizedBox(width: 5),
                      Text(
                        '${place.rating.toStringAsFixed(1)} ${t('rating')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${place.reviewsCount} ${t('reviews')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.03, end: 0);
  }
}

class _PlaceDetailStats extends StatelessWidget {
  const _PlaceDetailStats({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.public,
        MockData.regionById(place.regionId).name,
        t('regions'),
        AppTheme.leaf,
      ),
      (Icons.category_outlined, place.type.label, t('type'), AppTheme.clay),
      (Icons.trending_up, '${place.popularity}', t('popular'), AppTheme.rose),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(
            child: _DetailStatTile(
              icon: stats[i].$1,
              value: stats[i].$2,
              label: stats[i].$3,
              color: stats[i].$4,
            ).animate(delay: (40 * i).ms).fadeIn().slideY(begin: 0.05, end: 0),
          ),
          if (i != stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _DetailStatTile extends StatelessWidget {
  const _DetailStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(icon, color: color.withValues(alpha: 0.12), size: 48),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceIntroCard extends StatelessWidget {
  const _PlaceIntroCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TundukMark(size: 28, color: AppTheme.rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('Story of the place'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(place.description),
        ],
      ),
    );
  }
}

class _PlaceActionPanel extends StatelessWidget {
  const _PlaceActionPanel({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/ai?place=${place.id}'),
            icon: const Icon(Icons.auto_awesome),
            label: Text(t('Ask guide')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/booking?place=${place.id}'),
            icon: const Icon(Icons.event_available),
            label: Text(t('Plan visit')),
          ),
        ),
      ],
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (action != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _PlacePaletteStrip extends StatelessWidget {
  const _PlacePaletteStrip({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: place.colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => Container(
          width: 126,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                place.colors[index],
                place.colors[(index + 1) % place.colors.length],
              ],
            ),
          ),
          child: CustomPaint(
            painter: KyrgyzCornerPainter(
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.leaf,
              child: Text(
                review.user.characters.first,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.user,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.star, color: AppTheme.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(appStateProvider).posts;
    return AppScaffold(
      title: t('Community'),
      actions: [
        IconButton(
          onPressed: () => context.push('/feed/create'),
          icon: const Icon(Icons.add),
        ),
      ],
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          final place = post.placeId == null
              ? null
              : MockData.placeById(post.placeId!);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: post.color,
                        child: Text(
                          post.userName.characters.first,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(post.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Chip(label: Text(post.type.label)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(post.text),
                  if (place != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/place/${place.id}'),
                      icon: const Icon(Icons.place),
                      label: Text(place.title),
                    ),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(appStateProvider).toggleLike(post.id),
                        icon: Icon(
                          post.liked ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text('${post.likeCount}'),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text('${post.commentCount}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final text = TextEditingController();
  PostType type = PostType.experience;
  String? placeId;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: t('New post'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: text,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: t('Share a review, tip, issue, or experience'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PostType>(
            initialValue: type,
            decoration: InputDecoration(labelText: t('Post type')),
            items: PostType.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value ?? type),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: placeId,
            decoration: InputDecoration(labelText: t('Related place')),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(t('No place')),
              ),
              ...MockData.places.map(
                (place) => DropdownMenuItem<String?>(
                  value: place.id,
                  child: Text(place.title),
                ),
              ),
            ],
            onChanged: (value) => setState(() => placeId = value),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (text.text.trim().isEmpty) return;
              ref
                  .read(appStateProvider)
                  .addPost(text.text.trim(), type, placeId);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/feed');
              }
            },
            child: Text(t('Publish locally')),
          ),
        ],
      ),
    );
  }
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({this.placeId, super.key});

  final String? placeId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late String selectedPlaceId = widget.placeId ?? MockData.places.first.id;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
  int people = 2;
  bool confirmed = false;
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(appStateProvider).bookings;
    final place = MockData.placeById(selectedPlaceId);
    return AppScaffold(
      title: t('Booking request'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _BookingHero(place: place),
          const SizedBox(height: 14),
          const _KyrgyzOrnamentBand(compact: true),
          const SizedBox(height: 16),
          _DetailSectionTitle(title: t('Plan your visit')),
          const SizedBox(height: 10),
          _BookingFormCard(
            title: t('1. Sacred place'),
            subtitle: t('Choose where the visit request should go.'),
            icon: Icons.place_outlined,
            color: AppTheme.leaf,
            child: DropdownButtonFormField<String>(
              initialValue: selectedPlaceId,
              decoration: InputDecoration(labelText: t('Place')),
              items: MockData.places
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedPlaceId = value ?? selectedPlaceId),
            ),
          ),
          const SizedBox(height: 12),
          _BookingDateCard(
            date: selectedDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: selectedDate,
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 12),
          _BookingPeopleCard(
            people: people,
            onDecrease: people > 1 ? () => setState(() => people--) : null,
            onIncrease: () => setState(() => people++),
          ),
          const SizedBox(height: 12),
          _BookingFormCard(
            title: t('4. Notes for the visit'),
            subtitle: t(
              'Add guide requests, transport notes, or accessibility needs.',
            ),
            icon: Icons.edit_note,
            color: AppTheme.clay,
            child: TextField(
              controller: notes,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(labelText: t('Optional notes')),
            ),
          ),
          const SizedBox(height: 12),
          _RulesConfirmationCard(
            confirmed: confirmed,
            onChanged: (value) => setState(() => confirmed = value),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: confirmed
                ? () {
                    ref
                        .read(appStateProvider)
                        .addBooking(
                          Booking(
                            id: 'b${DateTime.now().microsecondsSinceEpoch}',
                            placeId: place.id,
                            placeTitle: place.title,
                            date: selectedDate,
                            peopleCount: people,
                            notes: notes.text.trim(),
                            rulesConfirmed: confirmed,
                            status: BookingStatus.pending,
                            createdAt: DateTime.now(),
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('Visit request saved locally.')),
                      ),
                    );
                  }
                : null,
            child: Text(t('Send visit request')),
          ),
          const SizedBox(height: 24),
          _DetailSectionTitle(title: t('My visit requests')),
          const SizedBox(height: 10),
          ...bookings.map(
            (booking) => _BookingHistoryCard(
              booking: booking,
            ).animate().fadeIn().slideY(begin: 0.04, end: 0),
          ),
        ],
      ),
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSacredModel(place: place, compact: true, showTitle: false),
            CustomPaint(
              painter: KyrgyzHeroPainter(
                ornament: AppTheme.gold.withValues(alpha: 0.9),
                mountain: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.26),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 16,
              top: 16,
              child: _TundukMark(size: 46, color: Colors.white),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBadge(label: t('Respectful visit')),
                  const SizedBox(height: 10),
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'Choose date, group size, and rules before sending a local request.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.90),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
  }
}

class _BookingFormCard extends StatelessWidget {
  const _BookingFormCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingDateCard extends StatelessWidget {
  const _BookingDateCard({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();
    final weekday = DateFormat('EEEE').format(date);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 82,
              decoration: BoxDecoration(
                color: AppTheme.rose,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        day,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('2. Visit date'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text('$weekday, ${DateFormat('MMMM d, y').format(date)}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 16,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t('Moon marker: mock calendar'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingPeopleCard extends StatelessWidget {
  const _BookingPeopleCard({
    required this.people,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int people;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return _BookingFormCard(
      title: t('3. Visitors'),
      subtitle: t('Keep the group size clear for local planning.'),
      icon: Icons.groups_2_outlined,
      color: AppTheme.leaf,
      child: Row(
        children: [
          IconButton.outlined(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$people',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(t('people'), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: onIncrease,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _RulesConfirmationCard extends StatelessWidget {
  const _RulesConfirmationCard({
    required this.confirmed,
    required this.onChanged,
  });

  final bool confirmed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!confirmed),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: confirmed
              ? AppTheme.leaf.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: confirmed
                ? AppTheme.leaf
                : AppTheme.rose.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: confirmed,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('5. Visiting rules'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(
                      'I will keep the place clean, respect prayer or ritual spaces, and follow local guidance.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.04, end: 0);
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.pending => AppTheme.gold,
      BookingStatus.approved => AppTheme.leaf,
      BookingStatus.rejected => AppTheme.rose,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: KyrgyzCornerPainter(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  const Icon(Icons.event_available, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.placeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, y').format(booking.date)} - ${booking.peopleCount} ${t('people')}',
                  ),
                  if (booking.notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      booking.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(label: Text(booking.status.label)),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.settings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: settings.themeMode == ThemeMode.dark,
            title: Text(l10n.darkTheme),
            subtitle: Text(l10n.savedLocally),
            onChanged: (value) => ref.read(settingsProvider).setDarkMode(value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.language,
            decoration: InputDecoration(labelText: l10n.language),
            items: AppLocalizations.supportedLocales.map((locale) {
              final code = locale.languageCode;
              return DropdownMenuItem(
                value: code,
                child: Text(languageLabel(context, code)),
              );
            }).toList(),
            onChanged: (value) =>
                ref.read(settingsProvider).setLanguage(value ?? 'ky'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: settings.musicEnabled,
            title: Text(l10n.music),
            subtitle: Text(l10n.mockSettingOnly),
            onChanged: (value) => ref.read(settingsProvider).setMusic(value),
          ),
          const SizedBox(height: 16),
          SectionBlock(
            title: l10n.contactDevelopers,
            text: 'hack2026@sacred.kg',
            icon: Icons.mail,
          ),
          SectionBlock(
            title: l10n.about,
            text: l10n.aboutText,
            icon: Icons.info,
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(appStateProvider);
    final l10n = context.l10n;
    final displayName = LocalizedContent.phrase(auth.userName);
    final favorites = MockData.places
        .where((place) => state.favorites.contains(place.id))
        .toList();
    return AppScaffold(
      selectedIndex: 4,
      title: l10n.account,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.leaf,
                    child: Text(
                      displayName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(auth.email),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.favorites,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            EmptyView(message: l10n.favoritePlacesEmpty)
          else
            ...favorites.map((place) => PlaceCard(place: place, wide: true)),
          const SizedBox(height: 18),
          Text(
            l10n.myBookings,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...state.bookings.map(
            (booking) => Card(
              child: ListTile(
                title: Text(booking.placeTitle),
                subtitle: Text(DateFormat('MMM d, y').format(booking.date)),
                trailing: Chip(label: Text(booking.status.label)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.shortcuts,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.communityFeed,
            subtitle: l10n.visitorTips,
            icon: Icons.forum_outlined,
            color: AppTheme.leaf,
            onTap: () => context.push('/feed'),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.bookingRequests,
            subtitle: l10n.planAnotherVisit,
            icon: Icons.event_available,
            color: AppTheme.gold,
            onTap: () => context.push('/booking'),
          ),
          const SizedBox(height: 8),
          _HomeToolRow(
            title: l10n.settings,
            subtitle: l10n.themeLanguageMusic,
            icon: Icons.tune,
            color: AppTheme.clay,
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: () async {
              await ref.read(authProvider).logout();
              await AuthService.logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteAccountQuestion),
                  content: Text(l10n.deleteAccountBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider).deleteAccount();
                await AuthService.logout();
                if (context.mounted) context.go('/login');
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.child,
    this.title,
    this.actions,
    this.selectedIndex,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final navIndex = selectedIndex ?? _navIndexForPath(path);
    return PopScope(
      canPop: context.canPop() || path == '/home',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && path != '/home') {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: title == null
            ? null
            : AppBar(title: Text(title!), actions: actions),
        body: SafeArea(
          top: title == null,
          child: Column(
            children: [
              const _AdminViewAsUserBanner(),
              Expanded(child: child),
            ],
          ),
        ),
        bottomNavigationBar:
            NavigationBar(
                  selectedIndex: navIndex,
                  animationDuration: const Duration(milliseconds: 420),
                  onDestinationSelected: (index) {
                    final routes = [
                      '/home',
                      '/map',
                      '/catalog',
                      '/ai',
                      '/account',
                    ];
                    context.go(routes[index]);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: l10n.home,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.public_outlined),
                      selectedIcon: const Icon(Icons.public),
                      label: l10n.regions,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: l10n.places,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      selectedIcon: const Icon(Icons.auto_awesome),
                      label: l10n.ai,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: l10n.account,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 180.ms)
                .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

/// Shows a thin banner at the top of [AppScaffold] when an administrator has
/// switched into the user-facing UI, so they can quickly return to /admin.
class _AdminViewAsUserBanner extends StatefulWidget {
  const _AdminViewAsUserBanner();

  @override
  State<_AdminViewAsUserBanner> createState() => _AdminViewAsUserBannerState();
}

class _AdminViewAsUserBannerState extends State<_AdminViewAsUserBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final v = await AuthService.isAdminViewingAsUser();
    if (!mounted) return;
    setState(() => _visible = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: () async {
          await AuthService.setAdminViewAsUser(false);
          if (!context.mounted) return;
          context.go('/admin');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Режим администратора (просмотр глазами пользователя) — '
                  'нажмите, чтобы вернуться в админ-панель',
                  style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _navIndexForPath(String path) {
  if (path.startsWith('/map') || path.startsWith('/region')) {
    return 1;
  }
  if (path.startsWith('/catalog') || path.startsWith('/place')) {
    return 2;
  }
  if (path.startsWith('/ai')) {
    return 3;
  }
  if (path.startsWith('/account') ||
      path.startsWith('/feed') ||
      path.startsWith('/booking') ||
      path.startsWith('/settings')) {
    return 4;
  }
  return 0;
}

class PlaceCard extends StatelessWidget {
  const PlaceCard({required this.place, this.wide = false, super.key});

  final Place place;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/place/${place.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: wide
            ? Row(
                children: [
                  _ArtStrip(place: place, width: 92),
                  Expanded(child: _PlaceText(place: place)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ArtStrip(place: place)),
                  _PlaceText(place: place, compact: true),
                ],
              ),
      ),
    );
  }
}

class _ArtStrip extends StatelessWidget {
  const _ArtStrip({required this.place, this.width});

  final Place place;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: place.colors,
        ),
      ),
      child: CustomPaint(
        painter: PetroglyphPatternPainter(Colors.white.withValues(alpha: 0.45)),
      ),
    );
    final url = place.imageUrl;
    if (url.isEmpty) return placeholder;
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          PlaceImage(source: url, fit: BoxFit.cover),
        ],
      ),
    );
  }
}

/// Универсальный виджет показа фото места. Понимает asset-пути и сетевые URL.
class PlaceImage extends StatelessWidget {
  const PlaceImage({
    required this.source,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String source;
  final BoxFit fit;

  bool get _isAsset =>
      source.startsWith('assets/') || source.startsWith('asset:');

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return Container(color: Colors.black12);
    }
    if (_isAsset) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }
    return Image.network(
      source,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

/// Свайп-галерея фотографий места: показывает все [place.images] с индикатором страниц.
class PlaceGallery extends StatefulWidget {
  const PlaceGallery({required this.place, super.key});

  final Place place;

  @override
  State<PlaceGallery> createState() => _PlaceGalleryState();
}

class _PlaceGalleryState extends State<PlaceGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.place.images;
    if (images.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => PlaceImage(source: images[i]),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    final selected = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            if (images.length > 1)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceText extends StatelessWidget {
  const _PlaceText({required this.place, this.compact = false});

  final Place place;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            place.shortDescription,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppTheme.gold),
              const SizedBox(width: 4),
              Text(place.rating.toStringAsFixed(1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  MockData.regionById(place.regionId).name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class SectionBlock extends StatelessWidget {
  const SectionBlock({
    required this.title,
    required this.text,
    required this.icon,
    super.key,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(child: Text(message)),
    );
  }
}

class AnimatedSacredModel extends StatefulWidget {
  const AnimatedSacredModel({
    this.place,
    this.compact = false,
    this.showTitle = true,
    super.key,
  });

  final Place? place;
  final bool compact;
  final bool showTitle;

  @override
  State<AnimatedSacredModel> createState() => _AnimatedSacredModelState();
}

class _AnimatedSacredModelState extends State<AnimatedSacredModel>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.place?.colors ??
        const [AppTheme.leaf, AppTheme.gold, AppTheme.rose];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final turn = controller.value * math.pi * 2;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.first,
                colors[1 % colors.length],
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: PetroglyphPatternPainter(
                  Colors.white.withValues(alpha: 0.18),
                ),
              ),
              Align(
                alignment: Alignment(0, widget.compact ? 0.2 : 0.34),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateY(math.sin(turn) * 0.35)
                    ..rotateX(-0.58 + math.cos(turn) * 0.04),
                  child: SizedBox(
                    width: widget.compact ? 150 : 230,
                    height: widget.compact ? 150 : 220,
                    child: CustomPaint(
                      painter: SacredStoneModelPainter(
                        primary: colors.first,
                        accent: colors.length > 1 ? colors[1] : AppTheme.gold,
                        glow: colors.length > 2 ? colors[2] : AppTheme.rose,
                        progress: controller.value,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showTitle)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Text(
                    widget.place?.title ?? t('Kyrgyz sacred routes'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      shadows: const [Shadow(blurRadius: 10)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedKyrgyzstanMap extends StatefulWidget {
  const AnimatedKyrgyzstanMap({super.key});

  @override
  State<AnimatedKyrgyzstanMap> createState() => _AnimatedKyrgyzstanMapState();
}

class _AnimatedKyrgyzstanMapState extends State<AnimatedKyrgyzstanMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: RegionMapPainter(progress: controller.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class KyrgyzOrnamentPainter extends CustomPainter {
  KyrgyzOrnamentPainter({
    required this.base,
    required this.accent,
    required this.secondary,
    required this.compact,
  });

  final Color base;
  final Color accent;
  final Color secondary;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [base, Color.lerp(base, secondary, 0.36)!, secondary],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final step = compact ? 34.0 : 42.0;
    final centerY = size.height / 2;
    for (var x = -step; x < size.width + step; x += step) {
      final diamond = Path()
        ..moveTo(x + step * 0.50, 2)
        ..lineTo(x + step * 0.86, centerY)
        ..lineTo(x + step * 0.50, size.height - 2)
        ..lineTo(x + step * 0.14, centerY)
        ..close();
      canvas.drawPath(diamond, Paint()..color = accent.withValues(alpha: 0.90));

      final inner = Path()
        ..moveTo(x + step * 0.50, size.height * 0.24)
        ..lineTo(x + step * 0.68, centerY)
        ..lineTo(x + step * 0.50, size.height * 0.76)
        ..lineTo(x + step * 0.32, centerY)
        ..close();
      canvas.drawPath(
        inner,
        Paint()..color = Colors.white.withValues(alpha: 0.64),
      );

      final hookPaint = Paint()
        ..color = Colors.white.withValues(alpha: compact ? 0.26 : 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.2 : 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x + step * 0.22, centerY),
          width: step * 0.42,
          height: step * 0.42,
        ),
        -math.pi / 2,
        math.pi,
        false,
        hookPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x + step * 0.78, centerY),
          width: step * 0.42,
          height: step * 0.42,
        ),
        math.pi / 2,
        math.pi,
        false,
        hookPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KyrgyzOrnamentPainter oldDelegate) {
    return oldDelegate.base != base ||
        oldDelegate.accent != accent ||
        oldDelegate.secondary != secondary ||
        oldDelegate.compact != compact;
  }
}

class TundukPainter extends CustomPainter {
  TundukPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.width * 0.07)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      Offset(center.dx - radius * 0.68, center.dy),
      Offset(center.dx + radius * 0.68, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.68),
      Offset(center.dx, center.dy + radius * 0.68),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.58),
      -math.pi * 0.88,
      math.pi * 1.76,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TundukPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MiniOrnamentPainter extends CustomPainter {
  MiniOrnamentPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.10, 2, size.width * 0.28, size.height - 4),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.62, 2, size.width * 0.28, size.height - 4),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MiniOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class KyrgyzHeroPainter extends CustomPainter {
  KyrgyzHeroPainter({required this.ornament, required this.mountain});

  final Color ornament;
  final Color mountain;

  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()..color = mountain;
    final mountainPath = Path()
      ..moveTo(0, size.height * 0.56)
      ..lineTo(size.width * 0.18, size.height * 0.42)
      ..lineTo(size.width * 0.30, size.height * 0.50)
      ..lineTo(size.width * 0.47, size.height * 0.35)
      ..lineTo(size.width * 0.64, size.height * 0.53)
      ..lineTo(size.width * 0.82, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    final linePaint = Paint()
      ..color = ornament
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sideX = size.width - 22;
    for (var y = size.height * 0.22; y < size.height * 0.78; y += 38) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(sideX, y), width: 30, height: 30),
        math.pi / 2,
        math.pi,
        false,
        linePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(22, y + 18), width: 30, height: 30),
        -math.pi / 2,
        math.pi,
        false,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KyrgyzHeroPainter oldDelegate) {
    return oldDelegate.ornament != ornament || oldDelegate.mountain != mountain;
  }
}

class KyrgyzCornerPainter extends CustomPainter {
  KyrgyzCornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12, 12), Offset(size.width * 0.32, 12), paint);
    canvas.drawLine(
      const Offset(12, 12),
      Offset(12, size.height * 0.32),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(12, 12, 28, 28),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 12, size.height - 12),
      Offset(size.width * 0.68, size.height - 12),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 12, size.height - 12),
      Offset(size.width - 12, size.height * 0.68),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant KyrgyzCornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class SacredStoneModelPainter extends CustomPainter {
  SacredStoneModelPainter({
    required this.primary,
    required this.accent,
    required this.glow,
    required this.progress,
  });

  final Color primary;
  final Color accent;
  final Color glow;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.82),
        width: size.width * 0.8,
        height: size.height * 0.16,
      ),
      shadow,
    );

    final base = Paint()
      ..shader = LinearGradient(
        colors: [primary, accent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final side = Paint()..color = Color.lerp(primary, Colors.black, 0.24)!;
    final cap = Paint()..color = Color.lerp(accent, Colors.white, 0.16)!;

    final body = Path()
      ..moveTo(size.width * 0.28, size.height * 0.78)
      ..lineTo(size.width * 0.39, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.10,
        size.width * 0.61,
        size.height * 0.20,
      )
      ..lineTo(size.width * 0.72, size.height * 0.78)
      ..close();
    final sidePath = Path()
      ..moveTo(size.width * 0.61, size.height * 0.20)
      ..lineTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.58, size.height * 0.86)
      ..lineTo(size.width * 0.50, size.height * 0.24)
      ..close();
    final capPath = Path()
      ..moveTo(size.width * 0.39, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.10,
        size.width * 0.61,
        size.height * 0.20,
      )
      ..lineTo(size.width * 0.50, size.height * 0.24)
      ..close();

    canvas.drawPath(body, base);
    canvas.drawPath(sidePath, side);
    canvas.drawPath(capPath, cap);

    final orbit = progress * math.pi * 2;
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final y = size.height * (0.38 + math.sin(orbit) * 0.025);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, y),
        width: size.width * 0.34,
        height: size.height * 0.12,
      ),
      math.pi * 0.08,
      math.pi * 1.45,
      false,
      glowPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.52),
      Offset(size.width * 0.57, size.height * 0.52),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.46),
      size.width * 0.035,
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.50, size.height * 0.62),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.57),
      Offset(size.width * 0.44, size.height * 0.66),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.57),
      Offset(size.width * 0.58, size.height * 0.66),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SacredStoneModelPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primary != primary;
  }
}

class PetroglyphPatternPainter extends CustomPainter {
  PetroglyphPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final x = ((i * 57) % math.max(size.width, 1.0)).toDouble();
      final y = (24 + (i * 41) % math.max(size.height - 48, 1.0)).toDouble();
      canvas.drawCircle(Offset(x + 18, y), 8, paint);
      canvas.drawLine(Offset(x + 18, y + 8), Offset(x + 18, y + 26), paint);
      canvas.drawLine(Offset(x + 18, y + 17), Offset(x + 5, y + 28), paint);
      canvas.drawLine(Offset(x + 18, y + 17), Offset(x + 34, y + 28), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PetroglyphPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class RegionMapPainter extends CustomPainter {
  RegionMapPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.leaf, AppTheme.gold],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final regionPaint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.75);
    for (var i = 0; i < MockData.regions.length; i++) {
      final region = MockData.regions[i];
      regionPaint.color = region.color.withValues(alpha: 0.78);
      final x = size.width * (0.10 + (i % 4) * 0.22);
      final y =
          size.height *
          (0.28 + (i ~/ 4) * 0.28 + math.sin(progress * math.pi + i) * 0.015);
      final rect = Rect.fromCenter(
        center: Offset(x + size.width * 0.08, y),
        width: size.width * 0.19,
        height: size.height * 0.22,
      );
      final path = Path()
        ..moveTo(rect.left, rect.center.dy)
        ..lineTo(rect.left + rect.width * 0.25, rect.top)
        ..lineTo(rect.right - rect.width * 0.16, rect.top + rect.height * 0.08)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.right - rect.width * 0.22, rect.bottom)
        ..lineTo(
          rect.left + rect.width * 0.10,
          rect.bottom - rect.height * 0.08,
        )
        ..close();
      canvas.drawPath(path, regionPaint);
      canvas.drawPath(path, stroke);
      final textPainter = TextPainter(
        text: TextSpan(
          text: region.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      textPainter.paint(canvas, Offset(rect.left + 5, rect.center.dy - 8));
    }
  }

  @override
  bool shouldRepaint(covariant RegionMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
