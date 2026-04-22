# rpg-combat-data-model
FIIT STU-DBS 2. Assignment;  Data Modelling for a Turn-Based RPG Combat System  

 &

FIIT STU-DBS 3. Assignment; Implementation of Data Model in PostgreSQL

# RPG Combat System (PostgreSQL)

Database-driven RPG combat system implemented in PostgreSQL, focused on complex game logic, relational modeling, and performance optimization.

## Overview

This project implements a turn-based RPG system where core gameplay mechanics are handled directly in the database. It demonstrates how relational databases can be used not only for storage, but also for executing non-trivial application logic such as combat resolution, spell evaluation, and state management.

The system supports characters, spells, items, combat sessions, and dynamic action processing.

## Core Concepts

### Data Model

The system is built around a normalized relational schema with the following key entities:

* `character` – player entity with attributes
* `class` – defines character specialization
* `spell` – abilities used in combat (damage or healing)
* `item` – objects affecting character attributes
* `inventory` – relationship between characters and items
* `spell_inventory` – relationship between characters and spells
* `combat` – active or completed battles
* `rounds` – turn-based progression of combat
* `actions` – log of all actions performed during combat

### State Management

To support complex combat scenarios, the system uses snapshot tables:

* `character_combat_state`
* `inventory_state`
* `spell_state`

These tables store temporary state during combat, enabling rollback, simulation, and consistent state transitions.

## Game Logic (Implemented in SQL)

The system uses PostgreSQL functions and procedures to implement core mechanics:

* `f_effective_spell_cost` – calculates dynamic action point cost of spells
* `f_effective_spell_effect` – computes final damage or healing value
* `sp_cast_spell` – executes spell casting logic
* `sp_rest_character` – handles regeneration outside combat
* `sp_enter_combat` – initializes combat participation
* `sp_loot_item` – processes item acquisition
* `sp_reset_round` – advances combat rounds and resets action points

## Mechanics

### Combat

* Turn-based system with rounds
* Action points (AP) determine available actions
* All actions are recorded in the `actions` table

### Spell System

* Supports both offensive and healing spells
* Effects depend on:

  * character attributes
  * item modifiers
  * randomness (dice roll)
  * scaling factors

### Regeneration

* Characters regenerate health outside combat
* Regeneration is computed using timestamps stored in the `actions` table

## Performance Considerations

Indexes are applied to optimize queries on large tables, including:

* combat activity filtering
* action lookup by combat and round
* inventory and item search
* character state retrieval

Examples:

* composite indexes on `(combat_ID, round_ID)`
* filtered index on active combats
* search indexes for inventory and actions

## Example Computations

The system includes non-trivial formulas for gameplay balancing, such as:

* dynamic spell cost based on attributes and modifiers
* damage calculation using base values, randomness, and scaling factors
* derived attributes like maximum action points and inventory capacity

## Project Structure

The project is organized as a set of SQL scripts:

* `table_creation.sql` – schema definition
* `table_filling.sql` – static data initialization
* `items.sql` – item data population
* `indexes.sql` – index definitions
* `functions_procedures.sql` – core logic
* `views.sql` – helper views
* `simulation.sql` – combat simulation
* `tests.sql` – test cases

## How to Run

Execute the scripts in the following order:

1. `table_creation.sql`
2. `table_filling.sql`
3. `items.sql`
4. `indexes.sql`
5. `functions_procedures.sql`
6. `views.sql`
7. `simulation.sql`
8. `tests.sql`

The simulation script supports:

* full combat execution
* partial simulation (stops at round 10 for analysis)

## What This Project Demonstrates

* Advanced relational database design
* Implementation of application logic in SQL
* Handling of complex state transitions
* Performance optimization using indexing
* System-level thinking beyond basic CRUD operations

## Limitations and Future Work

* No API or application layer (database-only system)
* No user interface
* Limited validation outside database constraints

Possible extensions:

* REST API layer (e.g. Spring, Node.js, Kotlin)
* frontend or Android client
* additional spell effects (buffs, debuffs)
* multiplayer support
