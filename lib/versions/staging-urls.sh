# Public URLs of the staging instances and of their discovery hubs on the
# staging host, one slot per variant. deploy-multi.sh and deploy-hubs.sh
# source this file and export the URLs of a variant for the compose files
# (docker-compose-<variant>.yml, docker-compose-hub-<variant>.yml), which
# read them as MP_ROOT_URL, MP_HUB_URL and MP_API_URL. A deploy on another
# host changes the domain and the slots here, or exports the three variables
# before a manual `docker compose` call.
#
#   variant      slot   instance                      discovery hub
#   pl           16     marketplace-16.<domain>       search-16.<domain>
#   whitelabel   17     marketplace-17.<domain>       (no hub)
#   marketplace  18     marketplace-18.<domain>       search-18.<domain>

STAGING_DOMAIN="docker-fid.grid.cyf-kr.edu.pl"

staging_slot() {
    case "$1" in
        pl)          echo 16 ;;
        whitelabel)  echo 17 ;;
        marketplace) echo 18 ;;
        *)           return 1 ;;
    esac
}

# Exports MP_ROOT_URL, MP_HUB_URL and MP_API_URL of the variant, without a
# trailing slash. The transform service reaches the instance on its public
# URL, so MP_API_URL equals MP_ROOT_URL here.
export_staging_urls() {
    local slot
    slot=$(staging_slot "$1") || { echo "unknown variant: $1"; return 1; }
    export MP_ROOT_URL="https://marketplace-${slot}.${STAGING_DOMAIN}"
    export MP_HUB_URL="https://search-${slot}.${STAGING_DOMAIN}"
    export MP_API_URL="$MP_ROOT_URL"
}
