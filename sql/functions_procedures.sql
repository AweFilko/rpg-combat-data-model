--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION f_effective_spell_cost (
	p_spell_id INTEGER ,
	p_caster_id INTEGER
) RETURNS NUMERIC AS $$
DECLARE
	v_effective_cost NUMERIC ;
	char_copy RECORD;
	spell_copy RECORD;
	atribute_value INT;
	i_cost_reduct NUMERIC;
	i_eff_category INT;
BEGIN
	SELECT * INTO char_copy
	FROM character WHERE character_ID = p_caster_id;

	SELECT * INTO spell_copy
	FROM spell WHERE spell_ID = p_spell_id;

	SELECT 
        CASE spell_copy.atribute_to_use
            WHEN 'int' THEN char_copy.intelligence
            WHEN 'stg' THEN char_copy.strength
            WHEN 'dex' THEN char_copy.dexterity
            WHEN 'cos' THEN char_copy.constitution
        END
    INTO atribute_value;

	IF char_copy.item_equipped IS NOT NULL 
	AND spell_copy.eff_category =  (
		SELECT eff_category FROM item WHERE item_ID = char_copy.item_equipped
		LIMIT 1
		)
		THEN 
			SELECT cost_factor INTO i_cost_reduct
			FROM item WHERE item_ID = char_copy.item_equipped;
			
			
	ELSIF char_copy.off_hand_item IS NOT NULL 
	AND spell_copy.eff_category =  (
		SELECT eff_category FROM item WHERE item_ID = char_copy.off_hand_item
		LIMIT 1
		)
		THEN 
			SELECT cost_factor INTO i_cost_reduct
			FROM item WHERE item_ID = char_copy.off_hand_item;
			
			
	ELSE i_cost_reduct:= 1;
	
	END IF;

	v_effective_cost := FLOOR((30 - atribute_value) * spell_copy.base * i_cost_reduct);

	RETURN v_effective_cost;
	
END ;
$$ LANGUAGE plpgsql ;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION f_effective_spell_effect (
	p_spell_id INT,
	p_caster_id INT,
	dice_roll INT
) RETURNS INT AS $$
DECLARE 
	v_effect NUMERIC;
	char_copy RECORD;
	spell_copy RECORD;
	item_copy RECORD;
	atribute_value INT;
	item_modifier INT;
BEGIN
	SELECT * INTO char_copy
	FROM character WHERE character_ID = p_caster_id;

	SELECT * INTO spell_copy
	FROM spell WHERE spell_ID = p_spell_id;

	SELECT 
        CASE spell_copy.atribute_to_use
            WHEN 'int' THEN char_copy.intelligence
            WHEN 'stg' THEN char_copy.strength
            WHEN 'dex' THEN char_copy.dexterity
            WHEN 'cos' THEN char_copy.constitution
        END
    INTO atribute_value;

	IF char_copy.item_equipped IS NOT NULL
	AND char_copy.class_ID = (
		SELECT pref_class FROM item WHERE item_ID = char_copy.item_equipped
		LIMIT 1
		)
	AND spell_copy.eff_category =  (
		SELECT eff_category FROM item WHERE item_ID = char_copy.item_equipped
		LIMIT 1
		)
		THEN 
			SELECT * INTO item_copy
			FROM item WHERE item_ID = char_copy.item_equipped;

			item_modifier := item_copy.eff_factor + item_copy.rarity - 1;
			
			
	ELSIF char_copy.off_hand_item IS NOT NULL 
	AND char_copy.class_ID = (
		SELECT pref_class FROM item WHERE item_ID = char_copy.off_hand_item
		LIMIT 1
		)
	AND spell_copy.eff_category =  (
		SELECT eff_category FROM item WHERE item_ID = char_copy.off_hand_item
		LIMIT 1
		)
		THEN 
			SELECT * INTO item_copy
			FROM item WHERE item_ID = char_copy.off_hand_item;
			
			item_modifier := item_copy.eff_factor + item_copy.rarity - 1;
			
			
	ELSE item_modifier:= 1;

	END IF;
	
	v_effect:= FLOOR(((dice_roll) / 2) + atribute_value) * spell_copy.base * item_modifier * ((char_copy.head_bounty / 500)+1);
	
	RETURN v_effect;
