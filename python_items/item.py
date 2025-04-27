import random

random.seed(72)

item1 = ['dagger', 'shortsword', 'longsword', 'rapier', 'knife', 'spear', 'bow', 'crossbow', 'mace', 'hammer', 'flail', 'axe', 'shield']
adj1 = ['swift', 'gallant', 'blackstone', 'cursed', 'holy']

rarity = ['common', 'uncommon', 'rare', 'epic', 'legendary']

base_rar = {
    'common': 1.05,
    'uncommon': 1.1,
    'rare': 1.15,
    'epic': 1.2,
    'legendary': 1.25
}

item2 = ['wand', 'staff', 'orb', 'grimoire', 'pendant']
adj2 = ['arcane', 'holy', 'cursed']
nature = ['fire', 'water', 'earth', 'ice', 'lightning', 'healing']
eff_nature = [4, 5, 7, 6, 8, 9]

pref_class = {
    'swift': 3, #'rouge'
    'gallant': 4, #'knight'
    'blackstone': 2, #'dwarf'
    'cursed': 6, #'warlock'
    'holy': 5, #'paladin'
    'arcane': 1 #'mage'
}

base_weights = {
    'dagger': 1.0,
    'shortsword': 1.5,
    'longsword': 3.0,
    'rapier': 2.0,
    'knife': 0.5,
    'spear': 2.5,
    'bow': 1.8,
    'crossbow': 3.5,
    'mace': 3.2,
    'hammer': 4.0,
    'flail': 3.8,
    'axe': 3.0,
    'shield': 5.0,
    'wand': 0.5,
    'staff': 2.8,
    'orb': 1.0,
    'grimoire': 1.5,
    'pendant': 0.5
}
base_effects1 = {
    'dagger': 1,
    'shortsword': 1,
    'longsword': 1,
    'rapier': 2,
    'knife': 2,
    'spear': 2,
    'bow': 2,
    'crossbow': 2,
    'mace': 3,
    'hammer': 3,
    'flail': 3,
    'axe': 1,
    'shield': 3,
}
base_effects_val= {
    'dagger': 0.2,
    'shortsword': 0.3,
    'longsword': 0.35,
    'rapier': 0.2,
    'knife': 0.1,
    'spear': 0.3,
    'bow': 0.25,
    'crossbow': 0.35,
    'mace': 0.2,
    'hammer': 0.35,
    'flail': 0.30,
    'axe': 0.25,
    'shield': 0.1,
    'wand': 0.25,
    'staff': 0.35,
    'orb': 0.15,
    'grimoire': 0.2,
    'pendant': 0.1
}

index = 0
with open("items.csv", "w") as file:
    file.write("item_ID,item_name,item_weight,eff_category,eff_factor,cost_factor,rarity,sell_cost,pref_class\n")

    for rar in rarity:
        for adj in adj1:
            for item in item1:
                full_name = f"{rar} {adj} {item}"
                weight = f"{base_weights[item]:.1f}"
                effect_cat = f"{base_effects1[item]}"
                eff_factor = f"{base_effects_val[item]}"
                base_rarity = f"{base_rar[rar]}"
                random_value = random.randint(1, 15)
                money_cost = f"{int(base_rar[rar]*((base_weights[item] * 10) + (base_effects_val[item] * 500))) + random_value}"
                prf_class = f"{pref_class[adj]}"
                index+=1
                file.write(f"{index},"
                           f"{full_name},"
                           f"{weight},"
                           f"{effect_cat},"
                           f"{float(eff_factor) + 1},"
                           f"{float (eff_factor) + 0.5},"
                           f"{base_rarity},"
                           f"{money_cost},"
                           f"{prf_class}"
                           f"\n")
        for adj in adj2:
            for nat in nature:
                for item in item2:
                    full_name = f"{rar} {adj} {nat} {item}"
                    weight = f"{base_weights[item]:.1f}"
                    eff_factor = f"{base_effects_val[item]}"
                    base_rarity = f"{base_rar[rar]}"
                    random_value = random.randint(1, 15)
                    money_cost = f"{int(base_rar[rar] * ((base_weights[item] * 20) + (base_effects_val[item] * 500))) + random_value}"
                    prf_class = f"{pref_class[adj]}"
                    index+=1
                    file.write(f"{index},"
                               f"{full_name},"
                               f"{weight},"
                               f"{eff_nature[nature.index(nat)]},"
                               f"{float(eff_factor) + 1},"
                               f"{float (eff_factor) + 0.5},"
                               f"{base_rarity},"
                               f"{money_cost},"
                               f"{prf_class}"
                               f"\n")