DROP TABLE IF EXISTS 
    spell_state,
    inventory_state,
    inventory,
    character_combat_state,
    actions,
    spell_inventory,
    rounds,
    combat,
    character,
    spell,
    item,
    shop,
    class,
    spell_category 
CASCADE;

CREATE TABLE spell_category (
	category_ID SERIAL PRIMARY KEY,
	category_name TEXT 
	CHECK (category_name IN ('SLASHING', 'PIERCING', 'BLUNT', 'FIRE','WATER', 'ICE', 'LIGHTNING', 'HEALING', 'EARTH'))
);

CREATE TABLE class (
	class_ID SERIAL PRIMARY KEY,
	class_name TEXT,
	base_dex INT,
	base_int INT,
	base_stg INT,
	base_cos INT,
	base_hlt INT,
	base_reg INT,
	inv_factor NUMERIC(10,2),
	ap_factor NUMERIC(10,2),
	ac_factor NUMERIC(10,2)
);

CREATE TABLE shop (
	shop_ID SERIAL PRIMARY KEY,
	shop_name TEXT,
	profit_margin NUMERIC(10,2)
);

CREATE TABLE item (
	item_ID SERIAL PRIMARY KEY,
	item_name TEXT,
	item_weight NUMERIC(10,2),
	eff_category INT REFERENCES spell_category( category_ID),
	eff_factor NUMERIC(10,2),
	cost_factor NUMERIC(10,2),
	rarity NUMERIC(10,2),
	sell_cost INT,
	pref_class INT REFERENCES class( class_ID)
);

CREATE TABLE spell (
	spell_ID SERIAL PRIMARY KEY,
	spell_name TEXT,
	eff_category INT REFERENCES spell_category(category_ID),
	base NUMERIC(10,2),
	is_aoe BOOLEAN,
	atribute_to_use TEXT CHECK (atribute_to_use IN ('dex', 'stg', 'int', 'cos'))
);

CREATE TABLE character (
	character_ID SERIAL PRIMARY KEY,
	class_ID INT REFERENCES class(class_ID),
	shop_ID INT REFERENCES shop(shop_ID) DEFAULT NULL,
	item_equipped INT REFERENCES item(item_ID) DEFAULT NULL,
	off_hand_item INT REFERENCES item(item_ID) DEFAULT NULL,
	character_name TEXT,
	action_points INT,
	armor_class INT,
	health INT,
	max_health INT,
	strength INT,
	dexterity INT,
	intelligence INT,
	constitution INT,
	regeneration INT,
	max_cap_inv NUMERIC(10,2),
	curr_inv_state NUMERIC(10,2) DEFAULT 0,
	head_bounty INT DEFAULT 10,
	money_bag INT DEFAULT 100
);

CREATE TABLE combat (
	combat_ID SERIAL PRIMARY KEY,
	is_active BOOLEAN,
	combat_name TEXT
);

CREATE TABLE rounds (
	round_ID SERIAL PRIMARY KEY,
	combat_ID INT REFERENCES combat(combat_ID),
	round_num INT 
);

CREATE TABLE spell_inventory (
	spell_inv_ID SERIAL PRIMARY KEY,
	character_ID INT NOT NULL,
	is_shop BOOLEAN DEFAULT FALSE,
	spell_ID INT REFERENCES spell(spell_ID)
);

CREATE TABLE actions (
	action_ID SERIAL PRIMARY KEY,
	combat_ID INT REFERENCES combat(combat_ID),
	round_ID INT REFERENCES rounds(round_ID),
	target INT DEFAULT NULL,
	actor INT REFERENCES character(character_ID),
	used_spell INT REFERENCES spell(spell_ID) DEFAULT NULL,
	action_type TEXT CHECK( action_type in ('flee', 'cast', 'pickup', 'pursue', 'switch', 'drop', 'end', 'join')),
	action_num INT,
	is_success BOOLEAN,
	eff_dealt INT DEFAULT NULL,
	ap_cost INT DEFAULT NULL,
	dice_roll INT CHECK(dice_roll <= 20 AND dice_roll > 0) DEFAULT NULL,
	time_stamp TIMESTAMP DEFAULT NOW() -- add to the doku lebo inak bitka!
);

CREATE TABLE character_combat_state (
	character_state_ID SERIAL PRIMARY KEY,
	character_ID INT REFERENCES character(character_ID),
	item_equipped INT REFERENCES item(item_ID),
	off_hand_item INT REFERENCES item(item_ID),
	combat_ID INT REFERENCES combat(combat_ID),
	round_ID INT REFERENCES rounds(round_ID),
	action_points INT,
	health INT,
	head_bounty INT,
	money_bag INT
);

CREATE TABLE inventory (
	inventory_ID SERIAL PRIMARY KEY,
	owner_ID INT NOT NULL,
	inv_description TEXT CHECK( inv_description in ('shp', 'ply', 'cmb')),
	item_ID INT REFERENCES item(item_ID)
);

CREATE TABLE inventory_state (
	inventory_state_ID SERIAL PRIMARY KEY,
	combat_ID INT REFERENCES combat(combat_ID),
	round_ID INT REFERENCES rounds(round_ID),
	owner_ID INT NOT NULL,
	inv_description TEXT CHECK( inv_description in ('shp', 'ply', 'cmb')),
	item_ID INT REFERENCES item(item_ID)
);

CREATE TABLE spell_state (
	spell_state_ID SERIAL PRIMARY KEY,
	character_ID INT NOT NULL,
	spell_ID INT REFERENCES spell(spell_ID),
	combat_ID INT REFERENCES combat(combat_ID),
	round_ID INT REFERENCES rounds(round_ID)
);