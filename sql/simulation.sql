DO $$
	DECLARE
		j_character_id INT;
	    p_caster_id INT;
	    p_target_id INT;
	    p_spell_id INT;
	    character_count INT;
	    active_combat_id INT;
		curr_round_id INT;
		alive_count INT;
		caster_record RECORD;
		alive_character RECORD;
		survivor_id INT;
	BEGIN	

		-- Ill create some characters 
		PERFORM create_character('Ren', 'mage');
		PERFORM create_character('Thorn', 'knight');
		PERFORM create_character('Valery', 'paladin');
		PERFORM create_character('Kylo', 'warlock');
		PERFORM create_character('Elise', 'rouge');
		PERFORM create_character('Durin', 'dwarf');

		-- Ill create combat now, but when someone wants to join a combat and there is none, system will automaticaly create one 
		-- also when the combat doesnt have rounds the system will make new one
		
		INSERT INTO combat(is_active, combat_name) VALUES (TRUE, 'Battle of the last querry')
		RETURNING combat_ID INTO active_combat_id;
		
		-- Give them some spells

		INSERT INTO spell_inventory(character_ID, spell_ID)
		VALUES  (1 + ((active_combat_id - 1) * 6),9), -- fireball
				(1 + ((active_combat_id - 1) * 6),10), --flame_shot
				(2 + ((active_combat_id - 1) * 6),1), --slash
				(2 + ((active_combat_id - 1) * 6),4), --bash
				(3 + ((active_combat_id - 1) * 6),20), --heal
				(3 + ((active_combat_id - 1) * 6),5), -- cleave
				(4 + ((active_combat_id - 1) * 6),3), -- punch
				(4 + ((active_combat_id - 1) * 6), 18), -- lightning_strike
				(5 + ((active_combat_id - 1) * 6), 2), -- stab
				(5 + ((active_combat_id - 1) * 6), 8), -- shot/throw
				(6 + ((active_combat_id - 1) * 6),6), -- pummel
				(6 + ((active_combat_id - 1) * 6), 7) -- pierce
				;
		
		-- When the combat_ID is faulty for some reason, the system will find the active combat (there can be only one) and will join there
		
		FOR j_character_id IN SELECT character_ID FROM character WHERE health != 0 LOOP
			PERFORM sp_enter_combat(active_combat_id,j_character_id); --each character joins fight
		END LOOP;

		-- Ill insert some items on the battle field

		INSERT INTO inventory(owner_ID, inv_description, item_ID)
		VALUES 	(active_combat_id, 'cmb', 222), -- uncommon arcane fire staff
				(active_combat_id, 'cmb', 25), -- common gallant axe
				(active_combat_id, 'cmb', 181), -- common gallant shield
				(active_combat_id, 'cmb', 210), -- uncommon holy longsword
				(active_combat_id, 'cmb', 280), -- uncommon holy pendant
				(active_combat_id, 'cmb', 303), -- uncommon cursed lightning orb
				(active_combat_id, 'cmb', 315), -- rare swift knife
				(active_combat_id, 'cmb', 187), -- uncommon blackstone spear
				(active_combat_id, 'cmb', 35); -- common blackstone mace

		-- let the fighting and looting begin

		PERFORM sp_loot_item(active_combat_id, 1 + ((active_combat_id - 1) * 6), 222);
	    PERFORM sp_loot_item(active_combat_id, 2 + ((active_combat_id - 1) * 6), 25);
	    PERFORM sp_loot_item(active_combat_id, 2 + ((active_combat_id - 1) * 6), 181);
	    PERFORM sp_loot_item(active_combat_id, 3 + ((active_combat_id - 1) * 6), 210);
	    PERFORM sp_loot_item(active_combat_id, 3 + ((active_combat_id - 1) * 6), 280);
	    PERFORM sp_loot_item(active_combat_id, 4 + ((active_combat_id - 1) * 6), 303);
	    PERFORM sp_loot_item(active_combat_id, 5 + ((active_combat_id - 1) * 6), 315);
	    PERFORM sp_loot_item(active_combat_id, 6 + ((active_combat_id - 1) * 6), 187);
	    PERFORM sp_loot_item(active_combat_id, 6 + ((active_combat_id - 1) * 6), 35);

		-- Lets equipp them items

		UPDATE character
		SET item_equipped = 222
		WHERE character_ID = 1 + ((active_combat_id - 1) * 6);

		UPDATE character
		SET item_equipped = 25,
			off_hand_item = 181
		WHERE character_ID = 2 + ((active_combat_id - 1) * 6);

		UPDATE character
		SET item_equipped = 210,
		    off_hand_item = 280
		WHERE character_ID = 3 + ((active_combat_id - 1) * 6);
		
		UPDATE character
		SET item_equipped = 303
		WHERE character_ID = 4 + ((active_combat_id - 1) * 6);
		
		UPDATE character
		SET item_equipped = 315
		WHERE character_ID = 5 + ((active_combat_id - 1) * 6);
		
		UPDATE character
		SET item_equipped = 187,
		    off_hand_item = 35
		WHERE character_ID = 6 + ((active_combat_id - 1) * 6);

	    -- repeat until someone wins / survives
	    LOOP
	        -- create fresh table of alive characters
	        CREATE TEMPORARY TABLE alive_characters ON COMMIT DROP AS
	        SELECT character_ID 
	        FROM character 
	        WHERE health > 0 AND EXISTS (SELECT 1 FROM character_combat_state WHERE combat_ID = active_combat_id)
	        ORDER BY character_ID;
	        
	        -- check how many are alive
	        SELECT COUNT(*) INTO alive_count FROM alive_characters;
	        
	        -- Exit the loop if <=1 player alive
	        IF alive_count <= 1 THEN
	            DROP TABLE alive_characters;
	            EXIT;
	        END IF;

