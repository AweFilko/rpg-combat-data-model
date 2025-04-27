-- unset or wrong parameters and function was called

TRUNCATE TABLE
    inventory,
    spell_inventory,
    character,
	combat,
	rounds,
	character_combat_state,
	spell_state,
	inventory_state,
	actions
RESTART IDENTITY CASCADE;


SELECT new_action_number();

SELECT sp_cast_spell(NULL,NULL,NULL);

SELECT sp_enter_combat(NULL,NULL);

SELECT sp_loot_item(NULL,NULL,NULL);

SELECT f_effective_spell_cost(NULL, NULL);

SELECT f_effective_spell_effect(NULL, NULL);

SELECT sp_rest_character(NULL);

SELECT sp_reset_round(NULL);

----------------------------------

SELECT sp_cast_spell(1,1,1);

SELECT sp_enter_combat(1,1);

SELECT sp_loot_item(1,1,1);

SELECT sp_rest_character(1);

SELECT sp_reset_round(1);

--------------------------------------------------------------------------------------------------------------------

--faulty parameters for some cases

SELECT create_character('Testos', 'mage');

SELECT sp_loot_item(1,1,1);

SELECT sp_cast_spell(1,1,1);

SELECT create_character(-1, 'mage');

--SELECT sp_enter_combat(1,1); -> makes new combat if the picked one isn not valid
--------------------------------------------------------------------------------------------------------------------

-- correct parameters

SELECT create_character('Testos', 'mage');
SELECT create_character('Skuskos', 'knight');

SELECT f_effective_spell_effect(10, 1, 15) AS result;

SELECT f_effective_spell_effect(1, 2, 15) AS result;

SELECT f_effective_spell_cost(10, 1) AS result;

SELECT f_effective_spell_cost(1, 2) AS result;

UPDATE character SET item_equipped = 687 WHERE character_ID = 1;
UPDATE character SET item_equipped = 645 WHERE character_ID = 2;

SELECT f_effective_spell_effect(10, 1, 15) AS result;

SELECT f_effective_spell_effect(1, 2, 15) AS result;

SELECT f_effective_spell_cost(10, 1) AS result;

SELECT f_effective_spell_cost(1, 2) AS result;

--------------------------------------------------------------------------------------------------------------------

-- pretty much everything is tested at simulation.sql but in this you can see behind the scene things