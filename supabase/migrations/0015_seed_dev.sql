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

  -- 2. Annapurna Sanctuary & Base Camp Trek
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

  -- 3. Ghorepani Poon Hill Sunrise Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_annapurna, 'Ghorepani Poon Hill Sunrise Trek', 'ghorepani-poon-hill-trek',
    'A short, accessible Himalayan trek with panoramic golden sunrise views.',
    'Perfect for beginners and families. Climb the stone steps through ancient oak and rhododendron forests to Poon Hill (3,210m) for sunrise over Annapurna and Dhaulagiri ranges.',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?q=80&w=800',
    'Ghorepani / Kaski', 'Pokhara Hotel Departure', 28.4000, 83.7000, 96, 'moderate', 3210,
    1, 14, 6, 4500000, 3500000,
    array['All meals and lodge stays during trek', 'Guide and porter service', 'ACAP permit'],
    array['Warm jacket for early morning sunrise', 'Headlamp', 'Comfortable trail runners or boots'],
    array['Early morning start on Day 3 for sunrise', 'Stone staircases require decent knee stability'],
    array['ACAP Permit', 'TIMS Card'],
    4.7, 156, 'published'
  );

  -- 4. Langtang Valley & Kyanjin Ri Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_langtang, 'Langtang Valley & Kyanjin Ri Trek', 'langtang-valley-trek',
    'Explore the valley of glaciers closest to Kathmandu with rich Tamang heritage.',
    'Trek along the rushing Langtang River through pine forests to Kyanjin Gompa (3,870m) and climb Kyanjin Ri (4,773m) for views into Tibet.',
    'https://images.unsplash.com/photo-1575997759852-033cd52f8db6?q=80&w=800',
    'Syabrubesi / Rasuwa', 'Machhapokhari Bus Park, Kathmandu', 28.1600, 85.3300, 168, 'moderate', 4773,
    1, 10, 10, 7500000, 6000000,
    array['Kathmandu to Syabrubesi bus transport', 'Teahouse meals & stay', 'Guide & porter', 'National park fees'],
    array['Trekking boots', 'Fleece jacket', 'Sun hat and sunglasses'],
    array['Local yak cheese factory tasting included at Kyanjin Gompa'],
    array['Langtang National Park Permit', 'TIMS Card'],
    4.8, 72, 'published'
  );

  -- 5. Mardi Himal Ridge Trek
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_trekking, v_reg_annapurna, 'Mardi Himal High Camp & Ridge Trek', 'mardi-himal-trek',
    'Walk along a narrow mountain ridge right below Machhapuchhre (Fishtail).',
    'A pristine hidden gem trek leading up to Mardi Himal Base Camp (4,500m) with intimate close-up views of Fishtail Mountain.',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800',
    'Kande / Kaski', 'Pokhara Lakeside Center', 28.4200, 83.8500, 120, 'moderate', 4500,
    1, 10, 12, 6500000, 5000000,
    array['Transport to trail head', 'Lodge accommodations', 'Trekking guide'],
    array['Windproof jacket', 'Trekking poles', 'Water filter bottle'],
    array['Ridge path can be narrow and exposed near High Camp'],
    array['ACAP Permit', 'TIMS Card'],
    4.9, 88, 'published'
  );

  -- 6. Shivapuri Peak & Nagi Gompa Day Hike
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Shivapuri Peak & Nagi Gompa Day Hike', 'shivapuri-day-hike',
    'Escape Kathmandu to serene oak forests and Bagdwar, the origin of Bagmati River.',
    'A day trek inside Shivapuri Nagarjun National Park passing Nagi Gompa monastery to Shivapuri Peak (2,732m).',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=800',
    'Budhanilkantha / Kathmandu', 'Budhanilkantha Temple Gate', 27.8000, 85.3700, 8, 'moderate', 2732,
    1, 15, 8, 350000, 250000,
    array['National park entry ticket', 'Packed lunch', 'Local hiking guide'],
    array['Comfortable walking shoes', '1.5L drinking water', 'Rain jacket'],
    array['Monastery respects modest shoulder/knee clothing'],
    array['Shivapuri National Park Ticket'],
    4.6, 45, 'published'
  );

  -- 7. Nagarkot Sunrise & Changunarayan Heritage Hike
  insert into public.experiences (
    category_id, region_id, title, slug, summary, description, cover_image_url,
    location_name, meeting_point, lat, lng, duration_hours, difficulty, max_altitude_m,
    group_size_min, group_size_max, min_age, price_paisa, child_price_paisa,
    included, bring_list, things_to_know, permits_required, rating_avg, rating_count, status
  ) values (
    v_cat_hiking, v_reg_kathmandu, 'Nagarkot Sunrise & Changunarayan Trail', 'nagarkot-sunrise-hike',
    'Witness Himalayan sunrise panorama then walk downhill to Nepal oldest temple.',
    'Watch the sunrise over the eastern Himalayas from Nagarkot tower, followed by a downhill village walk to Changunarayan (UNESCO site).',
    'https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=800',
    'Nagarkot / Bhaktapur', 'Kathmandu Hotel Pick-up at 4:30 AM', 27.7170, 85.5200, 10, 'easy', 2175,
    1, 12, 6, 450000, 300000,
    array['Private hotel pick-up & drop', 'Breakfast in Nagarkot', 'Guide service', 'Changunarayan temple entrance fee'],
    array['Warm layer for early morning', 'Sun protection', 'Camera'],
    array['Clear morning visibility best in Oct-Nov and Mar-Apr'],
    array[]::text[],
    4.7, 62, 'published'
  );

  -- 8. Chitwan Jungle Safari & Tharu Cultural Experience
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

  -- 9. Pokhara Tandem Paragliding over Fewa Lake
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

  -- 10. Ghandruk Traditional Gurung Village & Homestay
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
end $$;
