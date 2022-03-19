#!/bin/bash  
export LC_NUMERIC="en_US.UTF-8"
SOLANA_PATH="/root/.local/share/solana/install/active_release/bin/solana" #Поменять на свой путь к active_release. обрати вниманеи что путь со словом "solana" его не удалять!!!
#Cluster: m-mainnet-beta или t-testnet
CLUSTER=t
#если хочешь 1 ноду то в скобках указывается только один pub,vote,ip,TEXT и т.д. Добавить можно сколько угодно нод но каждый новый параметр через пробел!  
PUB_KEY=(pub1 pub2)
VOTE=(vote1 vote2)
IP=(ip1 ip2)
# telegram bot token, chat id,text,alarm text...
BOT_TOKEN=1963539115:AAF6Xvf1wBtjzLt0H3Plmtulq4aWCT8QDAk
CHAT_ID_ALARM=-111111111
CHAT_ID_LOG=-111111112
TEXT_ALARM=("delinquent Noda1!" "delinquent Noda2!")
TEXT_NODE=("Info Noda1" "Info Noda2")
INET_ALARM=("Пропал inet Noda1!" "Пропал inet Noda2!")
BALANCE_ALARM=("Пополни Identity Noda1!" "Пополни Identity Noda2!" )
BALANCEWARN=(1 1) # если меньше этого числа на балансе то будет тревожное сообщение!
skip_dop=15     #число  которое + к среднему скипу по кластеру, чтоб вывести красн. кружок  возле скипа при его  превышении
TEXT_INFO_EPOCH="Info Epoch Testnet" # заголовок для инфо, или  Testnet или Mainnet
echo -e
date
for index in ${!PUB_KEY[*]}
do
    PING=$(ping -c 4 ${IP[$index]} | grep transmitted | awk '{print $4}')
    DELINQUEENT=$($SOLANA_PATH -u$CLUSTER validators --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY[$index]}"'" ) | .delinquent ')
    BALANCE_TEMP=$($SOLANA_PATH balance ${PUB_KEY[$index]} -u$CLUSTER | awk '{print $1}')
    BALANCE=$(printf "%.2f" $BALANCE_TEMP)
      
    if (( $(bc <<< "$BALANCE < ${BALANCEWARN[$index]}") )) 
    then
    echo "закончился баланс" ${TEXT_NODE[$index]}
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"'"${BALANCE_ALARM[$index]}"' '"\nBalance:$BALANCE"' '"${PUB_KEY[$index]}"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" 
    fi
    if [[ $PING == 0 ]] && [[ $DELINQUEENT == true ]]
    then
       echo ${INET_ALARM[$index]} ${TEXT_ALARM[$index]}
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"'"${INET_ALARM[$index]}"' '"${TEXT_ALARM[$index]}"' '"$PUB_KEY[$index]"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    echo -e "\n"
    elif [[ $PING == 0 ]]
    then
       echo ${INET_ALARM[$index]}
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"'"${INET_ALARM[$index]}"' '"${PUB_KEY[$index]}"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    echo -e "\n"
    elif [[ $DELINQUEENT == true ]]
    then
       echo ${TEXT_ALARM[$index]}
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"'"${TEXT_ALARM[$index]}"' '"${PUB_KEY[$index]}"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    else
    echo "Все ok" ${PUB_KEY[$index]}
    fi
done

    if (( $(echo "$(date +%M) < 5" | bc -l) ))
then

mesto_top_temp=$($SOLANA_PATH validators -u$CLUSTER --sort=credits -r -n > ~/mesto_top.txt )
lider=$(cat ~/mesto_top.txt | sed -n 2,1p |  awk '{print $2}')
lider2=$($SOLANA_PATH validators -u$CLUSTER --output json-compact | jq '.validators[] | select(.identityPubkey == "'"$lider"'") | .epochCredits ')
Average_temp=$($SOLANA_PATH validators -u$CLUSTER | grep "Average Stake-Weighted Skip Rate" | awk '{print $5}')
Average="${Average_temp%?}"
if [[ -z "$Average" ]]; then Average=0
   fi
for index in ${!PUB_KEY[*]}
do
    epochCredits=$($SOLANA_PATH -u$CLUSTER validators --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY[$index]}"'" ) | .epochCredits ')
    mesto_top=$(cat ~/mesto_top.txt | grep ${PUB_KEY[$index]} | awk '{print $1}' | grep -oE "[0-9]*|[0-9]*.[0-9]")
    proc=$(bc <<< "scale=2; $epochCredits*100/$lider2")
    onboard=$(curl -s -X GET 'https://kyc-api.vercel.app/api/validators/list?search_term='"${PUB_KEY[$index]}"'&limit=40&order_by=name&order=asc' | jq '.data[0].onboarding_number')
#dali blokov
    All_block=$($SOLANA_PATH leader-schedule -u$CLUSTER | grep ${PUB_KEY[$index]} | wc -l)
