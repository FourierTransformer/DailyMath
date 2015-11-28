// the controller handles what part of the model is relevant to the page
app.controller = function() {
    app.vm.init();
    this.doNothing = function() { return false; };
};