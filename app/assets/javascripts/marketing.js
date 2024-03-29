// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap-modal.js

$(document).ready(function() {  
  
    $('.login').click(function(event) {
      event.preventDefault();
      
      if ($('#login-form').is(':visible')) {
        $('.login').removeClass('active');
        $('#login-form').modal('hide');
      } else {
        $(this).addClass('active');
        $('#login-form').modal('show');
        $('#login-form').find(':text:first')[0].focus(); 
      }
    });
    
});
