// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery(document).ready(function($) {
    //Dropdown Menu
    var pull 		= $('#pull');
    menu 		= $('nav ul');
    menuHeight	= menu.height();

    $(pull).on('click', function(e) {
        e.preventDefault();
        menu.slideToggle();
    });
    $('body').on('click',function(e){
        if(!pull.is(e.target))
            menu.slideUp();
    });
    
    $(window).resize(function(){
        var w = $(window).width();
        if(w > 320 && menu.is(':hidden')) {
            menu.removeAttr('style');
        }
    });
    
/*===============Accordion in applicant dashboard==================*/   
    $('.accordion > .dashboard > div').not('.default').hide();
    var allPanels = $('.accordion > .dashboard > div');
    $('.accordion > div > a').click(function() {
      allPanels.slideUp();
      $(this).next('div').slideDown();
      return false;
    });
    
    $('.show-profile').click(function(){
        var this_link=$(this);
        $('#profile').toggle(function(){
            this_link.text($(this).is(':visible') ? "Hide Profile" : "Show Profile");
        });
        return false;
    });
});
//=========================Registration Form ==============================
jQuery(document).ready(function($){
//    $('span.error_explanation').hover(function(){
//    var $this=$(this);
//    $this.prev()
//                .find('input,select')
//                .focus();
//    $this.fadeOut(function(){
//        $this.remove();
//    });
//    });
    $('span.error_explanation').click(function(){
        var $this=$(this);
        $this.prev('input')
                .focus();
        $this.fadeOut(function(){
        $this.remove();
    });
    });

    $('span.error_explanation')
        .prev('input')
        .focus(function(){
            var $this=$(this).next();
            $this.fadeOut(function(){
            $this.remove();
        });
    });
    
    $('span.error_explanation')
        .prev('select')
        .change(function(){
            var $this=$(this).next().next();
            $this.fadeOut(function(){
            $this.remove();
        });
    });
    
    $('a.close').click(function(){
        $(this).parent().slideUp('slow');
    });
    
    $('#applicant_email').blur(function(){
        var email=$(this);
        var username=$('#applicant_username');
        if(username.data('edited')==false && !username.attr('disabled')){
            username.val(email.val());
            username.addClass('new-user');
        }
    });
    
    $('#applicant_username').on('focus',function(){
        var username=$(this);
        username.data('edited',true);
        username.removeClass('new-user');
    });
    
    $('#errorExplanation').click(function(){
        $(this).fadeOut();
    });
    
    
    $(document).ajaxStart(function(){
        $(".ajax_loader").show();
        $('input[type=submit]').attr('disabled',true);
      });

    $(document).ajaxStop(function(){
        $(".ajax_loader").hide();
        $('input[type=submit]').attr('disabled',false);
    });
    
});
//-----------------------------------------------------------------------

//----------------Bootstrap=====================


jQuery(document).ready(function($){
    $("input[type=checkbox]").bootstrapSwitch();
    $('select').selectpicker('mobile');
});