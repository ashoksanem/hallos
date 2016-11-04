function clear() {
    alert("clearing");
    document.getElementById("halmsg").innerHTML="";
}

function passDataToWeb(message){
    document.getElementById("halmsg").innerHTML=stringifyData(message);
}

function sendSSOAuthenticationMessageToWeb(message){
    document.getElementById("SSOMessage").innerHTML=stringifyData(message);
}

function stringifyData(message) {
    jsonStr = JSON.stringify(message),
    regeStr = '',
    f = {
    brace: 0
    };
    var regeStr = jsonStr.replace(/({|}[,]*|[^{}:]+:[^{}:,]*[,{]*)/g, function (m, p1) {
                                  var rtnFn = function() {
                                  return '<div style="text-indent: ' + (f['brace'] * 20) + 'px;">' + p1 + '</div>';
                                  },
                                  rtnStr = 0;
                                  if (p1.lastIndexOf('{') === (p1.length - 1)) {
                                  rtnStr = rtnFn();
                                  f['brace'] += 1;
                                  } else if (p1.indexOf('}') === 0) {
                                  f['brace'] -= 1;
                                  rtnStr = rtnFn();
                                  } else {
                                  rtnStr = rtnFn();
                                  }
                                  return rtnStr;
                                  });
    return regeStr;
}

function receiveDeviceId(message) {
    document.getElementById("halmsg").innerHTML = "deviceId: " + message.deviceId;
}

function passSSOData(message){
    document.getElementById("halmsg").innerHTML=message;
}


function updateSledBattery(message){
    document.getElementById("sledbatterypercentage").innerHTML=stringifyData(message);
}

function updateIpodBattery(message){
    document.getElementById("ipodbatterypercentage").innerHTML=stringifyData(message);
}
function passBarcodeDataToWeb(message){
    document.getElementById("halmsg").innerHTML=message;
}

function sendScannerStatus(message){
    if ( message ) {
        document.getElementById("scannerstatus").innerHTML="enabled";
    }
    else
    {
        document.getElementById("scannerstatus").innerHTML="disabled";
    }
}
function updateSledStatus(message){
    if ( message ) {
    document.getElementById("sledstatus").innerHTML="connected";
    }
    else
    {
    document.getElementById("sledstatus").innerHTML="not connected";
    }
}
function enableScannertest(){
    console.log(document.getElementById("enablescan").value);
    if(document.getElementById("enablescan").value=="enable scanner"){
        enableScanner()
        document.getElementById("enablescan").value="disable scanner";
    }
    else{
        disableScanner()
        document.getElementById("enablescan").value="enable scanner";
        }
}

