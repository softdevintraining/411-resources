#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5002/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done


###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}


##########################################################
#
# Meal Management
#
##########################################################

clear_catalog() {
  echo "Clearing the playlist..."
  curl -s -X DELETE "$BASE_URL/clear-meals" | grep -q '"status": "success"'
}

create_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal ($meal - $cuisine, $price, $difficulty) to the database..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}" | grep -q '"status": "success"'
    
  if [ $? -eq 0 ]; then
    echo "Meal added successfully!!!"
  else
    echo "Failed to add meal."
    exit 1
  fi
}

delete_meal() {
  meal_id=$1

  echo "Deleting meal by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to delete meal by ID ($meal_id)."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id=$1

  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal)."
    exit 1
  fi
}

get_meal_by_name() {
  meal_name=$1
  meal=$(echo $meal_name | sed 's/ /%20/g')
  echo "$BASE_URL/get-meal-by-name/$meal"

  echo "Getting meal by meal name (Name: $meal_name)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name/$meal")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by name."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (by name):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by name."
    exit 1
  fi
}


############################################################
#
# Battle Management
#
############################################################
battle() {
  echo "Starting battle with prepped combatants"
  response=$(curl -s -X GET "$BASE_URL/battle")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "$response" | jq .
  else
    echo "Failed to start battle."
    echo "$response" | jq .
    exit 1
  fi
}

prep_combatant() {
  meal=$1

  echo "Prepping $meal for battle..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal successfully prepped for battle."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to prep meal for battle."
    exit 1
  fi
}

clear_combatants() {
  echo "Removing combatants from battle..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants cleared successfully."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}

get_combatants() {
  echo "Getting combatant meals..."
  response=$(curl -s -X GET "$BASE_URL/get-combatants")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatant meals retrieved successfully."
    echo "$response" | jq .
  else
    echo "Failed to get battle combatants."
    exit 1
  fi
}

############################################################
#
# Leaderboard
#
############################################################

get_leaderboard() {
  sort_by=$1
  echo $(echo $sort_by | sed 's/ /%20/g')

  echo "Retrieving meal leaderboard..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard?sort=$(echo $sort_by | sed 's/ /%20/g')")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "$response" | jq .
  else
    echo "Failed to retrieve meal leaderboard."
    exit 1
  fi
}


# Health checks
check_health
check_db

# Clear the catalog
clear_catalog
clear_combatants

# get meals and battle combatants, should both be empty
#get_leaderboard
#get_combatants

# Add meals to db
create_meal "Meal" "Cuisine 1" 1.00 "LOW"
create_meal "Meal 2" "Cuisine 2" 2.00 "MED"
create_meal "Meal 3" "Cuisine 3" 3.00 "LOW"
create_meal "Meal 4" "Cuisine 4" 4.00 "HIGH"

# delete meal 1, should now show meals 2-4
delete_meal 1 
get_leaderboard "wins"

# should get meal 2, then meal 4
get_meal_by_id 2
get_meal_by_name 'Meal 3'

# clear catalog again
clear_catalog

# Add meals to db again
create_meal "Meal 1" "Cuisine 1" 1.00 "LOW"
create_meal "Meal 2" "Cuisine 2" 2.00 "MED"
create_meal "Meal 3" "Cuisine 3" 3.00 "LOW"
create_meal "Meal 4" "Cuisine 4" 4.00 "HIGH"

# prep meals 1 and 2 for battle, should show both in combatants list
prep_combatant "Meal 1"
prep_combatant "Meal 2"
get_combatants

# simulate a battle, then clear. repeat
battle
clear_combatants

prep_combatant "Meal 1"
prep_combatant "Meal 3"
battle
clear_combatants

prep_combatant "Meal 1"
prep_combatant "Meal 4"
battle
clear_combatants

prep_combatant "Meal 2"
prep_combatant "Meal 3"
battle
clear_combatants


get_leaderboard "wins"

get_leaderboard "win_pct"

# remove all combatants from battle
clear_combatants
get_combatants

echo "All tests passed successfully!"
