# Autologin integration (technology agnostic)

To integrate your application with the autologin scheme, you need to:
1. `Set-Cookie: eosc_logged_in=true; Domain=.eosc-portal.eu; Expires=<SAME_AS_AAI_SESSION_COOKIE>`
1. `Set-Cookie: internal_session=true; Expires=<SAME_AS_YOUR_INTERNAL_SESSION_COOKIE>`

... AFTER your user has successfully been authenticated through OIDC AAI.

1. `Set-Cookie: eosc_logged_in=false; Domain=.eosc-portal.eu;`
1. `Set-Cookie: internal_session=false;`

(OR just delete these cookies) AFTER your user has successfully logged out.


You also need to provide your `/login` url to EOSC Commons and (optionally) your internal session cookie key 
(IF you don't want to set and delete the `internal_session` cookie)

