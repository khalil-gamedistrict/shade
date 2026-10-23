// Game ke rang. Saare chapter Limbo jaise kaale-safed; aakhri chapter (ghar) subah ke rangeen jungle mein.
// Painter har frame level ke mahaul se [palette] chunta hai; figures/props/grass isi se rang lete hain.
import 'dart:ui';

class Palette {
  final bool colorful;
  final Color ink; // kirdar, neze, cheezen (saaye)
  final Color ground; // zameen ka bhara hissa
  final Color grass; // ghaas aur zameen ka kinara
  final Color skyTop, skyBottom;
  final Color haze; // door ki dhund
  final Color fog; // neeche se uthti dhund
  final Color vignette; // kinaron ka andhera
  final Color waterTop, waterDeep, waterShine;
  // Jungle: (tana, patte) har layer ke
  final Color farTrunk, farLeaf, midTrunk, midLeaf, nearTrunk, nearLeaf;
  final Color frontTrunk, frontLeaf, vine;
  final Color undergrowthFar, undergrowthMid, plants, frontPlants;

  const Palette({
    required this.colorful,
    required this.ink,
    required this.ground,
    required this.grass,
    required this.skyTop,
    required this.skyBottom,
    required this.haze,
    required this.fog,
    required this.vignette,
    required this.waterTop,
    required this.waterDeep,
    required this.waterShine,
    required this.farTrunk,
    required this.farLeaf,
    required this.midTrunk,
    required this.midLeaf,
    required this.nearTrunk,
    required this.nearLeaf,
    required this.frontTrunk,
    required this.frontLeaf,
    required this.vine,
    required this.undergrowthFar,
    required this.undergrowthMid,
    required this.plants,
    required this.frontPlants,
  });

  /// Limbo jaisa: kaala, sleti, dhundla
  static const mono = Palette(
    colorful: false,
    ink: Color(0xFF070707),
    ground: Color(0xFF070707),
    grass: Color(0xFF070707),
    skyTop: Color(0xFFB8B8B8),
    skyBottom: Color(0xFF6E6E6E),
    haze: Color(0xFFD8DADB),
    fog: Color(0x55FFFFFF),
    vignette: Color(0xCC000000),
    waterTop: Color(0xE0404346),
    waterDeep: Color(0xF6141516),
    waterShine: Color(0x88C9CDD1),
    farTrunk: Color(0x28000000),
    farLeaf: Color(0x26000000),
    midTrunk: Color(0xFF5E6062),
    midLeaf: Color(0xFF656769),
    nearTrunk: Color(0xFF131313),
    nearLeaf: Color(0xFF0E0E0E),
    frontTrunk: Color(0xFF030303),
    frontLeaf: Color(0xF5050505),
    vine: Color(0xE8101010),
    undergrowthFar: Color(0xFF7A7C7D),
    undergrowthMid: Color(0xFF4C4E4F),
    plants: Color(0xFF2A2A2A),
    frontPlants: Color(0xFF040404),
  );

  /// Subah ka hara jungle: sunehri dhoop, neela aasmaan, hare patte, bhoori mitti, saaf paani.
  /// Kirdar gehre bhoore saaye rehte hain (chamakti aankhen) — rangeen duniya mein saaf dikhte hain.
  static const dawn = Palette(
    colorful: true,
    ink: Color(0xFF1E150D),
    ground: Color(0xFF3A2914),
    grass: Color(0xFF3F8A2A),
    skyTop: Color(0xFF6FB9EA),
    skyBottom: Color(0xFFFFE2A0),
    haze: Color(0xFFFFF1CC),
    fog: Color(0x33FFF3D2),
    vignette: Color(0x55241A08),
    waterTop: Color(0xD84AA5C8),
    waterDeep: Color(0xF0164A66),
    waterShine: Color(0xCCE9FAFF),
    farTrunk: Color(0x554F7F86),
    farLeaf: Color(0x5562A08A),
    midTrunk: Color(0xFF5B5636),
    midLeaf: Color(0xFF5E9E44),
    nearTrunk: Color(0xFF3B2A17),
    nearLeaf: Color(0xFF2F7424),
    frontTrunk: Color(0xFF22180D),
    frontLeaf: Color(0xF2224F17),
    vine: Color(0xE82E6A1E),
    undergrowthFar: Color(0xFF8CBF72),
    undergrowthMid: Color(0xFF4E9440),
    plants: Color(0xFF2F6E25),
    frontPlants: Color(0xFF17380F),
  );
}

/// Abhi ka rang (painter har frame level ke hisaab se set karta hai)
Palette palette = Palette.mono;
