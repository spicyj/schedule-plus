
  $(window).resize(function() {
    $('#main-bg').height($(window).height());
    $('#main-bg').css({ marginLeft:Math.max(132,($(window).width()-960)/2+132) });
    $('.page').css({ width:$(window).width() });
    $('#main-page #bg-mask').css({ width:$(window).width()/2 });
  });

function popupCenter(url,width,height,name) {
  var left = (screen.width/2)-(width/2);
  var top = (screen.height/2)-(height/2);
  return window.open(url,name, 'menubar=no,toolbar=no,status=no,width='+width
    +',height='+height+',toolbar=no,left='+left+',top='+top);
}


$(document).ready(function() {

  $('body').delegate('#fb-login,#fb-connect','click',function(e) {
    popupCenter($(this).attr('href'),600,400,'fbPopup');
    e.stopPropagation();
    return false;
  });

  (new Image()).src = "/images/ajax-small.gif";

  var speed = 600;
  
  $(window).resize();

  $('#start-page .error.tooltip').hide();
  $('#start-page #add-schedule').submit(function(e) {
    e.preventDefault();
    var f = $(this);
    $('#start-page .error.tooltip').fadeOut();
    f.find('input').attr('disabled',true);
    f.find('input[type=submit]')
     .css('background-image',"url(/images/ajax-small.gif)")
    $.ajax({
      url:      f.attr('action'),
      type:     f.attr('method'),
      dataType: 'json',
      data:     'url='+f.find('input[type=text]').attr('value'),
      complete: function() {
        f.find('input').attr('disabled',false);
        f.find('input[type=submit]')
         .css('background-image',"url(/images/form-add.png)")
      },
      success: function(data,textStatus,jqXHR) {
        $.get('/main?schedule='+data.schedule.id,function(mainPage) {
          $('#fb-login').fadeOut();
          $(mainPage).css({
              position:'absolute',
              left:'100%',
              width:$(window).width()
            })
            .appendTo('#pages');
          $(window).resize();
          if (data.warnings) {
            var html = '<div id="import-warning" class="warning"><p>The following course(s) failed to import:</p><ul>';
            for (var i=0; i<data.warnings.length; ++i) 
              html += '<li>' + data.warnings[i] + '</li>';
            
            html += '</ul><p>We keep our database of courses as up-to-date as possible, according to the official Schedule of Classes. Either the courses on your ScheduleMan do not exist anymore, or the lecture/section information is inconsistent. Please leave some feedback by clicking the feedback button to the left and we will follow up on this issue. Thanks!</p></div>';
            
            $('#main-page #article').prepend(html);
          }
          $('<div id="courses-after-tooltip" style="text-align:center"><span class="tooltip">Now that your schedule has been imported, connect to Facebook to see your friends\' schedules!</span></div>').appendTo('.main-aside');//.hide();
          $('#page-footer').fadeOut();
          $('#page-content').animate({height:$('#main-content').height()},800);
          $('#start-page').animate({left:'-100%'},800)
            .queue(function() { $(this).remove() });
          $('#main-bg').animate({ left:'0%' },800);
          $('#main-page')
            .animate({ left:'0%' },800)
            .queue(function() {
              $(this).css('position','relative');
              $('#page-content').height('auto');
              $('#page-footer')
                .removeClass('start')
                .show(); 
              $('.main-aside #courses-after-tooltip')
                .delay(data.schedule.scheduled_courses.length*200)
                .fadeIn(800);
              $('#fb-login')
                .delay(data.schedule.scheduled_courses.length*200)
                .fadeIn(); 
            });
        });
      },
      error: function(jqXHR,textStatus,errorThrown) {
        $('#start-page .error.tooltip').html(//errorThrown
          "We couldn't import your schedule. Check your URL and try again.").fadeIn();
      }
    });
  });

});


