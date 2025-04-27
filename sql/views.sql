CREATE OR REPLACE VIEW v_combat_state AS
SELECT *
FROM character 
WHERE character_ID IN (
    SELECT character_ID 
    FROM character_combat_state 
    WHERE combat_ID = (
        SELECT combat_ID 
        FROM combat 
        WHERE is_active = TRUE
    )
    AND round_ID = (
        SELECT MAX(round_ID) 
        FROM rounds 
        WHERE combat_ID = (
            SELECT combat_ID 
            FROM combat 
            WHERE is_active = TRUE
        )
    )
);


CREATE OR REPLACE VIEW v_most_damage AS
SELECT SUM(eff_dealt) as total_damage, actor, combat_ID FROM 
	(SELECT eff_dealt, actor, combat_ID FROM actions WHERE is_success = TRUE 
	AND action_type = 'cast'
	AND used_spell NOT IN(20,19)
	ORDER BY combat_ID ASC, actor ASC)
GROUP BY actor, combat_ID
ORDER BY total_damage DESC;


CREATE OR REPLACE VIEW v_strongest_character AS
	SELECT character_ID, character_name, head_bounty, money_bag, health, total_damage FROM character
		JOIN (SELECT SUM(eff_dealt) as total_damage, actor, combat_ID FROM 
			(SELECT eff_dealt, actor, combat_ID FROM actions WHERE is_success = TRUE 
			AND action_type = 'cast'
			AND used_spell NOT IN(20,19)
			ORDER BY combat_ID ASC, actor ASC)
			GROUP BY actor, combat_ID
			ORDER BY total_damage DESC) ON character_ID = actor
		WHERE health != 0
	ORDER BY total_damage DESC, health DESC, head_bounty DESC, money_bag DESC;


CREATE OR REPLACE VIEW v_combat_damage AS
	SELECT SUM(eff_dealt) FROM actions WHERE is_success = TRUE 
	AND action_type = 'cast'
	AND used_spell NOT IN(20,19);


CREATE OR REPLACE VIEW v_spell_statistics AS
	SELECT spell_ID, effect, success_rate FROM 
		(SELECT SUM(eff_dealt) as effect, used_spell as spell_id  FROM 
			(SELECT eff_dealt, used_spell FROM actions
			WHERE action_type = 'cast'
			AND is_success = TRUE)
		GROUP BY spell_id)
	JOIN 
		(SELECT (ROUND(((COUNT(*) FILTER (WHERE is_success = TRUE)::NUMERIC /  COUNT(*) FILTER (WHERE action_type =  'cast'))::NUMERIC), 2)) AS success_rate, used_spell
		FROM actions
		WHERE action_type = 'cast'
		GROUP BY used_spell)
	ON spell_ID = used_spell
	ORDER BY effect DESC, success_rate ASC;

-- SELECT * FROM v_most_damage;
-- SELECT * FROM v_combat_damage;
-- SELECT * FROM v_spell_statistics;

-- SELECT * FROM v_combat_state;
-- SELECT * FROM v_strongest_character;