/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb
if(process.env.CUSTOMIZATION_PATH) {
    // try catch is to handle situation where there is no /javascript/images in customization path
    try {
        require.context(process.env.CUSTOMIZATION_PATH + '/javascript/images');
    } catch (e) {}
}

require.context('../images');

import "app"
import Shepherd from 'shepherd.js';
window.Shepherd = Shepherd;
import Cookies from 'js-cookie/src/js.cookie';
window.Cookies = Cookies;
