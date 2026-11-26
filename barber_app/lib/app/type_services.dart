import 'service_catalog.dart';

/// هر نوع کسب‌وکار فقط خدمات خودش را در فهرست «دنبال چه خدمتی هستی؟» می‌بیند
const Map<String, List<String>> kTypeServices = {
  // آرایش و زیبایی
  'barber': [
    'full_cut', 'haircut', 'beard', 'face_groom', 'eyebrow', 'hair_color',
    'keratin', 'hair_mask', 'skin_clean',
  ],
  'salon': [
    'full_cut', 'haircut', 'blowdry', 'highlights', 'keratin', 'hair_color',
    'hair_mask', 'eyebrow', 'waxing', 'manicure', 'nail_art', 'makeup',
    'lash_ext', 'skin_clean',
  ],
  'hair_color': [
    'hair_color', 'highlights', 'keratin', 'hair_mask', 'blowdry', 'haircut',
  ],
  'nails': ['manicure', 'nail_art'],
  'lash_brow': ['lash_ext', 'eyebrow'],
  'makeup': ['makeup', 'eyebrow', 'lash_ext'],
  'skin': ['skin_clean', 'waxing'],
  // سلامت و آرامش
  'massage': ['massage_body', 'massage_foot', 'massage_sport'],
  'spa': [
    'spa_package', 'sauna_jacuzzi', 'massage_body', 'massage_foot',
    'relax_session',
  ],
  'relax': [
    'relax_session', 'massage_body', 'massage_foot', 'sauna_jacuzzi',
  ],
  'yoga': ['yoga_class'],
  'meditation': ['meditation_session'],
  'fitness_pt': ['pt_session'],
  // خودرو
  'carwash': ['wash_out', 'wash_full', 'interior_detail', 'wax_polish'],
  'detailing': ['wax_polish', 'ceramic_coat', 'interior_detail', 'wash_full'],
  'oil_change': ['oil_change', 'car_service'],
  'garage': ['car_service', 'oil_change', 'tire_balance', 'car_inspection'],
  'body_paint': ['body_paint_job', 'wax_polish'],
  'car_inspect': ['car_inspection'],
  // حرفه‌ای
  'photo_studio': ['photo_shoot'],
  'wedding_photo': ['wedding_shoot', 'photo_shoot'],
  'biz_consult': ['biz_consulting'],
  'lawyer': ['legal_consulting'],
  'fin_consult': ['finance_consulting'],
  'translation': ['translation_service'],
  // آموزش و ورزش
  'gym': ['gym_session', 'coach_session'],
  'private_coach': ['coach_session'],
  'music_school': ['music_lesson'],
  'language_class': ['language_lesson'],
  'driving_class': ['driving_lesson'],
  'private_class': ['private_lesson'],
  // حیوانات
  'pet_grooming': ['pet_grooming_s', 'pet_clean_trim'],
  'vet': ['pet_visit', 'pet_vaccine'],
  'pet_care': ['pet_boarding', 'pet_clean_trim'],
  'pet_training': ['pet_training_s'],
};

/// اگر نوع انتخاب شده باشد فقط خدمات همان نوع؛ وگرنه کل گروه
List<CatalogItem> catalogForType(String group, String type, String gender) {
  final base = catalogForGroup(group, gender);
  if (type.isEmpty) return base;
  final keys = kTypeServices[type];
  if (keys == null) return base;
  final out = base.where((c) => keys.contains(c.key)).toList();
  return out.isEmpty ? base : out;
}
