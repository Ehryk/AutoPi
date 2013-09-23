


AutoPi = function(){
	// "static" vars
	this.host = "http://192.168.1.15";
	// ivar 

	// methods
	this.read = function(pin, callback){
		_callback = callback;
		$.post(this.host + "/gpio/read/" + pin, {
			"success":function(){
				console.log(arguments);
				_callback();
			},
			"error":function(jqXHR){
				console.warn("Error with yo shit yo'");
				console.warn(jqXHR);
			}
		})
	}

	this.readX = function(pin, callback){
		_callback = callback;
		$.ajax({
			url: this.host + "/gpio/read/" + pin +".json",
			type: "GET",
			dataType: "jsonp",
			"success":function(){
				console.log(arguments);
				_callback();
			},
			"error":function(jqXHR){
				
				console.warn(jqXHR);
			}
		});
	}	

	return this;
}

$(document).ready(function(){

	
	mypi = new AutoPi();

	$('button.toggle').on('click', function() {
		// Fire button event before flipping toggle switch 
		console.log( $._data(this, "events") ); 

		statusIndicator = $(this).find('div.on, div.off');
		$(statusIndicator).hasClass('on') ? $(statusIndicator).attr('class', 'off').html('OFF') : $(statusIndicator).attr('class', 'on').html('ON') ;

		mypi.readX(3, function(){ console.log('ho') });
	});


	
})
