(function(window, undefined) {

    function escapeHTML(str) {
        return str
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&apos;")
            .replace(/\//g, "&#x2f;");
    }

    function unescapeHTML(str) {
        return str
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"')
            .replace(/&apos;/g, "'")
            .replace(/&#x2f;/g, "/")
            .replace(/&amp;/g, "&");
    }

    var socket;

    var Func = {
        Assets: {
            _generateItem: function(item) {
                if (item.description.length == 0) {
                    item.description = '<none>';
                }
                var img = '<div class="assets-img" style="background-image:url(' + item.thumbnailURI + ')"></div>';
                var desc = '<div class="assets-desc">' + escapeHTML(item.description) + '</div>';
                return '<div class="assets-item" data-URI="' + item.URI + '" data-hash="' + item.hash + '"><div class="assets-inner">' + img + desc + '</div></div>';
            },
            reload: function(data) {
                var html = '';
                data.forEach(function(item) {
                    html += Func.Assets._generateItem(item);
                });
                $('.role-module-assets .module-main').html(html);
            }
        },

        changeStatus: function(type, status) {
            var $dom = $('.' + type);
            $dom.attr('status', status.toLowerCase().replace(/ /g, '-'));
            $dom.find('.text').text(status);
        },

        changeControllerToClientStatus: function(status) {
            Func.changeStatus('conn-controller2client', status);
        },

        changeClientToServerStatus: function(status) {
            Func.changeStatus('conn-client2server', status);
        }
    };

    var API = {
        tryConnectScreen: function(id) {
            jQuery.ajax({
                url: '/control/screen/info/' + id.toString(),
                type: 'GET',
                cache: false
            }).done(function(data) {
                if (SCREEN_CONNECTED) {
                    if (confirm('确认连接到屏幕：' + data.title + '?')) {
                        API.connectScreen(id);
                    }    
                } else {
                    API.connectScreen(id);
                }
            });
        },

        refreshKeywords: function() {
            jQuery.ajax({
                url: '/control/keywords',
                type: 'GET',
                cache: false
            }).done(function(data) {
                var keywords = data.keywords;
                $('.role-keyword-filter').text(keywords.join(' '));
            });
        },

        setKeywords: function(keywords) {
            jQuery.ajax({
                url: '/control/keywords',
                type: 'POST',
                cache: false,
                data: JSON.stringify({
                    keywords: keywords
                }),
                contentType: 'application/json',
            });
        },

        connectScreen: function(id) {
            jQuery.ajax({
                url: '/control/screen/connect/' + id.toString(),
                type: 'POST',
                cache: false
            }).done(function(data) {
                window.location.reload();
            });
        },

        revealAssetsDirectory: function(callback) {
            jQuery.ajax({
                url: '/control/assets/reveal',
                type: 'POST',
                cache: false
            }).done(function() {
                callback && callback();
            });
        },

        scanAssetsDirectory: function(callback) {
            $('.role-module-assets .module-main').css({opacity: 0.5});
            jQuery.ajax({
                url: '/control/assets/scan',
                type: 'POST',
                cache: false
            }).done(function(data) {
                Func.Assets.reload(data);
                $('.role-module-assets .module-main').css({opacity: 1});
                callback && callback(null, data);
            });
        },

        updateAssetDescription: function(hash, description, callback) {
            jQuery.ajax({
                url: '/control/assets/' + hash + '/modify',
                type: 'POST',
                cache: false,
                data: {
                    description: description
                }
            }).done(function(data) {
                Func.Assets.reload(data);
                callback && callback(null, data);
            });
        },

        switchToAsset: function(hash, callback) {
            jQuery.ajax({
                url: '/control/wall/switch/' + hash,
                type: 'POST',
                cache: false,
            }).done(callback);
        },

        showDanmaku: function(callback) {
            jQuery.ajax({
                url: '/control/wall/show',
                type: 'POST',
                cache: false,
            }).done(callback);
        },

        hideDanmaku: function(callback) {
            jQuery.ajax({
                url: '/control/wall/hide',
                type: 'POST',
                cache: false,
            }).done(callback);
        },

        updateDanmakuSettings: function(duration, maxline, callback) {
            jQuery.ajax({
                url: '/control/wall/settings',
                type: 'POST',
                cache: false,
                data: {
                    duration: duration,
                    maxline: maxline
                }
            }).done(callback);
        },

        updateAssetsRepeat: function(repeat, callback) {
            jQuery.ajax({
                url: '/control/wall/asset/repeat',
                type: 'POST',
                cache: false,
                data: JSON.stringify({
                    repeat: !!repeat
                }),
                contentType: 'application/json',
            }).done(callback);
        },

        sendComment: function(comment, callback) {
            jQuery.ajax({
                url: '/control/wall/comment',
                type: 'POST',
                cache: false,
                data: JSON.stringify({
                    msg: comment,
                    color: '#FFF'
                }),
                contentType: 'application/json',
            }).done(callback);
        },

        updateScreenStatus: function(callback) {
            jQuery.ajax({
                url: '/control/screen/status',
                type: 'GET',
                cache: false
            }).done(function(data) {
                if (data.connected !== SCREEN_CONNECTED) {
                    window.location.reload();
                    return;
                }
                Func.changeClientToServerStatus(data.status);
                callback && callback(null, data);
            });
        }

    };

    $(document).ready(function() {

        socket = io();

        Func.changeControllerToClientStatus('Connecting');
        API.updateScreenStatus();

        socket.on('connect', function() {
            socket.emit('identify', 'controller');
            Func.changeControllerToClientStatus('Connected');
            API.updateScreenStatus();
        });

        socket.on('disconnect', function() {
            Func.changeControllerToClientStatus('Disconnected');
        });

        socket.on('reconnecting', function() {
            Func.changeControllerToClientStatus('Reconnecting');
        });

        socket.on('reconnect_failed', function() {
            Func.changeControllerToClientStatus('Reconnect failed')
        });

        socket.on('statusChange', function(data) {
            Func.changeClientToServerStatus(data.status);
            if (data.status === 'Connected') {
                API.updateScreenStatus();
            }
        });

        $('.role-connect-screen').click(function() {
            API.tryConnectScreen($('.role-screen-id').val());
        });

        $('.role-assets-opendir').click(function() {
            API.revealAssetsDirectory();
        });

        $('.role-assets-scan').click(function() {
            API.scanAssetsDirectory();
        });

        $('.role-danmuku-show').click(function() {
            API.showDanmaku();
        });

        $('.role-danmuku-hide').click(function() {
            API.hideDanmaku();
        });

        $('.role-danmuku-send').click(function() {
            API.sendComment($('.role-comment-text').val());
            $('.role-comment-text').val('');
        });

        $('.role-comment-text').keypress(function(ev) {
            if (ev.which === 13) {
                $('.role-danmuku-send').click();
            }
        });

        $('.role-danmuku-settings-update').click(function() {
            API.updateDanmakuSettings($('.role-danmaku-duration').val(), $('.role-danmaku-maxline').val());
        });

        // update keywords
        $('.role-keywords-refresh').click(function() {
            API.refreshKeywords();
        });

        $('.role-keywords-save').click(function() {
            var keywords = $('.role-keyword-filter').val().split(/\s+/g).filter(function(v) {
                return v.length > 0;
            });
            API.setKeywords(keywords);
        });

        // load assets
        if (SCREEN_CONNECTED) {
            API.scanAssetsDirectory();
        }

        // change assets description
        $('.role-module-assets').on('click', '.assets-desc', function(ev) {
            var item = $(this).closest('.assets-item');
            var enter = prompt('请输入描述:', $(this).text());
            if (enter) {
                API.updateAssetDescription(item.attr('data-hash'), enter);
            }
            ev.stopPropagation();
        });

        // switch assets
        $('.role-module-assets').on('click', '.assets-item', function() {
            var item = $(this);
            //zif ($(this).hasClass('assets-item-active')) return;
            $('.role-module-assets .assets-item-active').removeClass('assets-item-active');
            $(this).addClass('assets-item-active');
            API.switchToAsset(item.attr('data-hash'));
        });

        // iCheck
        $('input').iCheck({
            checkboxClass: 'icheckbox_polaris',
            radioClass: 'iradio_polaris'
        });

        // change repeat settings
        $('.role-asset-repeat').on('ifChanged', function() {
            API.updateAssetsRepeat($(this).prop('checked'));
        });
    });

})(window);