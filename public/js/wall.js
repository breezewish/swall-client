(function() {

    var lastAsset = null;

    String.prototype.endsWith = function(suffix) {
        return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };

    function loadImage(url, callback) {
        var tmpImg = new Image();
        tmpImg.onload = callback;
        tmpImg.src = url;
    }

    function setDanmakuVisibility(visible) {
        if (visible) {
            $('#danmaku, #float-window').addClass('show');
        } else {
            $('#danmaku, #float-window').removeClass('show');
        }
    }

    function updateDanmakuSettings(prop) {
        window.danmaku.setMaxline(prop.maxline);
        window.danmaku.setDisplaySecond(prop.duration);
    }

    function generateAssetDOM(asset, callback) {
        if (asset.type === 'image') {
            loadImage(asset.URI, function() {
                var $dom = $('<div class="asset-img asset-item" style="background-image:url(' + asset.URI + ')">');
                callback($dom);
            });
        } else if (asset.type === 'video') {
            if (asset.URI.endsWith('.webm')) {
                var source = '<source src="' + asset.URI + '" type="video/webm">';
            } else {
                var source = '<source src="' + asset.URI + '" type="video/mp4">';
            }
            var $dom = $('<video class="asset-video asset-item" autoplay>' + source + '</video>');
            callback($dom);
        }
    }

    function switchToAsset(asset) {
        generateAssetDOM(asset, function($dom) {
            var assetToFadeout = lastAsset;
            $dom.appendTo('#bg');
            lastAsset = $dom;
            setTimeout(function() {
                $dom.addClass('show');
                if (assetToFadeout) {
                    assetToFadeout.removeClass('show');
                }
            }, 50); // wait for image decode
        });
    }

    $(document).ready(function() {
        window.danmaku = new Danmaku($('#danmaku'));
        danmaku.bindEvents();

        window.socket = io();

        socket.on('connect', function() {
            socket.emit('identify', 'wall');
        });

        socket.on('comment', function(data) {
            danmaku.fly({text: data.msg, color: data.color});
        });

        socket.on('switchTo', function(newAsset) {
            switchToAsset(newAsset);
        });

        socket.on('setVisibility', function(visible) {
            setDanmakuVisibility(visible);
        });

        socket.on('updateSettings', function(prop) {
            updateDanmakuSettings(prop);
        });

        $('#bg').on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', '.asset-item', function() {
            if (!$(this).hasClass('show')) {
                $(this).remove();
            }
        });
    });
})();

function switchTo(bgId) {
    $('.bg-cover').removeClass('bg-cover-show');
    $('.bg' + bgId).addClass('bg-cover-show');
}