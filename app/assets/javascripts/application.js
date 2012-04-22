// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.labelify.js
//= require bootstrap-modal.js
//= require facebox

var myTimer = null;
var TOTAL_SECONDS = 0;

$(document).ready(function() {

  $('.close').live('click', function() {
    $(document).trigger('close.facebox');
  });

  $(".data-entry input").labelify(
    {text: "label", labelledClass: "labelHighlight"});

  if($('pre#top').length != 0)
  {
    update_top();
  }
  
  if($('#server-list').length != 0)
  {
    update_server_list();
  }
  
  if($('#memory').length != 0)
  {
    update_memory();
  }
  
  if($('pre#log').length != 0)
  {
    update_log();
  }

  $.facebox.settings.opacity = 0.3;

  jQuery('a[rel*=facebox]').facebox();

  $('#code-view-button').click(function(){
    jQuery.facebox({ div: '#code-view' });
    return false;
  });

  $('#public-key-button').click(function(){
    jQuery.facebox({ div: '#public-key' });
    return false;
  });

  $('#add-server-link').click(function(){
    jQuery.facebox({ div: '#add-server-form' });
    return false;
  });

  $('#add-user-link').click(function(){
    jQuery.facebox({ div: '#add-user-form' });
    return false;
  });

  $('a.remote-delete').click(function() {
    return confirm("Are you sure you want to delete ?");
  });

  $('#external_id').live('change', function() {
    var code = $('#code-area').val().replace(/external\/.*$/, 'external/' 
      + $(this).val());
    $('#facebox #code-area').val(code);
  });
  
  if($('#livestats').length != 0)
  {
    $("#load-graph").html('<div class="bar" style="width: 0%"></div>');
    $("#memory-graph").html('<div class="bar" style="width: 0%"></div>');
    $("#swap-graph").html('<div class="bar" style="width: 0%"></div>');
    update_stats();
  }
  
  if($('.slider').length != 0)
    $(".slider").slider({
      slide: function(event, ui) {
        type = $($(this).parent()).attr('class') 
        $('#' + type + '-show').text(ui.value);
        $('#' + type + '-value').val(ui.value);
      }
    });
    
    $('.slider').each(function(i, val) {
      type = $($(val).parent()).attr('class')
      newVal = $('#' + type + '-value').val();
      $('#' + type + '-show').text(newVal);
      $(val).slider('value',newVal);
    });
});

function add_server()
{
	var measure_id  = $('#facebox .measure_id:first').val();
	var server_id = $('#facebox select:first').val();
	var dataString = 'server_id=' + server_id;
	var server_name = $('#facebox select:first :selected').text();
	var url = '/measures/' + measure_id + '/addserver';
	$.ajax({
		type: "POST",
		url: url,
		data: dataString,
		success: function(xml) 
		{ 
                  location.reload();
		}
	});

	$.facebox.close(); 
    	return false;
}

function add_user()
{
	var wait_for  = $('#facebox .wait_for:first').val();
	var measure_id  = $('#facebox .measure_id:first').val();
	var type  = $('#facebox .notify_type:first').val();
	var user_id = $('#facebox select:first').val();
	var user_name = $('#facebox select:first :selected').text();
	var dataString = 'user_id=' + user_id + '&notify_type=' + type + '&wait_for=' + wait_for;
	var url = '/measures/' + measure_id + '/adduser';
  var msg = 'Email';
  if(type == '1')
    msg = 'SMS';
  if(type == '2')
    msg = 'Email and SMS';

	$.ajax({
		type: "POST",
		url: url,
		data: dataString,
		success: function(xml) 
		{ 
                  location.reload();
		}
	});

	$.facebox.close(); 
    return false;
}

function convertGBtoMB(val)
{
	var conv = parseFloat(val);
	if(/GB/.test(val))
	{
		conv = conv * 1024;
	}

	return conv;	
}

function timer_text(name, time)
{
	if(time > 1)
	{
		$('#timer-text').text('(Update in ' + time + ' seconds)');
		time--;
    TOTAL_SECONDS++;
		setTimeout('timer_text(' + name + ',' + time + ')', 1000);
	}
	else
	{
		$('#timer-text').text('(Update in 1 second)');
		time--;
		setTimeout(name, 1000);
    TOTAL_SECONDS++;
	}
	
}
 
function update_memory()
{    
  var id = $('#server_id').attr('value');
  $.ajax({
    type: "GET",
    url: "/statistics/meminfo/" + id + ".xml",
    dataType: "xml",
    success: function(xml) {
      $(xml).find('memory').each(function(){
      swapused = $(this).find('swapused').text();
      swaptotal = $(this).find('swaptotal').text();
      memused = $(this).find('used').text();
      memtotal = $(this).find('total').text();
      $('#swap2').text(swapused + ' MB / ' + swaptotal + ' MB');
      $('#memory2').text(memused + ' MB / ' + memtotal + ' MB');
      });
    }
  });
  
  timer_text('update_memory', 60);
}

function update_log()
{    
  var id = $('#server_id').attr('value');
  var log_id = $('#log_id').attr('value');
  $.ajax({
    type: "GET",
    url: "/statistics/log/" + id + ".xml?log_id=" + log_id,
    dataType: "xml",
    success: function(xml) {
      $('pre#log').html($(xml).text());
    }
  });
  
  timer_text('update_log', 5);
}

