const {environment} = require('@rails/webpacker');
const webpack = require('webpack');
const fs = require('fs');
const path = require('path');

/**
 * Automatically load modules instead of having to import or require them
 *
 * everywhere. Support by webpack. To get more information:
 *
 * https://webpack.js.org/plugins/provide-plugin/
 * http://j.mp/2JzG1Dm
 */
environment.plugins.prepend(
    'Provide',
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        jquery: 'jquery',
        'window.jQuery': 'jquery',
        Popper: ['popper.js', 'default']
    })
);

/**
 * To use jQuery in views
 */
environment.loaders.append('expose', {
    test: require.resolve('jquery'),
    use: [{
        loader: 'expose-loader',
        options: '$'
    }]
})

const CUSTOMIZATION_PATH = process.env.CUSTOMIZATION_PATH;

if (CUSTOMIZATION_PATH) {
    const rootDir = path.resolve('.');
    const relRE = new RegExp(`${rootDir}/app/(.+)/.+\..+`);
    const sassLoader = environment.loaders.get('sass').use.find(element => element.loader === 'sass-loader');

    sassLoader.options.importer = function (url, prev, done) {
        if (url.startsWith('~')) {
            return null;
        }

        const match = prev.match(relRE);
        if (!match) {
            return null;
        }

        const relPath = match[1];

        function findPath(path, url) {
            function checkAndReturn(path) {
                if(fs.existsSync(path)) {
                    return path
                }
                return null;
            }

            const check = checkAndReturn(path + '/' + url)
                || checkAndReturn(path + '/' + url + '.scss')
                || checkAndReturn(path + '/' + url + '.sass');

            if(check) {return check;}

            const pos = url.search(new RegExp('[^/\.]\..+$'));
            if(pos === -1 || url.charAt(1) === '_') {
                return null;
            }

            const urlSub = url.slice(0, pos) + '_' + url.slice(pos);
            return checkAndReturn(path + '/' + urlSub)
            || checkAndReturn(path + '/' + urlSub + '.scss')
            || checkAndReturn(path + '/' + urlSub + '.sass');
        }


        const filePath = findPath(CUSTOMIZATION_PATH + '/' + relPath, url);

        if (filePath) {
            return {file: filePath};
        }

        return null;
    };

}

module.exports = environment;