#done,skipnul, skyp%
    STRING2=$($SOLANA_PATH -v block-production -u$CLUSTER | grep ${PUB_KEY[$index]} | awk 'NR == 1'| awk '{print $2,$4,$5}')
    Done=$(echo "$STRING2" | awk '{print $1}')
    if [[ -z "$Done" ]]; then Done=0
        fi
    skipped=$(echo "$STRING2" | awk '{print $2}')
    if [[ -z "$skipped" ]]; then skipped=0
        fi
    skip_temp=$(echo "$STRING2" | awk '{print $3}')
    skip="${skip_temp%?}"
    if [[ -z "$skip" ]]; then skip=0
        fi    
    if (( $(bc <<< "$skip <= $Average + $skip_dop") )); then skip=🟢$skip
    else skip=🔴$skip
        fi
    BALANCE_TEMP=$($SOLANA_PATH balance ${PUB_KEY[$index]} -u$CLUSTER | awk '{print $1}')
    BALANCE=$(printf "%.2f" $BALANCE_TEMP)
    VOTE_BALANCE_TEMP=$($SOLANA_PATH balance ${VOTE[$index]} -u$CLUSTER | awk '{print $1}')
    VOTE_BALANCE=$(printf "%.2f" $VOTE_BALANCE_TEMP)
    RESPONSE_STAKES=$($SOLANA_PATH stakes ${VOTE[$index]} -u$CLUSTER --output json-compact)
    ACTIVE=$(echo "scale=2; $(echo $RESPONSE_STAKES | jq -c '.[] | .activeStake' | paste -sd+ | bc)/1000000000" | bc)
    ACTIVATING=$(echo "scale=2; $(echo $RESPONSE_STAKES | jq -c '.[] | .activatingStake' | paste -sd+ | bc)/1000000000" | bc)
    if (( $(echo "$ACTIVATING > 0" | bc -l) )); then ACTIVATING=$ACTIVATING🟢
        fi
    DEACTIVATING=$(echo "scale=2; $(echo $RESPONSE_STAKES | jq -c '.[] | .deactivatingStake' | paste -sd+ | bc)/1000000000" | bc)
    if (( $(echo "$DEACTIVATING > 0" | bc -l) )); then DEACTIVATING=$DEACTIVATING⚠️
        fi

    VER=$($SOLANA_PATH -u$CLUSTER validators --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY[$index]}"'" ) | .version '| sed 's/\"//g')
    PUB=$(echo ${PUB_KEY[$index]:0:10})
    info='"
<b>'"${TEXT_NODE[$index]}"'</b> '"[$PUB]"' ['"$VER"']<code>
'"All:"$All_block" Done:"$Done" skipped:"$skipped""'
'"skip:"$skip%" Average:"$Average%""'
epochCredits >['"$epochCredits"']
mesto>['"$mesto_top"'] proc>['"$proc"']
onboard > ['"$onboard"'] 
active_stk >>>['"$ACTIVE"']
activating >>>['"$ACTIVATING"']
deactivating >['"$DEACTIVATING"']
my_balance >>>['"$BALANCE"'] 
vote_balance>>['"$VOTE_BALANCE"']</code>"'
    
    if [[ $onboard == null ]]; then info='"
<b>'"${TEXT_NODE[$index]}"'</b> '"[$PUB]"' ['"$VER"']<code>
'"All:"$All_block" Done:"$Done" skipped:"$skipped""'
'"skip:"$skip%" Average:"$Average%""'
epochCredits >['"$epochCredits"']
mesto>['"$mesto_top"'] proc>['"$proc"']
active_stk >>>['"$ACTIVE"']
activating >>>['"$ACTIVATING"']
deactivating >['"$DEACTIVATING"']
my_balance >>>['"$BALANCE"'] 
vote_balance>>['"$VOTE_BALANCE"']</code>"'
       fi

    if [[ $CLUSTER == m ]]; then info='"
<b>'"${TEXT_NODE[$index]}"'</b> ['"$PUB"'] ['"$VER"']<code>
'"All:"$All_block" Done:"$Done" skipped:"$skipped""'
'"skip:"$skip%" Average:"$Average%""'
epochCredits >['"$epochCredits"']
mesto>['"$mesto_top"'] proc>['"$proc"']
active_stk >>>['"$ACTIVE"']
activating >>>['"$ACTIVATING"']
deactivating >['"$DEACTIVATING"']
my_balance >>>['"$BALANCE"'] 
vote_balance>>['"$VOTE_BALANCE"']</code>"'
     fi
    echo "Нода в порядке" ${TEXT_NODE[$index]}
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_LOG"'",
"text":'"$info"',  "parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    echo -e "\n"
done
    RESPONSE_EPOCH=$($SOLANA_PATH epoch-info -u$CLUSTER > ~/temp.txt)
    EPOCH=$(cat ~/temp.txt | grep "Epoch:" | awk '{print $2}')
    EPOCH_PERCENT=$(printf "%.2f" $(cat ~/temp.txt | grep "Epoch Completed Percent" | awk '{print $4}' | grep -oE "[0-9]*|[0-9]*.[0-9]*" | awk 'NR==1 {print; exit}'))"%"
    END_EPOCH=$(echo $(cat ~/temp.txt | grep "Epoch Completed Time" | grep -o '(.*)' | sed "s/^(//" | awk '{$NF="";sub(/[ \t]+$/,"")}1'))    
    echo "$TEXT_INFO_EPOCH" 
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_LOG"'","text":"<b>'"$TEXT_INFO_EPOCH"'</b> <code>
['"$EPOCH"'] | ['"$EPOCH_PERCENT"'] 
End_Epoch '"$END_EPOCH"'</code>", "parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    fi

