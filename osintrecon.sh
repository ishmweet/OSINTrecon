#!/usr/bin/env bash

trap 'printf "\n[!] Interrupted. Exiting...\n"; exit 1' 2

MAX_JOBS=10
CURL_TIMEOUT=10
CURL_CONNECT_TIMEOUT=5
CURL_RETRIES=2

USERNAME=""
TMP_RESULTS="$(mktemp)"

GREEN="\e[1;32m"
BRIGHT="\e[1;92m"
WHITE="\e[1;77m"
YELLOW="\e[1;93m"
RED="\e[1;91m"
RESET="\e[0m"

banner() {
  clear
  printf "${GREEN}"
  cat << "EOF"

░█████╗░░██████╗██╗███╗░░██╗████████╗██████╗░███████╗░█████╗░░█████╗░███╗░░██╗
██╔══██╗██╔════╝██║████╗░██║╚══██╔══╝██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗░██║
██║░░██║╚█████╗░██║██╔██╗██║░░░██║░░░██████╔╝█████╗░░██║░░╚═╝██║░░██║██╔██╗██║
██║░░██║░╚═══██╗██║██║╚████║░░░██║░░░██╔══██╗██╔══╝░░██║░░██╗██║░░██║██║╚████║
╚█████╔╝██████╔╝██║██║░╚███║░░░██║░░░██║░░██║███████╗╚█████╔╝╚█████╔╝██║░╚███║
░╚════╝░╚═════╝░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░╚════╝░░╚════╝░╚═╝░░╚══╝
EOF
  printf "${RESET}"
  printf "${GREEN}──────────────────────────────────────────────────────────────────────────────${RESET}\n"
  printf "${BRIGHT}[ OSINT RECON ]${RESET}  ${WHITE}Username Footprint Mapper${RESET}\n"
  printf "${WHITE}Mode:${RESET} ${BRIGHT}Passive${RESET}\n"
  printf "${GREEN}──────────────────────────────────────────────────────────────────────────────${RESET}\n\n"
}

wait_for_slot() {
  while (( $(jobs -rp | wc -l) >= MAX_JOBS )); do
    sleep 0.1
  done
}

check_site_bg() {
  local name="$1"
  local url="$2"
  local not_found_pattern="$3"

  {
    response=$(curl -s -L \
      --max-time "$CURL_TIMEOUT" \
      --connect-timeout "$CURL_CONNECT_TIMEOUT" \
      --retry "$CURL_RETRIES" \
      -H "Accept-Language: en" \
      -A "Mozilla/5.0" \
      "$url")

    if echo "$response" | grep -qiE "$not_found_pattern"; then
      printf "${WHITE}[+] %-16s:${RESET} ${YELLOW}Not Found${RESET}\n" "$name"
      echo "NOT|$name|$url" >> "$TMP_RESULTS"
    else
      printf "${WHITE}[+] %-16s:${RESET} ${BRIGHT}Found!${RESET} $url\n" "$name"
      echo "FOUND|$name|$url" >> "$TMP_RESULTS"
    fi
  } &
}

