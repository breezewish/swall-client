function Danmaku(container, options) {

    // options:
    // 
    //   displaySecond: 10
    //   maxLine: 7
    
    this.$container = $(container);
    options = options || {};
    this.displaySecond = options.displaySecond || PREFERENCE.danmaku.duration;
    this.spaceAllocator = new SpaceAllocator(options.maxLine || PREFERENCE.danmaku.maxline);
}

Danmaku.prototype.bindEvents = function() {
    // remove danmaku when it flyed over the screen
    var self = this;
    self.$container.on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', '.danmaku-item', function() {
        $(this).remove();
    });
}

Danmaku.prototype.fly = function(options) {
    if (options.text.trim().length === 0) {
        return;
    }

    var self = this;
    var line = self.spaceAllocator.allocate();

    // generate Danmaku DOM
    var $dom = $('<div>')
        .addClass('danmaku-item')
        .attr('data-line', line)
        .text(options.text)
        .hide();

    if (options.color) {
        $dom.css({color: options.color});
    }
    
    $dom.appendTo(self.$container);

    var w = $dom.outerWidth();
    var h = $dom.outerHeight();
    var top = h * line;

    var containerWidth = self.$container.width();

    // initialize position
    self.setPosition($dom, containerWidth, top);

    // start moving
    setTimeout(function() {
        self.setTransition($dom, '-webkit-transform ' + self.displaySecond + 's linear');
        self.setTransition($dom, '        transform ' + self.displaySecond + 's linear');
        $dom.show();
        setTimeout(function() {
            self.setPosition($dom, -w, top);

            // release line
            var speed = (containerWidth + w) / self.displaySecond;
            var releaseDelay = w / speed;
            setTimeout(function() {
                self.spaceAllocator.release(line);
            }, releaseDelay * 1000);
        }, 0);
    }, 0);
}

Danmaku.prototype.setMaxline = function(line) {
    this.spaceAllocator.setMaxline(line);
}

Danmaku.prototype.setDisplaySecond = function(second) {
    this.displaySecond = second;
}

Danmaku.prototype.setPosition = function($dom, x, y) {
    $dom.css({
        webkitTransform: 'translate3d(' + x + 'px,' + y + 'px,0)',
              transform: 'translate3d(' + x + 'px,' + y + 'px,0)'
    });
}

Danmaku.prototype.setTransition = function($dom, transition) {
    $dom.css({
        webkitTransition: transition,
              transition: transition
    });
}

function SpaceAllocator(options) {
    this.maxLine = options.maxLine || 7;
    this.lineOccupied = {};
}

SpaceAllocator.prototype.setMaxline = function(line) {
    this.maxLine = line;
}

SpaceAllocator.prototype.allocate = function() {
    var line = 0;
    while (this.lineOccupied[line]) {
        if (line >= this.maxLine - 1) {
            // occupied all stacks:
            // clear stack
            for (var i = 0; i < this.maxLine; ++i) {
                this.lineOccupied[i] = false;
            }
            line = 0;
            break;
        } else {
            line++;
        }
    }
    this.lineOccupied[line] = true;
    return line;
}

SpaceAllocator.prototype.release = function(line) {
    this.lineOccupied[line] = false;
}