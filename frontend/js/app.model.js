// our model stuff will go in app.
// this includes anything that modifies data
var app = {};

// load additional js scripts after the jquery call
app.additionalScripts = {};
app.additionalScripts["Duration Compare"] = "/static/lib/juration.js";

// download additional scripts if need be
// found somewhere on stack overflow as a non-jquery async script loader
// if i find the link I'll post it here
var getScript = function(source, callback) {
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
};

// function to get the data for our problem
app.getProblem = function() {
	
	// this feels kinda gross... open to ideas for how to get the same data
	var today = window.location.href.substring(window.location.href.lastIndexOf('/')+1);
	if (!today) {
		var todayDate = new Date();
		var day = todayDate.getDate();
		var month = todayDate.getMonth()+1;
		var year = todayDate.getFullYear();
		today = year + "-" + month + "-" + day;
	}
	var request = m.prop([]);
	m.request({method: "GET", url: "/api/v1/problems/" + today,
		unwrapError: function(response) {
			console.log(response.errors);
			// dailyMath.loadError = response.errors;
	        return response.errors;
	    }
	}).then(request).then(function(req) {
		req.problems.map(function(probs) {
			if (app.additionalScripts[probs.solution.method]) {
				getScript(app.additionalScripts[probs.solution.method]);
			}
		});
	});
	return request;
};

app.levels = [
	{title: "High School", level: 0},
	{title: "College", level: 1}
];

// our viewmodel. All UI-centric logic goes here
app.vm = {};
app.vm.init = function() {
	// load up our problem
	app.vm.problem = app.getProblem();

	// again levels used in the view (this one feels a little ridiculous)
	app.vm.levels = app.levels;

	// the user elements for our view
    app.vm.user = {
		answer: m.prop(''),
		level: 0,
		showHint: m.prop(false),
		showAnswerBox: m.prop(false),
		showDescription: m.prop(false),
		showAnswer: m.prop(false)
	};

	// do my sweet comparisons based on solution methods
	app.vm.compare = {};
	app.vm.compare["Duration Compare"] = function(correctValue, usersValue) {
		// TODO: make this handle juration errors gracefully
		return app.vm.propy(juration.parse(correctValue) == juration.parse(usersValue));
	};
	app.vm.compare["Numerical Compare"] = function(correctValue, usersValue) {
		return app.vm.propy(correctValue == usersValue);
	};

	// getting SUPERDRY now.
	// NOTE: this also works with truthy/falsey
	app.vm.propy = function(expr) {
		if (expr) { return m.prop(true); } else { return m.prop(false); }
	};
	
	// should we show the switcher or not?
	app.vm.showLevels = function() {
		return app.vm.propy(app.vm.problem().problems.length > 1);
	};

	// did hint get sent over or not?
	app.vm.showHintBox = function() {
		return app.vm.propy(app.vm.problem().problems[app.vm.user.level].hint);
	};

	// do that logic yo
	// i'm keeping the factory above "as-is" for now. 
	// I could skip passing in the variables to those functions, but I keep thinking it'll come in handy later on
	app.vm.isAnswerCorrect = function() {
		var solution = app.vm.problem().problems[app.vm.user.level].solution;
		return app.vm.compare[solution.method](solution.answer,	app.vm.user.answer());
	};

	// used to toggle m.prop() boolean values when a user clicks on something
    app.vm.toggle = function(prop) {
    	prop(!prop());
    };

    // non destructive toggle
    app.vm.opposite = function(prop) {
    	return m.prop(!prop());
    };

    // ALWAYS TRUE.
    app.vm.forceTrue = function(prop) {
    	prop(true);
    };

    // used to show/hide a UI element in css
    app.vm.display = function(prop) {
    	if (prop()) { return "block"; } else { return "none"; }
    };

    // changes between the "high school" and "college" problem (level 1 and 2)
    app.vm.changeLevel = function(newLevel) {
		app.vm.user.level = newLevel;
		app.vm.user.showHint(false);
		app.vm.user.showAnswerBox(false);
		app.vm.user.showAnswer(false);
		app.vm.user.showDescription(false);
		app.vm.user.answer('');
	};

};