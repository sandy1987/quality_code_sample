var original_button_text = "";
var inframe = false;
var single_card_show = false;

$(document).on('ready page:load', function () {
  var timer;
  function resetInterval() {
    clearInterval(timer);
    timer = setInterval(function () {
      ajaxRequest("/static/lcheck")
      .done(function(response) {
        if(!response.active) {
          window.location.href = "/";
        }
      });
    }, 3600000); 
  }
  $(document).on('keyup keypress keydown mouseover mousemove resize click scroll', function(e) {
    resetInterval();
  });

  $(document).bind('ajaxError', function(event, jqXHR) {
    if(jqXHR.status==401){
      window.location.reload()
    }
  });

  url = window.location.pathname;
  $.each( $("#aoverlay .menu-item"), function() {
    if ( url != "/cards" && this.pathname == url ) {
      $(this).addClass('active');
    }
    else if (this.pathname.indexOf('/analytics')>-1 && url.indexOf('/analytics')>-1 ) {
      $(this).addClass('active');
    }
  });

  path = window.location.pathname + window.location.search
  $(document).find("a[href='"+ path +"']").attr('href','#-');

  $(document).on('click', '.menu-item-header a', function() {
    if (this.href.indexOf(window.location.href)==0){
      $('#close-menu').click();
    }
  });

  $("[data-toggle='tooltip']").tooltip();

  $(document).on("click", ".main-ask-button",function(event) {
    window.location.href = "/users";
  });

  // Corner popover management
  $(document).on("click",".corner-ellipsis",function(event){
    //Close last opened div first
    //$( "div.corner-pop:visible" ).hide("slide", { direction: "right" }, 300);
    $( this ).next( "div.corner-pop" ).show("slide", { direction: "right" }, 300);
  });

  $(document).on("click",".dismiss-corner-popover",function(){
    $( this ).parent().hide("slide", { direction: "right" }, 300);
  });

  $(document).on("click",".corner-pop .contents .item", open_share);
  $(document).on("click",".success-share-button", open_share);

  function open_share(){
    switch ($(this).data("site")) {
      case 'facebook':
        var u = "https://www.facebook.com/sharer/sharer.php?u=" + $(this).data("url");
        break;
      case 'twitter':
        var u = "https://twitter.com/intent/tweet?text=" + $(this).data("text") + "&url=" + $(this).data("url");
        break;
      case 'direct-link':
        window.location.href = $(this).data("url");
        return;
        break;
      default:
        return false;
    }
    window.open(u, 'socialShareWindow', 'height=350, width=550, toolbar=0, location=0, menubar=0, directories=0, scrollbars=0');
    return false;
  }

  // Video management
  // https://developer.mozilla.org/en-US/docs/Web/Events/play
  // http://www.w3.org/2010/05/video/mediaevents.html
  $(document).on("click", ".overlay",function(event){
    var vdo = $( this ).parent().find( "video" )[0];
    var olay = $(this);
    vdo.onplay = function(e) {
      olay.hide();
    }
    vdo.onloadeddata = function(e) {
      $(this)[0].controls = true;
      ajaxRequest("/questions/"+$(this)[0].dataset.qid+"/answers/"+$(this)[0].dataset.aid+"/view", "POST", {"ref": document.referrer, "inframe": inframe})  
    }
    vdo.onended = function(e) {
      $(this)[0].controls = false;
      olay.show();
    };
    playPause(vdo);
  });

  function playPause(v) { 
    if (v.paused) {
      v.play();
      v.controls = true;
    } else {
      v.pause();
    } 
  }

  // Open page menu
  $(document).on('click', '#bmenu', function() {
    $( ".stacked-menu-items" ).show("slide", { direction: "right" }, 300);
    $('#aoverlay, #aoverlay-back').fadeIn(500);
  });

  $( "#close-menu" ).click(function( event ) {
    $( ".stacked-menu-items" ).hide("slide", { direction: "right" }, 300);
    $('#aoverlay-back, #aoverlay').fadeOut(500);
  });

  //Ajax modal - Fill modal with content from link href
  $(document).on("click",".ajax-modal-opener",function(e){
    var link = $(this).data("href");
    var title = $(this).data("modal-title");
    var login_title = $(this).data('loginTitle');
    var login_url = $(this).data('loginUrl');
    $('#ajaxModal .modal-title').html(title);
    $('#ajaxModal').modal("show");
    ajaxRequest(link)
    .done(function(response) {
      if(!response.has_error) {
        $('#ajaxModal .modal-body #html-response-holder').html(response);
      } else if(response.response_code != undefined && response.response_code == 1000) {
        show_login_modal(login_url, login_title);
      }
    });
  });

  //Ajax modal profile - Fill modal with content from link href
  $(document).on("click",".ajax-modal-opener-profile",function(e){
    var link = $(this).data("href");
    $('#ajaxModalProfile').modal("show");
    ajaxRequest(link)
    .done(function(response) {
      $('#ajaxModalProfile .modal-body #html-response-holder').html(response);
    });
  });

  // Card drops
  if (typeof(setupBlocks) == "function") {
    if(gon.is_mobile || $(window).width() < 704) {
      //For mobile, no need to arrange
      $(".card").addClass("mobile-card");
      $(".celebrity-list-box").addClass("full-width");
    } else {
      setupBlocks();
    }
  }

});

