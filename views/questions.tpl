%include('header_init.tpl', heading='Treat attribute')
	<div id="select">
		<table class="table">
			<thead>
				<tr>
					<th>Attribute</th>
					<th>Method</th>
					<th>N° questionnaires answered</th>
					<th>Answer new questionnaire</th>
					<th>Calulate utility function</th>
				</tr>
			</thead>
			<tbody id="table_attributes">
			</tbody>
		</table>
            </div>
            <div id="trees">
            </div>
            <div id="charts">
            	<h2>Select the regression function you want to use</h2>

            </div>	

%include('header_end.tpl')
%include('js.tpl')

<script> var tree_image = '{{ get_url("static", path="img/tree_choice.png") }}'; </script>

<!-- Tree object -->
<script src="{{ get_url('static', path='js/tree.js') }}"></script>

<script>
$(function() { 
	$('#charts').hide();
	var asses_session = JSON.parse(localStorage.getItem("asses_session"));

	// We fill the table
	for (var i=0; i < asses_session.attributes.length; i++){
		var text = '<tr><td>' + asses_session.attributes[i].name + '</td><td>'+ asses_session.attributes[i].method + '</td><td>'+ asses_session.attributes[i].questionnaire.number +'</td>';
		if (asses_session.attributes[i].questionnaire.number < 3 && asses_session.attributes[i].completed == 'False') {
			text += '<td><button type="button" class="btn btn-default btn-xs answer_quest" id="q_' + asses_session.attributes[i].name  + '">Answer</button></td>';
		}
		else {
			text += '<td>Done</td>';
		}
		if (asses_session.attributes[i].completed == 'False'  && asses_session.attributes[i].questionnaire.number > 0) {
			text += '<td><button type="button" class="btn btn-default btn-xs calc_util" id="u_' + asses_session.attributes[i].name  + '">Utility function</button></td>';
		}
		else if (asses_session.attributes[i].completed == 'True') {
			text += '<td>Done</td>';
		}
		else{
			text += '<td>Please answer questionnaire</td>';
		}
		$('#table_attributes').append(text);
	}


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////// CLICK ON THE ANSWER BUTTON //////////////////////////////////////////////////////////////// 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	$('.answer_quest').click(function() {
		// we store the name of the attribute
		var name = $(this).attr('id').slice(2);

		// we delete the slect div
		$('#select').hide();

		// which index is it ?
		var indice;
		for (var j = 0; j < asses_session.attributes.length; j++) {
			if(asses_session.attributes[j].name == name){
				indice = j;
			}
		}

		var mode = asses_session.attributes[indice].mode;
		var val_min = asses_session.attributes[indice].val_min;
		var val_max = asses_session.attributes[indice].val_max;
		var method = asses_session.attributes[indice].method;

		function random_proba(proba1, proba2) {
			var coin = Math.round(Math.random());
			if (coin == 1) {
				return proba1;
			}
			else {
				return proba2;
			}
		}

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////// PE METHOD //////////////////////////////////////////////////////////////// 
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		if (method == 'PE') {
			(function(){
				// VARIABLES
				var probability = 0.75;
				var min_interval = 0;
				var max_interval = 1;

				// INTERFACE

				$('.container-fluid').append(
					'<div id=\"choice\">\
				            	<img src="{{ get_url('static', path='img/tree_choice.png') }}" class="center"></img>\
				            	<span id="questions_val_min"></span>\
				            	<span id="questions_val_max"></span>\
				            	<span id="questions_val_mean"></span>\
				            	<span id="questions_proba_haut"></span>\
				            	<span id="questions_proba_bas"></span>\
				        	</div>'
				);
				$('#questions_val_min').append(val_min);
				$('#questions_val_max').append(val_max);

				// The certain gain will change whether it is the 1st, 2nd or 3rd questionnaire
				if (asses_session.attributes[indice].questionnaire.number == 0) {
					var gain_certain = parseFloat(val_min) + (parseFloat(val_max)- parseFloat(val_min)) / 2;
					$('#questions_val_mean').append(gain_certain);
				}
				else if (asses_session.attributes[indice].questionnaire.number == 1) {
					var gain_certain = parseFloat(val_min) + (parseFloat(val_max)- parseFloat(val_min)) / 4;
					$('#questions_val_mean').append(gain_certain);
				}
				else if (asses_session.attributes[indice].questionnaire.number == 2) {
					var gain_certain = parseFloat(val_min) + (parseFloat(val_max)- parseFloat(val_min)) * 3 / 4;
					$('#questions_val_mean').append(gain_certain);
				}
				$('#choice').append('</div><button type="button" class="btn btn-default"><a id="gain">Gain</a></button><button type="button" class="btn btn-default"><a id="lottery">Lottery</a></button>');

				// FUNCTIONS
				function sync_values() {
					$('#questions_proba_haut').empty();
					$('#questions_proba_bas').empty();
					var proba_bas = 1 - probability;
					$('#questions_proba_bas').append(proba_bas.toFixed(2));
					$('#questions_proba_haut').append(probability);

				}

				function treat_answer(data){
					min_interval = data.interval[0];
					max_interval = data.interval[1];
					probability = parseFloat(data.proba).toFixed(2);

					if (max_interval - min_interval <= 0.05){
						sync_values();
						ask_final_value();
					}
					else {
						sync_values();
					}
				}

				function ask_final_value(){
					// we delete the choice div
					$('.btn').hide();
					$('.container-fluid').append(
						'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done, please now enter the value of the probability: <br /> '+ min_interval +'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" style="width: 100px; display: inline-block"> <= '+ max_interval +'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
					);

					// when the user validate
					$('.final_validation').click(function(){
						var final_proba = parseFloat($('#final_proba').val());

						if (final_proba <= max_interval && final_proba >= min_interval) {
							// we save it 
							asses_session.attributes[indice].questionnaire.points.push([gain_certain, final_proba]);
							asses_session.attributes[indice].questionnaire.number += 1;
							// backup local
							localStorage.setItem("asses_session", JSON.stringify(asses_session));
							// we reload the page
							window.location.reload();
						}
					});
				}

				sync_values();

				// HANDLE USERS ACTIONS
				$('#gain').click(function() {
					$.post('ajax', '{"type":"question", "method": "PE", "proba": '+ String(probability) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "0", "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
					});
				});

				$('#lottery').click(function() {
					$.post('ajax', '{"type":"question","method": "PE", "proba": '+ String(probability) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "1" , "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
					});
				});
			})()
		}

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////// LE METHOD //////////////////////////////////////////////////////////////// 
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		else if (method == 'LE') {
			(function(){
				// VARIABLES
				var probability = random_proba(0.38,0.13);
				var min_interval = 0;
				var max_interval = 0.5;

				// INTERFACE

				var arbre_gauche = new Arbre('gauche', '#trees');
				var arbre_droite = new Arbre('droite', '#trees');

				// SETUP ARBRE GAUCHE
				arbre_gauche.questions_proba_haut = probability;
				arbre_gauche.questions_val_max = val_max;
				arbre_gauche.questions_val_min = val_min;
				arbre_gauche.display();
				arbre_gauche.update();

				// SETUP ARBRE DROIT
				arbre_droite.questions_proba_haut = 0.5;

				// The certain gain will change whether it is the 1st, 2nd or 3rd questionnaire
				if (asses_session.attributes[indice].questionnaire.number == 0) {
					arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max) -  parseFloat(val_min)) / 2;
				}
				else if (asses_session.attributes[indice].questionnaire.number == 1) {
					arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max) -  parseFloat(val_min)) / 4;
				}
				else if (asses_session.attributes[indice].questionnaire.number == 2) {
					arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max)- parseFloat(val_min)) * 3 / 4;
				}

				arbre_droite.questions_val_min = val_min;
				arbre_droite.display();
				arbre_droite.update();

				// we add the choice button
				$('#trees').append('<button type="button" class="btn btn-default lottery_a">Lottery A</button><button type="button" class="btn btn-default lottery_b">Lottery B</button>')


				function treat_answer(data){
					min_interval = data.interval[0];
					max_interval = data.interval[1];
					probability = parseFloat(data.proba).toFixed(2);

					if (max_interval - min_interval <= 0.05){
						arbre_gauche.questions_proba_haut = probability;
						arbre_gauche.update();
						ask_final_value();
					}
					else {
						arbre_gauche.questions_proba_haut = probability;
						arbre_gauche.update();
					}
				}

				function ask_final_value(){
					$('.lottery_a').hide();
					$('.lottery_b').hide();
					$('.container-fluid').append(
						'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done, please now enter the value of the probability: <br /> '+ min_interval +'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" style="width: 100px; display: inline-block"> <= '+ max_interval +'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
					);

					// when the user validate
					$('.final_validation').click(function(){
						var final_proba = parseFloat($('#final_proba').val());

						if (final_proba <= max_interval && final_proba >= min_interval) {
							// we save it 
							asses_session.attributes[indice].questionnaire.points.push([arbre_droite.questions_val_max, final_proba * 2]);
							asses_session.attributes[indice].questionnaire.number += 1;
							// backup local
							localStorage.setItem("asses_session", JSON.stringify(asses_session));
							// we reload the page
							window.location.reload();
						}
					});
				}



				// HANDLE USERS ACTIONS
				$('.lottery_a').click(function() {
					$.post('ajax', '{"type":"question", "method": "LE", "proba": '+ String(probability) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "0" , "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
						console.log(data);
					});
				});

				$('.lottery_b').click(function() {
					$.post('ajax', '{"type":"question","method": "LE", "proba": '+ String(probability) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "1" , "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
						console.log(data);
					});
				});
			})()
		}

		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////// CE METHOD //////////////////////////////////////////////////////////////// 
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		else if (method == 'CE_Constant_Prob') {
			(function(){

				// VARIABLES
				if (asses_session.attributes[indice].questionnaire.number == 0) {
					var min_interval = val_min;
					var max_interval = val_max;
				}
				else if (asses_session.attributes[indice].questionnaire.number == 1) {
					var min_interval = asses_session.attributes[indice].questionnaire.points[0][0];
					var max_interval = val_max;
				}
				else if (asses_session.attributes[indice].questionnaire.number == 2) {
					var min_interval = val_min;
					var max_interval = asses_session.attributes[indice].questionnaire.points[0][0];
				}

				var L = [0.75*(max_interval-min_interval)+min_interval, 0.25*(max_interval-min_interval)+min_interval];
				var gain = Math.round(random_proba(L[0],L[1]));

				// INTERFACE

				var arbre_gauche = new Arbre('gauche', '#trees');

				// SETUP ARBRE GAUCHE
				arbre_gauche.questions_proba_haut = 0.5;
				arbre_gauche.questions_val_max = max_interval;
				arbre_gauche.questions_val_min = min_interval;
				arbre_gauche.questions_val_mean = gain;
				arbre_gauche.display();
				arbre_gauche.update();

				// we add the choice button
				$('#trees').append('<button type="button" class="btn btn-default gain">Gain with certainty</button><button type="button" class="btn btn-default lottery">Lottery</button>')

				function utility_finder(gain){
					var points = asses_session.attributes[indice].questionnaire.points;
					if (gain == val_min) {
						if (mode == 'normal') {
							return 0;
						}
						else {
							return 1;
						}
					}
					else if (gain == val_max) {
						if (mode == 'normal') {
							return 1;
						}
						else {
							return 0;
						}
					}
					else {
						for (var i =0;  i  < points.length; i++){
							if (points[i][0] == gain) {
								return points[i][1];
							}
						}
					}
				}

				function treat_answer(data){
					min_interval = data.interval[0];
					max_interval = data.interval[1];
					gain = data.gain;

					if (max_interval - min_interval <= 0.05 * arbre_gauche.questions_val_max - arbre_gauche.questions_val_min || max_interval - min_interval  < 2){
						$('.gain').hide();
						$('.lottery').hide();
						arbre_gauche.questions_val_mean = gain;
						arbre_gauche.update();
						ask_final_value();
					}
					else {
						arbre_gauche.questions_val_mean = gain;
						arbre_gauche.update();
					}
				}

				function ask_final_value(){
					$('.lottery_a').hide();
					$('.lottery_b').hide();
					$('.container-fluid').append(
						'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done, please now enter the value of the gain: <br /> '+ min_interval +'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" style="width: 100px; display: inline-block"> <= '+ max_interval +'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
					);

					// when the user validate
					$('.final_validation').click(function(){
						var final_gain = parseInt($('#final_proba').val());
						var final_utility = arbre_gauche.questions_proba_haut * utility_finder(arbre_gauche.questions_val_max) + (1 - arbre_gauche.questions_proba_haut) * utility_finder(arbre_gauche.questions_val_min);
						console.log(arbre_gauche.questions_proba_haut);
						console.log(utility_finder(arbre_gauche.questions_val_max));
						console.log(utility_finder(arbre_gauche.questions_val_min));
						if (final_gain <= max_interval && final_gain >= min_interval) {
							// we save it 
							asses_session.attributes[indice].questionnaire.points.push([final_gain, final_utility]);
							asses_session.attributes[indice].questionnaire.number += 1;
							// backup local
							localStorage.setItem("asses_session", JSON.stringify(asses_session));
							// we reload the page
							window.location.reload();
						}
					});
				}



				// HANDLE USERS ACTIONS
				$('.lottery').click(function() {
					$.post('ajax', '{"type":"question", "method": "CE_Constant_Prob", "gain": '+ String(gain) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "0" , "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
						console.log(data);
					});
				});

				$('.gain').click(function() {
					$.post('ajax', '{"type":"question","method": "CE_Constant_Prob", "gain": '+ String(gain) + ', "min_interval": '+ min_interval+ ', "max_interval": '+ max_interval+' ,"choice": "1" , "mode": "'+String(mode)+'"}', function(data) {
						treat_answer(data);
						console.log(data);
					});
				});
			})()
		}
	});

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////// CLICK ON THE UTILITY BUTTON //////////////////////////////////////////////////////////////// 
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	$('.calc_util').click(function() {
		// we store the name of the attribute
		var name = $(this).attr('id').slice(2);

		// we delete the slect div
		$('#select').hide();

		// which index is it ?
		var indice;
		for (var j = 0; j < asses_session.attributes.length; j++) {
			if(asses_session.attributes[j].name == name){
				indice = j;
			}
		}

		var val_min = asses_session.attributes[indice].val_min;
		var val_max = asses_session.attributes[indice].val_max;
		var mode = asses_session.attributes[indice].mode;
		var points = asses_session.attributes[indice].questionnaire.points.slice();

		if (mode=="normal") {
			points.push([val_max, 1]);
			points.push([val_min, 0]);
		}
		else {
			points.push([val_max, 0]);
			points.push([val_min, 1]);
		}
		json_2_send = {"type":"calc_util"};
		json_2_send["points"] = points;

		$.post('ajax', JSON.stringify(json_2_send), function(data) {

			$.post('ajax', JSON.stringify({"type":"svg", "data": data, "min": val_min, "max": val_max, "liste_cord": points}), function(data2) {
				$('#charts').append('<div id="main_graph">'+ data2+'</div>');

				for (var key in data) {
					$('#charts').show();
					if (key == 'exp') {
						div_function = '<div id="' + key +'" class="functions_graph"><h3 style="color:#401539">Exponential</h3><br />Coefficient of determination: ' + Math.round(data[key]['r2'] * 100) / 100 + '<br /><button type="button" class="btn btn-default b_choose">Choose</button></div>';
						$('#charts').append(div_function);
					}
					else if (key == 'log') {
						div_function = '<div id="' + key +'" class="functions_graph"><h3 style="color:#D9585A">Logarithmic</h3><br />Coefficient of determination: ' + Math.round(data[key]['r2'] * 100) / 100 + '<br /><button type="button" class="btn btn-default b_choose">Choose</button></div>';
						$('#charts').append(div_function);
					}
					else if (key == 'pow') {
						div_function = '<div id="' + key +'" class="functions_graph"><h3 style="color:#6DA63C">Power</h3><br />Coefficient of determination: ' + Math.round(data[key]['r2'] * 100) / 100 + '<br /><button type="button" class="btn btn-default b_choose">Choose</button></div>';
						$('#charts').append(div_function);
					}
					else if (key == 'quad') {
						div_function = '<div id="' + key +'" class="functions_graph"><h3 style="color:#458C8C">Quadratic</h3><br />Coefficient of determination: ' + Math.round(data[key]['r2'] * 100) / 100 + '<br /><button type="button" class="btn btn-default b_choose">Choose</button></div>';
						$('#charts').append(div_function);
					}
					else if (key == 'lin') {
						div_function = '<div id="' + key +'" class="functions_graph"><h3 style="color:#D9B504">Linear</h3><br />Coefficient of determination: ' + Math.round(data[key]['r2'] * 100) / 100 + '<br /><button type="button" class="btn btn-default b_choose">Choose</button></div>';
						$('#charts').append(div_function);
					}
				}

				$('.b_choose').click(function(){
					var selected_function = $(this).parent().attr('id');
					
					// we save it
					asses_session.attributes[indice].questionnaire.utility[selected_function] = data[selected_function];
					asses_session.attributes[indice].completed = 'True';
					// backup local
					localStorage.setItem("asses_session", JSON.stringify(asses_session));
					// we reload the page
					window.location.reload();

				});
			});
		});

	});
});
</script>

</body>

</html>