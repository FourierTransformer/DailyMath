function getScript(source, callback) {
    var script = document.createElement('script');
    var prior = document.getElementsByTagName('script')[0];
    script.async = 1;
    prior.parentNode.insertBefore(script, prior);

    script.onload = script.onreadystatechange = function( _, isAbort ) {
        if(isAbort || !script.readyState || /loaded|complete/.test(script.readyState) ) {
            script.onload = script.onreadystatechange = null;
            script = undefined;

            if(!isAbort) { if(callback) callback(); }
        }
    };

    script.src = source;
}

	var dailyMath = {};
		dailyMath.user = function() {
			this.answer = m.prop('');
			this.level = 0;
			this.showHint = false;
			this.showAnswerBox = false;
		};

		dailyMath.renderKatex = function(problem) {
			output = "";
			dpos = problem.indexOf('$');
			// my hacky parser
			while (dpos !== -1) {
				var start_pos = dpos + 1;
				var end_pos = problem.indexOf('$',start_pos);
				var text_to_get = problem.substring(start_pos,end_pos);
				text_to_get = text_to_get.replace(/(?:\r\n|\r|\n)/g, '<br />');
				output = output.concat(problem.substring(0, start_pos-1) + katex.renderToString(text_to_get));
				problem = problem.substring(end_pos+1);
				dpos = problem.indexOf('$');
			}
			output = output.concat(problem.substring(dpos));
			return output;
		};

		dailyMath.levels = [
			{title: "High School", level: 0},
			{title: "College", level: 1}
		];

		// load additional js scripts after the jquery call
		dailyMath.additionalScripts = {};
		dailyMath.additionalScripts["Duration Compare"] = "/static/lib/juration.js";

		// do my sweet compare based on solution method
		dailyMath.compare = {};
		dailyMath.compare["Duration Compare"] = function(correctValue, usersValue) {
			if (juration.parse(correctValue) == juration.parse(usersValue)) {
				return true;
			} else {
				return false;
			}
		};
		dailyMath.compare["Numerical Compare"] = function(correctValue, usersValue) {
			if (correctValue == usersValue) {
				return true;
			} else {
				return false;
			}
		};


		dailyMath.loadError = null;
		dailyMath.load = function() {
			var today = null;
			if (!today) {
				var todayDate = new Date();
				var day = todayDate.getDate();
				var month = todayDate.getMonth()+1;
				var year = todayDate.getFullYear();
				today = year + '-' + month + '-' + day;
			}
			var request = m.prop([]);
			m.request({method: "GET", url: "/api/v1/problems/" + today,
				unwrapError: function(response) {
					console.log(response.errors);
					dailyMath.loadError = response.errors;
			        return response.errors;
			    }
			}).then(request).then(function(req) {
				req.problems.map(function(probs) {
					if (dailyMath.additionalScripts[probs.solution.method]) {
						getScript(dailyMath.additionalScripts[probs.solution.method]);
					}
				});
			});
			return request;
		};

		dailyMath.controller = function() {
			this.user = new dailyMath.user();
			this.problem = dailyMath.load();

			this.showDescription = false;
			this.showAnswer = false;

			//hmmmm oft-repeated code. Needs a cleanup...
			this.toggleHint = function() {
				this.user.showHint === true ? this.user.showHint = false : this.user.showHint = true;
			};

			this.toggleAnswerBox = function() {
				this.user.showAnswerBox === true ? this.user.showAnswerBox = false : this.user.showAnswerBox = true;
			};

			this.toggleAnswer = function() {
				this.showAnswer === true ? this.showAnswer = false : this.showAnswer = true;
			};

			this.toggleAnswerDescription = function() {
				this.showDescription === true ? this.showDescription = false : this.showDescription = true;
			};

			this.hintButtonDisplay = function() {
				if (this.problem().problems[this.user.level].hint) {
					return "block";
				} else {
					return "none";
				}
			};

			this.answerDisplay = function() {
				if (this.user.showAnswerBox) {
					return "block";
				} else {
					return "none";
				}
			};

			this.doNothing = function() { return false; };

			this.submitAnswer = function() {
				// console.log(this.user.answer());
				// console.log(this.problem().problems[this.user.level].answer);
				this.user.showAnswerBox = true;
				if (this.user.answer() == this.problem().problems[this.user.level].solution.answer) {
					// alert("That is correct!");
				} else {
					// alert("Sorry, " + this.user.answer() + " is not correct. Try Again!")
				}
			};

			// eh - This should do for now...!
			this.isAnswerCorrect = function() {
				var prob = this.problem().problems[this.user.level];
				if (dailyMath.compare[prob.solution.method](this.user.answer(), prob.solution.answer)) {
					return m(".flex", 
						m("h1", "Correct!"),
						m("p", this.user.answer() + " is a valid response! New problems every Monday, Wednesday, and Friday!")
					);
				} else {
					// here is where it really starts feeling slimy
					return m("#incorrect",
						m("h3", this.showAnswer ? "Answer: " + this.problem().problems[this.user.level].solution.answer : "Sorry, that's not correct!"),
						m(".buttons",
							m("button#try", {onclick: this.toggleAnswerBox.bind(this)}, "Try Again"),
							m(this.showAnswer ? "button.error" : "button.warning", {onclick: this.showAnswer ? this.toggleAnswerDescription.bind(this) : this.toggleAnswer.bind(this)}, this.showAnswer ? "Show Description" : "Show Answer")
						),
						m("pre", {style: { display: this.showDescription ? "block" : "none"}}, m.trust(dailyMath.renderKatex(this.problem().problems[this.user.level].answer_desc)))
					);
				}
			};
			
			this.showLevels = function() {
				if (this.problem().problems.length == 1) {
					return "none";
				} else {
					return "block";
				}
			};
			this.changeLevel = function(newLevel) {
				this.user.level = newLevel;
				this.user.showHint = false;
			};

		};

		dailyMath.view = function(ctrl) {
			if (dailyMath.loadError) {
				// I unfortunately couldn't get the error message to show from the load function
				// so I set a variable instead. I might be able to make the load() function smarter
				// to handle this. But right now, I am good.
				return m("p", dailyMath.loadError);
			} else {
			return [

				// THE CONTROLS AND STUFF
				m(".controls",
				m("h2", ctrl.problem().problems[ctrl.user.level].name),
				m("ul", {style: {display: ctrl.showLevels()}},
				dailyMath.levels.map(function(selectedLevel) {
		            return m("li",
		            		m(selectedLevel.level == ctrl.user.level ? "span.current" : "button", {onclick: ctrl.changeLevel.bind(ctrl, selectedLevel.level)}, selectedLevel.title)
		            		);
		        })),
				
				// needed this so this text easily lined up when turning on/off  the level selector
				m(".postControls", 
					m("p#date", ctrl.problem().problems[ctrl.user.level].date),
					m("p#category", ctrl.problem().problems[ctrl.user.level].category)
				)
		        ),

				// DISPLAYING THE PROBLEM
				// also, the isAnswerCorrect feels wrong. I'll look into how to do this proper a little later...
		        m("#problem",
		        	ctrl.user.showAnswerBox ? ctrl.isAnswerCorrect()
		        	 :
					m("pre", m.trust(dailyMath.renderKatex(ctrl.problem().problems[ctrl.user.level].problem)))
				),

				//HINT
				m(".row#hint",
					m(".fourth", m("button", {onclick: ctrl.toggleHint.bind(ctrl), style: {display: ctrl.hintButtonDisplay()}}, ctrl.user.showHint ? "Hide Hint" : "Show Hint")),
					m("p", ctrl.user.showHint ? m.trust(dailyMath.renderKatex(ctrl.problem().problems[ctrl.user.level].hint)) : "")
				),

				// THE ANSWER FORM
				m("form", {onsubmit: ctrl.doNothing.bind(ctrl)},
					m("label", {for: "answer"}, "Answer:"),
					m("input[type=text]", {id: "answer", placeholder: "Enter your answer here", autocomplete: "off", onchange: m.withAttr("value", ctrl.user.answer)}),
					m("input", { type: "submit", value:"Submit", onclick: ctrl.submitAnswer.bind(ctrl)})
				),

			]; }
		};
