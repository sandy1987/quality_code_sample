// Courtesy 
// https://benholland.me/javascript/2012/02/20/how-to-build-a-site-that-works-like-pinterest.html
// http://labs.benholland.me/pinterest/demo-centered.php
var colCount = 0;
var colWidth = 318;
var margin = 12;
var spaceLeft = 0;
var windowWidth = 0;
var blocks = [];
var tolerance = 20;

$(function(){
  $(window).resize(setupBlocks);
});

// make sure to forcefully do it 1.5s after entire page load 
$(document).ready(function() {
  setTimeout(setupBlocks, 1500);
});

function setupBlocks() {
  if(gon.is_mobile) { 
    //Make sure all cards (fetched on scroll) should have mobile-card class for mobile devices
    $(".card:not([class~='mobile-card'])").addClass("mobile-card");
    return; 
  }

  $(".card").removeClass("mobile-card"); //Hack

  windowWidth = $(window).width()-tolerance; //Added tolerance hack
  blocks = [];

  // Calculate the margin so the blocks are evenly spaced within the window
  colCount = Math.floor(windowWidth/(colWidth+margin*2));
  spaceLeft = (windowWidth - ((colWidth*colCount)+(margin*(colCount-1)))) / 2;
  
  for(var i=0; i<colCount; i++){
    blocks.push(margin);
  }
  positionBlocks();

  // Hack 
  if(colCount == 1) {
    $(".card").css({"width": "100%", "left": "0px"});
    $(".card:first-child").css({"top": "0px"});
  } else {
    $(".card").css({"width": ""});
  }
}

function positionBlocks() {
  $('.card').each(function(i){
    var min = Array.min(blocks);
    var index = $.inArray(min, blocks);
    var leftPos = margin+(index*(colWidth+margin));
    $(this).css({
      'left': (leftPos+spaceLeft)+'px',
      'top': min+'px'
    });
    blocks[index] = min+$(this).outerHeight()+margin;
  }); 
}

// Function to get the Min value in Array
Array.min = function(array) {
  return Math.min.apply(Math, array);
};