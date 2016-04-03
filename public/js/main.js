'use strict';

var app = {};

app.req = {
    user_id:                      undefined,
    article_id:                   undefined,
    url_for_all_comments:         undefined,
    url_for_create_a_new_comment: undefined,
    default_parent_id:            0
};

app.init_bindings = function() {
    var _this         = this;
    var $panel        = $('#create_a_new_comment .panel-body');
    var $form         = $panel.find('> form');
    var $textarea     = $form.find('textarea');
    var $all_comments = $('#all_comments');

    $.ajaxSetup({
        error: function() {
            alert('Ошибка. Не удалось получить данные с сервера');
        }
    });

    _.templateSettings = {
        interpolate: /\{\{(.+?)\}\}/g
    };

    // compile the markup as a named template
    _this.template = {
        comment_body: _.template($('#tmpl_comment_body').html()),
        comment_form: _.template($('#tmpl_comment_form').html())
    };

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

                        _this.show_root_comment(data.comment_id, comment);
                    });
        });

    $form
        .find('.btn-group > button:nth-child(2)')
        .on('click', function() {
            $textarea.val('');
            _this.hide_comment_form();
        });

    $all_comments
        .on('click', '.add_comment', function() {
            $(this)
                .hide()
                .after($(_this.template.comment_form));
        });

    $all_comments
        .on('click', '.submit_comment', function() {
            var $button = $(this);

            var $comment    = $button.closest('.panel');
            var $add_button = $($comment.find('.add_comment').get(0));
            var $form       = $($comment.find('form').get(0));
            var $textarea   = $($comment.find('textarea').get(0));

            var id      = $comment.data('id');
            var comment = $textarea.val();

            if (!comment.length) {
                return;
            }

            _this
                .api_post_new_comment(_this.req.user_id, id, comment)
                    .done(function(data) {
                        var comment_body = _this.template.comment_body({
                            id:        data.comment_id,
                            parent_id: id,
                            comment:   comment
                        });

                        $textarea.val('');
                        $form.hide();
                        $add_button.show();

                        $($comment.find('.comments').get(0)).append($(comment_body));
                    });
        });

    $all_comments
        .on('click', '.cancel_comment', function() {
            $(this)
                .closest('form')
                    .hide()
                    .end()
                .closest('.btn-group')
                    .find('.add_comment')
                        .show();
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
    var _this = this;

    _this
        .api_get_all_comments()
            .done(function(data) {
                _this.show_comments(data.comments);
            });
};

app.show_root_comment = function(comment_id, comment) {
    var parent_id = this.req.default_parent_id;

    var comment_body = this.template.comment_body({
        id:        comment_id,
        parent_id: parent_id,
        comment:   comment
    });

    $(comment_body).appendTo($('#all_comments .panel-body'));
};

app.show_comments = function(comments) {
    var _this   = this;
    var $panel  = $('#all_comments .panel-body');
    var parents = {0: $panel};

    walk(comments);

    function walk(comments) {
        $.each(comments, function(index, value) {
            var comment_body = _this.template.comment_body({
                id:        value.comment_id,
                parent_id: value.parent_id,
                comment:   value.comment
            });

            var $comment_body = $(comment_body);

            if (! parents.hasOwnProperty(value.id)) {
                parents[value.id] = $comment_body.find('.comments');
            }

            $comment_body.appendTo(parents[value.parent_id]);

            if (value.comments.length) {
                walk(value.comments);
            }
        });
    }
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
