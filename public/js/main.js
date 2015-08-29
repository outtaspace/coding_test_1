'use strict';

$.ajaxSetup({
    error: function() {
        alert('Ошибка. Не удалось получить данные с сервера');
    },
});

var app = {};

app.req = {
    user_id:                      undefined,
    article_id:                   undefined,
    url_for_all_comments:         undefined,
    url_for_create_a_new_comment: undefined
};

app.reload_comments = function() {
    var app = this;

    app.api_get_all_comments().done(function(data) {
        alert('Комменты загружены успешно');
    });
};

app.post_new_comment = function() {
    var app = this;

    app.api_post_new_comment().done(function(data) {
        alert('Успешно создан коммент');
    });
};

// AJAX
app.api_get_all_comments = function() {
    var app = this;

    return $.getJSON(app.req.url_for_all_comments);
};

app.api_post_new_comment = function(user_id, parent_id, comment) {
    var app, data;

    app  = this;
    data = {parent_id: parent_id, user_id: user_id, comment: comment};

    return $.post(app.req.url_for_create_a_new_comment, data, 'json');
};

