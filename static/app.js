var app={};app.additionalScripts={},app.additionalScripts["Duration Compare"]="/static/lib/juration.js",app.additionalScripts["Byte Compare"]="/static/lib/nattybytes.js",app.additionalScripts["MathJS Compare"]="https://cdnjs.cloudflare.com/ajax/libs/mathjs/2.5.0/math.min.js";var getScript=function(e,p){var r=document.createElement("script"),t=document.getElementsByTagName("script")[0];r.async=1,t.parentNode.insertBefore(r,t),r.onload=r.onreadystatechange=function(e,t){(t||!r.readyState||/loaded|complete/.test(r.readyState))&&(r.onload=r.onreadystatechange=null,r=void 0,t||p&&p())},r.src=e},padVals=function(e){return 10>e?"0"+e:e};app.getProblem=function(){var e=m.prop([]),p=function(e){e.problems.map(function(e){app.additionalScripts[e.solution.method]&&getScript(app.additionalScripts[e.solution.method])})};if("undefined"!=typeof sha32)return e(JSON.parse(window.atob(sha32))),p(e()),e;var r=new Date,t=r.getDate(),o=r.getMonth()+1,a=r.getFullYear();return today=a+"-"+padVals(o)+"-"+padVals(t),m.request({method:"GET",url:"/api/v1/problems/"+today,unwrapError:function(e){return console.log(e.errors),e.errors}}).then(e).then(p),e},app.levels=[{title:"High School",level:0},{title:"College",level:1}],app.vm={},app.vm.init=function(){app.vm.problem=app.getProblem(),app.vm.levels=app.levels,app.vm.user={answer:m.prop(""),level:0,showHint:m.prop(!1),showAnswerBox:m.prop(!1),showDescription:m.prop(!1),showAnswer:m.prop(!1)},app.vm.compare={},app.vm.compare["Duration Compare"]=function(e,p){var r=m.prop(!1);try{r=app.vm.propy(juration.parse(e)==juration.parse(p))}catch(t){}return r},app.vm.compare["Byte Compare"]=function(e,p){var r=m.prop(!1);try{r=app.vm.propy(nattybytes.parse(e)==nattybytes.parse(p))}catch(t){}return r},app.vm.compare["String Compare"]=function(e,p){return app.vm.propy(e.toLowerCase()==p.toLowerCase())},app.vm.compare["MathJS Compare"]=function(e,p){var r=m.prop(!1);round=function(e){return math.eval(math.format(math.eval(e),{precision:5}))};try{r(0===math.compare(round(e),round(p)))}catch(t){}return r},app.vm.propy=function(e){return e?m.prop(!0):m.prop(!1)},app.vm.showLevels=function(){return app.vm.propy(app.vm.problem().problems.length>1)},app.vm.showHintBox=function(){return app.vm.propy(app.vm.problem().problems[app.vm.user.level].hint)},app.vm.isAnswerCorrect=function(){var e=app.vm.problem().problems[app.vm.user.level].solution;return app.vm.compare[e.method](e.answer,app.vm.user.answer())},app.vm.toggle=function(e){e(!e())},app.vm.opposite=function(e){return m.prop(!e())},app.vm.forceTrue=function(e){e(!0)},app.vm.display=function(e){return e()?"block":"none"},app.vm.visibility=function(e){return"undefined"==typeof e?".disabled":".pseudo"},app.vm.changeLevel=function(e){app.vm.user.level=e,app.vm.user.showHint(!1),app.vm.user.showAnswerBox(!1),app.vm.user.showAnswer(!1),app.vm.user.showDescription(!1),app.vm.user.answer("")}},app.controller=function(){app.vm.init(),this.doNothing=function(){return!1}};var renderKatex=function(e){for(var p="",r=e.indexOf("$");-1!==r;){var t=r+1,o=e.indexOf("$",t),a=e.substring(t,o);a=a.replace(/(?:\r\n|\r|\n)/g,"<br />"),p=p.concat(e.substring(0,t-1)+katex.renderToString(a)),e=e.substring(o+1),r=e.indexOf("$")}return p=p.concat(e.substring(r))};app.view=function(e){var p=app.vm.user;return[m(".controls",m("h2",app.vm.problem().problems[p.level].name),m(".postControls",m("p#date",app.vm.problem().problems[p.level].date),m("p#category",app.vm.problem().problems[p.level].category))),m("#problem",p.showAnswerBox()?app.vm.isAnswerCorrect()()?m(".flex",m("h1","Correct!"),m("p",p.answer()+" is correct! "+(app.vm.problem().problems[p.level].correct_message?app.vm.problem().problems[p.level].correct_message:"New problems every Monday, Wednesday, and Friday!"))):m("#incorrect",m("h3",p.showAnswer()?"Answer: "+app.vm.problem().problems[p.level].solution.answer:"Sorry, "+p.answer()+" is not correct!"),m(".buttons",m("button#try",{onclick:app.vm.toggle.bind(this,p.showAnswerBox)},"Try Again"),m("button.error",{style:{display:app.vm.display(app.vm.opposite(p.showAnswer))},onclick:app.vm.forceTrue.bind(this,p.showAnswer)},"Show Answer"),m("button.warning",{style:{display:app.vm.display(p.showAnswer)},onclick:app.vm.toggle.bind(this,p.showDescription)},p.showDescription()?"Hide Description":"Show Description")),m("pre",{style:{display:p.showDescription()?"block":"none"}},m.trust(renderKatex(app.vm.problem().problems[p.level].answer_desc)))):m("pre",m.trust(renderKatex(app.vm.problem().problems[p.level].problem)))),app.vm.showHintBox()()?m("table",m("tr",m("td",m("button",{onclick:app.vm.toggle.bind(this,p.showHint)},p.showHint()?"Hide Hint":"Show Hint")),m("td",m("span",p.showHint()?m.trust(renderKatex(app.vm.problem().problems[p.level].hint)):"")))):"",m("form",{onsubmit:e.doNothing.bind(e)},m("label",{"for":"answer"},"Answer:"),m("input[type=text]",{value:p.answer(),id:"answer",placeholder:"Enter your answer here",autocomplete:"off",onchange:m.withAttr("value",p.answer)}),m("input",{type:"submit",value:"Submit",onclick:app.vm.forceTrue.bind(e,p.showAnswerBox)})),m("p.nav",{style:{"text-align":"center"}},m("a.icon-step-backward.button"+app.vm.visibility(app.vm.problem().dateInfo.previous),{href:"/p/2015-11-23"},m("span.text","First")),m("a.icon-backward.button"+app.vm.visibility(app.vm.problem().dateInfo.previous),{href:"/p/"+app.vm.problem().dateInfo.previous},m("span.text","Prev")),m("a.icon-forward.button"+app.vm.visibility(app.vm.problem().dateInfo.next),{href:"/p/"+app.vm.problem().dateInfo.next},m("span.text","Next")),m("a.icon-step-forward.button"+app.vm.visibility(app.vm.problem().dateInfo.next),{href:"/"},m("span.text","Last")))]};
//# sourceMappingURL=app.js.map
