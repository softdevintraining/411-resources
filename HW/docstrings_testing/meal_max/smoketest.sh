#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5000/api"

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

add_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal ($meal - $cuisine, $price) to the playlist..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisinse\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty}" | grep -q '"status": "success"'

  if [ $? -eq 0 ]; then
    echo "Meal added successfully."
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
  response=$(curl -s -X GET "$BASE_URL/get-meal--by-id/$meal_id")
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
  echo "Getting meal by meal name (Name: '$meal_name')..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name?meal=$(echo $meal_name | sed 's/ /%20/g')")
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

add_song_to_playlist() {
  artist=$1
  title=$2
  year=$3

  echo "Adding song to playlist: $artist - $title ($year)..."
  response=$(curl -s -X POST "$BASE_URL/add-song-to-playlist" \
    -H "Content-Type: application/json" \
    -d "{\"artist\":\"$artist\", \"title\":\"$title\", \"year\":$year}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song added to playlist successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Song JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to add song to playlist."
    exit 1
  fi
}

clear_combatants() {
  echo "Removing combatants from battle..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Playlist cleared successfully."
  else
    echo "Failed to clear playlist."
    exit 1
  fi
}


############################################################
#
# Leaderboard
#
############################################################

get_leadboard() {
  echo "Retrieving meal leaderboard..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard")

  if echo "$response" | grep -q '"status": "success"'; then
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON:"
      echo "$response" | jq .
  fi  
  else
    echo "Failed to retrieve meal leaderboard."
    exit 1
  fi
}

############################################################
#
# Arrange Playlist
#
############################################################

move_song_to_beginning() {
  artist=$1
  title=$2
  year=$3

  echo "Moving song ($artist - $title, $year) to the beginning of the playlist..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-beginning" \
    -H "Content-Type: application/json" \
    -d "{\"artist\": \"$artist\", \"title\": \"$title\", \"year\": $year}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to the beginning successfully."
  else
    echo "Failed to move song to the beginning."
    exit 1
  fi
}

move_song_to_end() {
  artist=$1
  title=$2
  year=$3

  echo "Moving song ($artist - $title, $year) to the end of the playlist..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-end" \
    -H "Content-Type: application/json" \
    -d "{\"artist\": \"$artist\", \"title\": \"$title\", \"year\": $year}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to the end successfully."
  else
    echo "Failed to move song to the end."
    exit 1
  fi
}

move_song_to_track_number() {
  artist=$1
  title=$2
  year=$3
  track_number=$4

  echo "Moving song ($artist - $title, $year) to track number ($track_number)..."
  response=$(curl -s -X POST "$BASE_URL/move-song-to-track-number" \
    -H "Content-Type: application/json" \
    -d "{\"artist\": \"$artist\", \"title\": \"$title\", \"year\": $year, \"track_number\": $track_number}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song moved to track number ($track_number) successfully."
  else
    echo "Failed to move song to track number ($track_number)."
    exit 1
  fi
}

swap_songs_in_playlist() {
  track_number1=$1
  track_number2=$2

  echo "Swapping songs at track numbers ($track_number1) and ($track_number2)..."
  response=$(curl -s -X POST "$BASE_URL/swap-songs-in-playlist" \
    -H "Content-Type: application/json" \
    -d "{\"track_number_1\": $track_number1, \"track_number_2\": $track_number2}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Songs swapped successfully between track numbers ($track_number1) and ($track_number2)."
  else
    echo "Failed to swap songs."
    exit 1
  fi
}

######################################################
#
# Leaderboard
#
######################################################

# Function to get the song leaderboard sorted by play count
get_song_leaderboard() {
  echo "Getting song leaderboard sorted by play count..."
  response=$(curl -s -X GET "$BASE_URL/song-leaderboard?sort=play_count")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Song leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by play count):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get song leaderboard."
    exit 1
  fi
}


# Health checks
check_health
check_db

# Clear the catalog
clear_catalog

# Create songs
create_song "The Beatles" "Hey Jude" 1968 "Rock" 180
create_song "The Rolling Stones" "Paint It Black" 1966 "Rock" 180
create_song "The Beatles" "Let It Be" 1970 "Rock" 180
create_song "Queen" "Bohemian Rhapsody" 1975 "Rock" 180
create_song "Led Zeppelin" "Stairway to Heaven" 1971 "Rock" 180

delete_song_by_id 1
get_all_songs

get_song_by_id 2
get_song_by_compound_key "The Beatles" "Let It Be" 1970
get_random_song

clear_playlist

add_song_to_playlist "The Rolling Stones" "Paint It Black" 1966
add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
add_song_to_playlist "Led Zeppelin" "Stairway to Heaven" 1971
add_song_to_playlist "The Beatles" "Let It Be" 1970

remove_song_from_playlist "The Beatles" "Let It Be" 1970
remove_song_by_track_number 2

get_all_songs_from_playlist

add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
add_song_to_playlist "The Beatles" "Let It Be" 1970

move_song_to_beginning "The Beatles" "Let It Be" 1970
move_song_to_end "Queen" "Bohemian Rhapsody" 1975
move_song_to_track_number "Led Zeppelin" "Stairway to Heaven" 1971 2
swap_songs_in_playlist 1 2

get_all_songs_from_playlist
get_song_from_playlist_by_track_number 1

get_playlist_length_duration

play_current_song
rewind_playlist

play_entire_playlist
play_current_song
play_rest_of_playlist

get_song_leaderboard

echo "All tests passed successfully!"
