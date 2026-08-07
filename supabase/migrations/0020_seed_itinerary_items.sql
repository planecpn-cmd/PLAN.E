-- Migration 0020: Real itinerary content for the seeded experience catalog.
--
-- `itinerary_items` was created in 0009 but never populated, so the experience
-- detail screen (lib/features/experience/experience_detail_repository.dart)
-- rendered an empty day-by-day plan for every experience.
--
-- Multi-day trips get one row per day with no start_time. Day trips get
-- time-stamped rows on day 1. Idempotent: skips any experience that already
-- has itinerary rows.

insert into public.itinerary_items (
  experience_id,
  day_number,
  start_time,
  title,
  description,
  sort_order
)
select
  e.id,
  v.day_number,
  v.start_time,
  v.title,
  v.description,
  v.sort_order
from public.experiences e
join (
  values
    -- ===== Everest Base Camp Trek (12 days) =====
    ('everest-base-camp-trek', 1, null::time, 'Fly Kathmandu to Lukla, trek to Phakding', 'Early mountain flight to Tenzing-Hillary Airport (2,860m). Meet the porter crew and drop 200m along the Dudh Koshi to Phakding (2,610m).', 1),
    ('everest-base-camp-trek', 2, null::time, 'Phakding to Namche Bazaar', 'Cross five suspension bridges including the high Hillary Bridge, enter Sagarmatha National Park at Monjo, then climb steeply to Namche (3,440m).', 1),
    ('everest-base-camp-trek', 3, null::time, 'Namche acclimatisation day', 'Hike to the Everest View Hotel (3,880m) for the first Everest panorama, then visit Khumjung village and the Sherpa Culture Museum. Sleep low at Namche.', 1),
    ('everest-base-camp-trek', 4, null::time, 'Namche to Tengboche', 'Contour the Dudh Koshi gorge to Phunki Thanga, then climb to Tengboche Monastery (3,860m) in time for the late-afternoon prayer ceremony.', 1),
    ('everest-base-camp-trek', 5, null::time, 'Tengboche to Dingboche', 'Through rhododendron forest to Pangboche, past the old gompa, then above the treeline into the Imja Valley at Dingboche (4,410m).', 1),
    ('everest-base-camp-trek', 6, null::time, 'Dingboche acclimatisation day', 'Ascend Nangkartshang Peak (5,083m) for views of Makalu, Lhotse and Ama Dablam, then descend to sleep at Dingboche.', 1),
    ('everest-base-camp-trek', 7, null::time, 'Dingboche to Lobuche', 'Climb to Thukla Pass and the Everest memorial chortens, then follow the Khumbu Glacier moraine to Lobuche (4,940m).', 1),
    ('everest-base-camp-trek', 8, null::time, 'Lobuche to Everest Base Camp, sleep Gorak Shep', 'Cross the glacier moraine to Gorak Shep (5,164m), then walk out to Everest Base Camp (5,364m) beneath the Khumbu Icefall.', 1),
    ('everest-base-camp-trek', 9, null::time, 'Kala Patthar sunrise, descend to Pheriche', 'Pre-dawn climb of Kala Patthar (5,545m) for the classic Everest summit view, then a long descent to Pheriche (4,371m).', 1),
    ('everest-base-camp-trek', 10, null::time, 'Pheriche to Namche Bazaar', 'Retrace the Imja Valley through Pangboche and Tengboche, dropping back into thicker air at Namche.', 1),
    ('everest-base-camp-trek', 11, null::time, 'Namche to Lukla', 'Final long descent along the Dudh Koshi to Lukla, with a celebration dinner with the Sherpa crew.', 1),
    ('everest-base-camp-trek', 12, null::time, 'Fly Lukla to Kathmandu', 'Morning flight back to Kathmandu before the valley winds build. Transfer to your hotel.', 1),

    -- ===== Annapurna Base Camp Trek (10 days) =====
    ('annapurna-base-camp-trek', 1, null::time, 'Drive Pokhara to Nayapul, trek to Ulleri', 'Road transfer to the trailhead at Nayapul, then the famous 3,300 stone steps up to Ulleri (2,070m).', 1),
    ('annapurna-base-camp-trek', 2, null::time, 'Ulleri to Ghorepani', 'Climb through moss-hung rhododendron forest via Banthanti and Nangethanti to the ridge village of Ghorepani (2,874m).', 1),
    ('annapurna-base-camp-trek', 3, null::time, 'Poon Hill sunrise, trek to Tadapani', 'Pre-dawn ascent of Poon Hill (3,210m) for Dhaulagiri and Annapurna South at first light, then traverse to Tadapani (2,630m).', 1),
    ('annapurna-base-camp-trek', 4, null::time, 'Tadapani to Chhomrong', 'Descend to Kimrong Khola and climb to Chhomrong (2,170m), the Gurung gateway village to the Annapurna Sanctuary.', 1),
    ('annapurna-base-camp-trek', 5, null::time, 'Chhomrong to Dovan', 'Drop to the Chhomrong Khola, climb to Sinuwa and enter the bamboo corridor of the sanctuary gorge to Dovan (2,600m).', 1),
    ('annapurna-base-camp-trek', 6, null::time, 'Dovan to Deurali', 'Past the Hinku Cave and Himalaya Hotel, the valley narrows and opens above the treeline at Deurali (3,230m).', 1),
    ('annapurna-base-camp-trek', 7, null::time, 'Deurali to Annapurna Base Camp', 'Enter the sanctuary via Machhapuchhre Base Camp (3,700m) and continue into the amphitheatre at Annapurna Base Camp (4,130m).', 1),
    ('annapurna-base-camp-trek', 8, null::time, 'ABC sunrise, descend to Bamboo', 'Watch the sun hit the Annapurna I face, then a long descent out of the sanctuary to Bamboo (2,310m).', 1),
    ('annapurna-base-camp-trek', 9, null::time, 'Bamboo to Jhinu Danda hot springs', 'Back over the Chhomrong stair to Jhinu Danda (1,780m) and a soak in the riverside natural hot springs.', 1),
    ('annapurna-base-camp-trek', 10, null::time, 'Jhinu Danda to Nayapul, drive Pokhara', 'Easy riverside walk to the road head at Nayapul and a short drive back to Pokhara lakeside.', 1),

    -- ===== Gokyo Lakes Trek (11 days) =====
    ('gokyo-lakes-trek', 1, null::time, 'Fly Kathmandu to Lukla, trek to Phakding', 'Mountain flight into Lukla (2,860m), then a gentle first walk down the Dudh Koshi valley to Phakding.', 1),
    ('gokyo-lakes-trek', 2, null::time, 'Phakding to Namche Bazaar', 'Park entry at Monjo, the high Hillary Bridge crossing, then the long climb to Namche Bazaar (3,440m).', 1),
    ('gokyo-lakes-trek', 3, null::time, 'Namche acclimatisation day', 'Acclimatisation hike to Khunde and Khumjung, visiting the Hillary school and monastery, then back down to Namche to sleep.', 1),
    ('gokyo-lakes-trek', 4, null::time, 'Namche to Dole', 'Leave the Base Camp trail at Sanasa and climb the quieter Gokyo branch via Mong La (3,975m) to Dole (4,040m).', 1),
    ('gokyo-lakes-trek', 5, null::time, 'Dole to Machhermo', 'Short acclimatisation stage along the Dudh Koshi headwaters beneath Kangtega and Thamserku to Machhermo (4,470m).', 1),
    ('gokyo-lakes-trek', 6, null::time, 'Machhermo to Gokyo', 'Pass the terminal moraine of the Ngozumpa Glacier and the first two lakes to reach Gokyo village on the third lake (4,790m).', 1),
    ('gokyo-lakes-trek', 7, null::time, 'Gokyo Ri summit and the fourth and fifth lakes', 'Dawn climb of Gokyo Ri (5,357m) for four 8,000m peaks in one panorama, then walk out to Thonak and Ngozumpa Tsho.', 1),
    ('gokyo-lakes-trek', 8, null::time, 'Gokyo to Dole', 'Retrace the moraine trail past the turquoise lakes and drop back below the treeline at Dole.', 1),
    ('gokyo-lakes-trek', 9, null::time, 'Dole to Namche Bazaar', 'Climb back over Mong La and rejoin the main Khumbu trail into Namche.', 1),
    ('gokyo-lakes-trek', 10, null::time, 'Namche to Lukla', 'Final descent along the Dudh Koshi with a farewell dinner with the crew in Lukla.', 1),
    ('gokyo-lakes-trek', 11, null::time, 'Fly Lukla to Kathmandu', 'Early morning flight back to Kathmandu ahead of the afternoon wind.', 1),

    -- ===== Manaslu Circuit Trek (13 days) =====
    ('manaslu-circuit-trek', 1, null::time, 'Drive Kathmandu to Machha Khola', 'Long road day via Dhading Besi and Arughat along the Budhi Gandaki to the trailhead at Machha Khola (930m).', 1),
    ('manaslu-circuit-trek', 2, null::time, 'Machha Khola to Jagat', 'Through the hot lower gorge past Khorlabesi hot springs and Tatopani, entering the restricted area at Jagat (1,340m).', 1),
    ('manaslu-circuit-trek', 3, null::time, 'Jagat to Deng', 'Permit check at Philim, then the valley narrows into steep pine gorge and crosses into ethnically Tibetan country at Deng (1,860m).', 1),
    ('manaslu-circuit-trek', 4, null::time, 'Deng to Namrung', 'Cross the Budhi Gandaki several times, pass the Serang Gompa turnoff and climb the gorge gate to Namrung (2,630m).', 1),
    ('manaslu-circuit-trek', 5, null::time, 'Namrung to Lho', 'First clear Manaslu views open above Lihi and Sho, arriving at Lho village (3,180m) below Ribung Gompa.', 1),
    ('manaslu-circuit-trek', 6, null::time, 'Lho to Samagaun', 'Through Shyala with Manaslu, Himalchuli and Ganesh Himal encircling the valley, to the large Tibetan village of Samagaun (3,530m).', 1),
    ('manaslu-circuit-trek', 7, null::time, 'Samagaun acclimatisation day', 'Day hike to Birendra Lake and the Manaslu Base Camp viewpoint (4,400m), or the ancient Pungyen Gompa. Sleep at Samagaun.', 1),
    ('manaslu-circuit-trek', 8, null::time, 'Samagaun to Samdo', 'Short stage above the treeline past the old mani walls to the last permanent village before Tibet, Samdo (3,875m).', 1),
    ('manaslu-circuit-trek', 9, null::time, 'Samdo to Dharamsala', 'Two-hour climb to the stone huts of Dharamsala, also called Larkya Phedi (4,460m), for an early night before the pass.', 1),
    ('manaslu-circuit-trek', 10, null::time, 'Cross Larkya La to Bimthang', 'Pre-dawn start for the Larkya La (5,106m), the circuit high point, then a long knee-testing descent to the meadows of Bimthang (3,720m).', 1),
    ('manaslu-circuit-trek', 11, null::time, 'Bimthang to Tilije', 'Cross the Dudh Khola, drop through rhododendron and pine forest into the Manang district village of Tilije (2,300m).', 1),
    ('manaslu-circuit-trek', 12, null::time, 'Tilije to Dharapani, drive to Besisahar', 'Join the Annapurna Circuit road at Dharapani and take a jeep down the Marsyangdi valley to Besisahar.', 1),
    ('manaslu-circuit-trek', 13, null::time, 'Drive Besisahar to Kathmandu', 'Road transfer back to Kathmandu along the Prithvi Highway.', 1),

    -- ===== Tilicho Lake & Thorong La Circuit (13 days) =====
    ('tilicho-lake-annapurna-circuit', 1, null::time, 'Drive Kathmandu to Chame', 'Jeep up the Marsyangdi valley via Besisahar to the Manang district headquarters at Chame (2,670m).', 1),
    ('tilicho-lake-annapurna-circuit', 2, null::time, 'Chame to Upper Pisang', 'Past the great Paungda Danda rock face, leaving the forest for the dry upper valley at Upper Pisang (3,300m).', 1),
    ('tilicho-lake-annapurna-circuit', 3, null::time, 'Upper Pisang to Manang via Ghyaru', 'Take the high route through the Tibetan villages of Ghyaru and Ngawal for Annapurna II and IV views, descending to Manang (3,540m).', 1),
    ('tilicho-lake-annapurna-circuit', 4, null::time, 'Manang acclimatisation day', 'Hike to Gangapurna Lake and the Chongkor viewpoint, or up to Ice Lake (4,600m). Attend the afternoon altitude-sickness briefing at the HRA post.', 1),
    ('tilicho-lake-annapurna-circuit', 5, null::time, 'Manang to Khangsar', 'Short stage leaving the main circuit for the Tilicho branch, climbing to the old village of Khangsar (3,734m).', 1),
    ('tilicho-lake-annapurna-circuit', 6, null::time, 'Khangsar to Tilicho Base Camp', 'Cross the notorious eroded landslide traverse above the Khangsar Khola to the lodges at Tilicho Base Camp (4,150m).', 1),
    ('tilicho-lake-annapurna-circuit', 7, null::time, 'Tilicho Lake and return to base camp', 'Early climb to Tilicho Lake (4,919m), one of the highest large lakes on earth, then descend the same way to sleep lower.', 1),
    ('tilicho-lake-annapurna-circuit', 8, null::time, 'Tilicho Base Camp to Yak Kharka', 'Return via Shree Kharka and rejoin the circuit trail north of Manang at Yak Kharka (4,050m).', 1),
    ('tilicho-lake-annapurna-circuit', 9, null::time, 'Yak Kharka to Thorong Phedi', 'Short careful stage over the Marsyangdi landslide section to Thorong Phedi (4,450m) at the foot of the pass.', 1),
    ('tilicho-lake-annapurna-circuit', 10, null::time, 'Cross Thorong La to Muktinath', 'Alpine start for the Thorong La (5,416m), then a 1,600m descent into the Mustang rain shadow at the pilgrimage town of Muktinath (3,800m).', 1),
    ('tilicho-lake-annapurna-circuit', 11, null::time, 'Muktinath to Jomsom via Kagbeni', 'Visit the 108 water spouts and eternal flame at Muktinath temple, then down the Kali Gandaki through Kagbeni to Jomsom (2,720m).', 1),
    ('tilicho-lake-annapurna-circuit', 12, null::time, 'Jomsom to Pokhara', 'Morning mountain flight or jeep through the world''s deepest gorge to Pokhara.', 1),
    ('tilicho-lake-annapurna-circuit', 13, null::time, 'Pokhara to Kathmandu', 'Flight or tourist coach back to Kathmandu.', 1),

    -- ===== Upper Mustang Trek (12 days) =====
    ('upper-mustang-trek', 1, null::time, 'Fly Pokhara to Jomsom, trek to Kagbeni', 'Early flight through the Kali Gandaki gorge to Jomsom (2,720m), then a windy afternoon walk to the medieval village of Kagbeni (2,810m).', 1),
    ('upper-mustang-trek', 2, null::time, 'Kagbeni to Chele', 'Restricted-area permit check at the Kagbeni police post, then up the Kali Gandaki past Tangbe and Chhusang to Chele (3,050m).', 1),
    ('upper-mustang-trek', 3, null::time, 'Chele to Syangboche', 'Cross the Taklam La and Dajori La past Samar and the sacred Rangbyung cave to Syangboche (3,800m).', 1),
    ('upper-mustang-trek', 4, null::time, 'Syangboche to Ghami', 'Over the Yamda La and Nyi La into the red-cliff country, descending to Ghami (3,520m) below the longest mani wall in Nepal.', 1),
    ('upper-mustang-trek', 5, null::time, 'Ghami to Tsarang', 'Cross the Ghami Khola and the Tsarang La to the old royal seat of Tsarang (3,560m) with its dzong and 14th-century gompa.', 1),
    ('upper-mustang-trek', 6, null::time, 'Tsarang to Lo Manthang', 'Over the Lo La for the first sight of the walled capital, entering Lo Manthang (3,840m) through its single gate.', 1),
    ('upper-mustang-trek', 7, null::time, 'Lo Manthang walled city', 'Full day inside the walls: Jampa Lhakhang, Thubchen Gompa, Chodey monastery and the former royal palace.', 1),
    ('upper-mustang-trek', 8, null::time, 'Chhoser sky caves excursion', 'Ride or walk north to the Jhong sky caves, a five-storey cliff dwelling carved into the conglomerate, and Nyphu cave monastery.', 1),
    ('upper-mustang-trek', 9, null::time, 'Lo Manthang to Dhakmar', 'Return by the western route via Ghar Gompa, the oldest monastery in Mustang, to the red cliffs of Dhakmar (3,820m).', 1),
    ('upper-mustang-trek', 10, null::time, 'Dhakmar to Samar', 'Back over the Nyi La and Bhena La through Syangboche to the poplar grove at Samar (3,660m).', 1),
    ('upper-mustang-trek', 11, null::time, 'Samar to Jomsom', 'Descend past Chele and Chhusang and follow the Kali Gandaki through Kagbeni back to Jomsom.', 1),
    ('upper-mustang-trek', 12, null::time, 'Fly Jomsom to Pokhara', 'Early morning flight to Pokhara before the valley wind picks up.', 1),

    -- ===== Tiji Festival, Lo Manthang (13 days) =====
    ('tiji-festival-mustang', 1, null::time, 'Fly Pokhara to Jomsom, trek to Kagbeni', 'Mountain flight to Jomsom (2,720m) and an afternoon walk into the gateway village of Kagbeni.', 1),
    ('tiji-festival-mustang', 2, null::time, 'Kagbeni to Chele', 'Upper Mustang permits checked at Kagbeni, then along the Kali Gandaki past Tangbe and Chhusang to Chele (3,050m).', 1),
    ('tiji-festival-mustang', 3, null::time, 'Chele to Syangboche', 'Cross the Taklam La and Dajori La, passing Samar and the Rangbyung cave shrine, to Syangboche (3,800m).', 1),
    ('tiji-festival-mustang', 4, null::time, 'Syangboche to Ghami', 'Over the Yamda La and Nyi La to Ghami (3,520m) and its 300m mani wall.', 1),
    ('tiji-festival-mustang', 5, null::time, 'Ghami to Tsarang', 'Climb the Tsarang La to the old royal village of Tsarang (3,560m) and its five-storey white dzong.', 1),
    ('tiji-festival-mustang', 6, null::time, 'Tsarang to Lo Manthang', 'Cross the Lo La and enter the walled capital (3,840m), timed to arrive before the festival opens.', 1),
    ('tiji-festival-mustang', 7, null::time, 'Tiji day one: Tsa Chham', 'Monks of Chodey Gompa perform the Tsa Chham, opening the three-day cycle that recounts Dorje Jono defeating his demon father.', 1),
    ('tiji-festival-mustang', 8, null::time, 'Tiji day two: Nga Chham', 'The Nga Chham drum dances fill the palace square, with the great thangka of Padmasambhava unfurled on the palace wall.', 1),
    ('tiji-festival-mustang', 9, null::time, 'Tiji day three: the exorcism', 'The final ritual carries the demon effigy out beyond the city walls, closing the festival with archery and horse events.', 1),
    ('tiji-festival-mustang', 10, null::time, 'Chhoser sky caves excursion', 'Quiet day after the crowds leave: the Jhong sky caves at Chhoser and Nyphu cave monastery.', 1),
    ('tiji-festival-mustang', 11, null::time, 'Lo Manthang to Ghami', 'Return south via Ghar Gompa and the red cliffs of Dhakmar to Ghami.', 1),
    ('tiji-festival-mustang', 12, null::time, 'Ghami to Jomsom', 'Long stage by trail and jeep back down the Kali Gandaki through Kagbeni to Jomsom.', 1),
    ('tiji-festival-mustang', 13, null::time, 'Fly Jomsom to Pokhara', 'Morning flight out of Mustang to Pokhara.', 1),

    -- ===== Island Peak (Imja Tse) Expedition (15 days) =====
    ('island-peak-climbing', 1, null::time, 'Fly Kathmandu to Lukla, trek to Phakding', 'Mountain flight to Lukla (2,860m) and an easy first stage down the Dudh Koshi to Phakding.', 1),
    ('island-peak-climbing', 2, null::time, 'Phakding to Namche Bazaar', 'Sagarmatha National Park entry at Monjo, the Hillary Bridge, and the climb to Namche (3,440m).', 1),
    ('island-peak-climbing', 3, null::time, 'Namche acclimatisation day', 'Hike to the Everest View Hotel and Khumjung, then sleep back at Namche. Guides check personal climbing kit.', 1),
    ('island-peak-climbing', 4, null::time, 'Namche to Tengboche', 'Traverse the Dudh Koshi gorge and climb to Tengboche Monastery (3,860m) below Ama Dablam.', 1),
    ('island-peak-climbing', 5, null::time, 'Tengboche to Dingboche', 'Through Pangboche and above the treeline into the Imja Valley at Dingboche (4,410m).', 1),
    ('island-peak-climbing', 6, null::time, 'Dingboche acclimatisation day', 'Climb Nangkartshang Peak (5,083m) to build red cells, then descend to Dingboche to sleep.', 1),
    ('island-peak-climbing', 7, null::time, 'Dingboche to Chhukung', 'Short stage up the Imja Valley to Chhukung (4,730m), directly beneath the Lhotse south face.', 1),
    ('island-peak-climbing', 8, null::time, 'Chhukung to Island Peak Base Camp', 'Follow the Imja Khola and glacier moraine to Base Camp (5,087m). Tented camp with a full kitchen crew.', 1),
    ('island-peak-climbing', 9, null::time, 'Rope and ice training at base camp', 'Full day of fixed-line ascent and descent, crampon technique, jumar and figure-of-eight practice on a training slope.', 1),
    ('island-peak-climbing', 10, null::time, 'Summit Island Peak, descend to Chhukung', 'Midnight start up the rock gully to the glacier, cross the crevasse field, then the fixed headwall to the summit (6,189m). Long descent to Chhukung.', 1),
    ('island-peak-climbing', 11, null::time, 'Reserve summit day', 'Spare day held in the itinerary for weather or a second summit attempt. If unused, rest and acclimatise at Chhukung.', 1),
    ('island-peak-climbing', 12, null::time, 'Chhukung to Pangboche', 'Drop back down the Imja Valley to Pangboche (3,930m) and thicker air.', 1),
    ('island-peak-climbing', 13, null::time, 'Pangboche to Namche Bazaar', 'Back past Tengboche and along the gorge trail to Namche.', 1),
    ('island-peak-climbing', 14, null::time, 'Namche to Lukla', 'Final descent to Lukla and a celebration dinner with the climbing Sherpas.', 1),
    ('island-peak-climbing', 15, null::time, 'Fly Lukla to Kathmandu', 'Morning flight back to Kathmandu and transfer to your hotel.', 1),

    -- ===== Mera Peak Expedition (17 days) =====
    ('mera-peak-climbing', 1, null::time, 'Kathmandu briefing and gear check', 'Expedition briefing, permit formalities and a full personal equipment check with the climbing leader. Hire or buy any missing kit in Thamel.', 1),
    ('mera-peak-climbing', 2, null::time, 'Fly Kathmandu to Lukla, trek to Chutanga', 'Mountain flight to Lukla, then turn away from the Everest trail and climb east into forest at Chutanga (3,050m).', 1),
    ('mera-peak-climbing', 3, null::time, 'Chutanga to Thuli Kharka via Zatrwa La', 'Cross the Zatrwa La (4,610m), the first serious pass, and descend into the Hinku Valley at Thuli Kharka (4,300m).', 1),
    ('mera-peak-climbing', 4, null::time, 'Thuli Kharka to Kothe', 'Long descent through rhododendron and pine into the floor of the Hinku Valley at Kothe (3,600m).', 1),
    ('mera-peak-climbing', 5, null::time, 'Kothe to Thangnak', 'Follow the Hinku Khola past the Lungsumgba Gompa to the summer grazing settlement of Thangnak (4,350m).', 1),
    ('mera-peak-climbing', 6, null::time, 'Thangnak acclimatisation day', 'Day hike to the Sabai Tsho glacial lake and the moraine above it, then sleep low at Thangnak.', 1),
    ('mera-peak-climbing', 7, null::time, 'Thangnak to Khare', 'Climb the Dig Glacier moraine with the Mera north face ahead to the last settlement at Khare (5,045m).', 1),
    ('mera-peak-climbing', 8, null::time, 'Khare acclimatisation and ice training', 'Crampon, ice axe and fixed-rope training on the glacier above Khare. Final gear issue and rope teams assigned.', 1),
    ('mera-peak-climbing', 9, null::time, 'Khare to Mera Base Camp', 'Short technical section onto the Mera La and across the glacier to Base Camp (5,300m).', 1),
    ('mera-peak-climbing', 10, null::time, 'Base Camp to High Camp', 'Roped glacier travel to the exposed High Camp perched on rock at 5,780m, with Everest, Lhotse and Makalu in view.', 1),
    ('mera-peak-climbing', 11, null::time, 'Summit Mera Peak, descend to Khare', 'Two in the morning start on the long snow slope to the central summit (6,476m), Nepal''s highest trekking peak, then all the way down to Khare.', 1),
    ('mera-peak-climbing', 12, null::time, 'Reserve summit day', 'Contingency day for weather or a repeat attempt. If unused, rest at Khare.', 1),
    ('mera-peak-climbing', 13, null::time, 'Khare to Kothe', 'Retrace the Hinku Valley down to the treeline at Kothe.', 1),
    ('mera-peak-climbing', 14, null::time, 'Kothe to Thuli Kharka', 'Climb back out of the valley through forest to Thuli Kharka.', 1),
    ('mera-peak-climbing', 15, null::time, 'Thuli Kharka to Lukla via Zatrwa La', 'Recross the Zatrwa La and drop steeply through Chutanga to Lukla.', 1),
    ('mera-peak-climbing', 16, null::time, 'Reserve day in Lukla', 'Buffer day for the Lukla flight, which is frequently delayed by cloud. If the flight runs on schedule, this day is spare in Kathmandu.', 1),
    ('mera-peak-climbing', 17, null::time, 'Fly Lukla to Kathmandu', 'Morning flight back to Kathmandu and expedition debrief.', 1),

    -- ===== Langtang Valley Trek (7 days) =====
    ('langtang-valley-trek', 1, null::time, 'Drive Kathmandu to Syabrubesi', 'Seven-hour road journey north via Trishuli and Dhunche to the trailhead at Syabrubesi (1,460m).', 1),
    ('langtang-valley-trek', 2, null::time, 'Syabrubesi to Lama Hotel', 'Cross the Bhote Koshi and climb the Langtang Khola gorge through oak and bamboo forest, prime red panda habitat, to Lama Hotel (2,470m).', 1),
    ('langtang-valley-trek', 3, null::time, 'Lama Hotel to Langtang village', 'Climb past Ghoda Tabela to the rebuilt village of Langtang (3,430m) and the memorial to the 2015 earthquake landslide.', 1),
    ('langtang-valley-trek', 4, null::time, 'Langtang village to Kyanjin Gompa', 'Short stage past long mani walls and yak pasture to the monastery and cheese factory at Kyanjin Gompa (3,870m).', 1),
    ('langtang-valley-trek', 5, null::time, 'Kyanjin Ri and Tserko Ri', 'Dawn climb of Kyanjin Ri (4,773m) for the Langtang Lirung glacier panorama, with the option of continuing to Tserko Ri (4,984m).', 1),
    ('langtang-valley-trek', 6, null::time, 'Kyanjin Gompa to Lama Hotel', 'Long descent retracing the valley back into the forest at Lama Hotel.', 1),
    ('langtang-valley-trek', 7, null::time, 'Lama Hotel to Syabrubesi, drive Kathmandu', 'Final morning through the gorge to Syabrubesi, then the road back to Kathmandu.', 1),

    -- ===== Rara Lake Wilderness Trek (8 days) =====
    ('rara-lake-wilderness-trek', 1, null::time, 'Fly Nepalgunj to Talcha, trek to Rara Lake', 'Short flight into the Talcha airstrip (2,700m) and a three-hour walk through blue pine forest to the shore of Rara Lake (2,990m).', 1),
    ('rara-lake-wilderness-trek', 2, null::time, 'Rara Lake circuit and Murma Top', 'Walk the full lake shore, then climb to Murma Top for the classic view of Nepal''s largest lake against the Kanjirowa range.', 1),
    ('rara-lake-wilderness-trek', 3, null::time, 'Chuchemara viewpoint', 'Ascend Chuchemara Danda (4,087m) on the south shore for the widest panorama over the lake and into Dolpo.', 1),
    ('rara-lake-wilderness-trek', 4, null::time, 'Rara Lake to Gorosingha', 'Leave the lake and cross high meadow and pine forest to the herders'' camp at Gorosingha (3,190m).', 1),
    ('rara-lake-wilderness-trek', 5, null::time, 'Gorosingha to Sinja Valley', 'Follow the Ghatta Khola down into the Sinja Valley (2,440m), the 12th-century capital of the Khasa Malla kingdom.', 1),
    ('rara-lake-wilderness-trek', 6, null::time, 'Sinja Valley and the Ghurchi Lagna', 'Visit the Kanaka Sundari temple and the old Malla inscriptions, then climb toward the Ghurchi Lagna pass (3,450m).', 1),
    ('rara-lake-wilderness-trek', 7, null::time, 'Trek to Jumla', 'Descend through terraced Khasa villages and apple orchards to the district town of Jumla (2,540m).', 1),
    ('rara-lake-wilderness-trek', 8, null::time, 'Fly Jumla to Nepalgunj', 'Morning flight out of the Karnali to Nepalgunj for onward connections.', 1),

    -- ===== Helambu Hyolmo Circuit (5 days) =====
    ('helambu-circuit-trek', 1, null::time, 'Drive to Sundarijal, trek to Chisapani', 'Short drive to the Sundarijal trailhead, climb through Shivapuri Nagarjun National Park to the ridge at Chisapani (2,215m).', 1),
    ('helambu-circuit-trek', 2, null::time, 'Chisapani to Kutumsang', 'Ridge walking through Pati Bhanjyang and Gul Bhanjyang, Tamang villages with Langtang views, to Kutumsang (2,470m).', 1),
    ('helambu-circuit-trek', 3, null::time, 'Kutumsang to Tharepati', 'Climb through rhododendron and fir forest along the Yurin Danda to the exposed ridge camp at Tharepati (3,690m).', 1),
    ('helambu-circuit-trek', 4, null::time, 'Tharepati to Melamchigaun', 'Drop east off the ridge into Hyolmo country and the old Buddhist village of Melamchigaun (2,530m) with its 400-year-old gompa.', 1),
    ('helambu-circuit-trek', 5, null::time, 'Melamchigaun to Tarkeghyang, drive Kathmandu', 'Cross the Melamchi Khola to Tarkeghyang, the largest Hyolmo village, then take the road back to Kathmandu.', 1),

    -- ===== Mardi Himal Trek (5 days) =====
    ('mardi-himal-trek', 1, null::time, 'Drive Pokhara to Kande, trek to Forest Camp', 'Short drive to Kande, climb past Australian Camp and Pothana, then a long forest traverse to Forest Camp (2,550m).', 1),
    ('mardi-himal-trek', 2, null::time, 'Forest Camp to Low Camp', 'Steady climb through moss-draped rhododendron forest, breaking out of the trees at Low Camp (2,970m) with Machhapuchhre ahead.', 1),
    ('mardi-himal-trek', 3, null::time, 'Low Camp to High Camp', 'Walk the exposed ridge above the treeline with Annapurna South and Hiunchuli on the left to High Camp (3,580m).', 1),
    ('mardi-himal-trek', 4, null::time, 'High Camp to View Point, descend to Low Camp', 'Dawn climb along the narrow ridge to the Mardi Himal View Point (4,200m) beneath the Machhapuchhre face, then a long descent to Low Camp.', 1),
    ('mardi-himal-trek', 5, null::time, 'Low Camp to Sidhing, drive Pokhara', 'Descend the quiet eastern trail through Sidhing village to the road head at Lwang and drive back to Pokhara.', 1),

    -- ===== Bardia Tiger Tracking (4 days) =====
    ('bardia-tiger-tracking', 1, null::time, 'Arrive Bardia, orientation and Tharu village walk', 'Transfer from Nepalgunj to Thakurdwara, park briefing with the naturalist, then an evening walk through the Tharu village and community forest edge.', 1),
    ('bardia-tiger-tracking', 2, null::time, 'Full-day tiger tracking on foot', 'Dawn start into the Karnali floodplain with an armed park guide, reading pugmarks, scrapes and alarm calls from the Karnali machans.', 1),
    ('bardia-tiger-tracking', 3, null::time, 'Jeep safari and Babai valley machan', 'Jeep safari deep into the Babai valley for tiger, rhino and swamp deer, ending at an elevated machan over a waterhole at dusk.', 1),
    ('bardia-tiger-tracking', 4, null::time, 'Karnali river dolphin trip and departure', 'Dawn boat trip on the Karnali looking for the endangered Gangetic river dolphin and gharial, then transfer to Nepalgunj.', 1),

    -- ===== Chitwan Wildlife Safari (3 days) =====
    ('chitwan-jungle-safari', 1, null::time, 'Arrive Sauraha, Tharu culture and Rapti sunset', 'Check in at Sauraha, visit the Tharu cultural house for the evening stick dance, then watch sunset over the Rapti River.', 1),
    ('chitwan-jungle-safari', 2, null::time, 'Canoe, jungle walk and jeep safari', 'Dugout canoe down the Rapti for gharial and marsh mugger, guided jungle walk, elephant breeding centre, and an afternoon jeep safari for one-horned rhino.', 1),
    ('chitwan-jungle-safari', 3, null::time, 'Dawn bird walk and departure', 'Early morning bird walk in the community forest, over 500 species recorded in the park, then breakfast and departure.', 1),

    -- ===== Ghandruk Heritage Homestay (2 days) =====
    ('ghandruk-homestay-experience', 1, null::time, 'Drive Pokhara to Nayapul, trek to Ghandruk', 'Drive to Nayapul and climb the stone staircase to the Gurung village of Ghandruk (1,940m). Visit the Gurung museum and meet your host family.', 1),
    ('ghandruk-homestay-experience', 2, null::time, 'Annapurna South sunrise, cooking session and return', 'Sunrise on Annapurna South and Machhapuchhre from the village terraces, a Gurung cooking session with your host, then descend and drive to Pokhara.', 1),

    -- ===== Bandipur Living Museum (2 days) =====
    ('bandipur-cultural-walk', 1, null::time, 'Drive to Bandipur, bazaar walk and Thani Mai sunset', 'Road transfer to the Newari hill town of Bandipur (1,030m), a walking tour of the car-free bazaar and its 18th-century merchant houses, then sunset from the Thani Mai temple.', 1),
    ('bandipur-cultural-walk', 2, null::time, 'Siddha Gufa cave and Khadga Devi temple', 'Morning walk to Siddha Gufa, the largest cave in Nepal, then the Khadga Devi temple and Tundikhel viewpoint before driving back.', 1),

    -- ===== Australian Camp Overnight (2 days) =====
    ('australian-camp-overnight', 1, null::time, 'Drive to Kande, hike to Australian Camp, sunset', 'Afternoon drive to Kande, a 90-minute climb to the meadow at Australian Camp (2,060m), tent setup, then sunset on Machhapuchhre with dinner around the fire.', 1),
    ('australian-camp-overnight', 2, null::time, 'Sunrise and descent via Dhampus', 'First light across the whole Annapurna wall from the camp meadow, breakfast, then descend through Dhampus village to Phedi and drive to Pokhara.', 1),

    -- ===== Panauti Community Homestay (2 days) =====
    ('panauti-community-homestay', 1, null::time, 'Drive to Panauti, temple walk and family dinner', 'Transfer to the Newari town of Panauti, visit the 13th-century Indreshwar Mahadev temple and the river confluence, then dinner cooked with your host family.', 1),
    ('panauti-community-homestay', 2, null::time, 'Farm morning, Newari cooking and return', 'Join the household on the terraced farm at dawn, learn to make yomari and chatamari in the family kitchen, walk to Khopasi, then return to Kathmandu.', 1),

    -- ===== Bhaktapur Pottery Workshop (day trip) =====
    ('bhaktapur-pottery-workshop', 1, '09:00'::time, 'Meet at Bhaktapur Durbar Square', 'Meet your guide at the Golden Gate for an introduction to the Malla-era palace complex and the Newari craft guilds.', 1),
    ('bhaktapur-pottery-workshop', 1, '10:00'::time, 'Pottery Square wheel-throwing session', 'Hands-on session at Talako with a master potter: wedging clay, throwing on the traditional heavy wheel, and sun-drying in the square.', 2),
    ('bhaktapur-pottery-workshop', 1, '12:00'::time, 'Samay baji lunch and juju dhau', 'Traditional Newari samay baji platter followed by juju dhau, the king of curds, set in the black clay pots you have just been working with.', 3),
    ('bhaktapur-pottery-workshop', 1, '13:30'::time, 'Palace and temple walk', 'The 55-Window Palace, the five-tiered Nyatapola temple and Dattatreya Square, ending with the peacock window.', 4),

    -- ===== Bhotekoshi Rafting (day trip) =====
    ('bhotekoshi-whitewater-rafting', 1, '06:30'::time, 'Depart Kathmandu for the Bhotekoshi', 'Early departure along the Araniko Highway toward the Tibet border, roughly three hours to the put-in.', 1),
    ('bhotekoshi-whitewater-rafting', 1, '09:30'::time, 'Safety briefing and paddle drill', 'Kit issue, swim test, and a full safety and paddle-command drill in a calm eddy before committing to the rapids.', 2),
    ('bhotekoshi-whitewater-rafting', 1, '10:30'::time, 'Upper section: Class III-IV rapids', 'The steep upper run including Frog in a Blender, Liquid Bliss and Fear Factory, with safety kayakers alongside.', 3),
    ('bhotekoshi-whitewater-rafting', 1, '13:30'::time, 'Riverside lunch', 'Hot lunch on a sandy beach with time to dry off before the second half.', 4),
    ('bhotekoshi-whitewater-rafting', 1, '15:00'::time, 'Lower section to Lamosangu', 'Continuous read-and-run water down to the take-out at Lamosangu.', 5),
    ('bhotekoshi-whitewater-rafting', 1, '17:00'::time, 'Drive back to Kathmandu', 'Change, debrief and the return drive to Kathmandu.', 6),

    -- ===== Dhulikhel to Namobuddha Hike (day trip) =====
    ('dhulikhel-namobuddha-hike', 1, '07:00'::time, 'Drive Kathmandu to Dhulikhel', 'Drive to the Newari town of Dhulikhel (1,550m) on the old Tibet trade route.', 1),
    ('dhulikhel-namobuddha-hike', 1, '08:30'::time, 'Ridge hike via Kavre Bhanjyang', 'Walk the ridge trail through terraced fields and pine, with the Himalaya from Langtang to Everest on a clear morning.', 2),
    ('dhulikhel-namobuddha-hike', 1, '11:30'::time, 'Namobuddha stupa and monastery', 'The stupa marking where the prince gave his body to the tigress, and the hilltop Thrangu Tashi Yangtse monastery above it.', 3),
    ('dhulikhel-namobuddha-hike', 1, '12:30'::time, 'Monastery vegetarian lunch', 'Simple vegetarian meal in the monastery dining hall with the monks.', 4),
    ('dhulikhel-namobuddha-hike', 1, '14:00'::time, 'Descend to Panauti, drive back', 'Two-hour descent through Bahunepati farmland to the Newari town of Panauti, then the drive to Kathmandu.', 5),

    -- ===== Everest Helicopter Tour (day trip) =====
    ('everest-heli-tour', 1, '06:00'::time, 'Kathmandu heliport check-in and briefing', 'Weigh-in, safety briefing and seat allocation at the domestic terminal. Flights leave early for the calmest air.', 1),
    ('everest-heli-tour', 1, '06:30'::time, 'Flight to Lukla and refuelling stop', 'Fly east over the middle hills and the Dudh Koshi into Lukla for a short refuelling stop.', 2),
    ('everest-heli-tour', 1, '07:30'::time, 'Kala Patthar landing', 'Land briefly at Kala Patthar (5,545m) for the closest possible ground view of the Everest summit and the Khumbu Icefall. Ten to fifteen minutes only, at this altitude.', 3),
    ('everest-heli-tour', 1, '08:15'::time, 'Champagne breakfast at Everest View Hotel', 'Breakfast on the terrace at the Everest View Hotel (3,880m) above Namche, facing Everest, Lhotse and Ama Dablam.', 4),
    ('everest-heli-tour', 1, '09:30'::time, 'Return flight to Kathmandu', 'Scenic return down the Khumbu with landing back at the Kathmandu heliport.', 5),

    -- ===== Himalayan Sound Healing (day trip) =====
    ('himalayan-sound-healing', 1, '10:00'::time, 'Intention setting and breath work', 'Settle in the studio, a short guided pranayama sequence to slow the breath before the bowls begin.', 1),
    ('himalayan-sound-healing', 1, '10:30'::time, 'Seven-bowl chakra sound bath', 'Lie down for a full sound bath using hand-hammered Himalayan bowls tuned to the seven chakras, plus tingsha and gong.', 2),
    ('himalayan-sound-healing', 1, '11:15'::time, 'Guided Himalayan meditation', 'A short guided meditation drawn from the Tibetan shamatha tradition to hold the state the bowls created.', 3),
    ('himalayan-sound-healing', 1, '11:45'::time, 'Herbal tea and integration', 'Himalayan herbal tea and a quiet conversation with the practitioner about what came up.', 4),

    -- ===== Kakani Trout and Strawberry (day trip) =====
    ('kakani-trout-strawberry', 1, '08:00'::time, 'Drive Kathmandu to Kakani', 'Drive northwest out of the valley on the old Trishuli road to the hill station of Kakani (2,073m).', 1),
    ('kakani-trout-strawberry', 1, '09:30'::time, 'Ganesh Himal viewpoint and Memorial Park', 'Views across to Ganesh Himal, Langtang and Manaslu, and a stop at the Thai Airways memorial park.', 2),
    ('kakani-trout-strawberry', 1, '11:00'::time, 'Trout farm walk and lunch', 'Walk the raceway ponds of a working rainbow trout farm, then eat fresh grilled trout straight from the tanks.', 3),
    ('kakani-trout-strawberry', 1, '13:30'::time, 'Organic strawberry farm tasting', 'Pick and taste at a hillside organic strawberry farm, with jam and wine made on site.', 4),
    ('kakani-trout-strawberry', 1, '15:00'::time, 'Return to Kathmandu', 'Drive back down into the valley.', 5),

    -- ===== Nagarkot Sunrise Hike (day trip) =====
    ('nagarkot-sunrise-hike', 1, '04:00'::time, 'Pre-dawn drive to Nagarkot', 'Leave Kathmandu in the dark for the 32km climb to the Nagarkot ridge (2,175m).', 1),
    ('nagarkot-sunrise-hike', 1, '05:30'::time, 'Sunrise over the Himalaya', 'From the view tower, the range unfolds from Annapurna and Manaslu through Langtang and Dorje Lakpa to Everest on a clear day.', 2),
    ('nagarkot-sunrise-hike', 1, '07:00'::time, 'Breakfast on the ridge', 'Hot breakfast at a ridge-top lodge as the valley mist burns off.', 3),
    ('nagarkot-sunrise-hike', 1, '08:00'::time, 'Hike the Nagarkot to Changunarayan ridge', 'Three-hour downhill ridge walk through pine forest and Tamang farmland with the mountains behind you.', 4),
    ('nagarkot-sunrise-hike', 1, '11:00'::time, 'Changunarayan temple', 'The oldest Hindu temple in the valley, a UNESCO site founded in the 5th century, with Nepal''s earliest dated stone inscription.', 5),
    ('nagarkot-sunrise-hike', 1, '12:30'::time, 'Drive back to Kathmandu', 'Short transfer back into the city.', 6),

    -- ===== Phulchowki Mountain Biking (day trip) =====
    ('phulchowki-mountain-biking', 1, '07:00'::time, 'Bike fit and shuttle to the summit', 'Full-suspension bike fit, brake and pressure check in Godavari, then the jeep shuttle up the fire road to the summit.', 1),
    ('phulchowki-mountain-biking', 1, '08:30'::time, 'Summit views and trail briefing', 'From Phulchowki (2,760m), the highest point on the valley rim, a full panorama and a run-through of the trail features and line choices.', 2),
    ('phulchowki-mountain-biking', 1, '09:00'::time, 'Singletrack descent through cloud forest', 'Roughly 1,300m of descent on loamy singletrack through oak and rhododendron cloud forest, with rock gardens and switchback sections.', 3),
    ('phulchowki-mountain-biking', 1, '11:30'::time, 'Godavari Botanical Garden break', 'Regroup and refuel at the botanical garden at the base of the mountain.', 4),
    ('phulchowki-mountain-biking', 1, '12:30'::time, 'Final section to Lubhu', 'Last flowing section through terraced farmland and Newari villages to the finish at Lubhu.', 5),

    -- ===== Pokhara Tandem Paragliding (day trip) =====
    ('pokhara-paragliding', 1, '09:00'::time, 'Meet lakeside and drive to Sarangkot', 'Check in at the lakeside office, weigh-in, then the winding drive up to the launch site at Sarangkot (1,592m).', 1),
    ('pokhara-paragliding', 1, '10:00'::time, 'Harness fit and safety briefing', 'Your pilot fits the tandem harness and helmet and walks you through the launch run and landing position.', 2),
    ('pokhara-paragliding', 1, '10:30'::time, 'Tandem flight over Fewa Lake', 'Roughly 30 minutes riding thermals over Fewa Lake with the Annapurna range and Machhapuchhre across the valley, often sharing lift with Himalayan griffon vultures.', 3),
    ('pokhara-paragliding', 1, '11:30'::time, 'Landing and video handover', 'Landing at the lakeside field, then collect your GoPro footage and photos before the transfer back.', 4),

    -- ===== World Peace Pagoda Boat and Hike (day trip) =====
    ('pokhara-peace-stupa-hike', 1, '07:30'::time, 'Wooden boat across Fewa Lake', 'Paddle or ride a hand-rowed doonga from the lakeside across Fewa Lake to the southern shore, passing the Tal Barahi temple island.', 1),
    ('pokhara-peace-stupa-hike', 1, '08:15'::time, 'Forest climb to the pagoda', 'A 45-minute climb up stone steps through subtropical forest, cool and shaded in the early morning.', 2),
    ('pokhara-peace-stupa-hike', 1, '09:15'::time, 'World Peace Pagoda and Annapurna panorama', 'The white Japanese-built stupa (1,100m) with its four Buddha statues, looking out over Fewa Lake to Annapurna and Machhapuchhre.', 3),
    ('pokhara-peace-stupa-hike', 1, '10:15'::time, 'Descend to Damside', 'Walk down the eastern trail through Pumdikot forest to Damside.', 4),
    ('pokhara-peace-stupa-hike', 1, '11:00'::time, 'Finish at lakeside', 'Short transfer back to lakeside for coffee.', 5),

    -- ===== Shivapuri Peak Hike (day trip) =====
    ('shivapuri-peak-hike', 1, '07:00'::time, 'Drive to Panimuhan gate', 'Short drive to the Shivapuri Nagarjun National Park entrance at Panimuhan, above Budhanilkantha, and buy permits.', 1),
    ('shivapuri-peak-hike', 1, '08:00'::time, 'Climb through oak and rhododendron forest', 'Steady ascent on the old army road and forest trail, good birding country with over 300 recorded species.', 2),
    ('shivapuri-peak-hike', 1, '10:30'::time, 'Shivapuri Peak summit', 'The second-highest point on the valley rim (2,732m), with Ganesh Himal and Langtang north and the whole Kathmandu valley south.', 3),
    ('shivapuri-peak-hike', 1, '12:00'::time, 'Nagi Gompa nunnery and lunch', 'Descend to the Nagi Gompa nunnery on its hillside terrace for lunch and a look at the meditation halls.', 4),
    ('shivapuri-peak-hike', 1, '14:00'::time, 'Descend to Budhanilkantha', 'Final descent to Budhanilkantha, ending near the sleeping Vishnu temple.', 5)
) as v(slug, day_number, start_time, title, description, sort_order)
  on v.slug = e.slug
where not exists (
  select 1
  from public.itinerary_items existing
  where existing.experience_id = e.id
);
