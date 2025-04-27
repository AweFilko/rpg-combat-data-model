TRUNCATE TABLE 
    spell,
    class,
    spell_category 
RESTART IDENTITY CASCADE;


INSERT INTO spell_category(category_name)
VALUES ('SLASHING'),
('PIERCING'),
('BLUNT'),
('FIRE'),
('WATER'),
('ICE'),
('EARTH'),
('LIGHTNING'),
('HEALING');

INSERT INTO class(class_name, base_dex, base_stg, base_int, base_cos, base_hlt, base_reg, ap_factor, ac_factor,inv_factor)
VALUES ('mage', 3, 1, 6, 2, 10, 2, 1.1, 0.8, 0.3),
	('dwarf', 2, 4, 2, 4, 30, 3, 1, 1, 0.7),
	('rouge', 5, 2, 3, 2, 20, 2, 0.9, 1, 0.5),
	('knight', 3, 4, 1, 4, 50, 4, 1.1, 0.6, 0.7),
	('paladin', 2, 3, 4, 3, 40, 4, 1.1, 0.4, 0.6),
	('warlock', 4, 2, 4, 2, 30, 3, 1, 0.6, 0.5);

INSERT INTO spell (spell_name, eff_category, base, is_aoe, atribute_to_use)
VALUES ('slash', 1, 1.1, FALSE,'stg'),
	('stab', 2, 1.1, FALSE,'dex'),
	('punch', 3, 1.1, FALSE,'stg'),
	('bash', 3, 1.2, TRUE,'cos'),
	('cleave', 1, 1.3, TRUE,'stg'),
	('pummel', 3, 1.3, FALSE,'stg'),
	('pierce', 2, 1.2, TRUE,'dex'),
	('shot/throw', 2, 1.2, FALSE,'dex'),
	('fireball', 4, 1.3, TRUE,'int'),
	('flame_shot', 4, 1.2, FALSE,'int'),
	('water_wave', 5, 1.2, TRUE,'int'),
	('water_jet', 5, 1.3, FALSE,'int'),
	('ice_storm', 6, 1.3, TRUE,'int'),
	('ice_spike', 6, 1.2, FALSE,'int'),
	('earthquake', 7, 1.3, TRUE,'int'),
	('rock_throw', 7, 1.1, FALSE,'int'),
	('thunder_wave', 8, 1.2, TRUE,'int'),
	('lightning_strike', 8, 1.3, FALSE,'int'),
	('healing_pool', 9, 1.2, TRUE,'int'),
	('heal', 9, 1.2, FALSE,'int');




