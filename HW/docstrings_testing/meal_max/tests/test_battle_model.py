import pytest

from meal_max.models.battle_model import BattleModel
from meal_max.models.kitchen_model import Meal

@pytest.fixture()
def battle_model():
    """Fixture to provide a new instance of BattleModel for each test."""
    return BattleModel()

@pytest.fixture
def mock_update_meal_stats(mocker):
    """Mock the update_meal_stats function for testing purposes."""
    return mocker.patch("meal_max.models.battle_model.update_meal_stats")

"""Fixtures providing sample meals for the tests."""
@pytest.fixture
def sample_meal1():
    return Meal(1, 'Meal 1', 'Cuisine 1', 20.0, 'MED')

@pytest.fixture
def sample_meal2():
    return Meal(2, 'Meal 2', 'Cuisine 2', 15.0, 'LOW')

@pytest.fixture
def sample_battle(sample_meal1, sample_meal2):
    return [sample_meal1, sample_meal2]

##################################################
# Testing Battle 
##################################################

def test_battle(battle_model, sample_battle):
    """Test a battle of 2 meals."""
    battle_model.combatants.extend(sample_battle)
    assert len(battle_model.combatants) == 2
    assert battle_model.combatants[0].meal == 'Meal 1'
    assert battle_model.combatants[1].meal == 'Meal 2'

##################################################
# Remove Combatants Management Test Cases
##################################################

def test_clear_combatants(battle_model, sample_battle):
    """Test removing the combatants from battle."""
    battle_model.combatants.extend(sample_battle)
    assert len(battle_model.combatants) == 2

    battle_model.clear_combatants()
    assert len(battle_model.combatants) == 0, f"Expected 0 combatants, but got {len(battle_model.combatants)}"

##################################################
# Battle Management Test Cases
##################################################
def test_prep_combatant(battle_model, sample_meal1):
    """Test adding a meal to the battle."""
    battle_model.prep_combatant(sample_meal1)
    assert len(battle_model.combatants) == 1
    assert battle_model.combatants[0].meal == 'Meal 1'

def test_get_battle_score(battle_model, sample_battle):
    """Test getting the battle score of a given meal."""
    battle_model.combatants.extend(sample_battle)
    assert len(battle_model.combatants) == 2

    # Get battle score of first meal
    result1 = battle_model.get_battle_score(battle_model.combatants[0])

    # Get battle score of second meal
    result2 = battle_model.get_battle_score(battle_model.combatants[1])

    assert isinstance(result1, float), "Expected result1 to be of type float"
    assert isinstance(result2, float), "Expected result2 to be of type float"

##################################################
# Meal Retrieval Test Cases
##################################################
    
def test_get_combatants(battle_model, sample_battle):
    """Test getting the current combatants in battle"""
    battle_model.combatants.extend(sample_battle)

    retrieved_combatants = battle_model.get_combatants()
    assert len(retrieved_combatants) == 2
    assert retrieved_combatants[0].id == 1
    assert retrieved_combatants[1].id == 2