END ;
$$ LANGUAGE plpgsql ;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_action_number()
RETURNS INT AS $$
DECLARE
    new_an INT;
    active_combat INT;
BEGIN
    SELECT combat_ID INTO active_combat
    FROM combat 
    WHERE is_active = TRUE
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active combat exists';
    END IF;

    SELECT COALESCE(MAX(action_num), 0) INTO new_an
    FROM actions
    WHERE combat_ID = active_combat;
    
    RETURN new_an + 1;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION apply_effect(
    eff_name TEXT,
    p_curr_ap INT,
    ap_cost INT,
    t_ac INT,
    dice_roll INT,
    total_effect INT,
    p_target_ID INT,
    p_caster_ID INT,
    p_spell_ID INT,
    t_max_health INT,
    combat_id INT,
    round_id INT,
	new_action_number INT
)
RETURNS VOID AS $$
BEGIN
    IF eff_name != 'HEALING' THEN
		RAISE NOTICE 'not a heal';
        IF p_curr_ap > ap_cost THEN
			
			RAISE NOTICE 'enough AP, cost %',ap_cost;
			
            IF t_ac < dice_roll AND (SELECT health FROM character WHERE character_ID = p_target_ID) != 0 THEN
                UPDATE character
                SET health = GREATEST(0, health - total_effect)
                WHERE character_ID = p_target_ID;

                INSERT INTO actions (
                    combat_id, round_id, target, actor, used_spell,
                    action_type, action_num, is_success, eff_dealt,
                    ap_cost, dice_roll
                ) VALUES (
                    combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                    'cast', new_action_number , TRUE, total_effect,
                    ap_cost, dice_roll
                );

                UPDATE character
                SET action_points = action_points - ap_cost
                WHERE character_ID = p_caster_ID;

				IF (SELECT health FROM character WHERE character_ID = p_target_ID)
				= 0 
				
				THEN

					UPDATE character
					SET money_bag = money_bag + (SELECT head_bounty FROM character WHERE character_ID = p_target_ID),
						head_bounty = LEAST(100, head_bounty + 10)
					WHERE character_ID = p_caster_ID;

					UPDATE inventory
					SET owner_ID = combat_id,
						inv_description = 'cmb'
					WHERE owner_ID = p_target_ID
					AND inv_description = 'ply';

					UPDATE character
					SET curr_inv_state = 0,
						item_equipped = NULL,
						off_hand_item = NULL
					WHERE character_ID = p_target_ID;

    				DELETE FROM spell_inventory
    				WHERE character_ID = p_target_ID;
					

					RAISE NOTICE '% was killed by % from %',
					  (SELECT character_name FROM character WHERE character_ID = p_target_ID),
					  (SELECT spell_name FROM spell WHERE spell_ID = p_spell_ID),
					  (SELECT character_name FROM character WHERE character_ID = p_caster_ID);
				
				END IF;

            ELSE
                INSERT INTO actions (
                    combat_id, round_id, target, actor, used_spell,
                    action_type, action_num, is_success, eff_dealt,
                    ap_cost, dice_roll
                ) VALUES (
                    combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                    'cast', new_action_number, FALSE, total_effect,
                    ap_cost, dice_roll
                );

                UPDATE character
                SET action_points = action_points - ap_cost
                WHERE character_ID = p_caster_ID;
            END IF;
        ELSE
			RAISE NOTICE 'not enough AP, cost %',ap_cost;
            INSERT INTO actions (
                combat_id, round_id, target, actor, used_spell,
                action_type, action_num, is_success, eff_dealt,
                ap_cost, dice_roll
            ) VALUES (
                combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                'cast',  new_action_number, FALSE, total_effect,
                ap_cost, dice_roll
            );
        END IF;
    ELSE

		RAISE NOTICE 'its a heal';
		
        IF p_curr_ap > ap_cost THEN
            IF t_ac < dice_roll AND (SELECT health FROM character WHERE character_ID = p_target_ID) != 0 THEN
                
				
				UPDATE character
                SET health = LEAST(t_max_health, health + total_effect)
                WHERE character_ID = p_target_ID;

                INSERT INTO actions (
                    combat_id, round_ID, target, actor, used_spell,
                    action_type, action_num, is_success, eff_dealt,
                    ap_cost, dice_roll
                ) VALUES (
                    combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                    'cast',  new_action_number, TRUE, total_effect,
                    ap_cost, dice_roll
                );

                UPDATE character
                SET action_points = action_points - ap_cost
                WHERE character_ID = p_caster_ID;
            ELSE
                INSERT INTO actions (
                    combat_id, round_id, target, actor, used_spell,
                    action_type, action_num, is_success, eff_dealt,
                    ap_cost, dice_roll
                ) VALUES (
                    combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                    'cast',  new_action_number, FALSE, total_effect,
                    ap_cost, dice_roll
                );

                UPDATE character
                SET action_points = action_points - ap_cost
                WHERE character_ID = p_caster_ID;
            END IF;
        ELSE
            INSERT INTO actions (
                combat_id, round_id, target, actor, used_spell,
                action_type, action_num, is_success, eff_dealt,
                ap_cost, dice_roll
            ) VALUES (
                combat_id, round_id, p_target_ID, p_caster_ID, p_spell_ID,
                'cast',  new_action_number, FALSE, total_effect,
                ap_cost, dice_roll
            );
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sp_cast_spell (
    p_caster_ID INT,
    p_target_ID INT,
    p_spell_ID INT
) RETURNS VOID AS $$
DECLARE
    total_effect INT;
    s_is_aoe BOOLEAN;
    s_eff_name TEXT;
    p_curr_ap INT;
    t_ac INT;
    t_max_health INT;
    ap_cost INT;
    target_ids INT;
    dice_roll INT;
	p_combat_id INT;
    p_round_id INT;
	p_new_action_number INT;
	p_health INT;
