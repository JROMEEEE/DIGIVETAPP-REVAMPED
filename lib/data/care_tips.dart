import 'package:flutter/material.dart';

/// General pet-care advice, the same wording as the web owner portal's
/// Pet Care page. Static text: nothing here comes from the server.
class CareTip {
  const CareTip(this.icon, this.title, this.summary, this.detail);
  final IconData icon;
  final String title;
  final String summary;
  final String detail;
}

const careTips = [
  CareTip(
    Icons.restaurant_outlined,
    'Nutrition',
    'Feed age-appropriate portions on a consistent schedule.',
    'Puppies and kittens need 3–4 small meals a day; adults do well on 2. Always keep fresh water available and avoid feeding table scraps, chocolate, onions, or grapes.',
  ),
  CareTip(
    Icons.directions_walk_outlined,
    'Exercise',
    'Daily walks or playtime keep pets healthy and calm.',
    'Dogs generally need 30–60 minutes of activity a day; cats do well with short bursts of interactive play. Regular exercise prevents obesity and reduces destructive behavior.',
  ),
  CareTip(
    Icons.content_cut_outlined,
    'Grooming',
    'Regular brushing and bathing prevents skin issues.',
    'Brush short-haired pets weekly and long-haired pets every 1–2 days to prevent matting. Trim nails monthly and check ears for odor or discharge.',
  ),
  CareTip(
    Icons.medical_services_outlined,
    'Checkups',
    'Annual vet visits catch problems early.',
    'Bring your pet in for a wellness exam once a year (twice a year for seniors). Keep vaccinations and deworming on schedule even between checkups.',
  ),
  CareTip(
    Icons.vaccines_outlined,
    'Vaccination Schedule',
    'Boosters keep protection active — don’t let it lapse.',
    'Most vaccines need a booster within 12 months. If a due date passes, protection can weaken — schedule a follow-up dose as soon as possible rather than restarting the full series.',
  ),
  CareTip(
    Icons.monitor_heart_outlined,
    'Warning Signs',
    'Know when a vet visit shouldn’t wait.',
    'Loss of appetite for more than a day, vomiting, lethargy, limping, or unusual swelling are reasons to see a vet promptly rather than waiting for the next scheduled checkup.',
  ),
];
