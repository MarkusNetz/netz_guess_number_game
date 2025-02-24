#!/bin/bash


#
# Variables
#

db_name="number_guess"
readonly PSQL="mysql --login-path=number_guess number_guess -se"
number_of_guesses=0


#
# Functions
#

setup_game_db(){
  # CREATE DATABASE number_guess ;
  $PSQL "CREATE TABLE if not exists players (player_id SERIAL PRIMARY KEY, name VARCHAR(30) NOT NULL, REGISTERED DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP);"
  $PSQL "CREATE TABLE if not exists games (game_id SERIAL PRIMARY KEY, player_id bigint unsigned NOT NULL, winning_number smallint unsigned NOT NULL, total_guesses smallint unsigned NOT NULL, difficulty ENUM('easy','intermediate','hard') NOT NULL DEFAULT 'easy', finished_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP);"
}

select_language() {

  echo ":: Select language | Välj språk ::"
  echo " 1) English / Engelska"
  echo " 2) Svenska / Swedish"

  read input_lang

  if [[ "${input_lang}" -eq 1 ]]; then
    lang="en"
  elif [[ "${input_lang}" -eq 2 ]]; then
    lang="sv"
  else
    echo "Using english by default"
    lang="en"
  fi
}

select_difficulty() {

  echo ":: $prompt_diff_header ::"
  echo "$prompt_diff_1"
  echo "$prompt_diff_2"
  echo "$prompt_diff_3"
  echo "$prompt_diff_4"

  read input_difficulty

  if [[ "${input_difficulty}" -eq 1 ]]; then
    difficulty="easy"
    readonly min_secret_value=1
    readonly max_secret_value=1000
  elif [[ "${input_difficulty}" -eq 2 ]]; then
    difficulty="intermediate"
    readonly min_secret_value=1
    readonly max_secret_value=3333
  elif [[ "${input_difficulty}" -eq 3 ]]; then
    difficulty="hard"
    readonly min_secret_value=1
    readonly max_secret_value=127
  elif [[ "${input_difficulty}" -eq 4 ]]; then
    difficulty="impossible"
    readonly min_secret_value=100
    readonly max_secret_value=1000000
  else
    echo "Invalid choice - defaulting to easy"
    echo ${prompt_diff_value_error}
    readonly min_secret_value=1
    readonly max_secret_value=1000
  fi
}


prompt_user_guess() {

  unset_guess

  while [[ -z "${USER_GUESS}" ]]; do
    read USER_GUESS
    if ! [[ "${USER_GUESS}" =~ ^[0-9]+$ ]]; then
      echo $nan_guess
      unset_guess
    elif [[ "${USER_GUESS}" -gt "${max_secret_value}" ]]; then
      echo $too_high_guess
	    unset_guess
    elif [[ "${USER_GUESS}" -lt "${min_secret_value}" ]]; then
      echo $too_low_guess
      unset_guess
    fi
  done

  number_of_guesses=$((number_of_guesses + 1 ))

}

unset_guess() {
  unset USER_GUESS
}

game_on() {

  prompt_user_guess
  
  if [[ "${USER_GUESS}" -eq "${secret_number}" ]]; then
    ins=$( $PSQL "INSERT INTO games (player_id, winning_number, total_guesses, difficulty) VALUES ((SELECT player_id FROM players WHERE name = '${USERNAME}'), '${secret_number}', '${number_of_guesses}', '${difficulty}' ) ;")
  elif [[ "${USER_GUESS}" -gt "${secret_number}" ]]; then
    print_guess_help $lower_guess
    game_on
  elif [[ "${USER_GUESS}" -lt "${secret_number}" ]]; then
    print_guess_help $higher_guess
    game_on
  fi
}

print_guess_help() {
  msg=$*

  if [[ $difficulty == "hard" ]]; then
    if [[ ${USER_GUESS} -ge ${calculated_lower} ]] && [[ ${USER_GUESS} -le ${calculated_higher} ]]; then
      msg=$prompt_hard_closer
    elif [[ ${USER_GUESS} -gt ${calculated_low} ]] && [[ ${USER_GUESS} -lt ${calculated_high} ]]; then
      msg=$prompt_hard_close
    else
      msg=$prompt_hard_wrong
    fi
  fi
  msg="$msg ($number_of_guesses)"
  echo $msg
}