BEGIN
	SELECT combat_ID, round_ID INTO p_combat_id, p_round_id
	FROM character_combat_state WHERE character_ID = p_caster_ID
	ORDER BY character_state_ID DESC
	LIMIT 1;

	IF NOT FOUND THEN 
		RAISE EXCEPTION 'ERROR: You cannot cast spells outside the combat';
	END IF;
	
    IF NOT EXISTS (
        SELECT 1 
        FROM spell_inventory
        WHERE character_ID = p_caster_ID 
        AND spell_ID = p_spell_ID
        AND is_shop = FALSE
    ) THEN
        RAISE EXCEPTION 'Character does not own this spell';
    END IF;

    SELECT s.is_aoe, sc.category_name
    INTO s_is_aoe, s_eff_name
    FROM spell s
    JOIN spell_category sc ON s.eff_category = sc.category_ID
    WHERE s.spell_ID = p_spell_ID;
   
    dice_roll := FLOOR(1 + RANDOM() * 20);
    
    total_effect := f_effective_spell_effect(p_spell_id, p_caster_id, dice_roll);
    
    ap_cost := f_effective_spell_cost(p_spell_id, p_caster_id);
    
  
    SELECT armor_class, max_health 
    INTO t_ac, t_max_health
    FROM character
    WHERE character_ID = p_target_ID;

	SELECT action_points, health INTO p_curr_ap, p_health 
	FROM character WHERE character_ID = p_caster_id;

	IF p_health = 0 THEN
		RAISE NOTICE 'Dead spellcasting is forrbiden!';
		RETURN;
	END IF;

	SELECT new_action_number() INTO p_new_action_number;
     
    -- Apply effects
    IF s_is_aoe THEN
        PERFORM apply_effect(s_eff_name, p_curr_ap, ap_cost, t_ac, dice_roll,
                total_effect, p_target_ID, p_caster_ID, p_spell_ID, t_max_health,
                p_combat_id, p_round_id, p_new_action_number);
                
        FOR target_ids IN    
            SELECT character_ID
            FROM character_combat_state
            WHERE combat_ID = combat_id
            AND round_ID = round_id
            AND character_ID != p_caster_ID
            AND character_ID != p_target_ID
            LIMIT 2
        LOOP
			SELECT armor_class, max_health 
		    INTO t_ac, t_max_health
		    FROM character
		    WHERE character_ID = p_target_ID;
		
			SELECT action_points INTO p_curr_ap 
			FROM character WHERE character_ID = p_caster_id;
			
            PERFORM apply_effect(s_eff_name, p_curr_ap, ap_cost, t_ac, dice_roll,
                total_effect, target_ids, p_caster_ID, p_spell_ID, t_max_health,
                p_combat_id, p_round_id, p_new_action_number);
        END LOOP;
    ELSE 
        PERFORM apply_effect(s_eff_name, p_curr_ap, ap_cost, t_ac, dice_roll,
            total_effect, p_target_ID, p_caster_ID, p_spell_ID, t_max_health,
            p_combat_id, p_round_id, p_new_action_number);
    END IF;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------------------------

