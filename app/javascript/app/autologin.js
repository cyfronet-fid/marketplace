export default function redirect_to_login() {
    const eosc_logged_in = (Cookies.get('eosc_logged_in') === "true");
    const internal_session = (Cookies.get('internal_session') === "true");

    const redirect_path = '/users/auth/checkin'
    if(location.pathname !== redirect_path && eosc_logged_in && !internal_session) {
        location.replace(redirect_path)
    }
}