----------------------------------------------------------------------------------------------------------
			-- IF curr_round_id = 10 THEN
			-- 	RAISE NOTICE 'Stopping here!';
			-- 	RETURN;
			-- END IF;

----------------------------------------------------------------------------------------------------------
			
	        -- Randomized spell casting
	        FOR caster_record IN SELECT character_ID FROM alive_characters LOOP
	            p_caster_id := caster_record.character_ID;
	            
	            -- Select a random target (not the caster)
	            SELECT character_ID INTO p_target_id
	            FROM alive_characters
	            WHERE character_ID != p_caster_id
	            ORDER BY random()
	            LIMIT 1;
	            
	            -- Select a random spell
	            SELECT spell_ID INTO p_spell_id 
	            FROM spell_inventory 
	            WHERE character_id = p_caster_id
	            ORDER BY random() 
	            LIMIT 1;
	            
	            -- If spell found, cast
	            IF p_spell_id IS NOT NULL THEN
	                PERFORM sp_cast_spell(p_caster_id, p_target_id, p_spell_id);
	            END IF;
	        END LOOP;
	        
	        -- Insert 'end' actions for everyone still alive
	        SELECT MAX(round_ID) INTO curr_round_id 
	        FROM rounds 
	        WHERE combat_ID = active_combat_id;
	        
	        FOR alive_character IN SELECT character_ID FROM alive_characters LOOP
	            INSERT INTO actions (
	                combat_id, round_id, actor,
	                action_type, action_num, is_success
	            ) VALUES (
	                active_combat_id, curr_round_id, alive_character.character_ID, 'end', new_action_number(), TRUE
	            );
	        END LOOP;
	        
	        -- Clean up temp table
	        DROP TABLE alive_characters;
			
	        
	        -- Move to next round
	        PERFORM sp_reset_round(active_combat_id);
	    END LOOP;

		SELECT character_ID INTO survivor_id FROM character 
		WHERE health > 0 AND EXISTS (SELECT 1 FROM character_combat_state 
		WHERE combat_ID = active_combat_id AND round_ID = curr_round_id);

		INSERT INTO actions(combat_ID, round_ID, actor, action_type, action_num, is_success)
    	VALUES (active_combat_id, curr_round_id, survivor_id, 'flee', new_action_number(), TRUE);
		
		UPDATE combat
		SET is_active = FALSE
		WHERE combat_ID = active_combat_id;

		DELETE FROM inventory
    	WHERE inv_description = 'cmb';

END $$;	

-- TRUNCATE TABLE
--     inventory,
--     spell_inventory,
--     character,
-- 	combat,
-- 	rounds,
-- 	character_combat_state,
-- 	spell_state,
-- 	inventory_state,
-- 	actions
-- RESTART IDENTITY CASCADE;