-- maybe i need to make it count the seconds between the round leave and enter so i ca calculate the exact health added
CREATE OR REPLACE FUNCTION sp_rest_character(
	c_character_id INT
)RETURNS VOID AS $$
DECLARE
	c_max_health INT;
	regen_value INT;
	curr_health INT;
	fled_at TIMESTAMP;
	p_class INT;
	seconds NUMERIC;
BEGIN
	SELECT max_health, regeneration, health, class_ID 
	INTO c_max_health, regen_value, curr_health, p_class
	FROM character WHERE character_ID = c_character_id;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'ERROR: character not found';
	END IF;

	IF c_max_health != curr_health AND curr_health != 0 THEN 
		SELECT time_stamp INTO fled_at 
		FROM actions WHERE action_type = 'flee'
		AND actor = c_character_id
		ORDER BY action_ID DESC
		LIMIT 1;

		SELECT EXTRACT(EPOCH FROM (NOW() - fled_at)) INTO seconds;

		UPDATE character
		SET health = LEAST((health + (seconds * regen_value)), c_max_health)
		WHERE character_ID = c_character_id;

		RAISE NOTICE 'HEALED BY TIME %', seconds * regen_value;

	END IF;

	UPDATE character
	SET action_points = (
		SELECT FLOOR((base_dex + base_int + 20) * ap_factor)
		FROM class
		WHERE class_ID = p_class
		LIMIT 1)
	WHERE character_ID = c_character_id;

END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sp_enter_combat (
    p_combat_id INT,
    p_character_id INT
) RETURNS VOID AS $$
DECLARE 
    p_round_ID INT;
    p_round_num INT;
    p_ap_factor NUMERIC(10,2);
    c_record RECORD;
