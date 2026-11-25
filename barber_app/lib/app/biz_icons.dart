import 'package:flutter/material.dart';

IconData bizGroupIcon(String key) {
  switch (key) {
    case 'beauty':
      return Icons.face_retouching_natural_rounded;
    case 'wellness':
      return Icons.spa_rounded;
    case 'auto':
      return Icons.directions_car_rounded;
    case 'pro':
      return Icons.business_center_rounded;
    case 'edu':
      return Icons.school_rounded;
    case 'pets':
      return Icons.pets_rounded;
  }
  return Icons.storefront_rounded;
}

IconData bizTypeIcon(String key) {
  switch (key) {
    case 'barber':
      return Icons.content_cut_rounded;
    case 'salon':
      return Icons.face_retouching_natural_rounded;
    case 'hair_color':
      return Icons.palette_rounded;
    case 'nails':
      return Icons.back_hand_rounded;
    case 'lash_brow':
      return Icons.visibility_rounded;
    case 'makeup':
      return Icons.brush_rounded;
    case 'skin':
      return Icons.spa_rounded;
    case 'massage':
      return Icons.self_improvement_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'relax':
      return Icons.hot_tub_rounded;
    case 'yoga':
      return Icons.self_improvement_rounded;
    case 'meditation':
      return Icons.psychology_rounded;
    case 'fitness_pt':
      return Icons.fitness_center_rounded;
    case 'carwash':
      return Icons.local_car_wash_rounded;
    case 'detailing':
      return Icons.auto_awesome_rounded;
    case 'oil_change':
      return Icons.oil_barrel_rounded;
    case 'garage':
      return Icons.car_repair_rounded;
    case 'body_paint':
      return Icons.format_paint_rounded;
    case 'car_inspect':
      return Icons.fact_check_rounded;
    case 'photo_studio':
      return Icons.photo_camera_rounded;
    case 'wedding_photo':
      return Icons.camera_alt_rounded;
    case 'biz_consult':
      return Icons.business_center_rounded;
    case 'lawyer':
      return Icons.gavel_rounded;
    case 'fin_consult':
      return Icons.account_balance_rounded;
    case 'translation':
      return Icons.translate_rounded;
    case 'gym':
      return Icons.fitness_center_rounded;
    case 'private_coach':
      return Icons.sports_rounded;
    case 'music_school':
      return Icons.music_note_rounded;
    case 'language_class':
      return Icons.language_rounded;
    case 'driving_class':
      return Icons.drive_eta_rounded;
    case 'private_class':
      return Icons.school_rounded;
    case 'pet_grooming':
      return Icons.pets_rounded;
    case 'vet':
      return Icons.medical_services_rounded;
    case 'pet_care':
      return Icons.favorite_rounded;
    case 'pet_training':
      return Icons.sports_rounded;
  }
  return Icons.storefront_rounded;
}