scanner() {
  read -p $'\e[1;92m[>] Enter Username: \e[0m' USERNAME

  > "$TMP_RESULTS"

  printf "\n${BRIGHT}[+] Scanning username:${RESET} ${WHITE}%s${RESET}\n\n" "$USERNAME"

  SITES=(
    "Instagram|https://www.instagram.com/$USERNAME|not found"
    "Twitter/X|https://twitter.com/$USERNAME|doesn’t exist"
    "Facebook|https://www.facebook.com/$USERNAME|not found"
    "Reddit|https://www.reddit.com/user/$USERNAME|404"
    "TikTok|https://www.tiktok.com/@$USERNAME|not found"
    "Pinterest|https://www.pinterest.com/$USERNAME|not found"
    "Tumblr|https://$USERNAME.tumblr.com|404"
    "VK|https://vk.com/$USERNAME|404"
    "Quora|https://www.quora.com/profile/$USERNAME|404"
    "Flickr|https://www.flickr.com/people/$USERNAME|404"
    "Threads|https://www.threads.net/@$USERNAME|404"
    "Mastodon|https://mastodon.social/@$USERNAME|404"
    "Bluesky|https://bsky.app/profile/$USERNAME.bsky.social|404"
    "Snapchat|https://www.snapchat.com/add/$USERNAME|404"
    "Meetup|https://www.meetup.com/members/$USERNAME|404"
    "GitHub|https://github.com/$USERNAME|404"
    "GitLab|https://gitlab.com/$USERNAME|404"
    "Bitbucket|https://bitbucket.org/$USERNAME|404"
    "Keybase|https://keybase.io/$USERNAME|404"
    "CodePen|https://codepen.io/$USERNAME|404"
    "Replit|https://replit.com/@$USERNAME|404"
    "HackerRank|https://www.hackerrank.com/$USERNAME|404"
    "LeetCode|https://leetcode.com/$USERNAME|404"
    "NPM|https://www.npmjs.com/~$USERNAME|404"
    "PyPI|https://pypi.org/user/$USERNAME|404"
    "DeviantArt|https://$USERNAME.deviantart.com|404"
    "Dribbble|https://dribbble.com/$USERNAME|404"
    "Behance|https://www.behance.net/$USERNAME|404"
    "SoundCloud|https://soundcloud.com/$USERNAME|404"
    "Bandcamp|https://bandcamp.com/$USERNAME|404"
    "500px|https://500px.com/$USERNAME|404"
    "ArtStation|https://www.artstation.com/$USERNAME|404"
    "Vimeo|https://vimeo.com/$USERNAME|404"
    "YouTube|https://www.youtube.com/@$USERNAME|404"
    "Mixcloud|https://www.mixcloud.com/$USERNAME|404"
    "Medium|https://medium.com/@$USERNAME|404"
    "WordPress|https://$USERNAME.wordpress.com|register"
    "Blogger|https://$USERNAME.blogspot.com|404"
    "Substack|https://$USERNAME.substack.com|404"
    "Wattpad|https://www.wattpad.com/user/$USERNAME|404"
    "Scribd|https://www.scribd.com/$USERNAME|404"
    "HackerNews|https://news.ycombinator.com/user?id=$USERNAME|No such user"
    "Disqus|https://disqus.com/$USERNAME|404"
    "Instructables|https://www.instructables.com/member/$USERNAME|404"
    "Kongregate|https://kongregate.com/accounts/$USERNAME|404"
    "Dev.to|https://dev.to/$USERNAME|404"
    "ProductHunt|https://www.producthunt.com/@$USERNAME|404"
    "Steam|https://steamcommunity.com/id/$USERNAME|could not be found"
    "Spotify|https://open.spotify.com/user/$USERNAME|404"
    "Roblox|https://www.roblox.com/user.aspx?username=$USERNAME|404"
    "Goodreads|https://www.goodreads.com/$USERNAME|404"
    "TripAdvisor|https://www.tripadvisor.com/members/$USERNAME|404"
    "Last.fm|https://www.last.fm/user/$USERNAME|404"
    "Pastebin|https://pastebin.com/u/$USERNAME|location: /index"
    "About.me|https://about.me/$USERNAME|404"
    "Patreon|https://www.patreon.com/$USERNAME|404"
    "Gumroad|https://www.gumroad.com/$USERNAME|404"
    "Ko-fi|https://ko-fi.com/$USERNAME|404"
    "BuyMeACoffee|https://www.buymeacoffee.com/$USERNAME|404"
  )

  for item in "${SITES[@]}"; do
    IFS="|" read -r n u p <<< "$item"
    wait_for_slot
    check_site_bg "$n" "$u" "$p"
  done

  echo
  wait

  TOTAL_CHECKED=$(wc -l < "$TMP_RESULTS")
  FOUND_COUNT=$(grep -c "^FOUND|" "$TMP_RESULTS")

  printf "${GREEN}──────────────────────── SUMMARY ────────────────────────${RESET}\n"
  printf "${WHITE}Username:${RESET} %s\n" "$USERNAME"
  printf "${WHITE}Sites Checked:${RESET} %d\n" "$TOTAL_CHECKED"
  printf "${WHITE}Found:${RESET} %d\n" "$FOUND_COUNT"
  printf "${WHITE}Not Found:${RESET} %d\n" "$((TOTAL_CHECKED - FOUND_COUNT))"

  if (( FOUND_COUNT <= 3 )); then
    EXPOSURE="Low"; COLOR="$GREEN"
  elif (( FOUND_COUNT <= 10 )); then
    EXPOSURE="Medium"; COLOR="$YELLOW"
  else
    EXPOSURE="High"; COLOR="$RED"
  fi

  printf "${WHITE}Exposure Level:${RESET} ${COLOR}%s${RESET}\n" "$EXPOSURE"
  printf "${GREEN}──────────────────────────────────────────────────────────${RESET}\n"

  rm -f "$TMP_RESULTS"
}

banner
scanner
