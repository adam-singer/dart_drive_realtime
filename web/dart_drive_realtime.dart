import 'dart:html';
import 'dart:json';
import 'dart:async';
import "package:google_drive_v2_api/drive_v2_api_browser.dart" as drivelib;
import "package:google_oauth2_client/google_oauth2_browser.dart";
import 'package:js/js.dart' as js;
import 'package:google_drive_realtime/google_drive_realtime.dart' as realtime;
import 'package:google_drive_realtime/google_drive_realtime_databinding.dart' as rtbinding;

String clientId = "";
GoogleOAuth2 auth;
drivelib.Drive drive;
final SCOPES = [drivelib.Drive.DRIVE_FILE_SCOPE, drivelib.Drive.DRIVE_SCOPE];
final GAPI_URL = "https://apis.google.com/js/api.js";

final TextAreaElement textArea1 = query("#textarea1");
final TextAreaElement textArea2 = query("#textarea2");
final ButtonElement createButton = query("#create");
final ButtonElement loadButton = query("#load");
final InputElement fileIdInput = query("#fileId");

void main() {
  
    clientId = window.localStorage["clientId"];
    if(clientId == null || clientId == "") _getClientId();
    print(clientId);
    auth = new GoogleOAuth2(clientId, SCOPES);
    drive = new drivelib.Drive(auth);
    drive.makeAuthRequests = true;
    
    ScriptElement gapiScript = new ScriptElement();
    gapiScript.src = GAPI_URL;
    document.body.children.add(gapiScript);
    
    gapiScript.onLoad.listen((data){
      js.context.gapi.load("auth:client,drive-realtime,drive-share", 
        new js.Callback.once((){
          _login();
        })    
      );
    });
    
    ScriptElement rtScript = new ScriptElement();
    rtScript.src = "lib/realtime.js";
    document.body.children.add(rtScript);
    
    createButton.onClick.listen(_newClick);
    loadButton.onClick.listen(_loadClick);
    fileIdInput.onInput.listen(_fileIdInputChange);
    
}

void _getClientId(){
  HttpRequest request = new HttpRequest();
  request.open("GET", "client_secrets.json");
  request.onLoad.listen((e){
    if(request.status == 200){
      Map client_secrets = parse(request.responseText);
      clientId = client_secrets["web"]["client_id"];
      window.localStorage["clientId"] = clientId;
    }
  });
  request.send();
  clientId = window.localStorage["clientId"];
}

void _login() {
  
  auth.login().then((token){
    createButton.disabled = false;
    fileIdInput.disabled = false;

  });
}

void _newClick(e) {
  var body = {
              'title': "New Realtime File",
              'mimeType': "application/vnd.google-apps.drive-sdk"
  };
  
  drivelib.File file = new drivelib.File.fromJson(body);
  drive.files.insert(file).then((drivelib.File newFile){
    String fileId = newFile.id;
    fileIdInput.value = fileId;
    _loadFile(fileId);
  });
}

void _loadClick(e) {
  _loadFile(fileIdInput.value);
}

void _loadFile(String fileId) {
  String access_token = auth.token.data;
  var token = {'access_token':access_token};
  js.context.gapi.auth.setToken(js.map(token));
  var onFileLoaded = new js.Callback.many(_onFileLoaded);
  var initializeModel = new js.Callback.once(_initializeModel);
  js.context.gapi.drive.realtime.load(fileId, onFileLoaded, initializeModel);
}

void _fileIdInputChange(e) {
  if(fileIdInput.value != "") loadButton.disabled = false;
}

void _initializeModel(js.Proxy modelProxy){
  realtime.Model model = realtime.Model.cast(modelProxy);
  realtime.CollaborativeString collabStr = model.createString("Hello Realtime World!");
  model.root.set("text",collabStr);
}

void _onFileLoaded(js.Proxy docProxy) {
  
  
  realtime.Document doc = realtime.Document.cast(docProxy);
  realtime.Model model = doc.model;
  realtime.CollaborativeString collabStr = new realtime.CollaborativeString.fromProxy(model.root.get("text"));
  
  rtbinding.Binding.cast(rtbinding.realtimeDatabinding['bindString'](collabStr, textArea1));
    
  collabStr.onTextInserted.listen((e) => textArea2.value = collabStr.text);
  collabStr.onTextDeleted.listen((e) => textArea2.value = collabStr.text);
  
  js.retain(collabStr);
  
  textArea1.disabled = false;
  
  textArea2.value = collabStr.text;
  
  
  
}