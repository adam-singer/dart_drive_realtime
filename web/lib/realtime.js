function Foo(x) {
  this.x = x;
}

Foo.prototype.add = function(other) {
  return new Foo(this.x + other.x);
}

function Realtime(access_token) {
  this.token = {'access_token':access_token};
  gapi.auth.setToken(this.token);
  console.log("TOKEN",this.token);
}

Realtime.prototype.load = function(fileId) {
	gapi.drive.realtime.load(fileId, onFileLoaded, initializeModel);
}

function onFileLoaded(doc) {
    var textArea1 = document.getElementById('textarea1');
    var textArea2 = document.getElementById('textarea2');

    var string = doc.getModel().getRoot().get('text');

    // Keeping one box updated with a String binder.

    gapi.drive.realtime.databinding.bindString(string, textArea1);

    // Keeping one box updated with a custom EventListener.
    var updateTextArea2 = function(e) {
        textArea2.value = string;
    };
    string.addEventListener(gapi.drive.realtime.EventType.TEXT_INSERTED, updateTextArea2);
    string.addEventListener(gapi.drive.realtime.EventType.TEXT_DELETED, updateTextArea2);
    textArea2.onkeyup = function() {
        string.setText(textArea2.value);
    };
    updateTextArea2();

    // Enabling UI Elements.
    textArea1.disabled = false;
    textArea2.disabled = false;
}

function initializeModel(model) {
    var string = model.createString("Hello Realtime World!");
    model.getRoot().set("text", string);
}
