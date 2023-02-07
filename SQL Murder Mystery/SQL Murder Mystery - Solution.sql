----------------------------------
-- Author: Dwiky Kurnia Lazuardi
-- Date: 12/2022 
----------------------------------
/*
SQL Murder Mystery - https://mystery.knightlab.com/

Web-based SQL Games untuk melatih skill SQL terutama dalam menyusun SQL Queries.
Pada permainan berbasis web ini, kita ditugaskan untuk membantu detektif dalam melakukan analisa, yang mana tujuan akhirnya untuk menemukan identitas pembunuh.
*/

-- SQL Queries :

-- Data Kejahatan Pada 15 Januari 2018 di SQL City
SELECT *
FROM crime_scene_report
WHERE date = 20180115
AND city = 'SQL City';

-- Saksi Mata Pertama, ID = 14887
SELECT *
FROM person
WHERE address_street_name = 'Northwestern Dr'
ORDER BY address_number DESC
LIMIT 1;

-- Saksi Mata Kedua, ID = 16371
SELECT *
FROM person
WHERE address_street_name = 'Franklin Ave'
AND name LIKE '%Annabel%';

-- Interview Saksi Mata Pertama dan Kedua
SELECT *
FROM interview
WHERE person_id = 14887
OR person_id = 16371;

-- Mobil Yang Dibawa Pembunuh, plate_number = H42W
SELECT *
FROM drivers_license
WHERE plate_number LIKE '%H42W%';

-- Tersangka di Gym GetFit
SELECT *
FROM get_fit_now_member
WHERE membership_status = 'gold'
AND id IN (SELECT membership_id
FROM get_fit_now_check_in
WHERE check_in_date = 20180109);

-- Interview Tersangka di Gym GetFit
SELECT *
FROM interview
WHERE person_id IN (SELECT person_id
FROM get_fit_now_member
WHERE membership_status = 'gold'
AND id IN (SELECT membership_id
FROM get_fit_now_check_in
WHERE check_in_date = 20180109));

-- Tersangka Yang Mengikuti 'SQL Symphony Concert' Pada Desember 2017 Sebanyak 3x
SELECT person_id, COUNT(*) AS attended
FROM facebook_event_checkin
WHERE event_name = 'SQL Symphony Concert'
AND date LIKE '201712%'
GROUP BY person_id
ORDER BY attended DESC
LIMIT 2;

-- Identitas Tersangka Yang Mengikuti 'SQL Symphony Concert' Pada Desember 2017 Sebanyak 3x
SELECT *
FROM person
WHERE id = 24556
OR id = 99716;

-- Mobil Pembunuh
SELECT *
FROM drivers_license
WHERE id IN (
SELECT license_id
FROM person
WHERE id = 24556
OR id = 99716);

-- Pembunuhnya adalah Miranda Priestly, ID: 99716