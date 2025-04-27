-- Inventory indexes
CREATE INDEX IF NOT EXISTS index_inventory_search
ON inventory (inv_description, owner_ID, item_ID);

CREATE INDEX IF NOT EXISTS index_inventory_description
ON inventory (inv_description);

-- Item indexes
CREATE INDEX IF NOT EXISTS index_item_item_id
ON item (item_ID);

-- Rounds indexes
CREATE INDEX IF NOT EXISTS index_rounds_combat_roundnum
ON rounds (combat_ID, round_num DESC);

-- Character indexes
CREATE INDEX IF NOT EXISTS index_character_character_id
ON character (character_ID);

-- Spell indexes
CREATE INDEX IF NOT EXISTS index_spell_spell_id
ON spell (spell_ID);

-- Character Combat State indexes
CREATE INDEX IF NOT EXISTS index_character_combat_state_search
ON character_combat_state (character_ID, combat_ID, round_ID);

-- Combat indexes
CREATE INDEX IF NOT EXISTS index_combat_active
ON combat (is_active)
WHERE is_active = TRUE;

-- Actions indexes
CREATE INDEX IF NOT EXISTS index_actions_flee_actor
ON actions (actor, action_type, combat_ID, round_ID);

CREATE INDEX IF NOT EXISTS index_actions_combat_round_type
ON actions (combat_ID, round_ID, action_type);

-- Class indexes
CREATE INDEX IF NOT EXISTS index_class_class_id
ON class (class_ID);

-- Spell Inventory indexes
CREATE INDEX IF NOT EXISTS index_spell_inventory_char_shop
ON spell_inventory (character_ID, is_shop);