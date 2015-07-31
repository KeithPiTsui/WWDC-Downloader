function seekToTimeCode(timecode) {
    
    var dict = {};
    dict["type"] = "selector";
    dict["selector"] = "seekToTimeCode";
    dict["data"] = timecode;
    
    window.webkit.messageHandlers.callbackHandler.postMessage(dict);
}

function highlightLineWithTimecode(timecode) {
    
    var paragraphs = $('body').find('p');
    for	(index = 0; index < paragraphs.length; index++) {
        var elm = paragraphs[index];
        $(elm).removeClass('paragraphHighlight');
    }
    
    var target = document.querySelector('a[data-timecode="'+timecode+'"]')

    var parent = target.parentElement;
    $(parent).addClass('paragraphHighlight');
    
    if (autoScrollEnabled) {
        $(target).goTo();
    }
}

var autoScrollEnabled = false
function setAutoScrollEnabled(enabled) {
    
    autoScrollEnabled = enabled
    
    var dict = {};
    dict["type"] = "log";
    dict["message"] = "setAutoScrollEnabled: "+enabled;

    window.webkit.messageHandlers.callbackHandler.postMessage(dict);
}

var lstEl = null;
var cntr = -1;

function findText(searchTerm) {

    if ((typeof(lstEl) !== 'undefined') && (lstEl !== null)) {
        for	(index = 0; index < lstEl.length; index++) {
            var elm = lstEl[index];
            $(elm).removeClass('current');
        }
    }
    
    lstEl = null;
    cntr = -1;
    
    $('p').removeHighlight();
    $('p').highlight(searchTerm);
    
    nextItem()
    
    Els = $('body').find('span.highlight');
    
    return Els.length
}

function nextItem() {
    if (lstEl === null) {
        lstEl = $('body').find('span.highlight');
        if (!lstEl || lstEl.length === 0) {
            lstEl = null;
            return;
        }
    }
    if (cntr < lstEl.length - 1) {
        cntr++;
        if (cntr > 0) {
            $(lstEl[cntr-1]).removeClass('current');
        }
        var elm = lstEl[cntr];
        $(elm).addClass('current');
        $(elm).goTo();
    }
    else if (cntr == lstEl.length - 1) {
        $(lstEl[cntr]).removeClass('current');
        cntr = 0;
        var elm = lstEl[cntr];
        $(elm).addClass('current');
        $(elm).goTo();
    }
}

function previousItem() {
    if (lstEl === null) {
        lstEl = $('body').find('span.highlight');
        if (!lstEl || lstEl.length === 0) {
            lstEl = null;
            return;
        }
    }
    if (cntr > 0) {
        cntr--;
        if (cntr < lstEl.length) {
            $(lstEl[cntr + 1]).removeClass('current');
        }
        var elm = lstEl[cntr];
        $(elm).addClass('current');
        $(elm).goTo();
    }
    else if (cntr == 0) {
        $(lstEl[cntr]).removeClass('current');
        cntr = lstEl.length - 1;
        var elm = lstEl[cntr];
        $(elm).addClass('current');
        $(elm).goTo();
    }
}

(function($) {
 $.fn.goTo = function() {
 $('html, body').animate({
                         scrollTop: $(this).offset().top - 100
                         }, 'fast');
 return this;
 }
 })(jQuery);