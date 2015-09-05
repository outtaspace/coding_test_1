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
    url_for_create_a_new_comment: undefined,
    default_parent_id:            0
};

app.init_bindings = function() {
    var _this     = this;
    var $panel    = $('#create_a_new_comment .panel-body');
    var $form     = $panel.find('> form');
    var $textarea = $form.find('textarea');

    $panel
        .find('> button')
        .on('click', function() {
            _this.show_comment_form();
        });

    $form
        .find('.btn-group > button:nth-child(1)')
        .on('click', function() {
            var comment = $textarea.val();

            if (! comment.length) {
                return;
            }

            _this
                .api_post_new_comment(_this.req.user_id, _this.req.default_parent_id, comment)
                    .done(function(data) {
                        $textarea.val('');
                        _this.hide_comment_form();
                        alert('Успешно создан коммент');
                    });
        });

    $form
        .find('.btn-group > button:nth-child(2)')
        .on('click', function() {
            $textarea.val('');
            _this.hide_comment_form();
        });
};

app.show_comment_form = function() {
    $('#create_a_new_comment .panel-body')
        .find('> button')
            .hide()
            .end()
        .find('> form')
            .show()
            .end();
};

app.hide_comment_form = function() {
    $('#create_a_new_comment .panel-body')
        .find('> button')
            .show()
            .end()
        .find('> form')
            .hide()
            .end();
};

app.reload_comments = function() {
    this
        .api_get_all_comments()
            .done(function(data) {
                alert('Комменты загружены успешно');
            });
};

// AJAX
app.api_get_all_comments = function() {
    return $.getJSON(this.req.url_for_all_comments);
};

app.api_post_new_comment = function(user_id, parent_id, comment) {
    var req_data = {
        parent_id: parent_id,
        user_id:   user_id,
        comment:   comment
    };

    return $.ajax({
        url:      this.req.url_for_create_a_new_comment,
        method:   'POST',
        data:     req_data,
        dataType: 'json'
    });
};

