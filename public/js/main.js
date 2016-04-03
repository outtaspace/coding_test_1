require.config({
    paths: {
        jquery: '/bower_components/jquery/dist/jquery',
        underscore: '/bower_components/underscore/underscore',
        backbone: '/bower_components/backbone/backbone',
        bootstrap: '/bower_components/bootstrap/dist/js/bootstrap.min',
        app: '/js/app'
    },
    shim: {
        jquery: {
            exports: '$'
        },
        underscore: {
            exports: '_'
        },
        backbone: {
            deps: ['jquery', 'underscore'],
            exports: 'Backbone'
        },
        bootstrap: {
            deps: ['jquery']
        }
    }
});

(function MainIIFE() {
    'use strict';

    var deps = ['app'];

    define(deps, run);

    function run(app) {
        app.init_bindings();
        app.reload_comments();
    }
})();