set_prompts() {

  selected_lang=$1
  if [[ "${selected_lang}" != "en" ]] && [[ "${selected_lang}" != "sv" ]]; then
    selected_lang="en"
  fi

  if [[ "${selected_lang}" == "en" ]]; then
    prompt_diff_header="Select difficulty"
    prompt_diff_value_error="Invalid choice - defaulting to easy"
    prompt_lang_value_error="Invalid choice - defaulting to English"
    prompt_diff_1=" 1) Easy         (1 - 1 000)"
    prompt_diff_2=" 2) Intermediate (1 - 3 333)"
    prompt_diff_3=" 3) Hard         (1 - 127, with no help)"
    prompt_diff_4=" 4) Impossible?  (?? - ??, with absolutely no help)"
    prompt_username="Enter your username"
    prompt_new_user_1="Welcome, "
    prompt_new_user_2="! It looks like this is your first time here."
    prompt_returning_user_1="Welcome back, "
    prompt_returning_user_2="! You have played "
    prompt_returning_user_3=" games, and your best game took "
    prompt_returning_user_4=" guesses."
    prompt_guess_start_1="Guess the secret number between ${min_secret_val} and ${max_secret_value}"
    prompt_guess_start_2="and"
    nan_guess="That is not a number, guess again:"
    lower_guess="It's lower than that, guess again:"
    higher_guess="It's higher than that, guess again:"
    too_high_guess="Your guess is too high, guess again:"
    too_low_guess="Your guess is too low, guess again:"
    prompt_game_finished_1="You guessed it in"
    prompt_game_finished_2="tries. The secret number was"
    prompt_game_finished_3=". Nice job!"
    prompt_game_finished_superb="Extra-ordinary performance!"
    prompt_hard_wrong="Mohahahaha.... Incorrect, guess again:"
    prompt_hard_close="Close..., guess again:"
    prompt_hard_closer="Very Close..., guess again:"
  elif [[ "${selected_lang}" == "sv" ]]; then
    prompt_diff_header="Välj svårighetsgrad"
    prompt_diff_value_error="Felaktigt val - Sätter svårighetsnivå till Lätt"
    prompt_lang_value_error="Ogiltigt val - väljer engelska."
    prompt_diff_1=" 1) Lätt         (1 - 1 000)"
    prompt_diff_2=" 2) Mellan       (1 - 3 333)"
    prompt_diff_3=" 3) Svår         (1 - 127, ingen hjälp)"
    prompt_diff_4=" 4) Omöjlig?     (?? - ??, ABSOLUT ingen hjälp!)"
    prompt_username="Ange spelarnamn"
    prompt_new_user_1="Välkommen, "
    prompt_new_user_2="! Det verkar som att det är första gången."
    prompt_returning_user_1="Välkommen tillbaka, "
    prompt_returning_user_2="! Du har spelat "
    prompt_returning_user_3=" gånger förut och din bästa runda gjorde du på "
    prompt_returning_user_4=" försök."
    prompt_guess_start_1="Gissa det hemliga numret mellan"
    prompt_guess_start_2="och"
    nan_guess="Du måste gissa på siffror, gissa igen:"
    lower_guess="Det är lägre, gissa igen:"
    higher_guess="Det är högre, gissa igen:"
    too_high_guess="Din gissning är för hög, gissa igen:"
    too_low_guess="Din gissning är för låg, gissa igen:"
    prompt_game_finished_1="Du gissade rätt på"
    prompt_game_finished_2="försök. Det hemliga numret var"
    prompt_game_finished_3=". Bra spelat!"
    prompt_game_finished_superb="Riktigt snyggt!"
    prompt_hard_wrong="Mohahahaha.... Det var fel, gissa igen:"
    prompt_hard_close="Varmt..., gissa igen:"
    prompt_hard_closer="Varmare..., gissa igen:"
  else
    prompt_lang_value_error="Ogiltigt val - väljer engelska."
  fi
}

#
# Main program
#

setup_game_db

echo
select_language
# set up variable values prompts to be printed, can set language.
set_prompts "${lang}"

echo
# prompt player for difficulty level
select_difficulty

# Will set the random number to guess for.
secret_number=$((min_secret_value + RANDOM % max_secret_value))
calculated_lower=$((secret_number - 2))
calculated_higher=$((secret_number + 2))
calculated_low=$((secret_number - 5))
calculated_high=$((secret_number + 5))


echo
echo ":: $prompt_username ::"
read USERNAME
# escape single qoutes.
USERNAME=$( echo "$USERNAME" | sed -e "s/'/\\\'/g" )

echo
check_user=$( ${PSQL} "SELECT name FROM players WHERE name = '${USERNAME}'")

# Here we greet a new user welcome.
if [[ -z "${check_user}" ]]; then
  echo "${prompt_new_user_1}${USERNAME}${prompt_new_user_2}"
  ins_user=$($PSQL "INSERT INTO players (name) VALUES('${USERNAME}');")


# Here we greet a returning user welcome back.
else
  tot_played=$( ${PSQL} "SELECT COUNT(game_id) FROM games WHERE player_id = (SELECT player_id FROM players WHERE name = '${check_user}'); ")
  
  best_play_round=$( ${PSQL} "SELECT IFNULL(MIN(total_guesses),0) FROM games WHERE player_id = (SELECT player_id FROM players WHERE name = '${check_user}'); ")
  echo "${prompt_returning_user_1}${check_user}${prompt_returning_user_2}${tot_played}${prompt_returning_user_3}${best_play_round}${prompt_returning_user_4}"
  USERNAME="${check_user}"
fi

echo
echo "${prompt_guess_start_1} ${min_secret_value} ${prompt_guess_start_2} ${max_secret_value}:"

# Start the game looping... :D
game_on

# When game_on function is done we print success message.
echo -e "${prompt_game_finished_1} ${number_of_guesses} ${prompt_game_finished_2} ${secret_number}${prompt_game_finished_3}\n"

if [[ "${number_of_guesses}" -le 10 ]] && [[ $difficulty != "hard" ]]; then
  echo $prompt_game_finished_superb
elif [[ "${number_of_guesses}" -le 3 ]] && [[ $difficulty == "hard" ]]; then
  echo $prompt_game_finished_superb
fi