BEGIN
    SELECT * INTO c_record FROM character WHERE character_ID = p_character_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Character with ID % not found', p_character_id;
    END IF;

    IF EXISTS (
        SELECT 1 
        FROM character_combat_state 
        WHERE character_ID = p_character_id 
        AND combat_ID IN (SELECT combat_ID FROM combat WHERE is_active = TRUE)
    ) THEN
        RAISE EXCEPTION 'Character is already in an active combat';
    END IF;

    IF EXISTS (
        SELECT 1 FROM combat WHERE combat_ID = p_combat_id AND is_active = TRUE
    ) THEN
        NULL; 
    ELSE
        RAISE NOTICE 'Specified combat not active or does not exist, looking for active combat';
        
        SELECT combat_ID INTO p_combat_id FROM combat WHERE is_active = TRUE LIMIT 1;
        
        IF NOT FOUND THEN
		
            INSERT INTO combat(is_active, combat_name)
            VALUES (TRUE, c_record.character_name || 's battle')
            RETURNING combat_ID INTO p_combat_id;
            
            RAISE NOTICE 'Created new combat: %', p_combat_id;
        ELSE
            RAISE NOTICE 'Joined existing active combat: %', p_combat_id;
        END IF;
    END IF;

    BEGIN
        SELECT round_ID, round_num
        INTO p_round_ID, p_round_num
        FROM rounds
        WHERE combat_ID = p_combat_id
        ORDER BY round_num DESC
        LIMIT 1;

        IF NOT FOUND THEN
            p_round_num := 1;
            INSERT INTO rounds (combat_ID, round_num)
            VALUES (p_combat_id, p_round_num)
            RETURNING round_ID INTO p_round_ID;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error handling rounds: %', SQLERRM;
    END; 

    IF EXISTS (
        SELECT 1
        FROM actions
        WHERE action_type = 'flee' AND combat_ID = p_combat_id 
		AND round_ID = p_round_ID AND actor = p_character_id
    ) THEN 
        RAISE EXCEPTION 'Cannot join combat - previous round is not over, please wait';
    END IF;
    
    PERFORM sp_rest_character(p_character_id);

	SELECT health INTO c_record.health 
	FROM character WHERE character_ID = p_character_id;

    INSERT INTO character_combat_state(
        character_ID, item_equipped, off_hand_item,
        combat_ID, round_ID, action_points, health, head_bounty, money_bag
    ) VALUES (
        p_character_id, 
        c_record.item_equipped, 
        c_record.off_hand_item,
        p_combat_id, 
        p_round_ID,
        c_record.action_points, 
        c_record.health, 
        c_record.head_bounty,
        c_record.money_bag
    );

    INSERT INTO actions(combat_ID, round_ID, actor, action_type, action_num, is_success)
    VALUES (p_combat_id, p_round_ID, p_character_id, 'join', new_action_number(), TRUE);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sp_loot_item (
	p_combat_id INT,
	p_character_id INT,
	p_item_id INT
) RETURNS VOID AS $$
DECLARE
	p_round_id INT;
	p_round_num INT;
	i_weight NUMERIC;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM inventory
		WHERE item_ID = p_item_id
		AND inv_description = 'cmb'
		AND owner_ID = p_combat_id)
		
		THEN
		
		    SELECT item_weight
		    INTO i_weight
		    FROM item
		    WHERE item_ID = p_item_id;

			SELECT round_ID, round_num
			        INTO p_round_ID, p_round_num
			        FROM rounds
			        WHERE combat_ID = p_combat_id
			        ORDER BY round_num DESC
			        LIMIT 1;
		
			IF (SELECT (max_cap_inv - curr_inv_state) 
			FROM character WHERE character_ID = p_character_id) 
			>= i_weight
		
			THEN

				IF (SELECT action_points FROM character 
				WHERE character_ID = p_character_id) >= ROUND(i_weight)
	
				THEN 
				
	
					UPDATE inventory
					SET owner_ID = p_character_id,
					    inv_description = 'ply'
					WHERE owner_ID = p_combat_id
					AND inv_description = 'cmb'
					AND item_ID = p_item_id;
		
					UPDATE character
					SET curr_inv_state = curr_inv_state + i_weight,
						action_points = action_points - ROUND(i_weight)
					WHERE character_ID = p_character_id;
		
					INSERT INTO actions(combat_ID, round_ID, target,
					actor, action_type, action_num, is_success, ap_cost)
					VALUES (p_combat_id, p_round_id, p_item_id, p_character_id,
					'pickup', new_action_number(), TRUE, ROUND(i_weight));
					
				ELSE
				
					INSERT INTO actions(combat_ID, round_ID, target,
					actor, action_type, action_num, is_success, ap_cost)
					VALUES (p_combat_id, p_round_id, p_item_id, p_character_id,
					'pickup', new_action_number(), FALSE, 0);
				
					RAISE NOTICE 'Not enough AP';
				
				END IF;
			
			ELSE 
				
				INSERT INTO actions(combat_ID, round_ID, target,
				actor, action_type, action_num, is_success, ap_cost)
				VALUES (p_combat_id, p_round_id, p_item_id, p_character_id,
				'pickup', new_action_number(), FALSE, 0);
			
				RAISE NOTICE 'Not enough space left';
			
			END IF;
 
		ELSE 
			
			RAISE EXCEPTION 'ERROR: item not found';
	
	END IF;			

END ;
$$ LANGUAGE plpgsql ;

--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sp_reset_round (
	p_combat_id INT
) RETURNS VOID AS $$
DECLARE
	n_round_ID INT;
	p_round_ID INT;
	p_round_num INT;
	ccs_record RECORD;
	c_record RECORD;
	sp_inv_record RECORD;
	inv_record RECORD;
