// a function that helps render a view. I'm keeping it here unless someone has a good reason to move it.
var renderKatex = function(problem) {
	var output = "";
	var dpos = problem.indexOf('$');
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

app.view = function(ctrl) {
	// this just makes my life a little easer
	var user = app.vm.user;
	return [

	// start with returning the "controls" (aka switch between HS/C and show the problem name)
	m(".controls",
		m("h2", app.vm.problem().problems[user.level].name),

		// needed this so this text easily lined up when turning on/off  the level selector
		m(".postControls", 
			m("p#date", app.vm.problem().problems[user.level].date),
			m("p#category", app.vm.problem().problems[user.level].category)
		)
	),

	// DISPLAYING THE PROBLEM
    m("#problem",
    	// it's a little gross. but it prevents the answer from just being in the dom on page load
    	// and yes - I'm aware it's in the API
    	user.showAnswerBox() 
    	? app.vm.isAnswerCorrect()() // o.0 -> this is hilarious!
    		? m(".flex", 
				m("h1", "Correct!"),
				m("p", user.answer() + " is correct! " + (app.vm.problem().problems[user.level].correct_message ? app.vm.problem().problems[user.level].correct_message : "New problems every Monday, Wednesday, and Friday!"))
			)
    		: m("#incorrect",
				m("h3", user.showAnswer() ? "Answer: " + app.vm.problem().problems[user.level].solution.answer : "Sorry, that's not correct!"),
				m(".buttons",
					m("button#try", {onclick: app.vm.toggle.bind(this, user.showAnswerBox)}, "Try Again"),
					m("button.error",  {style: {display: app.vm.display(app.vm.opposite(user.showAnswer))}, onclick: app.vm.forceTrue.bind(this, user.showAnswer)}, "Show Answer"),
					m("button.warning", {style: {display: app.vm.display(user.showAnswer)}, onclick: app.vm.toggle.bind(this, user.showDescription)}, user.showDescription() ? "Hide Description" : "Show Description")
				),
				m("pre", {style: { display: user.showDescription() ? "block" : "none"}}, m.trust(renderKatex(app.vm.problem().problems[user.level].answer_desc)))
			)
    	: m("pre", m.trust(renderKatex(app.vm.problem().problems[user.level].problem)))
	),

	// HINT
	app.vm.showHintBox()() ?
	m("table", m("tr",
		m("td", m("button", {onclick: app.vm.toggle.bind(this, user.showHint)}, user.showHint() ? "Hide Hint" : "Show Hint")),
		m("td", m("span", user.showHint() ? m.trust(renderKatex(app.vm.problem().problems[user.level].hint)) : ""))
	)) : "",

	// ANSWER FORM
	m("form", {onsubmit: ctrl.doNothing.bind(ctrl)}, // meh - gotta make that controller feel special!
		m("label", {for: "answer"}, "Answer:"),
		m("input[type=text]", {value: user.answer(), id: "answer", placeholder: "Enter your answer here", autocomplete: "off", onchange: m.withAttr("value", user.answer)}),
		m("input", { type: "submit", value:"Submit", onclick: app.vm.forceTrue.bind(ctrl, user.showAnswerBox)})
	),

	m("p.nav", {style: {"text-align": "center"}},
		m("a.icon-step-backward.button.pseudo", {href: "/p/2015-11-23", style: {visibility: app.vm.visibility(app.vm.problem().dateInfo.previous)}}, "First"),
		m("a.icon-backward.button.pseudo", {href: "/p/" + app.vm.problem().dateInfo.previous, style: {visibility: app.vm.visibility(app.vm.problem().dateInfo.previous)}}, "Prev"),
		m("a.icon-step-forward.button.pseudo", {href: "/p/" + app.vm.problem().dateInfo.next, style: {visibility: app.vm.visibility(app.vm.problem().dateInfo.next)}}, "Next"),
		m("a.icon-forward.button.pseudo", {href: "/", style: {visibility: app.vm.visibility(app.vm.problem().dateInfo.next)}}, "Last")
	)

	];
};