function update_top()
{  
  var id = $('#server_id').attr('value');
  $.ajax({
    type: "GET",
    url: "/statistics/top/" + id + ".xml",
    dataType: "xml",
    success: function(xml) {
      $('pre#top').html($(xml).find('top').find('top').text());
      $('span#load1').html($(xml).find('load1').text());
      $('span#load2').html($(xml).find('load2').text());
      $('span#load3').html($(xml).find('load3').text());
    }
  });
  
  timer_text('update_top', 60);
}

function update_stats()
{     
  var id = $('#server_id').attr('value'); 
  $.ajax({
    type: "GET",
    url: "/statistics/stats/" + id + ".xml",
    dataType: "xml",
    success: function(xml) {
      $(xml).find('status').each(function(){
      load = $(this).find('load1').text();
      loadtotal = $(this).find('loadtotal').text();
      swapused = $(this).find('swapused').text();
      swaptotal = $(this).find('swaptotal').text();
      memused = $(this).find('used').text();
      memtotal = $(this).find('total').text();
      var cpucount = $(this).find('cpucount').text();
      var uptime = $(this).find('uptime').text();
      var rx = $(this).find('rx').text();
      var tx = $(this).find('tx').text();

      clearTimeout(myTimer);
      doUptime(parseInt(uptime));

      $('#rx').text(rx + ' (' + readablizeBytes(parseInt(rx)) + ')');
      $('#tx').text(tx + ' (' + readablizeBytes(parseInt(tx)) + ')');
      $('#cpu-load').text(load);
      $('#cpu-load2').text(load + ' / ' + cpucount);
      $('#memory-used').text(memused + ' MB');
      $('#memory2').text(memused + ' MB / ' + memtotal + ' MB');
      $('#memory_stat').text(memused + ' MB / ' + memtotal + ' MB');
      $('#swap').text(swapused + ' MB');
      $('#swap2').text(swapused + ' MB / ' + swaptotal + ' MB');

      $('#load1').text($(this).find('load1').text());
      $('#load2').text($(this).find('load2').text());
      $('#load3').text($(this).find('load3').text());

      $('#cpu').text($(this).find('cpu').text());
      $('#cpumhz').text($(this).find('cpumhz').text());
      $('#cpucount').text($(this).find('cpucount').text());

      // Update TX rate
      var last_tx = $('#last-tx').val();
      if(last_tx != '')
      {
        var diff = (parseInt(tx) - parseInt(last_tx)) * 6;
        $('#tx_rate').text(readablizeBytes(diff));
      }
      $('#last-tx').val(tx);
      
      swapperc = (convertGBtoMB(swapused) / convertGBtoMB(swaptotal)) * 100;
        
      memperc = (convertGBtoMB(memused) / convertGBtoMB(memtotal)) * 100;
      
      load = load * 100 / parseInt(cpucount);

      if(load > 100)
          load = 100;
      
      $("#load-graph").html(
        '<div class="bar" style="width: ' + load + '%"></div>');
      $("#memory-graph").html(
        '<div class="bar" style="width: ' + memperc + '%"></div>');
      $("#swap-graph").html(
        '<div class="bar" style="width: ' + swapperc + '%"></div>');
      
      var i = 0;
      $(this).find("percent").each(function() {
        $("#drive-graph" + i).html(
          '<div class="bar" style="width: ' 
          + parseInt($(this).text()) + '%"></div>');
        i++;
      });
      
      });
    }
  });
  
  timer_text('update_stats', 60);
}

function update_server_list()
{
  $('#server-list').load('/servers.js',
    function() {
      jQuery('a[rel*=facebox]').facebox(); });

  timer_text('update_server_list', 60);
}

function readablizeBytes(bytes) {
  var s = ['bytes', 'kb', 'MB', 'GB', 'TB', 'PB'];
  var e = Math.floor(Math.log(bytes)/Math.log(1024));
  return (bytes/Math.pow(1024, Math.floor(e))).toFixed(2)+" "+s[e];
}

function doUptime(upSeconds) 
{
  var uptimeString = "";
  var secs = parseInt(upSeconds % 60);
  var mins = parseInt(upSeconds / 60 % 60);
  var hours = parseInt(upSeconds / 3600 % 24);
  var days = parseInt(upSeconds / 86400);

  if (days > 0) {
    uptimeString += days;
    uptimeString += ((days == 1) ? " Day" : " Days");
  }

  if (hours > 0) {
    uptimeString += ((days > 0) ? ", " : "") + hours;
    uptimeString += ((hours == 1) ? " Hour" : " Hours");
  }

  if (mins > 0) {
    uptimeString += ((days > 0 || hours > 0) ? ", " : "") + mins;
    uptimeString += ((mins == 1) ? " Min" : " Mins");
  }

  if (secs > 0) {
    uptimeString += ((days > 0 || hours > 0 || mins > 0) ? ", " : "") + secs;
    uptimeString += ((secs == 1) ? " Sec" : " Secs");
  }

  $("#uptime").text(uptimeString);

  upSeconds++;

  myTimer = setTimeout("doUptime("+upSeconds+")",1000);
}
