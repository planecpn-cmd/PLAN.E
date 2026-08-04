-- Migration 0015: Dev Seed Data (~30 Real Nepal Experiences)
do $$
declare
  v_cat_trekking uuid;
  v_cat_hiking uuid;
  v_cat_camping uuid;
  v_cat_climbing uuid;
  v_cat_homestay uuid;
  v_cat_culture uuid;
  v_cat_wildlife uuid;
  v_cat_wellness uuid;
  
  v_reg_everest uuid;
  v_reg_annapurna uuid;
  v_reg_langtang uuid;
  v_reg_mustang uuid;
  v_reg_chitwan uuid;
  v_reg_pokhara uuid;
  v_reg_kathmandu uuid;
  v_reg_rara uuid;
  v_reg_manaslu uuid;
begin
  select id into v_cat_trekking from public.categories where slug = 'trekking';
  select id into v_cat_hiking from public.categories where slug = 'hiking';
  select id into v_cat_camping from public.categories where slug = 'camping';
  select id into v_cat_climbing from public.categories where slug = 'climbing';
  select id into v_cat_homestay from public.categories where slug = 'homestay';
  select id into v_cat_culture from public.categories where slug = 'culture';
  select id into v_cat_wildlife from public.categories where slug = 'wildlife';
  select id into v_cat_wellness from public.categories where slug = 'wellness';

  select id into v_reg_everest from public.regions where slug = 'everest';
  select id into v_reg_annapurna from public.regions where slug = 'annapurna';
  select id into v_reg_langtang from public.regions where slug = 'langtang';
  select id into v_reg_mustang from public.regions where slug = 'mustang';
  select id into v_reg_chitwan from public.regions where slug = 'chitwan';
  select id into v_reg_pokhara from public.regions where slug = 'pokhara';
  select id into v_reg_kathmandu from public.regions where slug = 'kathmandu';
  select id into v_reg_rara from public.regions where slug = 'rara';
  select id into v_reg_manaslu from public.regions where slug = 'manaslu';

  -- Clear existing dev experiences for clean seed re-run
  truncate public.experiences cascade;

  -- 1. Everest Base Camp Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_everest, 'Everest Base Camp Trek', 'everest-base-camp-trek',
    'Journey to the foot of Earth highest peak through legendary Sherpa villages.',
    'Experience the iconic trek to Everest Base Camp (5,364m) and Kala Patthar (5,545m). Walk amidst towering Himalayan giants, cross suspension bridges adorned with prayer flags, and experience authentic Sherpa hospitality in Namche Bazaar.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000',
    'Lukla / Solukhumbu', 'Lukla Airport', 27.6870, 86.7314, 288, 'strenuous', 5545,
    1, 10, 12, 18500000, 15000000,
    array['Domestic flights (Kathmandu-Lukla return)', 'All lodge accommodations', 'Licensed English speaking guide & porter', 'TIMS card & Sagarmatha National Park permits'],
    array['Warm down jacket (-15C rating)', 'Broken-in trekking boots', 'Thermal layers & woollen socks', 'Trekking poles & headlamp'],
    array['High altitude sickness risks apply above 3000m', 'Travel insurance with helicopter evacuation required'],
    array['Sagarmatha National Park Entry Permit', 'Pasang Lhamu Rural Municipality Permit'],
    4.9, 124, 'published'
  );

  -- 2. Annapurna Base Camp Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_annapurna, 'Annapurna Base Camp Trek', 'annapurna-base-camp-trek',
    'Walk inside a 360-degree natural amphitheatre of 7,000m and 8,000m peaks.',
    'Trek through lush rhododendron forests, Gurung farming terraces, and hot springs at Jhinu Danda before entering the spectacular Annapurna Sanctuary at 4,130m.',
    'https://images.unsplash.com/photo-1585016495481-91613a3ab1bc?q=80&w=1000',
    'Nayapul / Kaski', 'Pokhara Lakeside Hotel Pick-up', 28.5300, 83.8780, 240, 'challenging', 4130,
    1, 12, 10, 12500000, 9500000,
    array['Pokhara to Nayapul transport', 'Teahouse accommodation', 'Experienced mountain guide', 'ACAP & TIMS permits'],
    array['Waterproof jacket & trousers', 'Sturdy hiking shoes', 'Personal first aid kit'],
    array['Hot springs entrance fee included', 'Water purification tablets essential'],
    array['ACAP Permit', 'TIMS Card'],
    4.8, 98, 'published'
  );

  -- 3. Langtang Valley Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_langtang, 'Langtang Valley & Kyanjin Gompa Trek', 'langtang-valley-trek',
    'Explore the valley of glaciers close to Kathmandu with Tamang culture.',
    'Discover the rebuild beauty of Langtang Valley, visit Kyanjin Gompa cheese factory, climb Kyanjin Ri (4,773m), and experience warm Tamang hospitality.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1000',
    'Syabrubesi / Rasuwa', 'Machhapokhari Bus Station, Kathmandu', 28.1600, 85.3400, 168, 'moderate', 4773,
    1, 10, 10, 8500000, 6500000,
    array['Kathmandu-Syabrubesi drive', 'Lodge accommodations & meals', 'Local Tamang guide', 'Langtang National Park Permit'],
    array['Trekking boots', 'Warm fleece & hat', 'Water bottle'],
    array['Accessible within 7 hours drive from Kathmandu'],
    array['Langtang National Park Permit', 'TIMS Card'],
    4.7, 76, 'published'
  );

  -- 4. Upper Mustang Forbidden Kingdom Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_culture, v_reg_mustang, 'Upper Mustang Forbidden Kingdom Trek', 'upper-mustang-trek',
    'Step back in time inside the ancient walled city of Lo Manthang.',
    'Explore desert canyon landscapes, sky caves, ancient Tibetan Buddhist monasteries, and the medieval palace of Lo Manthang in restricted Upper Mustang.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Jomsom / Mustang', 'Jomsom Airport', 29.1800, 83.9700, 288, 'moderate', 3840,
    2, 10, 14, 24000000, 20000000,
    array['Restricted area special permit ($500 value)', 'Pokhara-Jomsom return flights', 'Local Mustang guide', 'Teahouse stay & meals'],
    array['Windproof jacket & sunglasses', 'Dust mask/buff', 'Sunscreen SPF 50'],
    array['Minimum 2 trekkers required for restricted area permit'],
    array['RAP Upper Mustang Permit', 'ACAP Permit'],
    4.9, 54, 'published'
  );

  -- 5. Panauti Community Homestay
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_homestay, v_reg_kathmandu, 'Panauti Community Organic Homestay', 'panauti-community-homestay',
    'Live with local Newari host families in historic Panauti town.',
    'Join local women host families, participate in traditional cooking classes, bike through organic farms, and visit ancient Indreshwar Mahadev Temple.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Panauti / Kavre', 'Panauti Bus Park', 27.5800, 85.5100, 24, 'easy', 1400,
    1, 6, 4, 350000, 250000,
    array['Private homestay room', 'Traditional Newari home-cooked dinner & breakfast', 'Guided heritage town walk', 'Cooking lesson'],
    array['Modest comfortable clothing', 'Personal toiletries'],
    array['Directly empowers local women-led household cooperatives'],
    array[]::text[],
    4.9, 142, 'published'
  );

  -- 6. Nagarkot Sunrise & Changunarayan Hike
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Nagarkot Himalayan Sunrise & Changunarayan Day Hike', 'nagarkot-sunrise-hike',
    'Watch panoramic Himalayan sunrise then hike to UNESCO Changunarayan Temple.',
    'Early morning drive to Nagarkot viewpoint for sunrise over Everest range, followed by a gentle 4-hour ridge hike through pine pine forests to Nepal oldest temple.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Nagarkot / Bhaktapur', 'Kathmandu Hotel Pick-up (4:30 AM)', 27.7100, 85.5200, 10, 'easy', 2175,
    1, 8, 6, 450000, 350000,
    array['Private hotel pick-up & drop-off', 'Breakfast at Nagarkot resort', 'Experienced hiking guide', 'Changunarayan Temple entry ticket'],
    array['Warm morning jacket', 'Light walking shoes', 'Camera'],
    array['Clear mountain views best between October and April'],
    array[]::text[],
    4.7, 165, 'published'
  );

  -- 7. Island Peak Climbing Expedition
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_climbing, v_reg_everest, 'Island Peak (Imja Tse) 6,189m Mountaineering Expedition', 'island-peak-climbing',
    'Summit your first 6,000m Himalayan peak with technical ice climbing training.',
    'Combine Everest Base Camp trekking with technical climbing on Island Peak (6,189m). Includes pre-climb instruction on crampon technique, jumar, and fixed rope climbing.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000',
    'Chhukung / Solukhumbu', 'Lukla Airport', 27.9100, 86.9300, 360, 'strenuous', 6189,
    1, 8, 18, 28000000, 28000000,
    array['Climbing guide & high altitude Sherpa support', 'NMA climbing permit & garbage deposit', 'Climbing gear (crampons, harness, ice axe, helmet)', 'High altitude camping tents & meals'],
    array['Mountaineering double boots', 'Down suit or heavy thermal layers', 'Gore-Tex outer shell'],
    array['Previous trekking experience mandatory'],
    array['NMA Island Peak Permit', 'Sagarmatha National Park Permit'],
    4.9, 42, 'published'
  );

  -- 8. Chitwan Wildlife Safari & Tharu Culture
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_wildlife, v_reg_chitwan, 'Chitwan Wildlife Safari & Tharu Culture', 'chitwan-jungle-safari',
    'Jeep safari to spot one-horned rhinos, Royal Bengal tigers and gharial crocodiles.',
    'Immerse in Chitwan National Park with a jeep safari, canoe ride on Rapti river, elephant breeding center visit, and evening Tharu stick dance.',
    'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?q=80&w=800',
    'Sauraha / Chitwan', 'Sauraha Bus Park', 27.5800, 84.4900, 72, 'easy', 415,
    1, 8, 4, 1650000, 1200000,
    array['Resort accommodation with all meals', 'National park permit & naturalist guide', 'Jeep safari & canoe ride', 'Tharu cultural show ticket'],
    array['Neutral colored cotton clothing (khaki/green)', 'Binoculars', 'Insect repellent & hat'],
    array['Bright clothing (red/yellow) discouraged during safari'],
    array['Chitwan National Park Entry Fee'],
    4.8, 110, 'published'
  );

  -- 9. Pokhara Tandem Paragliding
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_pokhara, 'Pokhara Tandem Paragliding over Fewa Lake', 'pokhara-paragliding',
    'Soar like a hawk over Pokhara valley with reflection of Annapurna on Lake Fewa.',
    'Take off from Sarangkot (1,592m) with an experienced pilot and glide over the turquoise waters of Fewa Lake with Annapurna in the backdrop.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Sarangkot / Pokhara', 'Lakeside Paragliding Office', 28.2400, 83.9500, 3, 'easy', 1592,
    1, 4, 10, 1150000, 1150000,
    array['Transport to Sarangkot launch pad', 'Full flight gear & tandem pilot', 'GoPro HD photos & video download', 'Insurance coverage during flight'],
    array['Closed toe sports shoes mandatory', 'Sunglasses & windproof jacket'],
    array['Maximum passenger weight limit: 100 kg', 'Weather dependent activity'],
    array[]::text[],
    4.9, 215, 'published'
  );

  -- 10. Ghandruk Heritage Village & Homestay
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_homestay, v_reg_annapurna, 'Ghandruk Heritage Village & Homestay', 'ghandruk-homestay-experience',
    'Experience authentic Gurung hospitality, traditional attire and Annapurna vistas.',
    'Stay in a stone-roofed Gurung home in Ghandruk village (1,940m). Learn traditional cooking, wear cultural dress, and view Annapurna South up close.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Ghandruk / Kaski', 'Pokhara Lakeside Pick-up', 28.3700, 83.8000, 48, 'easy', 1940,
    1, 8, 5, 550000, 400000,
    array['Homestay room & home-cooked meals', 'Gurung cultural museum entry', 'Local host guide'],
    array['Personal toiletries & towel', 'Fleece pullover'],
    array['Homestays offer warm solar showers and organic home food'],
    array['ACAP Permit'],
    4.9, 84, 'published'
  );

  -- 11. Rara Lake Wilderness Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_rara, 'Rara Lake Queen of Lakes Wilderness Trek', 'rara-lake-wilderness-trek',
    'Discover Nepal largest, crystal-clear high-altitude alpine lake in remote Mugu.',
    'Trek through pine and juniper forests of Rara National Park to witness the mesmerizing color-changing waters of Rara Lake (2,990m) surrounded by snow-capped peaks.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Mugu / Karnali', 'Nepalgunj Airport', 29.5300, 82.0800, 192, 'moderate', 2990,
    1, 8, 10, 16000000, 13000000,
    array['Nepalgunj-Talcha flight tickets', 'Lodge stay & organic meals', 'Local Karnali guide', 'Rara National Park Permit'],
    array['Warm clothing', 'Windproof trousers', 'Sturdy boots'],
    array['Untouched pristine nature with very few tourists'],
    array['Rara National Park Permit'],
    4.8, 38, 'published'
  );

  -- 12. Manaslu Circuit Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_manaslu, 'Manaslu Circuit & Larkya La Pass Trek', 'manaslu-circuit-trek',
    'Circle Mount Manaslu (8,163m) across the high Larkya La Pass (5,106m).',
    'Experience an off-the-beaten-path teahouse trek circling the world 8th highest mountain through Tibetan-influenced Nyingma Buddhist villages.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Soti Khola / Gorkha', 'Kathmandu Bus Station', 28.5500, 84.6200, 312, 'strenuous', 5106,
    2, 10, 14, 17500000, 14500000,
    array['Kathmandu to Soti Khola jeep transport', 'Restricted area permit fees', 'Mountain guide & porter', 'Teahouse stays'],
    array['High altitude sleeping bag (-15C)', 'Microspikes for Larkya La pass', 'Warm gloves'],
    array['Restricted zone requires minimum 2 trekkers with a licensed guide'],
    array['Manaslu Restricted Area Permit', 'MCAP Permit', 'ACAP Permit'],
    4.9, 67, 'published'
  );

  -- 13. Mardi Himal Ridge Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_annapurna, 'Mardi Himal High Ridge Trek', 'mardi-himal-trek',
    'Trek along narrow forest ridges right up to the base of Machhapuchhre.',
    'A quick 5-day ridge trek offering front-row views of Fishtail Mountain (Machhapuchhre) and Mount Annapurna South with peaceful teahouses.',
    'https://images.unsplash.com/photo-1585016495481-91613a3ab1bc?q=80&w=800',
    'Kande / Kaski', 'Pokhara Hotel Pick-up', 28.4100, 83.8600, 120, 'moderate', 4500,
    1, 10, 8, 7500000, 5500000,
    array['Pokhara ground transport', 'Lodge accommodations', 'English speaking guide', 'ACAP permit'],
    array['Light down jacket', 'Hiking boots', 'Headlamp'],
    array['Ideal short trek suitable for intermediate walkers'],
    array['ACAP Permit', 'TIMS Card'],
    4.8, 112, 'published'
  );

  -- 14. Shivapuri Peak Day Hike
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Shivapuri Peak & Nagi Gompa Nature Hike', 'shivapuri-peak-hike',
    'Hike through protected forest to Nagi Gompa nunnery and Shivapuri summit.',
    'Escape Kathmandu city into Shivapuri Nagarjun National Park. Visit Nagi Gompa nunnery, drink from Bagdwar spring, and summit Shivapuri Peak (2,732m).',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Budhanilkantha / Kathmandu', 'Budhanilkantha Temple Entrance', 27.8000, 85.3800, 7, 'easy', 2732,
    1, 10, 6, 250000, 150000,
    array['National park entry fee', 'Experienced nature guide', 'Packed picnic lunch'],
    array['2L drinking water', 'Daypack', 'Sports shoes'],
    array['National park checkpoint requires photo ID'],
    array['Shivapuri National Park Entry Ticket'],
    4.6, 75, 'published'
  );

  -- 15. Bandipur Hilltop Newari Village Walk
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_culture, v_reg_annapurna, 'Bandipur Living Museum Newari Cultural Experience', 'bandipur-cultural-walk',
    'Discover 18th-century architecture and pedestrian-only streets atop Bandipur ridge.',
    'Walk through Bandipur preserved main bazaar, visit Siddha Cave (Nepal largest cave), hike to Thani Mai hilltop for sunset over Manaslu.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Bandipur / Tanahun', 'Bandipur Main Bazaar Gate', 27.9300, 84.4100, 36, 'easy', 1030,
    1, 6, 4, 450000, 300000,
    array['Heritage inn accommodation', 'Guided town walk', 'Traditional meals'],
    array['Comfortable walking sandals or shoes'],
    array['Vehicles are not allowed inside main village bazaar area'],
    array[]::text[],
    4.7, 88, 'published'
  );

  -- 16. Australian Camp & Dhampus Panorama Camping
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_camping, v_reg_pokhara, 'Australian Camp & Dhampus Himalayan Camping', 'australian-camp-overnight',
    'Overnight mountain camping with campfire views of Annapurna & Dhaulagiri.',
    'Short 2-hour hike from Kande to Australian Camp (2,060m). Sleep in comfortable ridge tents with clear views of Machhapuchhre.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Kande / Kaski', 'Pokhara Lakeside Pick-up', 28.3000, 83.8300, 24, 'easy', 2060,
    1, 8, 4, 480000, 350000,
    array['Pokhara round-trip transport', 'Dome tent, sleeping bag & mattress setup', 'Campfire & BBQ dinner', 'Guide fee'],
    array['Warm jumper', 'Headlamp', 'Powerbank'],
    array['Suitable for families and beginner campers'],
    array['ACAP Permit'],
    4.8, 93, 'published'
  );

  -- 17. Everest View Helicopter Tour
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_wellness, v_reg_everest, 'Everest Base Camp Helicopter Tour with Champagne Breakfast', 'everest-heli-tour',
    'Fly over Lukla, land at Kala Patthar and enjoy breakfast at Everest View Hotel.',
    'Experience Everest in a single morning! Fly by Airbus helicopter from Kathmandu, land at Kala Patthar (5,400m) for photos, then enjoy breakfast at Everest View Hotel in Syangboche.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000',
    'Syangboche / Solukhumbu', 'Tribhuvan International Airport Domestic Terminal', 27.8000, 86.7100, 4, 'easy', 5400,
    1, 5, 5, 145000000, 145000000,
    array['Shared helicopter charter seat', 'Breakfast at Hotel Everest View', 'Oxygen cylinder support on board', 'Airport transfers'],
    array['Sunglasses mandatory', 'Warm jacket & gloves', 'Passport/ID'],
    array['Ground time at Kala Patthar limited to 10-15 minutes to prevent altitude illness'],
    array['Sagarmatha National Park Fee'],
    5.0, 31, 'published'
  );

  -- 18. Bhaktapur Pottery & Woodcarving Heritage Tour
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_culture, v_reg_kathmandu, 'Bhaktapur Living Heritage & Pottery Workshop', 'bhaktapur-pottery-workshop',
    'Hands-on pottery making on traditional wheels in ancient Bhaktapur Durbar Square.',
    'Explore 55-Window Palace, Nyatapola Temple, and pottery square. Learn clay spinning from master artisans and taste famous Juju Dhau (King Curd).',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Bhaktapur', 'Bhaktapur Durbar Square Main Entrance', 27.6720, 85.4280, 5, 'easy', 1400,
    1, 8, 4, 280000, 180000,
    array['Bhaktapur heritage ticket', 'Pottery lesson & souvenir clay pot to take home', 'Juju Dhau tasting', 'Local historian guide'],
    array['Clothes that can get slightly dusty with clay'],
    array['UNESCO World Heritage preserved medieval city'],
    array[]::text[],
    4.9, 130, 'published'
  );

  -- 19. Bardia National Park Tiger Tracking
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_wildlife, v_reg_chitwan, 'Bardia National Park Wild Tiger Tracking Expedition', 'bardia-tiger-tracking',
    'Track wild Bengal tigers on foot with expert jungle naturalists in Bardia.',
    'Venture into Nepal largest undisturbed wilderness. Walk riverbanks of Karnali river, wait at tiger watch towers, and spot wild elephants and rhinos.',
    'https://images.unsplash.com/photo-1534177616072-ef7dc120449d?q=80&w=800',
    'Thakurdwara / Bardia', 'Nepalgunj Airport Pick-up', 28.4600, 81.3300, 96, 'moderate', 260,
    1, 6, 10, 2200000, 1800000,
    array['Jungle lodge stay & all meals', 'Experienced tiger tracking naturalist guide', 'Full day jungle walking safari', 'Park entry permits'],
    array['Earth tone clothing', 'Binoculars', 'Sturdy walking boots'],
    array['High tiger sighting success rate in dry season (March-May)'],
    array['Bardia National Park Permit'],
    4.9, 45, 'published'
  );

  -- 20. Phulchowki Mountain Bike Descent
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Phulchowki 2,760m Mountain Bike Singletrack Descent', 'phulchowki-mountain-biking',
    'Adrenaline-filled singletrack downhill mountain biking from highest valley peak.',
    'Vehicle shuttle to Phulchowki peak (2,760m) followed by 20km downhill singletrack through oak forest into Godavari botanical gardens.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Godavari / Lalitpur', 'Thamel Bike Shop', 27.5800, 85.4000, 6, 'challenging', 2760,
    1, 6, 14, 650000, 650000,
    array['Full suspension MTB bike rental', 'Helmet & protective pads', 'Vehicle shuttle to summit', 'MTB guide & trail fee'],
    array['Riding gloves', 'Sports shoes', 'Hydration pack'],
    array['Prior off-road mountain biking experience required'],
    array[]::text[],
    4.8, 59, 'published'
  );

  -- 21. Dhulikhel Namobuddha Monastery Hike
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Dhulikhel to Namobuddha Sacred Stupa Hike', 'dhulikhel-namobuddha-hike',
    'Walk through Tamang farms to sacred Namobuddha Stupa where Buddha fed the tigress.',
    'Scenic ridge walk from old town Dhulikhel to Thrangu Tashi Yangtse Monastery at Namobuddha. Enjoy vegetarian lunch with monks.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Dhulikhel / Kavre', 'Kathmandu Hotel Pick-up', 27.6000, 85.5500, 8, 'easy', 1750,
    1, 8, 5, 380000, 280000,
    array['Private transport', 'Guide services', 'Monastery vegetarian lunch', 'Monastery entry donation'],
    array['Walking shoes', 'Modest clothing for monastery'],
    array['One of Nepal top three sacred Tibetan Buddhist pilgrimage sites'],
    array[]::text[],
    4.8, 91, 'published'
  );

  -- 22. Mera Peak 6,476m Expedition
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_climbing, v_reg_everest, 'Mera Peak 6,476m Highest Trekking Peak Expedition', 'mera-peak-climbing',
    'Climb Nepal highest official trekking peak with five 8,000m summits visible.',
    'Ascend Mera Peak (6,476m) via Hinku valley. Broad glacier summit offering unbroken panorama of Everest, Lhotse, Cho Oyu, Makalu, and Kanchenjunga.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000',
    'Hinku Valley / Solukhumbu', 'Lukla Airport', 27.7000, 86.8600, 400, 'strenuous', 6476,
    1, 6, 18, 31000000, 31000000,
    array['Climbing Sherpa guide', 'NMA Mera Peak permit', 'Full camping crew & mountaineering tents', 'Lukla return flight'],
    array['Plastic mountaineering boots', 'Crampons & ice axe', 'Extreme cold weather suit'],
    array['High physical fitness required for summit day above 6000m'],
    array['NMA Mera Peak Permit', 'Makalu Barun / Sagarmatha Permit'],
    4.9, 36, 'published'
  );

  -- 23. Pokhara Peace Stupa & Raniban Forest Walk
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_pokhara, 'World Peace Pagoda Boat & Forest Hike', 'pokhara-peace-stupa-hike',
    'Cross Lake Fewa by wooden boat and hike through Raniban forest to World Peace Stupa.',
    'Enjoy a wooden boat ride across Fewa Lake followed by a shaded 1.5-hour forest climb to Shanti Stupa. Panoramic views of Lake Fewa and Pokhara valley.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Lakeside / Pokhara', 'Fewa Lake Boat Station', 28.2000, 83.9400, 4, 'easy', 1100,
    1, 8, 4, 180000, 120000,
    array['Traditional wooden boat transfer', 'Local guide', 'Bottled water'],
    array['Sun hat', 'Comfortable footwear'],
    array['Silence requested at World Peace Stupa grounds'],
    array[]::text[],
    4.7, 180, 'published'
  );

  -- 24. Himalayan Sound Bath & Meditation Retreat
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_wellness, v_reg_pokhara, 'Himalayan Singing Bowl Sound Healing & Meditation', 'himalayan-sound-healing',
    'Rejuvenate body and mind with authentic handmade 7-metal Tibetan singing bowls.',
    'Experience deep relaxation session led by master sound healer. Includes chakra balancing, vibrational therapy, and herbal tea ceremony overlooking Pokhara lake.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Lakeside / Pokhara', 'Himalayan Healing Center', 28.2100, 83.9600, 2, 'easy', 850,
    1, 10, 10, 320000, 320000,
    array['90-minute sound healing session', 'Herbal tea', 'Mat & cushion setup'],
    array['Comfortable loose clothing'],
    array['No prior meditation experience required'],
    array[]::text[],
    4.9, 87, 'published'
  );

  -- 25. Bhotekoshi White Water Rafting
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_camping, v_reg_kathmandu, 'Bhotekoshi Class III-IV White Water Rafting Adventure', 'bhotekoshi-whitewater-rafting',
    'Navigate steep continuous rapids on Nepal wildest snow-fed mountain river.',
    'Full day whitewater action on the steep Bhotekoshi river. Paddle through Class III+ and IV rapids under the guidance of river safety kayakers.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Sukute / Sindhupalchok', 'Thamel Rafting Center Pick-up', 27.8200, 85.7500, 10, 'challenging', 850,
    2, 8, 14, 550000, 550000,
    array['Kathmandu round-trip transport', 'Self-bailing raft & safety gear', 'International safety certified river guide', 'Riverside lunch buffet'],
    array['Swimsuit or shorts', 'Strap sandals or neoprene booties', 'Sunscreen'],
    array['Must be able to swim in open water'],
    array[]::text[],
    4.8, 105, 'published'
  );

  -- 26. Lo Manthang Tiji Festival Experience
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_culture, v_reg_mustang, 'Lo Manthang Tiji Festival & Sacred Mask Dances', 'tiji-festival-mustang',
    'Witness the 3-day sacred Tibetan Buddhist ritual mask dance inside Lo Manthang.',
    'Annual spring festival celebrating victory of good over evil. Watch monks perform sacred Chham dances in ceremonial robes inside the royal palace courtyard of Lo Manthang.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Lo Manthang / Mustang', 'Jomsom Airport', 29.1820, 83.9570, 312, 'moderate', 3840,
    2, 8, 12, 29000000, 24000000,
    array['Tiji festival special entry access', 'Upper Mustang RAP permit', 'Jeep & flight transfers', 'Teahouse stay & guide'],
    array['Warm windproof clothing', 'Camera with zoom lens', 'Sun hat'],
    array['Occurs annually in May according to Tibetan lunar calendar'],
    array['RAP Upper Mustang Permit', 'ACAP Permit'],
    5.0, 28, 'published'
  );

  -- 27. Gokyo Lakes & Gokyo Ri Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_everest, 'Turquoise Gokyo Lakes & Gokyo Ri Summit Trek', 'gokyo-lakes-trek',
    'Trek past six turquoise glacier lakes and climb Gokyo Ri (5,357m).',
    'Alternative to traditional EBC trek. Walk beside Ngozumpa glacier (longest in Himalayas), marvel at 6 turquoise lakes, and view 4 eight-thousanders from Gokyo Ri.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=1000',
    'Gokyo / Solukhumbu', 'Lukla Airport', 27.9500, 86.6900, 264, 'strenuous', 5357,
    1, 10, 12, 17500000, 14000000,
    array['Lukla return flight', 'Lodge stay', 'Local guide & porter', 'Permits'],
    array['Thermal base layers', 'Windproof trousers', 'Trekking poles'],
    array['Stunning quiet alternative to main Everest Base Camp trail'],
    array['Sagarmatha Permit', 'Pasang Lhamu Permit'],
    4.9, 79, 'published'
  );

  -- 28. Kakani Trout Farming & Strawberry Country Day Out
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_homestay, v_reg_kathmandu, 'Kakani Hilltop Rainbow Trout & Organic Strawberry Tasting', 'kakani-trout-strawberry',
    'Relax at 2,000m hilltop overlooking Ganesh Himal with fresh rainbow trout feast.',
    'Scenic day drive to Kakani (2,070m). Visit strawberry farms, enjoy fresh Himalayan rainbow trout lunch, and honor mountaineers at Kakani International Memorial Park.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Kakani / Nuwakot', 'Kathmandu Pick-up', 27.8000, 85.2500, 7, 'easy', 2070,
    1, 8, 4, 320000, 220000,
    array['Private car round-trip transport', 'Fresh trout lunch meal', 'Guide'],
    array['Casual clothes', 'Camera'],
    array['Famous for fresh cold water rainbow trout and organic strawberry produce'],
    array[]::text[],
    4.7, 63, 'published'
  );

  -- 29. Helambu Circuit Cultural Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_langtang, 'Helambu Hyolmo Heritage Circuit Trek', 'helambu-circuit-trek',
    'Low-altitude trek through sweet apple orchards and Hyolmo Buddhist monasteries.',
    'Uncrowded short trek through sweet Helambu apple orchards, green hills, and quiet monasteries. Suitable for families looking for quiet mountain walks.',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=800',
    'Sundarijal / Sindhupalchok', 'Sundarijal Bus Park', 28.0300, 85.5500, 120, 'easy', 3650,
    1, 8, 6, 6800000, 4800000,
    array['Transport to Sundarijal', 'Teahouse stay & meals', 'Guide', 'Shivapuri park permit'],
    array['Walking shoes', 'Fleece jacket', 'Rainponcho'],
    array['Low altitude trek under 3,650m with minimal risk of altitude sickness'],
    array['Shivapuri Park Permit', 'TIMS Card'],
    4.7, 51, 'published'
  );

  -- 30. Tilicho Lake & Thorong La Pass Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_annapurna, 'Tilicho High Lake & Thorong La Pass Circuit', 'tilicho-lake-annapurna-circuit',
    'Visit world highest turquoise lake (4,919m) and cross Thorong La Pass (5,416m).',
    'Ultimate Annapurna circuit extension visiting turquoise Tilicho Lake (4,919m) followed by crossing Thorong La Pass (5,416m) into Muktinath temple sanctuary.',
    'https://images.unsplash.com/photo-1585016495481-91613a3ab1bc?q=80&w=1000',
    'Manang / Mustang', 'Besisahar Pick-up', 28.6900, 83.8500, 312, 'strenuous', 5416,
    1, 10, 12, 16500000, 13500000,
    array['Besisahar jeep transfer', 'All lodge stays & meals', 'Guide & porter', 'ACAP & TIMS permits'],
    array['Warm sleeping bag', 'Microspikes', 'Sunglasses'],
    array['Requires strong cardiovascular stamina for high pass crossing'],
    array['ACAP Permit', 'TIMS Card'],
    4.9, 115, 'published'
  );

end $$;