function scrollDown() {
  var page_height = $(window).scrollTop() > ( $(document).height() - $(window).height() - 300 );
  if (page_height && $(".suggest-celebrity").length == 0) {
    $(window).unbind('scroll', scrollDown);
    $('.loading-more-cards').removeClass('hide');
    if ($('.no-qa-found').length < 1 ) {
      get_only_card_response();
    } else{
      $('.loading-more-cards').addClass('hide');
    }
  }
}

function get_only_card_response() {
  ajaxRequest( get_url(), "GET" )
  .done(function(response) {
    $('.loading-more-cards').addClass('hide');
    $('.card-container').append(response);
    if (response.length > 0) {
      $(window).bind('scroll', scrollDown);
      $("[data-toggle='tooltip']").tooltip();
      setupBlocks();
      setTimeout(setupBlocks, 1500);
    }
  });
}

function get_url() {
  path = $('.paginate-page-no').last().attr('url');
  return path;
}

function show_login_modal(link, title) {
  $('#ajaxModal .modal-body').html("");
  $('#ajaxModal .modal-title').html(title);
  $('#ajaxModal').modal("show");
  ajaxRequest(link)
  .done(function(response) {
    $('#ajaxModal .modal-body').html(response);
  });
}

function fill_modal_with_message(msg, title, type) {
  $('#ajaxModal .modal-body').html("");
  $('#ajaxModal .modal-title').html(title);
  $('#ajaxModal').modal("show");
  switch(type) {
    case 'error':
      msg = "<div class='alert alert-danger'>"+msg+"</div>";
      break;
    case 'info':
      msg = "<div class='alert alert-info'>"+msg+"</div>";
      break;
    case 'success':
      msg = "<div class='alert alert-success'>"+msg+"</div>";
      break;
    case 'custom':
      msg = msg;
      break;
    default:
      msg = "<h3>"+msg+"</h3>";
  }
  $('#ajaxModal .modal-body').html(msg);
}

//Button click disabling and enabling - must have attribute data-loading-text
function toggle_loading_button(button_id) {
  var btn = $("#"+button_id);
  if (btn.is('[disabled]')) {
    btn.removeAttr("disabled");
    btn.html(original_button_text);
  } else {
    original_button_text = btn.html();
    if($(this).data("loading-text") != undefined) {
      var lmsg = $(this).data("loading-text");
    } else {
      var lmsg = gon.loading_text;
    }
    btn.attr('disabled', 'disabled').html(lmsg+"&nbsp;&nbsp;<i class='fa fa-circle-o-notch fa-spin'></i>").addClass('animated pulse');
  }
}

function ajaxRequest(url, httpmethod, pdata, async ) {
  httpmethod = httpmethod || "GET";
  pdata = pdata || {};
  async = (async != undefined) ? async : true;
  return $.ajax({
    method: httpmethod,
    url: url,
    async: async,
    data: pdata
  });
}

function showimagepreview(input, id) {
  if (input.files && input.files[0]) {
    var filerdr = new FileReader();
    filerdr.onload = function(e) {
      img = e.target.result;
      div = $(id)
      if (div.length) {
        $.each( div, function( index, dv ) {
          $(dv).css({
            "background-image": "url("+img+")",
          });
        });
      } else {
        div.css({
          "background-image": "url("+img+")",
        });
      }
    }
    filerdr.readAsDataURL(input.files[0]);
  }
}

