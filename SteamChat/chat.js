
var addChatLine = function (name, state, text, myMessage)
{
	var table = $('#chat_table');
	
	var myMessageClass = myMessage ? ' mine' : '';
	
	var nameCell = $('<span class="state_' + unescape(state) + '"></span>');
	var textCell = $('<span class="text' + myMessageClass + '"></span>');
					 
	 nameCell.text(unescape(name) + ': ');
	 textCell.text(unescape(text));
	 
	 var row = $('<div></div>');
	 row.append(nameCell);
	 row.append(textCell);
	 
	 $('#chat_table').append(row);
 };

 var addActionLine = function (name, state, text, myMessage)
 {
	 var table = $('#chat_table');
	 
	 var myMessageClass = myMessage ? ' mine' : '';
	 
	 var actionCell = $('<span class="state_' + unescape(state) + ' action' + myMessageClass + '"></span>');
	 
	 actionCell.text(unescape(name) + ' ' + unescape(text));
	 
	 var row = $('<div></div>');
	 row.append(actionCell);
	 
	 $('#chat_table').append(row);
 };
 
 window.steam_addChatLine = addChatLine;
 window.steam_addActionLine = addActionLine;