BEGIN

	SELECT round_ID, round_num INTO p_round_ID, p_round_num
	FROM rounds WHERE combat_ID = p_combat_id
	ORDER BY round_num DESC
	LIMIT 1;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'ERROR: no round found - cant reset';
	END IF;

	INSERT INTO rounds(combat_ID, round_num)
	VALUES (p_combat_id, p_round_num + 1)
	RETURNING round_ID INTO n_round_ID;
	
	FOR ccs_record IN SELECT * FROM character_combat_state 
	WHERE combat_ID = p_combat_id AND round_ID = p_round_ID LOOP

		SELECT * FROM character INTO c_record
		WHERE character_ID = ccs_record.character_ID;

		IF c_record.health > 0 AND EXISTS (SELECT 1 FROM actions 
		WHERE action_type = 'end' AND combat_ID = p_combat_id 
		AND round_ID = p_round_ID)

			THEN

				UPDATE character
				SET action_points = (
					SELECT FLOOR((base_dex + base_int + 20) * ap_factor)
					FROM class
					WHERE class_ID = c_record.class_ID
					LIMIT 1)
				WHERE character_ID = c_record.character_ID;

				SELECT * FROM character INTO c_record
				WHERE character_ID = ccs_record.character_ID;
	
				INSERT INTO character_combat_state(
			        character_ID, item_equipped, off_hand_item,
			        combat_ID, round_ID, action_points, health, head_bounty, money_bag
			    ) VALUES (
			        ccs_record.character_ID, 
			        c_record.item_equipped, 
			        c_record.off_hand_item,
			        p_combat_id, 
			        n_round_ID,
			        c_record.action_points, 
			        c_record.health, 
			        c_record.head_bounty,
			        c_record.money_bag
			    );

				
				FOR sp_inv_record IN SELECT * FROM spell_inventory 
				WHERE character_ID = c_record.character_ID
				AND is_shop = FALSE LOOP
				
					INSERT INTO spell_state(combat_ID, round_ID, character_ID,
					spell_ID) VALUES (p_combat_id, n_round_id,
					sp_inv_record.character_ID, sp_inv_record.spell_ID);
				
				END LOOP;
		
		END IF;
	
	END LOOP;

	FOR inv_record IN SELECT * FROM inventory 
	WHERE inv_description IN('ply', 'cmb') LOOP

		INSERT INTO inventory_state(combat_ID, round_ID, inv_description,
		owner_ID, item_ID) VALUES (p_combat_ID, n_round_ID,
		inv_record.inv_description, inv_record.owner_ID, inv_record.item_ID);

	END LOOP;	
END ;
$$ LANGUAGE plpgsql ;

--------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_character (
	char_name TEXT ,
	class_name TEXT 
) RETURNS VOID AS $$
DECLARE
	copy_class RECORD;
	p_class_id INT;
BEGIN
	p_class_id := CASE class_name
		WHEN 'mage' THEN 1
		WHEN 'dwarf' THEN 2
		WHEN 'rouge' THEN 3
		WHEN 'knight' THEN 4
		WHEN 'paladin' THEN 5
		WHEN 'warlock' THEN 6
		ELSE NULL  
	END;

	SELECT * INTO copy_class
	FROM class
	WHERE class_ID = p_class_id;

	INSERT INTO character (
		class_ID, character_name, action_points, armor_class, health, max_health,
		strength, dexterity, intelligence, constitution, regeneration, max_cap_inv
	) VALUES (
		p_class_id, 
		char_name, 
		FLOOR((copy_class.base_dex + copy_class.base_int + 20) * copy_class.ap_factor),
		FLOOR(copy_class.base_dex * copy_class.ac_factor + 10), 
		100 + copy_class.base_hlt, 
		100 + copy_class.base_hlt,
		10 + copy_class.base_stg, 
		10 + copy_class.base_dex, 
		10 + copy_class.base_int, 
		10 + copy_class.base_cos,
		copy_class.base_reg, 
		FLOOR((copy_class.base_stg + copy_class.base_cos + 20) * copy_class.inv_factor)
	);
END ;
$$ LANGUAGE plpgsql ;