function response_notice(response, id) {
  if (response.type == "error"){
    $( id + ' #error').removeClass('hide').html(response.message);
    $( id + ' .field').addClass('field_with_errors');
  }
  else if (response.type == "success") {
    $( id + ' #error').addClass('hide');
    $( id + ' .field').removeClass('field_with_errors');
    $( id + ' #success').removeClass('hide').html(response.message);
    $( id + ' .flag-body').hide();
  }
}

// Clean modal on close
$(document).on('click','.close',function (e) {
  modal_id = $(this).parents('.modal').last().attr('id');
  $('#'+modal_id).find('#error').addClass('hide');
  $('#'+modal_id).find('#notice').addClass('hide');
  $('#'+modal_id).find('#success').addClass('hide');
  $('#'+modal_id).find('.field').removeClass('field_with_errors');
  $('#'+modal_id).find('.flag-body').show();
  $(this).parents('.modal-content').find('.form-control').val('');
});

(function( $ ) {
  // Custom autocomplete instance.
  $.widget( "app.autocomplete", $.ui.autocomplete, {
    // Which class get's applied to matched text in the menu items.
    options: {
        highlightClass: "highlight-search-content"
    },
    _renderItem: function( ul, item ) {
      // Replace the matched text with a custom span. This
      // span uses the class found in the "highlightClass" option.
      var re = new RegExp( "(" + this.term + ")", "gi" ),
          cls = this.options.highlightClass,
          template = "<span class='" + cls + "'>$1</span>",
          label = item.label.replace( re, template ),
          $li = $( "<li/>" ).appendTo( ul );
      
      // Create and return the custom menu item content.
      $( "<a/>" ).attr( "href", "#" )
                 .html( label )
                 .appendTo( $li );
      return $li;              
    }
  });      
})( jQuery );

function empty_all_messages(){
  $('.alert-success').html('').addClass('hide');
  $('.alert-info').html('').addClass('hide');
  $('.alert-danger').html('').addClass('hide');
}

$(document).on('click','.menu-item',function() {
  $( "#close-menu" ).click();
  return true;
});

function ucfirst(str) {
  var firstLetter = str.substr(0, 1);
  return firstLetter.toUpperCase() + str.substr(1);
}

$(document).on("click", ".follow_n_unfollow", function(e) {
  var celeb_id = $(this).attr('data-id');
  var dowat = $(this).attr('data-do');
  var element_id = "fol-"+celeb_id;
  var element_count = "ft-count-"+celeb_id;
  var element_icon = "ficon-"+celeb_id;
  var element_text = "ft-text-"+celeb_id;
  toggle_loading_button(element_id);
  if (dowat == 'request') {
    var qurl = "/follow?type=follow&following_id="+celeb_id;
    var new_title = gon.unfollow
    var loading_text = gon.follow_request
  } else {
    var qurl = "/follow?type=unfollow&following_id="+celeb_id;
    var new_title = gon.follow
    var loading_text = gon.follow_cancel
  }
  ajaxRequest( qurl, 'POST' )
  .done(function(response) {
    toggle_loading_button(element_id);
    if(!response.has_error) {
      if(response.fcount == 0) {
        $("."+element_count).html("").switchClass("visibility-v", "visibility-h");
      } else {
        $("."+element_count).html(response.fcount).switchClass("visibility-h", "visibility-v").addClass("animated flash");
      }

      $("."+element_text).html(new_title);
      var nwd = (dowat == 'request') ? 'cancel' : 'request';
      if(nwd == 'request') {
        $("."+element_icon).switchClass('fa-user-times', 'fa-user-plus');
        $("#"+element_id).removeClass('black-color-button');
      } else {
        $("."+element_icon).switchClass('fa-user-plus', 'fa-user-times');
        $("#"+element_id).addClass('black-color-button');
      }
      $("#"+element_id).attr("data-do", nwd);
      $("."+element_count).one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
        $("."+element_count).removeClass("animated flash");
      });
      $("."+element_text).one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
        $("."+element_text).removeClass("animated flash");
      });
    } else if(response.response_code != undefined && response.response_code == 1000) {
      //Open login modal
      show_login_modal("/users/login?modal=true&msg="+gon.follow_request_login_msg, gon.plzlogin);
    } else {
      //Open modal to show error message
      fill_modal_with_message(response.message, gon.error_title, 'error');
    }
  });
});